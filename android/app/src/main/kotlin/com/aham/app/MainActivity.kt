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
    private val BACKGROUND_CHANNEL = "com.ahamai.background"
    private val LATEX_CHANNEL = "com.ahamai.latex"
    private var sharedText: String? = null
    private var widgetAction: String? = null
    private lateinit var latexRenderer: LatexRenderer

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        latexRenderer = LatexRenderer(this)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundProcessing" -> {
                    val chatId = call.argument<String>("chatId") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val model = call.argument<String>("model") ?: "gpt-4"
                    val processType = call.argument<String>("processType") ?: "chat"
                    
                    startBackgroundService(chatId, message, model, processType)
                    result.success(true)
                }
                "stopBackgroundProcessing" -> {
                    stopBackgroundService()
                    result.success(true)
                }
                "getBackgroundResult" -> {
                    val backgroundResult = getStoredBackgroundResult()
                    result.success(backgroundResult)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LATEX_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "renderLatex" -> {
                    val latex = call.argument<String>("latex") ?: ""
                    val isDisplayMode = call.argument<Boolean>("isDisplayMode") ?: false
                    val isDarkTheme = call.argument<Boolean>("isDarkTheme") ?: false
                    
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val base64Image = latexRenderer.renderLatexToBase64(latex, isDisplayMode, isDarkTheme)
                            withContext(Dispatchers.Main) {
                                if (base64Image != null) {
                                    result.success(mapOf(
                                        "success" to true,
                                        "image" to base64Image
                                    ))
                                } else {
                                    result.success(mapOf(
                                        "success" to false,
                                        "error" to "Failed to render LaTeX"
                                    ))
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(mapOf(
                                    "success" to false,
                                    "error" to e.message
                                ))
                            }
                        }
                    }
                }
                "validateLatex" -> {
                    val latex = call.argument<String>("latex") ?: ""
                    val isValid = latexRenderer.isValidLatex(latex)
                    result.success(isValid)
                }
                "extractLatex" -> {
                    val text = call.argument<String>("text") ?: ""
                    val expressions = latexRenderer.extractLatexExpressions(text)
                    val serializedExpressions = expressions.map { expr ->
                        mapOf(
                            "original" to expr.original,
                            "latex" to expr.latex,
                            "isDisplay" to expr.isDisplay,
                            "start" to expr.start,
                            "end" to expr.end
                        )
                    }
                    result.success(serializedExpressions)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startBackgroundService(chatId: String, message: String, model: String, processType: String) {
        val intent = Intent(this, BackgroundProcessingService::class.java).apply {
            action = BackgroundProcessingService.ACTION_START_PROCESSING
            putExtra(BackgroundProcessingService.EXTRA_CHAT_ID, chatId)
            putExtra(BackgroundProcessingService.EXTRA_MESSAGE, message)
            putExtra(BackgroundProcessingService.EXTRA_MODEL, model)
            putExtra(BackgroundProcessingService.EXTRA_PROCESS_TYPE, processType)
        }
        startForegroundService(intent)
    }

    private fun stopBackgroundService() {
        val intent = Intent(this, BackgroundProcessingService::class.java).apply {
            action = BackgroundProcessingService.ACTION_STOP_PROCESSING
        }
        startService(intent)
    }

    private fun getStoredBackgroundResult(): Map<String, Any?>? {
        val sharedPref = getSharedPreferences("ahamai_background_results", Context.MODE_PRIVATE)
        val chatId = sharedPref.getString("last_result_chat_id", null)
        val processType = sharedPref.getString("last_result_type", null)
        val content = sharedPref.getString("last_result_content", null)
        val success = sharedPref.getBoolean("last_result_success", false)
        val timestamp = sharedPref.getLong("last_result_timestamp", 0)

        return if (chatId != null && content != null) {
            mapOf(
                "chatId" to chatId,
                "processType" to processType,
                "content" to content,
                "success" to success,
                "timestamp" to timestamp
            ).also {
                // Clear the stored result after reading
                sharedPref.edit().clear().apply()
            }
        } else {
            null
        }
    }
}
