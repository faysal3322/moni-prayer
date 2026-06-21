package com.example.moni_prayer

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        // home_widget package এর data সরাসরি SharedPreferences থেকে পড়া হচ্ছে
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)

        views.setTextViewText(
            R.id.widget_time,
            prefs.getString("widget_time", "--:--")
        )
        views.setTextViewText(
            R.id.widget_day,
            prefs.getString("widget_day", "")
        )
        views.setTextViewText(
            R.id.widget_gregorian,
            prefs.getString("widget_gregorian", "")
        )
        views.setTextViewText(
            R.id.widget_hijri,
            prefs.getString("widget_hijri", "")
        )
        views.setTextViewText(
            R.id.widget_sunrise,
            prefs.getString("widget_sunrise", "")
        )
        views.setTextViewText(
            R.id.widget_sunset,
            prefs.getString("widget_sunset", "")
        )
        views.setTextViewText(
            R.id.widget_sehri,
            prefs.getString("widget_sehri", "")
        )
        views.setTextViewText(
            R.id.widget_iftar,
            prefs.getString("widget_iftar", "")
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
