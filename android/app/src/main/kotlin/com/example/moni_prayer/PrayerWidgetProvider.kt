package com.example.moni_prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class PrayerWidgetProvider : AppWidgetProvider() {

    // Dart-এর _currentWidgetWaqt()-এর হুবহু (এক-এক লজিক মেলানো) Kotlin
    // সংস্করণ। এখানে কোনো astronomical calculation করা হচ্ছে না (সেটা
    // এখনো Dart-এর adhan প্যাকেজেই থাকছে, সবচেয়ে নির্ভরযোগ্য অংশ যেন
    // অপরিবর্তিত থাকে) — শুধু Dart থেকে আগেই পাঠানো আজ/গতকাল/আগামীকালের
    // ওয়াক্তের epoch millisecond গুলো নিয়ে "এখন কোন ওয়াক্ত, কত বাকি"
    // হিসাব করা হচ্ছে। এটাই মূল ফিক্স: এই হিসাবটা Dart isolate সচল
    // থাকা-না-থাকার উপর নির্ভর করে না, তাই Flutter অ্যাপ বন্ধ থাকলেও
    // AlarmManager প্রতি মিনিটে জেগে এই ফাংশন কল করে widget আপডেট করতে
    // পারে।
    data class WaqtInfo(
        val name: String,
        val range: String,
        val endMs: Long
    )

    private fun fmtNoAmPm(ms: Long, is24Hour: Boolean): String {
        val cal = Calendar.getInstance()
        cal.timeInMillis = ms
        val h = cal.get(Calendar.HOUR_OF_DAY)
        val m = cal.get(Calendar.MINUTE)
        return if (is24Hour) {
            String.format(Locale.US, "%02d:%02d", h, m)
        } else {
            val h12 = if (h % 12 == 0) 12 else h % 12
            String.format(Locale.US, "%d:%02d", h12, m)
        }
    }

    private fun computeWaqtInfo(
        prefs: android.content.SharedPreferences,
        nowMs: Long,
        isBn: Boolean,
        is24Hour: Boolean
    ): WaqtInfo? {
        // কোনো ওয়াক্তের timestamp prefs-এ না থাকলে (Dart এখনো একবারও
        // চালু হয়নি) হিসাব করা সম্ভব না — null রিটার্ন, caller খালি
        // দেখাবে (crash না করে)।
        if (!prefs.contains("widget_fajr_ms")) return null

        val fajr = prefs.getLong("widget_fajr_ms", 0L)
        val sunrise = prefs.getLong("widget_sunrise_ms", 0L)
        val dhuhr = prefs.getLong("widget_dhuhr_ms", 0L)
        val asr = prefs.getLong("widget_asr_ms", 0L)
        val maghrib = prefs.getLong("widget_maghrib_ms", 0L)
        val isha = prefs.getLong("widget_isha_ms", 0L)
        val yMaghribStored = prefs.getLong("widget_y_maghrib_ms", 0L)
        val yIshaStored = prefs.getLong("widget_y_isha_ms", 0L)

        // ══ মূল ফিক্স: বাসি (stale) prefs ডেটা শনাক্ত করা ══
        // আগে ধরে নেওয়া হতো prefs-এ থাকা fajr/isha/maghrib সবসময়
        // "আজকের" মান। কিন্তু Flutter অ্যাপ যদি টানা একদিনের বেশি বন্ধ
        // থাকে (prefs-এ শেষবার লেখা পুরনো কোনো দিনের), তাহলে এই সংখ্যাগুলো
        // আসলে গতকাল/তার আগের দিনের এশা/মাগরিবের timestamp বহন করে —
        // যা বর্তমান সময়ের চেয়ে ছোট, তাই "nowMs > nightIsha" শর্তটা
        // ভুলভাবে সবসময় true হয়ে যেত এবং সারাদিন (এমনকি সকাল/দুপুরেও)
        // widget "রাত" আটকে দেখাত।
        //
        // সমাধান: prefs-এর fajr timestamp থেকে ক্যালেন্ডার-দিন বের করে
        // ফোনের আজকের দিনের সাথে তুলনা করা হচ্ছে। যদি prefs-এর fajr আজকের
        // দিনের না হয় (অতীতের কোনো পুরনো দিনের), তাহলে ডেটা বাসি ধরে
        // নিয়ে null রিটার্ন — caller তখন Dart-এর পাঠানো শেষ স্ট্রিং
        // ফলব্যাক হিসেবে দেখাবে, একটা ভুল দিনের হিসাব থেকে ভালো, এবং এটা
        // ব্যবহারকারীকে ইঙ্গিত দেবে যে অ্যাপটা একবার খোলা দরকার।
        val fajrCal = Calendar.getInstance().apply { timeInMillis = fajr }
        val nowCal = Calendar.getInstance().apply { timeInMillis = nowMs }
        val fajrIsToday = fajrCal.get(Calendar.YEAR) == nowCal.get(Calendar.YEAR) &&
                fajrCal.get(Calendar.DAY_OF_YEAR) == nowCal.get(Calendar.DAY_OF_YEAR)
        // ফজরের পরের কিছু সময় (মধ্যরাত পার হয়ে) prefs-এর fajr এখনো
        // "গতকাল" হিসেবে গণনা হতে পারে যদিও এটা বৈধ আজকের-রাতের ডেটা —
        // তাই ফজরের আগের সময়ে (isPastMidnightBeforeFajr সম্ভাবনা) ১ দিন
        // যোগ করেও পরীক্ষা করা হচ্ছে।
        val fajrIsTomorrowFromNow = run {
            val tmr = Calendar.getInstance().apply { timeInMillis = nowMs; add(Calendar.DAY_OF_YEAR, 1) }
            fajrCal.get(Calendar.YEAR) == tmr.get(Calendar.YEAR) &&
                    fajrCal.get(Calendar.DAY_OF_YEAR) == tmr.get(Calendar.DAY_OF_YEAR)
        }
        if (!fajrIsToday && !fajrIsTomorrowFromNow) return null

        val isPastMidnightBeforeFajr = nowMs < fajr
        val hasYesterday = yMaghribStored > 0L && yIshaStored > 0L

        // ফিক্স: মধ্যরাতের পর কিন্তু ফজরের আগের সময়ে (isPastMidnightBeforeFajr
        // == true) "রাত"/"তাহাজ্জুদ" ওয়াক্ত হিসাব করতে অবশ্যই *গতকালের*
        // মাগরিব/এশা লাগবে। সেই ডেটা prefs-এ এখনো না থাকলে (Dart এখনো
        // একবারও নতুন কোড দিয়ে সেভ করেনি, বা কোনো কারণে লেখা ব্যর্থ
        // হয়েছে) আজকের মাগরিব/এশা দিয়ে ভুল হিসাব করার বদলে null
        // রিটার্ন করা হচ্ছে — caller তখন Dart-এর পাঠানো (হয়তো কিছুটা
        // বাসি কিন্তু অন্তত সঠিক দিনের) fallback স্ট্রিং দেখাবে, সম্পূর্ণ
        // ভুল দিনের হিসাব থেকে অনেক ভালো।
        if (isPastMidnightBeforeFajr && !hasYesterday) return null

        val nightMaghrib = if (isPastMidnightBeforeFajr) yMaghribStored else maghrib
        val nightIsha = if (isPastMidnightBeforeFajr) yIshaStored else isha

        // Dart-এর _currentWidgetWaqt()-এর nextFajr লজিকের সাথে হুবহু
        // মেলানো (pt.fajr.isAfter(nightMaghrib) ? pt.fajr : pt.fajr + 1day)
        // — dedicated tomorrowFajr prefs ব্যবহার করা হচ্ছে না, কারণ Dart
        // সাইডও তা করে না; দুই পাশের হিসাব ভিন্ন হয়ে গেলে সেটাই আসল বাগের
        // উৎস হতে পারে (যেমন এই স্ক্রিনশটে দেখা "রাত ১২:৫৫ পার হয়ে গেছে"
        // সমস্যা)।
        val nextFajr = if (fajr > nightMaghrib) fajr else fajr + 24L * 3600L * 1000L
        val nightDuration = nextFajr - nightMaghrib
        val lastThird = nightMaghrib + (nightDuration * 2L / 3L)
        val ishaaEnd = lastThird

        val ishraqStart = sunrise + 15L * 60L * 1000L
        val ishraqEnd = sunrise + 45L * 60L * 1000L
        val chashtStart = sunrise + 45L * 60L * 1000L
        val zawalStart = dhuhr - 5L * 60L * 1000L
        val zawalEnd = dhuhr

        fun range(s: Long, e: Long) = "${fmtNoAmPm(s, is24Hour)} - ${fmtNoAmPm(e, is24Hour)}"

        return when {
            nowMs > fajr && nowMs < sunrise ->
                WaqtInfo(if (isBn) "ফজর" else "Fajr", range(fajr, sunrise), sunrise)
            nowMs >= sunrise && nowMs < ishraqStart ->
                WaqtInfo(if (isBn) "সূর্যোদয়" else "Sunrise", range(sunrise, ishraqStart), ishraqStart)
            nowMs > ishraqStart && nowMs < ishraqEnd ->
                WaqtInfo(if (isBn) "ইশরাক" else "Ishraq", range(ishraqStart, ishraqEnd), ishraqEnd)
            nowMs > chashtStart && nowMs < zawalStart ->
                WaqtInfo(if (isBn) "দুহা/চাশত" else "Duha/Chasht", range(chashtStart, zawalStart), zawalStart)
            nowMs > zawalStart && nowMs < zawalEnd ->
                WaqtInfo(if (isBn) "যাওয়াল" else "Zawal", range(zawalStart, zawalEnd), zawalEnd)
            nowMs > dhuhr && nowMs < asr ->
                WaqtInfo(if (isBn) "যোহর" else "Dhuhr", range(dhuhr, asr), asr)
            nowMs > asr && nowMs < maghrib ->
                WaqtInfo(if (isBn) "আসর" else "Asr", range(asr, maghrib), maghrib)
            nowMs > maghrib && nowMs < isha ->
                WaqtInfo(if (isBn) "মাগরিব" else "Maghrib", range(maghrib, isha), isha)
            nowMs > isha && nowMs < ishaaEnd ->
                WaqtInfo(if (isBn) "এশা" else "Isha", range(isha, ishaaEnd), ishaaEnd)
            nowMs > nightIsha && nowMs >= lastThird && nowMs < nextFajr ->
                WaqtInfo(if (isBn) "তাহাজ্জুদ" else "Tahajjud", range(lastThird, fajr), nextFajr)
            nowMs > nightIsha && nowMs < nextFajr ->
                WaqtInfo(if (isBn) "রাত" else "Night", range(nightIsha, lastThird), lastThird)
            else -> null
        }
    }

    // prayer_time_screen.dart-এর "সালাতের নিষিদ্ধ সময়" এর সাথে হুবহু মেলানো
    // হিসাব — Dart-এর _updateHomeWidget()-এ থাকা isForbidden লজিকের মতোই।
    private fun computeIsForbidden(prefs: android.content.SharedPreferences, nowMs: Long): Boolean {
        if (!prefs.contains("widget_sunrise_ms")) return false
        val sunrise = prefs.getLong("widget_sunrise_ms", 0L)
        val dhuhr = prefs.getLong("widget_dhuhr_ms", 0L)
        val maghrib = prefs.getLong("widget_maghrib_ms", 0L)

        val fajrForbiddenEnd = sunrise + 15L * 60L * 1000L
        val zawalStart = dhuhr - 5L * 60L * 1000L
        val zawalEnd = dhuhr + 5L * 60L * 1000L
        val asrForbiddenStart = maghrib - 15L * 60L * 1000L

        return (nowMs > sunrise && nowMs < fajrForbiddenEnd) ||
               (nowMs > zawalStart && nowMs < zawalEnd) ||
               (nowMs > asrForbiddenStart && nowMs < maghrib)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            try {
                updateWidget(context, appWidgetManager, widgetId)
            } catch (e: Exception) {
                try {
                    val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)
                    views.setTextViewText(R.id.widget_time, "--:--")
                    appWidgetManager.updateAppWidget(widgetId, views)
                } catch (e2: Exception) { }
            }
        }
        try { scheduleNextUpdate(context) } catch (e: Exception) { }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        try { scheduleNextUpdate(context) } catch (e: Exception) { }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        try { cancelUpdate(context) } catch (e: Exception) { }
    }

    private fun scheduleNextUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val ids = AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val nextMinute = Calendar.getInstance().apply {
            add(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextMinute.timeInMillis, pendingIntent)
    }

    private fun cancelUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidgetProvider::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)

        val now = Calendar.getInstance()
        val isBn = prefs.getBoolean("widget_is_bn", true)
        val is24Hour = prefs.getBoolean("widget_24hr", false)

        val timeStr: SpannableString
        if (is24Hour) {
            // ২৪ ঘণ্টা ফরম্যাটে am/pm লাগে না
            val timeFormat = SimpleDateFormat("HH:mm", Locale.US)
            val timeDigits = timeFormat.format(now.time)
            timeStr = SpannableString(timeDigits)
        } else {
            val timeFormat = SimpleDateFormat("h:mm", Locale.US)
            val amPm = if (now.get(Calendar.AM_PM) == Calendar.AM) "AM" else "PM"
            val timeDigits = timeFormat.format(now.time)
            // am/pm অংশ ছোট ফন্টে দেখানোর জন্য SpannableString
            timeStr = SpannableString(timeDigits + "\u2009" + amPm)
            timeStr.setSpan(
                RelativeSizeSpan(0.45f),
                timeDigits.length,
                timeStr.length,
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }

        views.setTextViewText(R.id.widget_time, timeStr)

        // click করলে app open
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingLaunch = PendingIntent.getActivity(
                    context, 1, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_time, pendingLaunch)
            }
        } catch (e: Exception) { }

        views.setTextViewText(R.id.widget_day, prefs.getString("widget_day", "") ?: "")
        views.setTextViewText(R.id.widget_weather, prefs.getString("widget_weather", "") ?: "")
        views.setTextViewText(R.id.widget_location, prefs.getString("widget_location", "") ?: "")
        views.setTextViewText(R.id.widget_gregorian, prefs.getString("widget_gregorian", "") ?: "")
        views.setTextViewText(R.id.widget_hijri, prefs.getString("widget_hijri", "") ?: "")
        views.setTextViewText(R.id.widget_bangla_date, prefs.getString("widget_bangla_date", "") ?: "")

        // ══ মূল ফিক্স ══
        // আগে widget_waqt_name/range/remaining সরাসরি prefs থেকে
        // (Dart-এর হিসাব করা বাসি স্ট্রিং) পড়া হতো — Flutter অ্যাপ বন্ধ
        // থাকলে এগুলো কখনো আপডেট হতো না। এখন এই মিনিট-ভিত্তিক অংশটুকু
        // এখানেই, Kotlin-এ, বর্তমান সময় (now) আর Dart-এর পাঠানো স্থির
        // ওয়াক্ত-timestamp দিয়ে হিসাব হচ্ছে — তাই AlarmManager প্রতি
        // মিনিটে জাগলেই (Flutter চালু থাকুক বা না থাকুক) এই তথ্য
        // সবসময় বর্তমান মুহূর্তের সাথে মিলে যাবে, কখনো পিছিয়ে থাকবে না।
        // মিনিট-ভিত্তিক অংশটুকু (কোন ওয়াক্ত, কত বাকি) এখানেই হিসাব হচ্ছে
        // — উপরে ঘোষিত isBn/is24Hour ব্যবহার করে।
        val waqtInfo = computeWaqtInfo(prefs, now.timeInMillis, isBn, is24Hour)
        if (waqtInfo != null) {
            views.setTextViewText(R.id.widget_waqt_name, waqtInfo.name)
            views.setTextViewText(R.id.widget_waqt_range, waqtInfo.range)
            views.setTextViewText(R.id.widget_waqt_remaining_label, if (isBn) "ওয়াক্ত বাকি" else "Time left")
            val diffMs = waqtInfo.endMs - now.timeInMillis
            val remaining = if (diffMs < 0) "" else {
                val totalMinutes = diffMs / 60000L
                val hh = (totalMinutes / 60).toString().padStart(2, '0')
                val mm = (totalMinutes % 60).toString().padStart(2, '0')
                "$hh:$mm"
            }
            views.setTextViewText(R.id.widget_waqt_remaining_value, remaining)
        } else {
            // Dart এখনো একবারও চালু হয়ে prefs না লিখলে (একদম প্রথমবার
            // ইনস্টলের পর), fallback হিসেবে Dart-এর পাঠানো পুরনো স্ট্রিং
            // (যদি থাকে) দেখানো হচ্ছে — যাতে widget একদম খালি না থাকে।
            views.setTextViewText(R.id.widget_waqt_name, prefs.getString("widget_waqt_name", "") ?: "")
            views.setTextViewText(R.id.widget_waqt_range, prefs.getString("widget_waqt_range", "") ?: "")
            views.setTextViewText(R.id.widget_waqt_remaining_label, prefs.getString("widget_waqt_remaining_label", "") ?: "")
            views.setTextViewText(R.id.widget_waqt_remaining_value, prefs.getString("widget_waqt_remaining_value", "") ?: "")
        }
        views.setTextViewText(R.id.widget_sunrise, prefs.getString("widget_sunrise", "") ?: "")
        views.setTextViewText(R.id.widget_sunset, prefs.getString("widget_sunset", "") ?: "")
        views.setTextViewText(R.id.widget_sehri, prefs.getString("widget_sehri", "") ?: "")
        views.setTextViewText(R.id.widget_iftar, prefs.getString("widget_iftar", "") ?: "")

        // ══ দিন / রাত — মূল অ্যাপের ClockCard-এর _bottomTimeCol-এর সাথে
        // অভিন্ন সূত্র: দিন = সাহরি (ফজর) থেকে ইফতার (মাগরিব) পর্যন্ত
        // ব্যবধান; রাত = বাকি ২৪ ঘণ্টা। widget_fajr_ms/widget_maghrib_ms
        // আগে থেকেই (মিনিট-ভিত্তিক ওয়াক্ত হিসাবের জন্য) prefs-এ সেভ করা
        // থাকে, তাই এখানে নতুন কোনো prefs key লাগেনি — একই সংখ্যা থেকে
        // দিন/রাতের ব্যবধান বের করা হচ্ছে।
        try {
            if (prefs.contains("widget_fajr_ms") && prefs.contains("widget_maghrib_ms")) {
                val fajrMs = prefs.getLong("widget_fajr_ms", 0L)
                val maghribMs = prefs.getLong("widget_maghrib_ms", 0L)
                val dayMs = maghribMs - fajrMs
                val nightMs = 24L * 3600L * 1000L - dayMs
                fun fmtDuration(ms: Long): String {
                    val totalMinutes = ms / 60000L
                    val hh = (totalMinutes / 60).toString().padStart(2, '0')
                    val mm = (totalMinutes % 60).toString().padStart(2, '0')
                    return "$hh:$mm"
                }
                views.setTextViewText(R.id.widget_day_duration, fmtDuration(dayMs))
                views.setTextViewText(R.id.widget_night_duration, fmtDuration(nightMs))
            } else {
                views.setTextViewText(R.id.widget_day_duration, "")
                views.setTextViewText(R.id.widget_night_duration, "")
            }
        } catch (e: Exception) { }

        // নামাজের নিষিদ্ধ সময়ে (এখন এখানেই, Kotlin-এ, computeIsForbidden
        // দিয়ে সরাসরি হিসাব করা হয় — prefs-এর বাসি widget_is_forbidden
        // ফ্ল্যাগের উপর আর নির্ভর করে না) পুরো widget-এর ব্যাকগ্রাউন্ড
        // লাল করে দেওয়া হয়, অন্যথায় স্বাভাবিক (ডিফল্ট) ব্যাকগ্রাউন্ড থাকে।
        try {
            val isForbidden = if (prefs.contains("widget_sunrise_ms"))
                computeIsForbidden(prefs, now.timeInMillis)
            else
                prefs.getBoolean("widget_is_forbidden", false)
            val bgRes = if (isForbidden) R.drawable.widget_background_forbidden else R.drawable.widget_background
            views.setInt(R.id.widget_root, "setBackgroundResource", bgRes)
        } catch (e: Exception) { }

        // rotating alert - crash safe
        try {
            val alertFull = prefs.getString("widget_alert", "") ?: ""
            if (alertFull.isNotEmpty()) {
                val parts = alertFull.split("\u0001").filter { it.isNotEmpty() }
                if (parts.isNotEmpty()) {
                    val idx = now.get(Calendar.MINUTE) % parts.size
                    // সেকেন্ড কাউন্টডাউন (HH:MM:SS) সরিয়ে শুধু HH:MM দেখাও
                    val alertText = parts[idx].trim()
                        .replace(Regex("(\\d{2}):(\\d{2}):\\d{2}"), "$1:$2")
                    views.setTextViewText(R.id.widget_alert, alertText)
                } else {
                    views.setTextViewText(R.id.widget_alert, "")
                }
            } else {
                views.setTextViewText(R.id.widget_alert, "")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.widget_alert, "")
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun toBanglaDigits(input: String): String {
        val en = charArrayOf('0','1','2','3','4','5','6','7','8','9')
        val bn = charArrayOf('০','১','২','৩','৪','৫','৬','৭','৮','৯')
        val sb = StringBuilder()
        for (c in input) {
            val idx = en.indexOf(c)
            sb.append(if (idx != -1) bn[idx] else c)
        }
        return sb.toString()
    }
}
