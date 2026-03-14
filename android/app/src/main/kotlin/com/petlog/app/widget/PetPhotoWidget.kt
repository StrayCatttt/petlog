package com.petlog.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.petlog.app.R

/**
 * ぺちろぐ 写真ウィジェット（PRO機能）
 * home_widget パッケージと連携してFlutter側からデータを受け取る
 */
class PetPhotoWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.pet_photo_widget)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
