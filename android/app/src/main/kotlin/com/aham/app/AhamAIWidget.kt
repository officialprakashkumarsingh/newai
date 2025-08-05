package com.aham.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class AhamAIWidget : AppWidgetProvider() {
    
    companion object {
        const val ACTION_CHAT = "com.aham.app.ACTION_CHAT"
        const val ACTION_IMAGE = "com.aham.app.ACTION_IMAGE"
        const val ACTION_PRESENTATION = "com.aham.app.ACTION_PRESENTATION"
        const val ACTION_THINKING = "com.aham.app.ACTION_THINKING"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.ahamai_widget)
        
        // Set up click listeners for each button
        views.setOnClickPendingIntent(R.id.widget_chat, createPendingIntent(context, ACTION_CHAT))
        views.setOnClickPendingIntent(R.id.widget_image, createPendingIntent(context, ACTION_IMAGE))
        views.setOnClickPendingIntent(R.id.widget_presentation, createPendingIntent(context, ACTION_PRESENTATION))
        views.setOnClickPendingIntent(R.id.widget_thinking, createPendingIntent(context, ACTION_THINKING))
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun createPendingIntent(context: Context, action: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        return PendingIntent.getActivity(context, action.hashCode(), intent, flags)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_CHAT, ACTION_IMAGE, ACTION_PRESENTATION, ACTION_THINKING -> {
                // The intent will be handled by MainActivity
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = intent.action
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                context.startActivity(launchIntent)
            }
        }
    }
}