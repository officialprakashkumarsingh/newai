package com.aham.app

import android.content.Intent
import android.os.Bundle
import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ahamai.text_sharing"
    private val WIDGET_CHANNEL = "com.ahamai.widget"
    private val EMAIL_CHANNEL = "com.ahamai.email_intent"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EMAIL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendEmailWithAttachment" -> {
                    val recipient = call.argument<String>("recipient") ?: ""
                    val subject = call.argument<String>("subject") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val filePath = call.argument<String>("filePath")
                    sendEmailWithAttachment(recipient, subject, body, filePath, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendEmailWithAttachment(recipient: String, subject: String, body: String, filePath: String?, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
                
                // Add file attachment if provided
                if (!filePath.isNullOrEmpty()) {
                    val file = File(filePath)
                    if (file.exists()) {
                        val uri = FileProvider.getUriForFile(
                            this@MainActivity,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        type = "*/*" // Allow any file type
                    }
                }
            }

            // Try to open email app specifically
            val emailIntent = Intent.createChooser(intent, "Send Email")
            startActivity(emailIntent)
            result.success(mapOf("success" to true, "message" to "Email app opened"))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "error" to e.message))
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
