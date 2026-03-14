package com.petlog.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.petlog.app.R

class PetPhotoWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, prefs)
        }
    }

    companion object {
        fun updateWidget(context: Context, manager: AppWidgetManager, id: Int, prefs: SharedPreferences) {
            val views = RemoteViews(context.packageName, R.layout.pet_photo_widget)
            val petName = prefs.getString("flutter.widget_pet_name", "ぺとろぐ") ?: "ぺとろぐ"
            val emoji = prefs.getString("flutter.widget_pet_emoji", "🐾") ?: "🐾"
            val photoPath = prefs.getString("flutter.widget_photo_path", "") ?: ""

            views.setTextViewText(R.id.widget_pet_name, "$emoji $petName")
            // 写真がある場合は表示
            if (photoPath.isNotEmpty()) {
                try {
                    val file = java.io.File(photoPath)
                    if (file.exists()) {
                        val bitmap = android.graphics.BitmapFactory.decodeFile(photoPath)
                        if (bitmap != null) views.setImageViewBitmap(R.id.widget_image, bitmap)
                    }
                } catch (e: Exception) { /* ignore */ }
            }
            manager.updateAppWidget(id, views)
        }
    }
}
