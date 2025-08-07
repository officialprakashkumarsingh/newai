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
    private val EXTERNAL_TOOLS_CHANNEL = "com.ahamai.external_tools"
    private var sharedText: String? = null
    private var widgetAction: String? = null
    private lateinit var externalToolsHandler: ExternalToolsHandler

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize external tools handler
        externalToolsHandler = ExternalToolsHandler(this)
        
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXTERNAL_TOOLS_CHANNEL).setMethodCallHandler { call, result ->
            externalToolsHandler.handleMethodCall(call, result)
        }


    }

    override fun onDestroy() {
        super.onDestroy()
        if (::externalToolsHandler.isInitialized) {
            externalToolsHandler.cleanup()
        }
    }
}
