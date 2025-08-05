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
        const val ACTION_SEARCH_TAP = "com.aham.app.ACTION_SEARCH_TAP"
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
        
        // Set up click listeners for minimal widget
        views.setOnClickPendingIntent(R.id.widget_search_bar, createActionPendingIntent(context, ACTION_SEARCH_TAP))
        views.setOnClickPendingIntent(R.id.widget_voice, createActionPendingIntent(context, ACTION_VOICE))
        
        // Start Indian pride animation
        try {
            val searchBarDrawable = context.getDrawable(R.drawable.indian_pride_animation)
            if (searchBarDrawable is android.graphics.drawable.AnimationDrawable) {
                searchBarDrawable.start()
            }
        } catch (e: Exception) {
            // Fallback to static background if animation fails
            android.util.Log.w("AhamAIWidget", "Failed to start animation: ${e.message}")
        }
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
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
            ACTION_SEARCH_TAP, ACTION_VOICE -> {
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