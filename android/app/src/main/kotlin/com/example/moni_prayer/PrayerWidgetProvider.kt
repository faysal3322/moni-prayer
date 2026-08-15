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
        val timeFormat = SimpleDateFormat("h:mm", Locale.US)
        val amPm = if (now.get(Calendar.AM_PM) == Calendar.AM) {
            if (isBn) "am" else "AM"
        } else {
            if (isBn) "pm" else "PM"
        }
        var timeDigits = timeFormat.format(now.time)
        if (isBn) timeDigits = toBanglaDigits(timeDigits)

        // am/pm অংশ ছোট ফন্টে দেখানোর জন্য SpannableString
        val timeStr = SpannableString(timeDigits + "\u2009" + amPm)
        timeStr.setSpan(
            RelativeSizeSpan(0.45f),
            timeDigits.length,
            timeStr.length,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )

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
        views.setTextViewText(R.id.widget_waqt_name, prefs.getString("widget_waqt_name", "") ?: "")
        views.setTextViewText(R.id.widget_waqt_range, prefs.getString("widget_waqt_range", "") ?: "")
        views.setTextViewText(R.id.widget_waqt_remaining, prefs.getString("widget_waqt_remaining", "") ?: "")
        views.setTextViewText(R.id.widget_sunrise, prefs.getString("widget_sunrise", "") ?: "")
        views.setTextViewText(R.id.widget_sunset, prefs.getString("widget_sunset", "") ?: "")
        views.setTextViewText(R.id.widget_sehri, prefs.getString("widget_sehri", "") ?: "")
        views.setTextViewText(R.id.widget_iftar, prefs.getString("widget_iftar", "") ?: "")

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
