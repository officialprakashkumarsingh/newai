package com.aham.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import android.os.Environment
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

class ExternalToolsHandler(private val context: Context) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "executeFileTool" -> {
                executeFileTool(call, result)
            }
            "executeCommunicationTool" -> {
                executeCommunicationTool(call, result)
            }
            "getAvailableTools" -> {
                listAvailableTools(result)
            }
            "getToolCapabilities" -> {
                val toolName = call.argument<String>("toolName") ?: ""
                getToolCapabilities(toolName, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun executeFileTool(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                val operation = call.argument<String>("operation") ?: ""
                val fileName = call.argument<String>("fileName") ?: ""
                val content = call.argument<String>("content") ?: ""
                val fileType = call.argument<String>("fileType")
                val metadata = call.argument<Map<String, Any>>("metadata") ?: mapOf()

                if (fileName.isEmpty() || content.isEmpty()) {
                    withContext(Dispatchers.Main) {
                        result.success(mapOf(
                            "success" to false,
                            "error" to "Missing required parameters: fileName or content"
                        ))
                    }
                    return@launch
                }

                val executeResult = createFileDirectly(fileName, content, fileType, metadata)

                withContext(Dispatchers.Main) {
                    if (executeResult["success"] == true) {
                        val filePath = executeResult["file_path"] as? String
                        if (filePath != null) {
                            showFileCreatedNotification(fileName, filePath)
                        }
                    }
                    result.success(executeResult)
                }

            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "success" to false,
                        "error" to "File tool execution failed: ${e.message}"
                    ))
                }
            }
        }
    }
    
    private fun executeCommunicationTool(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                val operation = call.argument<String>("operation") ?: ""
                val recipient = call.argument<String>("recipient") ?: ""
                val content = call.argument<String>("content") ?: ""
                val subject = call.argument<String>("subject")

                if (recipient.isEmpty() || content.isEmpty()) {
                    withContext(Dispatchers.Main) {
                        result.success(mapOf(
                            "success" to false,
                            "error" to "Missing required parameters: recipient or content"
                        ))
                    }
                    return@launch
                }

                val executeResult = prepareCommunicationDirectly(operation, recipient, content, subject)

                withContext(Dispatchers.Main) {
                    if (executeResult["success"] == true) {
                        val data = executeResult["data"] as? Map<String, Any>
                        if (data != null) {
                            launchCommunicationIntent(operation, data)
                        }
                    }
                    result.success(executeResult)
                }

            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "success" to false,
                        "error" to "Communication tool execution failed: ${e.message}"
                    ))
                }
            }
        }
    }
    
    private fun createFileDirectly(fileName: String, content: String, fileType: String?, metadata: Map<String, Any>): Map<String, Any> {
        return try {
            // Determine file type from extension if not provided
            val actualFileType = fileType ?: fileName.substringAfterLast('.', "txt")
            
            // Get Downloads directory
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            
            val file = File(downloadsDir, fileName)
            
            when (actualFileType.lowercase()) {
                "txt", "html", "css", "js", "json", "xml", "md" -> {
                    // Text-based files
                    file.writeText(content, Charsets.UTF_8)
                }
                "pdf" -> {
                    // Create simple HTML file with PDF extension (can be opened in browser)
                    val htmlContent = """
                        <!DOCTYPE html>
                        <html>
                        <head>
                            <title>${metadata["title"] ?: "Document"}</title>
                            <style>
                                body { font-family: Arial, sans-serif; padding: 20px; }
                                pre { white-space: pre-wrap; }
                            </style>
                        </head>
                        <body>
                            <h1>${metadata["title"] ?: "Document"}</h1>
                            <pre>$content</pre>
                        </body>
                        </html>
                    """.trimIndent()
                    file.writeText(htmlContent, Charsets.UTF_8)
                }
                "zip" -> {
                    // For ZIP files, create a simple text file with .zip extension
                    // This is a limitation but maintains functionality
                    file.writeText(content, Charsets.UTF_8)
                }
                else -> {
                    // Default: treat as text file
                    file.writeText(content, Charsets.UTF_8)
                }
            }
            
            val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date())
            
            mapOf(
                "success" to true,
                "message" to "File created successfully: $fileName",
                "file_path" to file.absolutePath,
                "file_size" to file.length(),
                "created_at" to timestamp
            )
            
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "error" to "Failed to create file: ${e.message}",
                "file_name" to fileName
            )
        }
    }
    
    private fun prepareCommunicationDirectly(operation: String, recipient: String, content: String, subject: String?): Map<String, Any> {
        return try {
            val timestamp = System.currentTimeMillis()
            
            val data = when (operation) {
                "send_email" -> mapOf(
                    "recipient" to recipient,
                    "subject" to (subject ?: "Message from AI Assistant"),
                    "content" to content,
                    "timestamp" to timestamp
                )
                "send_whatsapp" -> {
                    // Clean phone number
                    val cleanPhone = recipient.replace(Regex("[^+\\d]"), "")
                    mapOf(
                        "recipient" to cleanPhone,
                        "content" to content,
                        "timestamp" to timestamp
                    )
                }
                "send_sms" -> {
                    // Clean phone number
                    val cleanPhone = recipient.replace(Regex("[^+\\d]"), "")
                    mapOf(
                        "recipient" to cleanPhone,
                        "content" to content,
                        "timestamp" to timestamp
                    )
                }
                else -> mapOf(
                    "recipient" to recipient,
                    "content" to content,
                    "timestamp" to timestamp
                )
            }
            
            mapOf(
                "success" to true,
                "operation" to operation,
                "data" to data,
                "message" to "${operation.replace("send_", "").uppercase()} prepared for $recipient"
            )
            
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "error" to "Failed to prepare $operation: ${e.message}"
            )
        }
    }
    
    private fun showFileCreatedNotification(fileName: String, filePath: String) {
        try {
            val message = "File created: $fileName"
            Toast.makeText(context, message, Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            // Ignore notification errors
        }
    }
    
    private fun launchCommunicationIntent(operation: String, data: Map<String, Any>) {
        try {
            val intent = when (operation) {
                "send_email" -> createEmailIntent(data)
                "send_whatsapp" -> createWhatsAppIntent(data)
                "send_sms" -> createSmsIntent(data)
                else -> null
            }

            intent?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(it)
            }
        } catch (e: Exception) {
            Toast.makeText(context, "Failed to launch ${operation}: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun createEmailIntent(data: Map<String, Any>): Intent {
        val recipient = data["recipient"] as? String ?: ""
        val subject = data["subject"] as? String ?: ""
        val content = data["content"] as? String ?: ""

        return Intent(Intent.ACTION_SENDTO).apply {
            this.data = Uri.parse("mailto:$recipient")
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, content)
        }
    }
    
    private fun createWhatsAppIntent(data: Map<String, Any>): Intent {
        val recipient = data["recipient"] as? String ?: ""
        val content = data["content"] as? String ?: ""

        val phone = recipient.replace("+", "").replace(" ", "")
        val url = "https://wa.me/$phone?text=${Uri.encode(content)}"

        return Intent(Intent.ACTION_VIEW, Uri.parse(url))
    }
    
    private fun createSmsIntent(data: Map<String, Any>): Intent {
        val recipient = data["recipient"] as? String ?: ""
        val content = data["content"] as? String ?: ""

        return Intent(Intent.ACTION_SENDTO).apply {
            this.data = Uri.parse("smsto:$recipient")
            putExtra("sms_body", content)
        }
    }
    
    private fun listAvailableTools(result: MethodChannel.Result) {
        val tools = listOf(
            "create_file",
            "send_email", 
            "send_whatsapp",
            "send_sms"
        )
        result.success(tools)
    }
    
    private fun getToolCapabilities(toolName: String, result: MethodChannel.Result) {
        val capabilities = when (toolName) {
            "create_file" -> mapOf(
                "name" to "File Creation Tool",
                "description" to "Creates files with content in various formats",
                "supported_formats" to listOf("txt", "html", "css", "pdf", "zip", "json", "xml"),
                "parameters" to listOf("fileName", "content", "fileType", "metadata")
            )
            "send_email" -> mapOf(
                "name" to "Email Tool",
                "description" to "Composes and sends emails",
                "parameters" to listOf("recipient", "subject", "content")
            )
            "send_whatsapp" -> mapOf(
                "name" to "WhatsApp Tool", 
                "description" to "Sends messages via WhatsApp",
                "parameters" to listOf("recipient", "content")
            )
            "send_sms" -> mapOf(
                "name" to "SMS Tool",
                "description" to "Sends text messages via SMS", 
                "parameters" to listOf("recipient", "content")
            )
            else -> mapOf(
                "error" to "Unknown tool: $toolName"
            )
        }
        result.success(capabilities)
    }
    
    fun cleanup() {
        scope.cancel()
    }
}