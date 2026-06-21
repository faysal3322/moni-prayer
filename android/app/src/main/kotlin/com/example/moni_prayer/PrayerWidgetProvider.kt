package com.example.moni_prayer

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class PrayerWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_AUTO_UPDATE = "com.example.moni_prayer.WIDGET_AUTO_UPDATE"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
        scheduleNextUpdate(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_AUTO_UPDATE || intent.action == "android.appwidget.action.APPWIDGET_UPDATE") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, PrayerWidgetProvider::class.java)
            )
            for (widgetId in widgetIds) {
                updateWidget(context, appWidgetManager, widgetId)
            }
            scheduleNextUpdate(context)
        }
    }

    private fun scheduleNextUpdate(context: Context) {
        // প্রতি মিনিটে widget এর সময় ঘড়ি নিজেই রিফ্রেশ করবে (app বন্ধ থাকলেও)
        val intent = Intent(context, PrayerWidgetProvider::class.java)
        intent.action = ACTION_AUTO_UPDATE
        val pendingIntent = android.app.PendingIntent.getBroadcast(
            context, 0, intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val triggerTime = System.currentTimeMillis() + 60_000L // ১ মিনিট পর
        alarmManager.setExact(android.app.AlarmManager.RTC, triggerTime, pendingIntent)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)

        // ══ সময় widget নিজেই হিসাব করছে (app বন্ধ থাকলেও সঠিক সময় দেখাবে) ══
        val now = Calendar.getInstance()
        val isBn = prefs.getBoolean("widget_is_bn", true)
        val timeFormat = SimpleDateFormat("h:mm", Locale.US)
        val amPm = if (now.get(Calendar.AM_PM) == Calendar.AM) {
            if (isBn) "am" else "AM"
        } else {
            if (isBn) "pm" else "PM"
        }
        var timeStr = timeFormat.format(now.time) + " " + amPm
        if (isBn) {
            timeStr = toBanglaDigits(timeStr)
        }
        views.setTextViewText(R.id.widget_time, timeStr)

        // বাকি তথ্য app থেকে পাঠানো data থেকে আসছে (এসব প্রতি মিনিটে বদলায় না)
        views.setTextViewText(R.id.widget_day, prefs.getString("widget_day", ""))
        views.setTextViewText(R.id.widget_gregorian, prefs.getString("widget_gregorian", ""))
        views.setTextViewText(R.id.widget_hijri, prefs.getString("widget_hijri", ""))
        views.setTextViewText(R.id.widget_sunrise, prefs.getString("widget_sunrise", ""))
        views.setTextViewText(R.id.widget_sunset, prefs.getString("widget_sunset", ""))
        views.setTextViewText(R.id.widget_sehri, prefs.getString("widget_sehri", ""))
        views.setTextViewText(R.id.widget_iftar, prefs.getString("widget_iftar", ""))

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun toBanglaDigits(input: String): String {
        val en = charArrayOf('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
        val bn = charArrayOf('০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯')
        val sb = StringBuilder()
        for (c in input) {
            val idx = en.indexOf(c)
            sb.append(if (idx != -1) bn[idx] else c)
        }
        return sb.toString()
    }

    override fun onEnabled(context: Context) {
        scheduleNextUpdate(context)
    }
}
