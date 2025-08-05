package com.aham.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

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

    private fun handleSharingIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") {
                    sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                }
            }
        }
    }

    private fun handleWidgetIntent(intent: Intent) {
        when (intent.action) {
            "com.aham.app.ACTION_SEARCH_TAP" -> {
                widgetAction = "search_tap"
            }
            "com.aham.app.ACTION_VOICE" -> {
                widgetAction = "voice"
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedText" -> {
                    result.success(sharedText)
                    sharedText = null // Clear after sending
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWidgetAction" -> {
                    result.success(widgetAction)
                    widgetAction = null // Clear after sending
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
