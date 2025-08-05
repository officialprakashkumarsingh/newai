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
        const val ACTION_SEND = "com.aham.app.ACTION_SEND"
        const val ACTION_WEB_SEARCH = "com.aham.app.ACTION_WEB_SEARCH"
        const val ACTION_ATTACHMENT = "com.aham.app.ACTION_ATTACHMENT"
        const val ACTION_VOICE = "com.aham.app.ACTION_VOICE"
        const val EXTRA_INPUT_TEXT = "input_text"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.ahamai_widget)
        
        // Set up click listeners for action buttons
        views.setOnClickPendingIntent(R.id.widget_search_bar, createSendPendingIntent(context))
        views.setOnClickPendingIntent(R.id.widget_send, createSendPendingIntent(context))
        views.setOnClickPendingIntent(R.id.widget_web_search, createActionPendingIntent(context, ACTION_WEB_SEARCH))
        views.setOnClickPendingIntent(R.id.widget_attachment, createActionPendingIntent(context, ACTION_ATTACHMENT))
        views.setOnClickPendingIntent(R.id.widget_voice, createActionPendingIntent(context, ACTION_VOICE))
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun createSendPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_SEND
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        return PendingIntent.getActivity(context, ACTION_SEND.hashCode(), intent, flags)
    }

    private fun createActionPendingIntent(context: Context, action: String): PendingIntent {
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
            ACTION_SEND, ACTION_WEB_SEARCH, ACTION_ATTACHMENT, ACTION_VOICE -> {
                // The intent will be handled by MainActivity
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = intent.action
                    putExtra(EXTRA_INPUT_TEXT, intent.getStringExtra(EXTRA_INPUT_TEXT))
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                context.startActivity(launchIntent)
            }
        }
    }
}