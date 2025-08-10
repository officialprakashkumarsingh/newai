package com.aham.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import java.io.IOException
import org.json.JSONObject
import org.json.JSONArray
import android.util.Log

class BackgroundProcessingService : Service() {
    
    companion object {
        const val CHANNEL_ID = "ahamai_background_processing"
        const val NOTIFICATION_ID = 1001
        const val COMPLETION_NOTIFICATION_ID = 1002
        const val TAG = "AhamAI_Background"
        
        const val ACTION_START_PROCESSING = "START_PROCESSING"
        const val ACTION_STOP_PROCESSING = "STOP_PROCESSING"
        
        const val EXTRA_CHAT_ID = "chat_id"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_MODEL = "model"
        const val EXTRA_PROCESS_TYPE = "process_type"
    }
    
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var processingJob: Job? = null
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "Background service created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_PROCESSING -> {
                val chatId = intent.getStringExtra(EXTRA_CHAT_ID) ?: return START_NOT_STICKY
                val message = intent.getStringExtra(EXTRA_MESSAGE) ?: return START_NOT_STICKY
                val model = intent.getStringExtra(EXTRA_MODEL) ?: "gpt-4"
                val processType = intent.getStringExtra(EXTRA_PROCESS_TYPE) ?: "chat"
                val retryAttempts = intent.getIntExtra("retryAttempts", 0)
                val priority = intent.getStringExtra("priority") ?: "normal"
                val timeout = intent.getLongExtra("timeout", 180000) // 3 minutes default
                
                Log.d(TAG, "🚀 Enhanced background processing (priority: $priority, timeout: ${timeout}ms, retry: $retryAttempts): $message")
                startForegroundProcessing(chatId, message, model, processType, retryAttempts, priority, timeout)
            }
            ACTION_STOP_PROCESSING -> {
                Log.d(TAG, "⏹️ Stopping background processing")
                stopProcessing()
            }
        }
        return START_STICKY
    }
    
    private fun startForegroundProcessing(
        chatId: String, 
        message: String, 
        model: String, 
        processType: String,
        retryAttempts: Int = 0,
        priority: String = "normal",
        timeout: Long = 180000
    ) {
        val notification = createOngoingNotification(processType, priority)
        startForeground(NOTIFICATION_ID, notification)
        
        Log.d(TAG, "🔄 Starting enhanced processing (attempt ${retryAttempts + 1}) for: $message")
        
        processingJob = serviceScope.launch {
            try {
                // Apply timeout
                val result = withTimeout(timeout) {
                    processRequest(message, model, retryAttempts)
                }
                
                onProcessingComplete(chatId, processType, result)
            } catch (e: TimeoutCancellationException) {
                Log.e(TAG, "⏰ Processing timeout after ${timeout}ms", e)
                onProcessingError(chatId, processType, "Request timed out after ${timeout / 1000}s")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Processing failed (attempt ${retryAttempts + 1}): ${e.message}")
                
                // Implement retry logic for certain errors
                if (retryAttempts < 2 && isRetriableError(e)) {
                    Log.d(TAG, "🔄 Retrying request (attempt ${retryAttempts + 2}/3)...")
                    delay(2000L * (retryAttempts + 1)) // Exponential backoff
                    startForegroundProcessing(chatId, message, model, processType, retryAttempts + 1, priority, timeout)
                } else {
                    onProcessingError(chatId, processType, e.message ?: "Unknown error")
                }
            }
        }
    }
    
    /// Check if error is retriable
    private fun isRetriableError(error: Exception): Boolean {
        return when (error) {
            is SocketTimeoutException,
            is UnknownHostException,
            is IOException -> true
            else -> {
                // Check for HTTP error codes that are retriable
                val message = error.message?.lowercase() ?: ""
                message.contains("timeout") || 
                message.contains("connection") || 
                message.contains("network") ||
                message.contains("500") ||
                message.contains("502") ||
                message.contains("503") ||
                message.contains("504")
            }
        }
    }
    
    private suspend fun processRequest(message: String, model: String, retryAttempts: Int = 0): String {
        return withContext(Dispatchers.IO) {
            Log.d(TAG, "Making API request for: $message")
            
            try {
                // Use the same API endpoint as the Flutter app
                val apiKey = "ahamaibyprakash25"
                
                val url = URL("https://ahamai-api.officialprakashkrsingh.workers.dev/v1/chat/completions")
                val connection = url.openConnection() as HttpURLConnection
                
                connection.apply {
                    requestMethod = "POST"
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $apiKey")
                    doOutput = true
                }
                
                val requestBody = JSONObject().apply {
                    put("model", model)
                    put("messages", org.json.JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", message)
                        })
                    })
                    put("max_tokens", 1000)
                    put("temperature", 0.7)
                }
                
                connection.outputStream.use { os ->
                    os.write(requestBody.toString().toByteArray())
                }
                
                val responseCode = connection.responseCode
                Log.d(TAG, "API response code: $responseCode")
                
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().readText()
                    val jsonResponse = JSONObject(response)
                    val content = jsonResponse
                        .getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content")
                    
                    Log.d(TAG, "API response received successfully")
                    return@withContext content
                } else {
                    val errorResponse = connection.errorStream?.bufferedReader()?.readText()
                    Log.e(TAG, "API error: $errorResponse")
                    throw Exception("API Error: $responseCode")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Network error: ${e.message}")
                throw e
            }
        }
    }
    
    private fun getApiKey(): String {
        // Try to get from SharedPreferences first
        val sharedPref = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val apiKey = sharedPref.getString("flutter.openai_api_key", null)
        
        if (!apiKey.isNullOrEmpty()) {
            return apiKey
        }
        
        // Fallback: Use a default or throw error
        throw Exception("API key not found. Please set your OpenAI API key in the app.")
    }
    
    private fun onProcessingComplete(chatId: String, processType: String, result: String) {
        Log.d(TAG, "Processing completed successfully")
        
        // Show completion notification
        showCompletionNotification(processType, result)
        
        // Send result back to Flutter via method channel
        sendResultToFlutter(chatId, processType, result, success = true)
        
        // Stop the service
        stopSelf()
    }
    
    private fun onProcessingError(chatId: String, processType: String, error: String) {
        Log.e(TAG, "Processing failed: $error")
        
        // Show error notification
        showErrorNotification(error)
        
        // Send error back to Flutter
        sendResultToFlutter(chatId, processType, error, success = false)
        
        // Stop the service
        stopSelf()
    }
    
    private fun sendResultToFlutter(chatId: String, processType: String, result: String, success: Boolean) {
        try {
            // This would normally use a method channel, but since the service runs independently,
            // we'll store the result and let the Flutter app retrieve it when it comes back to foreground
            val sharedPref = getSharedPreferences("ahamai_background_results", Context.MODE_PRIVATE)
            with(sharedPref.edit()) {
                putString("last_result_chat_id", chatId)
                putString("last_result_type", processType)
                putString("last_result_content", result)
                putBoolean("last_result_success", success)
                putLong("last_result_timestamp", System.currentTimeMillis())
                apply()
            }
            Log.d(TAG, "Result stored for Flutter app")
        } catch (e: Exception) {
            Log.e(TAG, "Error storing result: ${e.message}")
        }
    }
    
    private fun stopProcessing() {
        processingJob?.cancel()
        processingJob = null
        stopForeground(true)
        stopSelf()
        Log.d(TAG, "Background processing stopped")
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Create ongoing processing channel
            val ongoingChannel = NotificationChannel(
                CHANNEL_ID,
                "AhamAI Background Processing",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when AhamAI is processing in the background"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            // Create completion channel with HIGH importance for visibility
            val completionChannel = NotificationChannel(
                "${CHANNEL_ID}_completion",
                "AhamAI Task Completion",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows when AhamAI tasks are completed"
                setShowBadge(true)
                enableVibration(true)
                enableLights(true)
                lightColor = android.graphics.Color.BLUE
            }
            
            notificationManager.createNotificationChannel(ongoingChannel)
            notificationManager.createNotificationChannel(completionChannel)
            
            Log.d(TAG, "Notification channels created successfully")
        }
    }
    
    private fun createOngoingNotification(processType: String, priority: String = "normal"): Notification {
        val contentText = when (processType) {
            "chat" -> "Generating AI response..."
            "image" -> "Creating image..."
            "presentation" -> "Building presentation..."
            else -> "Processing your request..."
        }
        
        val priorityText = if (priority == "high") " (Priority)" else ""
        
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🔄 AhamAI Processing$priorityText")
            .setContentText("$contentText\n⏳ Continue using other apps!")
            .setSmallIcon(android.R.drawable.ic_popup_sync)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(if (priority == "high") NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    private fun showCompletionNotification(processType: String, result: String) {
        val contentText = when (processType) {
            "chat" -> "Response ready - tap to view"
            "image" -> "Image generated - tap to view"
            "presentation" -> "Presentation ready - tap to view"
            else -> "Task completed - tap to view"
        }
        
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, "${CHANNEL_ID}_completion")
            .setContentTitle("🎉 AhamAI Complete!")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setLargeIcon(android.graphics.BitmapFactory.decodeResource(resources, android.R.drawable.ic_dialog_info))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(COMPLETION_NOTIFICATION_ID, notification)
        
        Log.d(TAG, "Completion notification shown for $processType")
    }
    
    private fun showErrorNotification(error: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, "${CHANNEL_ID}_completion")
            .setContentTitle("❌ AhamAI Error")
            .setContentText("Processing failed: $error")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(COMPLETION_NOTIFICATION_ID, notification)
        
        Log.d(TAG, "Error notification shown: $error")
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        Log.d(TAG, "Background service destroyed")
    }
}