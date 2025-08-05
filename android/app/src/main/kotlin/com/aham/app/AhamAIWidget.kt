package com.aham.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.drawable.AnimationDrawable
import android.os.Build
import android.widget.RemoteViews
import android.os.Handler
import android.os.Looper

/**
 * Implementation of App Widget functionality.
 */
class AhamAIWidget : AppWidgetProvider() {
    
    companion object {
        const val ACTION_SEARCH_TAP = "com.aham.app.ACTION_SEARCH_TAP"
        const val ACTION_VOICE = "com.aham.app.ACTION_VOICE"
        const val EXTRA_INPUT_TEXT = "input_text"
        const val ACTION_START_ANIMATION = "com.aham.app.ACTION_START_ANIMATION"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
            startFlagAnimation(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.ahamai_widget)
        
        // Set up click listeners for minimal widget
        views.setOnClickPendingIntent(R.id.widget_search_bar, createActionPendingIntent(context, ACTION_SEARCH_TAP))
        views.setOnClickPendingIntent(R.id.widget_voice, createActionPendingIntent(context, ACTION_VOICE))
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun startFlagAnimation(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val handler = Handler(Looper.getMainLooper())
        
        // Schedule flag animation every 30 seconds
        val runnable = object : Runnable {
            override fun run() {
                animateFlag(context, appWidgetManager, appWidgetId)
                handler.postDelayed(this, 30000) // 30 seconds
            }
        }
        
        // Start first animation after 5 seconds
        handler.postDelayed(runnable, 5000)
    }

    private fun animateFlag(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.ahamai_widget)
        val handler = Handler(Looper.getMainLooper())
        
        // Saffron phase
        views.setInt(R.id.widget_search_bar, "setBackgroundResource", R.drawable.indian_saffron_bg)
        appWidgetManager.updateAppWidget(appWidgetId, views)
        
        handler.postDelayed({
            // White phase
            views.setInt(R.id.widget_search_bar, "setBackgroundResource", R.drawable.indian_white_bg)
            appWidgetManager.updateAppWidget(appWidgetId, views)
            
            handler.postDelayed({
                // Green phase
                views.setInt(R.id.widget_search_bar, "setBackgroundResource", R.drawable.indian_green_bg)
                appWidgetManager.updateAppWidget(appWidgetId, views)
                
                handler.postDelayed({
                    // Back to normal
                    views.setInt(R.id.widget_search_bar, "setBackgroundResource", R.drawable.minimal_search_background)
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }, 1500)
            }, 1500)
        }, 1500)
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

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}