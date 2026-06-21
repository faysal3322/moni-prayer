package com.example.moni_prayer

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

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
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)

        views.setTextViewText(
            R.id.widget_time,
            widgetData.getString("widget_time", "--:--")
        )
        views.setTextViewText(
            R.id.widget_day,
            widgetData.getString("widget_day", "")
        )
        views.setTextViewText(
            R.id.widget_gregorian,
            widgetData.getString("widget_gregorian", "")
        )
        views.setTextViewText(
            R.id.widget_hijri,
            widgetData.getString("widget_hijri", "")
        )
        views.setTextViewText(
            R.id.widget_sunrise,
            widgetData.getString("widget_sunrise", "")
        )
        views.setTextViewText(
            R.id.widget_sunset,
            widgetData.getString("widget_sunset", "")
        )
        views.setTextViewText(
            R.id.widget_sehri,
            widgetData.getString("widget_sehri", "")
        )
        views.setTextViewText(
            R.id.widget_iftar,
            widgetData.getString("widget_iftar", "")
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
