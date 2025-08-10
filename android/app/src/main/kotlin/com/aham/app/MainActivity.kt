package com.aham.app

import android.content.Intent
import android.os.Bundle
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ahamai.text_sharing"
    private val WIDGET_CHANNEL = "com.ahamai.widget"
    private var sharedText: String? = null
    private var widgetAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        handleSharingIntent(intent)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSharingIntent(intent)
        handleWidgetIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedText" -> {
                    result.success(sharedText)
                    sharedText = null
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWidgetAction" -> {
                    result.success(widgetAction)
                    widgetAction = null
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSharingIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }

    private fun handleWidgetIntent(intent: Intent?) {
        widgetAction = intent?.getStringExtra("widget_action")
    }
}
