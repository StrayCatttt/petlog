package com.petlog.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.petlog.app.R

class PetCountWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pet_count_widget)
            val petName = prefs.getString("flutter.count_pet_name", "ぺとろぐ") ?: "ぺとろぐ"
            val emoji = prefs.getString("flutter.count_pet_emoji", "🐾") ?: "🐾"
            val days = prefs.getLong("flutter.count_days", 0L)
            val age = prefs.getString("flutter.count_age", "") ?: ""

            views.setTextViewText(R.id.widget_emoji, emoji)
            views.setTextViewText(R.id.widget_days, "一緒に ${days}日目 🎂")
            views.setTextViewText(R.id.widget_name, "$petName${if (age.isNotEmpty()) " · $age" else ""}")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
