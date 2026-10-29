package com.example.moni_prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.os.Build
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
        val endMs: Long,
        // ব্যাকগ্রাউন্ডের রং বাছাইয়ের জন্য ভাষা-নিরপেক্ষ চাবি
        // (fajr/forbidden/ishraq/duha/dhuhr/asr/maghrib/isha/tahajjud/night)
        val key: String = ""
    )

    // ফাঁকা দেখালে কারণ বোঝার জন্য (widget-এ ছোট কোড দেখায়)
    @Volatile private var nullReason: String = ""

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

    // computeIsForbidden()-এর fajrForbiddenEnd-এর সাথে অভিন্ন সূত্র —
    // এক জায়গায় রাখা হলো যাতে দুই ফাংশনে ভিন্ন মান হয়ে না যায়।
    private fun fajrForbiddenEnd(sunrise: Long) = sunrise + 15L * 60L * 1000L

    // ফিক্স (অ্যাপ না খুললে উইজেট আপডেট না হওয়া): Dart এখন আজ থেকে পরবর্তী
    // ৭ দিনের প্রতিদিনের ওয়াক্ত-সময় আগাম widget_dN_..._ms key-তে সেভ করে
    // রাখে (N = আজ থেকে কত দিন পরে, সাথে widget_dN_date = "yyyy-MM-dd")।
    // এই ফাংশন ফোনের *আজকের* তারিখ মিলিয়ে সঠিক দিনের সেট খুঁজে বের করে
    // এবং সেই সময়গুলো মূল widget_*_ms key-তে (in-memory map হিসেবে) বসিয়ে
    // দেয়, যাতে নিচের বাকি সব হিসাব কোড (যা widget_fajr_ms ইত্যাদি পড়ে)
    // একটুও না বদলেই সঠিক দিনের সময় পায়। অ্যাপ কয়েক দিন না খুললেও
    // উইজেট তাই ঠিক থাকে। মিল না পেলে (৭ দিনের বেশি অ্যাপ বন্ধ) null —
    // তখন আগের আচরণই (মূল widget_*_ms) কাজ করে।
    private fun todayOverrides(
        prefs: android.content.SharedPreferences,
        nowMs: Long
    ): Map<String, Long>? {
        val days = prefs.getInt("widget_days_ahead", 0)
        if (days <= 0) return null
        val cal = Calendar.getInstance().apply { timeInMillis = nowMs }
        val todayKey = String.format(
            Locale.US, "%04d-%02d-%02d",
            cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH)
        )
        val yCal = Calendar.getInstance().apply { timeInMillis = nowMs; add(Calendar.DAY_OF_YEAR, -1) }
        val yesterdayKey = String.format(
            Locale.US, "%04d-%02d-%02d",
            yCal.get(Calendar.YEAR), yCal.get(Calendar.MONTH) + 1, yCal.get(Calendar.DAY_OF_MONTH)
        )
        var todayIdx = -1
        var yesterdayIdx = -1
        for (i in 0 until days) {
            val d = prefs.getString("widget_d${i}_date", null) ?: continue
            if (d == todayKey) todayIdx = i
            if (d == yesterdayKey) yesterdayIdx = i
        }
        if (todayIdx < 0) return null
        val out = HashMap<String, Long>()
        val names = listOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
        for (n in names) {
            out["widget_${n}_ms"] = prefs.getLong("widget_d${todayIdx}_${n}_ms", 0L)
        }
        if (yesterdayIdx >= 0) {
            out["widget_y_maghrib_ms"] = prefs.getLong("widget_d${yesterdayIdx}_maghrib_ms", 0L)
            out["widget_y_isha_ms"] = prefs.getLong("widget_d${yesterdayIdx}_isha_ms", 0L)
        }
        return out
    }

    // আজকের তারিখের সাথে মেলা widget_dN_date-এর N (না পেলে -1)। বার/তারিখের
    // লেখা (widget_dN_day, _gregorian, _hijri, _bangla_date) নির্বাচনে লাগে।
    private fun todayIndex(prefs: android.content.SharedPreferences, nowMs: Long): Int {
        val days = prefs.getInt("widget_days_ahead", 0)
        if (days <= 0) return -1
        val cal = Calendar.getInstance().apply { timeInMillis = nowMs }
        val todayKey = String.format(
            Locale.US, "%04d-%02d-%02d",
            cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH)
        )
        for (i in 0 until days) {
            if (prefs.getString("widget_d${i}_date", null) == todayKey) return i
        }
        return -1
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
        nullReason = ""
        if (!prefs.contains("widget_fajr_ms")) { nullReason = "E1"; return null }

        // আজকের তারিখের জন্য আগাম-সেভ করা সেট থাকলে (অ্যাপ কয়েকদিন না
        // খুললেও) সেটাই ব্যবহার হবে, নইলে আগের মতো মূল prefs।
        val ov = todayOverrides(prefs, nowMs)
        fun pl(key: String): Long = ov?.get(key) ?: prefs.getLong(key, 0L)

        val fajr = pl("widget_fajr_ms")
        val sunrise = pl("widget_sunrise_ms")
        val dhuhr = pl("widget_dhuhr_ms")
        val asr = pl("widget_asr_ms")
        val maghrib = pl("widget_maghrib_ms")
        val isha = pl("widget_isha_ms")
        val yMaghribStored = pl("widget_y_maghrib_ms")
        val yIshaStored = pl("widget_y_isha_ms")

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
        if (!fajrIsToday && !fajrIsTomorrowFromNow) { nullReason = "E2"; return null }

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
        if (isPastMidnightBeforeFajr && !hasYesterday) { nullReason = "E3"; return null }

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

        // ══ নিষিদ্ধ সময়ের তিনটা windows — computeIsForbidden()-এর সাথে
        // হুবহু মেলানো (সূর্যোদয়-পরবর্তী ১৫ মিনিট, যাওয়াল দুহুরের ৫ মিনিট
        // আগে থেকে ৫ মিনিট পর পর্যন্ত, এবং মাগরিবের ঠিক ১৫ মিনিট আগে
        // থেকে মাগরিব পর্যন্ত)। এই তিন সময়ে waqt name এ "আসর"/"সূর্যোদয়"
        // ইত্যাদির বদলে "নিষিদ্ধ সময় (...)" দেখানো হবে — উপরের রেফারেন্স
        // widget-এর ধাঁচে।
        val forbidden1End = fajrForbiddenEnd(sunrise)
        val forbidden2Start = zawalStart
        val forbidden2End = dhuhr + 5L * 60L * 1000L
        val forbidden3Start = maghrib - 15L * 60L * 1000L

        // ══ সারাদিনের রং-ধাপ: সূর্যের অবস্থান (ওয়াক্তের সময়) ধরে ১৪টা ধাপ ══
        // আগে প্রতি ওয়াক্তে একটাই রং ছিল (যেমন দুহা ৬:৪৪–১১:৩৯ পুরোটা একই)।
        // এখন সূর্যোদয়/যোহর/আসর/মাগরিব/এশা-র আসল সময়ের সাপেক্ষে ধাপ ঠিক হয়,
        // তাই সকাল-৯টা-১০টা, দুপুর, বিকেল, সন্ধ্যা, রাত, গভীর রাত — সব আলাদা রং।
        // ধাপের নাম থেকে ড্রয়েবল বাছে backgroundForWaqt() (নিচে)।
        val min = 60_000L
        val asrToMaghrib = maghrib - asr
        val stage = when {
            nowMs >= fajr && nowMs < sunrise -> "fajr"
            nowMs >= sunrise && nowMs < sunrise + 45 * min -> "sunrise"
            nowMs >= sunrise + 45 * min && nowMs < sunrise + 150 * min -> "morning1"
            nowMs >= sunrise + 150 * min && nowMs < dhuhr - 90 * min -> "morning2"
            nowMs >= dhuhr - 90 * min && nowMs < dhuhr + 60 * min -> "noon"
            nowMs >= dhuhr + 60 * min && nowMs < asr -> "afternoon1"
            nowMs >= asr && nowMs < asr + asrToMaghrib * 45L / 100L -> "asr1"
            nowMs >= asr + asrToMaghrib * 45L / 100L && nowMs < maghrib - 30 * min -> "asr2"
            nowMs >= maghrib - 30 * min && nowMs < maghrib + 25 * min -> "sunset"
            nowMs >= maghrib + 25 * min && nowMs < isha -> "dusk"
            nowMs >= lastThird && nowMs < nextFajr -> "tahajjud"
            nowMs - nightIsha < 90 * min -> "isha"
            nowMs - nightIsha < 240 * min -> "night"
            else -> "deepnight"
        }

        fun range(s: Long, e: Long) = "${fmtNoAmPm(s, is24Hour)} - ${fmtNoAmPm(e, is24Hour)}"

        // শুক্রবারে যোহরের ওয়াক্তের নাম "জুম'আ" দেখানো হবে
        val isFriday = Calendar.getInstance().apply { timeInMillis = nowMs }
            .get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY

        return when {
            nowMs > fajr && nowMs < sunrise ->
                WaqtInfo(if (isBn) "ফজর" else "Fajr", range(fajr, sunrise), sunrise, stage)
            // নিষিদ্ধ সময় ১: সূর্যোদয় থেকে পরবর্তী ১৫ মিনিট পর্যন্ত
            nowMs >= sunrise && nowMs < forbidden1End ->
                WaqtInfo(
                    if (isBn) "নিষিদ্ধ সময় (সূর্যোদয়)" else "Forbidden time (Sunrise)",
                    range(sunrise, forbidden1End), forbidden1End, "forbidden"
                )
            nowMs >= forbidden1End && nowMs < ishraqEnd ->
                WaqtInfo(if (isBn) "ইশরাক" else "Ishraq", range(forbidden1End, ishraqEnd), ishraqEnd, stage)
            nowMs > chashtStart && nowMs < forbidden2Start ->
                WaqtInfo(if (isBn) "দুহা/চাশত" else "Duha/Chasht", range(chashtStart, forbidden2Start), forbidden2Start, stage)
            // নিষিদ্ধ সময় ২: যাওয়াল — দুহুরের ৫ মিনিট আগে থেকে ৫ মিনিট পর পর্যন্ত
            nowMs >= forbidden2Start && nowMs < forbidden2End ->
                WaqtInfo(
                    if (isBn) "নিষিদ্ধ সময় (যাওয়াল)" else "Forbidden time (Zawal)",
                    range(forbidden2Start, forbidden2End), forbidden2End, "forbidden"
                )
            nowMs >= forbidden2End && nowMs < asr ->
                WaqtInfo(
                    if (isFriday) (if (isBn) "জুম'আ" else "Jumu'ah")
                    else (if (isBn) "যোহর" else "Dhuhr"),
                    range(forbidden2End, asr), asr, stage
                )
            // নিষিদ্ধ সময় ৩: মাগরিবের ঠিক ১৫ মিনিট আগে থেকে মাগরিব পর্যন্ত
            nowMs >= forbidden3Start && nowMs < maghrib ->
                WaqtInfo(
                    if (isBn) "নিষিদ্ধ সময় (সূর্যাস্ত)" else "Forbidden time (Sunset)",
                    range(forbidden3Start, maghrib), maghrib, "forbidden"
                )
            nowMs > asr && nowMs < forbidden3Start ->
                WaqtInfo(if (isBn) "আসর" else "Asr", range(asr, forbidden3Start), forbidden3Start, stage)
            nowMs > maghrib && nowMs < isha ->
                WaqtInfo(if (isBn) "মাগরিব" else "Maghrib", range(maghrib, isha), isha, stage)
            nowMs > isha && nowMs < ishaaEnd ->
                WaqtInfo(if (isBn) "এশা" else "Isha", range(isha, ishaaEnd), ishaaEnd, stage)
            nowMs > nightIsha && nowMs >= lastThird && nowMs < nextFajr ->
                WaqtInfo(if (isBn) "তাহাজ্জুদ" else "Tahajjud", range(lastThird, fajr), nextFajr, stage)
            nowMs > nightIsha && nowMs < nextFajr ->
                WaqtInfo(if (isBn) "রাত" else "Night", range(nightIsha, lastThird), lastThird, stage)
            else -> { nullReason = "E4"; null }
        }
    }

    // prayer_time_screen.dart-এর "সালাতের নিষিদ্ধ সময়" এর সাথে হুবহু মেলানো
    // হিসাব — Dart-এর _updateHomeWidget()-এ থাকা isForbidden লজিকের মতোই।
    private fun computeIsForbidden(prefs: android.content.SharedPreferences, nowMs: Long): Boolean {
        if (!prefs.contains("widget_sunrise_ms")) return false
        val ov = todayOverrides(prefs, nowMs)
        val sunrise = ov?.get("widget_sunrise_ms") ?: prefs.getLong("widget_sunrise_ms", 0L)
        val dhuhr = ov?.get("widget_dhuhr_ms") ?: prefs.getLong("widget_dhuhr_ms", 0L)
        val maghrib = ov?.get("widget_maghrib_ms") ?: prefs.getLong("widget_maghrib_ms", 0L)

        val fajrForbiddenEnd = fajrForbiddenEnd(sunrise)
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
        try { scheduleWatchdog(context) } catch (e: Exception) { }
    }

    // ══ ফিক্স: উইজেটের মিনিট-অ্যালার্ম চেইন মরে গিয়ে উইজেট আটকে যাওয়া ══
    // AlarmManager-এর অ্যালার্ম ফোন রিস্টার্ট দিলে, ঘড়ি/তারিখ/টাইমজোন বদলালে
    // বা অ্যাপ আপডেট হলে মুছে যায় — তখন কেউ উইজেটকে আর জাগাত না এবং অ্যাপ না
    // খুলে উইজেট ঠিক হতো না। এখন এই ঘটনাগুলো ধরে উইজেট সঙ্গে সঙ্গে আপডেট
    // করা হয় এবং অ্যালার্ম চেইন আবার চালু করা হয় (এর জন্য Manifest-এ
    // নিচের action গুলো intent-filter-এ যোগ করা আছে)।
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED -> {
                try {
                    val mgr = AppWidgetManager.getInstance(context)
                    val ids = mgr.getAppWidgetIds(
                        ComponentName(context, PrayerWidgetProvider::class.java)
                    )
                    if (ids.isNotEmpty()) onUpdate(context, mgr, ids)
                } catch (e: Exception) { }
            }
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        try { scheduleNextUpdate(context) } catch (e: Exception) { }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        try { cancelUpdate(context) } catch (e: Exception) { }
    }

    // আজকের নিষিদ্ধ সময়গুলোর (সূর্যোদয়+১৫মি / যাওয়াল ±৫মি / মাগরিবের ১৫মি আগে)
    // শুরু ও শেষের মধ্যে এখনকার পরের মুহূর্তটা (+০.৩ সেকেন্ড, কারণ computeIsForbidden
    // কঠোর > / < ব্যবহার করে)। না পেলে null।
    private fun nextForbiddenEdge(context: Context, nowMs: Long): Long? {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        if (!prefs.contains("widget_sunrise_ms")) return null
        val ov = todayOverrides(prefs, nowMs)
        val sunrise = ov?.get("widget_sunrise_ms") ?: prefs.getLong("widget_sunrise_ms", 0L)
        val dhuhr = ov?.get("widget_dhuhr_ms") ?: prefs.getLong("widget_dhuhr_ms", 0L)
        val maghrib = ov?.get("widget_maghrib_ms") ?: prefs.getLong("widget_maghrib_ms", 0L)
        if (sunrise <= 0L || dhuhr <= 0L || maghrib <= 0L) return null
        val minMs = 60L * 1000L
        val edges = longArrayOf(
            sunrise, fajrForbiddenEnd(sunrise),
            dhuhr - 5L * minMs, dhuhr + 5L * minMs,
            maghrib - 15L * minMs, maghrib
        )
        var best = Long.MAX_VALUE
        for (e in edges) {
            val t = e + 300L
            if (t > nowMs && t < best) best = t
        }
        return if (best == Long.MAX_VALUE) null else best
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
        var triggerAt = nextMinute.timeInMillis
        // নিষিদ্ধ সময়ের শুরু বা শেষ পরের মিনিটের আগে পড়লে ঠিক সেই মুহূর্তে জাগো,
        // যাতে লাল রং সময় শুরু হওয়া মাত্র আসে এবং শেষ হওয়া মাত্র চলে যায়।
        try {
            val edge = nextForbiddenEdge(context, System.currentTimeMillis())
            if (edge != null && edge < triggerAt) triggerAt = edge
        } catch (e: Exception) { }
        // ফিক্স: Android 12+ এ exact-alarm অনুমতি না থাকলে বা বাতিল হলে
        // setExactAndAllowWhileIdle SecurityException ছোড়ে — আগে সেটা চুপচাপ
        // গিলে ফেলা হতো ফলে অ্যালার্ম চেইন সম্পূর্ণ বন্ধ হয়ে উইজেট আটকে যেত।
        // এখন অনুমতি না থাকলে (বা ব্যতিক্রম হলে) অন্তত অনুমানভিত্তিক
        // (inexact) অ্যালার্মে ফিরে যায়, যাতে উইজেট একদম থেমে না যায়।
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        } catch (e: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    // ══ ওয়াচডগ: মূল অ্যালার্ম মিস হলেও চেইন যেন না মরে ══
    // মূল অ্যালার্মের (requestCode 0) সাথে আরেকটা আলাদা অ্যালার্ম (requestCode 2)
    // ৫ মিনিট পরে বসে। দুটোই onUpdate চালায় এবং দুটোকেই আবার বসায়, তাই একটা
    // OEM/Doze-এ হারিয়ে গেলেও অন্যটা চেইন বাঁচিয়ে রাখে।
    private fun scheduleWatchdog(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_IDS,
                AppWidgetManager.getInstance(context)
                    .getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
            )
        }
        val pi = PendingIntent.getBroadcast(
            context, 2, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + 5L * 60_000L, pi)
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

    // ══ নিষিদ্ধ সময়ের লাল — কোডে আঁকা ছবি (Bitmap) ══
    // কেন: XML গ্র্যাডিয়েন্ট ড্রয়েবলে ফোনের লঞ্চার/ডার্ক-মোড রংটা ফ্যাকাশে (ধূসর মিশিয়ে)
    // দেখাচ্ছিল। ছবি (Bitmap) হিসেবে দিলে লঞ্চার রং বদলায় না — অন্য অ্যাপের উইজেটের
    // লাল স্ক্রিনশট থেকে মেপে বসানো হয়েছে (ওপরে E63623 → নিচে 7F1A12)।
    private fun redGradientBitmap(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val opts = try { appWidgetManager.getAppWidgetOptions(widgetId) } catch (e: Exception) { null }
        val wDp = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0
        val hDp = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0) ?: 0
        var w = if (wDp > 0) (wDp * density).toInt() else 900
        var h = if (hDp > 0) (hDp * density).toInt() else 700
        // মেমরি সীমা (RemoteViews-এর জন্য ছোট রাখা): বড় হলে অনুপাত ঠিক রেখে ছোট করি
        val maxSide = 720
        val big = maxOf(w, h)
        val scale = if (big > maxSide) maxSide.toFloat() / big else 1f
        w = maxOf(64, (w * scale).toInt())
        h = maxOf(64, (h * scale).toInt())
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        // ══ আসল কারণ (স্ক্রিনশটের রং মেপে প্রমাণ করা): আপনার ফোনের স্ক্রিন "ওয়াইড কালার"
        // (Display-P3)। সাধারণ sRGB রং এতে ~২০% ফ্যাকাশে দেখায় (লাল কমে, সবুজ/নীল বাড়ে)।
        // অন্য অ্যাপের উইজেটের রং সরাসরি P3-তে দেওয়া, তাই উজ্জ্বল। এখানে লক্ষ্য রংটা
        // (E63623 → 7F1A12) P3 ধরে sRGB-তে রূপান্তর করে এঁকেছি, ফলে ফোনে ঠিক একই রং দেখাবে।
        // ওয়াইড-গ্যামুট নয় এমন ফোনে আগের সাধারণ রংই ব্যবহার হয়।
        val wide = context.resources.configuration.isScreenWideColorGamut
        // নিষিদ্ধ সময়ের লাল: অন্য অ্যাপের পছন্দের উইজেট থেকে মেপে নেওয়া রং —
        // ওপরে গাঢ় লাল (C52E1C) থেকে নিচে কালচে লাল (7E1D0A) — চোখে আরামদায়ক।
        // ধাপ: ০%, ২০%, ৪০%, ৬০%, ৮০%, ১০০%
        val colors = if (wide) intArrayOf(
            0xFFD80B01.toInt(), 0xFFC70800.toInt(), 0xFFB70802.toInt(),
            0xFFA70300.toInt(), 0xFF970402.toInt(), 0xFF8D0000.toInt()
        ) else intArrayOf(
            0xFFC52E1C.toInt(), 0xFFB52A18.toInt(), 0xFFA62616.toInt(),
            0xFF982210.toInt(), 0xFF891E11.toInt(), 0xFF7E1D0A.toInt()
        )
        paint.shader = LinearGradient(
            0f, 0f, 0f, h.toFloat(),
            colors,
            floatArrayOf(0f, 0.20f, 0.40f, 0.60f, 0.80f, 1f),
            Shader.TileMode.CLAMP
        )
        val r = 20f * density * scale
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), r, r, paint)
        return bmp
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

        // ঘড়ি TextClock — সিস্টেম নিজেই প্রতি মিনিটে বদলায়। এখানে শুধু ফরম্যাট (১২/২৪)।
        val clockFmt = if (is24Hour) "HH:mm" else "h:mm"
        views.setCharSequence(R.id.widget_time, "setFormat12Hour", clockFmt)
        views.setCharSequence(R.id.widget_time, "setFormat24Hour", clockFmt)
        views.setViewVisibility(
            R.id.widget_ampm,
            if (is24Hour) android.view.View.GONE else android.view.View.VISIBLE
        )

        // click করলে app open
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingLaunch = PendingIntent.getActivity(
                    context, 1, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingLaunch)
                views.setOnClickPendingIntent(R.id.widget_time, pendingLaunch)
            }
        } catch (e: Exception) { }

        // ফিক্স: বার/তারিখগুলো আগে সরাসরি Dart-এর সেভ করা (একদিনের) স্ট্রিং
        // থেকে আসত — অ্যাপ না খুললে পরদিনও গতকালের তারিখ আটকে থাকত। এখন
        // আজকের তারিখের আগাম-সেভ করা লেখা বেছে নেওয়া হয়; না পেলে আগের মতো
        // মূল স্ট্রিংই ফলব্যাক।
        val dIdx = todayIndex(prefs, now.timeInMillis)
        fun dateText(suffix: String, fallbackKey: String): String {
            if (dIdx >= 0) {
                val v = prefs.getString("widget_d${dIdx}_$suffix", null)
                if (!v.isNullOrEmpty()) return v
            }
            return prefs.getString(fallbackKey, "") ?: ""
        }
        views.setTextViewText(R.id.widget_day, dateText("day", "widget_day"))
        views.setTextViewText(R.id.widget_weather, prefs.getString("widget_weather", "") ?: "")
        views.setTextViewText(R.id.widget_location, prefs.getString("widget_location", "") ?: "")
        views.setTextViewText(R.id.widget_gregorian, dateText("gregorian", "widget_gregorian"))
        views.setTextViewText(R.id.widget_hijri, dateText("hijri", "widget_hijri"))
        views.setTextViewText(R.id.widget_bangla_date, dateText("bangla_date", "widget_bangla_date"))

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
            val fbName = prefs.getString("widget_waqt_name", "") ?: ""
            views.setTextViewText(R.id.widget_waqt_name,
                if (fbName.isNotEmpty()) fbName else (if (isBn) "অ্যাপ একবার খুলুন" else "Open app once"))
            views.setTextViewText(R.id.widget_waqt_range,
                if (fbName.isNotEmpty()) (prefs.getString("widget_waqt_range", "") ?: "") else "($nullReason)")
            views.setTextViewText(R.id.widget_waqt_remaining_label, prefs.getString("widget_waqt_remaining_label", "") ?: "")
            views.setTextViewText(R.id.widget_waqt_remaining_value, prefs.getString("widget_waqt_remaining_value", "") ?: "")
        }
        // ফিক্স: এই চারটা সময় আগে Dart-এর সেভ করা স্ট্রিং থেকে সরাসরি আসত,
        // যা অ্যাপ না খুললে গতকালের সময়ই দেখাত। এখন আজকের তারিখের আগাম-সেভ
        // করা timestamp থেকে এখানেই (Kotlin-এ) ফরম্যাট করা হচ্ছে; না পেলে
        // আগের মতো Dart-এর স্ট্রিংই ফলব্যাক।
        val ovTimes = todayOverrides(prefs, now.timeInMillis)
        fun timeText(key: String, fallbackKey: String): String {
            val ms = ovTimes?.get(key)
            return if (ms != null && ms > 0L) fmtNoAmPm(ms, is24Hour)
            else (prefs.getString(fallbackKey, "") ?: "")
        }
        views.setTextViewText(R.id.widget_sunrise, timeText("widget_sunrise_ms", "widget_sunrise"))
        views.setTextViewText(R.id.widget_sunset, timeText("widget_maghrib_ms", "widget_sunset"))
        views.setTextViewText(R.id.widget_sehri, timeText("widget_fajr_ms", "widget_sehri"))
        views.setTextViewText(R.id.widget_iftar, timeText("widget_maghrib_ms", "widget_iftar"))

        // ══ দিন / রাত — মূল অ্যাপের ClockCard-এর _bottomTimeCol-এর সাথে
        // অভিন্ন সূত্র: দিন = সাহরি (ফজর) থেকে ইফতার (মাগরিব) পর্যন্ত
        // ব্যবধান; রাত = বাকি ২৪ ঘণ্টা। widget_fajr_ms/widget_maghrib_ms
        // আগে থেকেই (মিনিট-ভিত্তিক ওয়াক্ত হিসাবের জন্য) prefs-এ সেভ করা
        // থাকে, তাই এখানে নতুন কোনো prefs key লাগেনি — একই সংখ্যা থেকে
        // দিন/রাতের ব্যবধান বের করা হচ্ছে।
        try {
            if (prefs.contains("widget_fajr_ms") && prefs.contains("widget_maghrib_ms")) {
                val ovDay = todayOverrides(prefs, now.timeInMillis)
                val fajrMs = ovDay?.get("widget_fajr_ms") ?: prefs.getLong("widget_fajr_ms", 0L)
                val maghribMs = ovDay?.get("widget_maghrib_ms") ?: prefs.getLong("widget_maghrib_ms", 0L)
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
            // ফিক্স: লাল রং এখন সরাসরি ওপরের লেখার (waqtInfo) সিদ্ধান্ত থেকে আসে।
            // আগে দুটো আলাদা হিসাব ছিল (লেখা: computeWaqtInfo, রং: computeIsForbidden),
            // তাই লেখায় "নিষিদ্ধ সময় (সূর্যোদয়)" দেখালেও রং না বদলানো সম্ভব ছিল।
            // এখন লেখায় নিষিদ্ধ সময় দেখালেই রং লাল — এক হিসাব, দুই ফলাফল নেই।
            val isForbidden = (waqtInfo?.key == "forbidden") ||
                (if (prefs.contains("widget_sunrise_ms"))
                    computeIsForbidden(prefs, now.timeInMillis)
                else
                    prefs.getBoolean("widget_is_forbidden", false))
            val bgNowMs = now.timeInMillis
            val bgOv = todayOverrides(prefs, bgNowMs)
            fun bgT(n: String): Long = bgOv?.get("widget_${n}_ms") ?: prefs.getLong("widget_${n}_ms", 0L)
            // আকাশের রং সবসময় নিচের স্তরে বসে (লাল স্তরের নিচে লুকিয়ে থাকলেও ক্ষতি নেই)।
            val bgColor = SkyColor.backgroundColor(
                false, bgNowMs,
                bgT("fajr"), bgT("sunrise"), bgT("dhuhr"), bgT("asr"), bgT("maghrib"), bgT("isha")
            )
            // ঝাপসা লাল ঠিক করা: আগে আকাশের-রংয়ের স্তরের ওপর লাল স্তর বসত (দুটো
            // স্তর মিশে রং ফ্যাকাশে/ঝাপসা দেখাত)। এখন নিষিদ্ধ সময়ে একটাই স্তর —
            // সরাসরি উজ্জ্বল লাল গ্র্যাডিয়েন্ট, কোনো রং-ফিল্টার ছাড়া। অন্য সময়ে আগের মতো।
            if (isForbidden) {
                try {
                    views.setImageViewBitmap(R.id.widget_bg, redGradientBitmap(context, appWidgetManager, widgetId))
                } catch (e: Exception) {
                    views.setImageViewResource(R.id.widget_bg, R.drawable.widget_bg_forbidden_shape)
                }
                views.setInt(R.id.widget_bg, "setColorFilter", 0)
                views.setViewVisibility(R.id.widget_bg_forbidden, android.view.View.GONE)
            } else {
                views.setImageViewResource(R.id.widget_bg, R.drawable.widget_bg_shape)
                views.setInt(R.id.widget_bg, "setColorFilter", bgColor)
                views.setViewVisibility(R.id.widget_bg_forbidden, android.view.View.GONE)
            }
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

    // (এখন আর ব্যবহার হচ্ছে না — রং এখন SkyColor.kt থেকে আসে; আগের ১৪টা গ্র্যাডিয়েন্ট ড্রয়েবল
    // রেখে দেওয়া হয়েছে যাতে চাইলে ফিরে যাওয়া যায়।)
    // চলতি ওয়াক্তের চাবি থেকে ব্যাকগ্রাউন্ড ড্রয়েবল বাছাই — ড্রয়েবলগুলো
    // res/drawable/widget_bg_*.xml এ আছে; রং বদলাতে চাইলে সেখানের hex বদলান।
    private fun backgroundForWaqt(key: String?): Int = when (key) {
        "fajr" -> R.drawable.widget_bg_fajr              // ভোর/ফজর
        "sunrise" -> R.drawable.widget_bg_ishraq         // সূর্যোদয় (পীচ→ম্যাজেন্টা)
        "morning1" -> R.drawable.widget_bg_duha          // সকাল — সবুজাভ নীল
        "morning2" -> R.drawable.widget_bg_morning2      // ৯–১০টা — উজ্জ্বল আকাশি
        "noon" -> R.drawable.widget_bg_dhuhr             // দুপুর — গাঢ় নীল
        "afternoon1" -> R.drawable.widget_bg_afternoon1  // দুপুর গড়ানো — ধূসর-নীল
        "asr1" -> R.drawable.widget_bg_asr               // বিকেল — সোনালি
        "asr2" -> R.drawable.widget_bg_asr2              // বিকেলের শেষ — কমলা
        "sunset" -> R.drawable.widget_bg_maghrib         // সূর্যাস্ত — লালচে কমলা
        "dusk" -> R.drawable.widget_bg_dusk              // গোধূলি — বেগুনি
        "isha" -> R.drawable.widget_bg_isha              // এশা — নেভি
        "night" -> R.drawable.widget_bg_night            // রাত — ইন্ডিগো
        "deepnight" -> R.drawable.widget_bg_deepnight    // গভীর রাত — প্রায় কালো
        "tahajjud" -> R.drawable.widget_bg_tahajjud      // শেষ রাত — বেগুনি
        else -> R.drawable.widget_background
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
