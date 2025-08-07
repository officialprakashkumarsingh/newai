package com.aham.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.File
import java.io.FileWriter
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.text.SimpleDateFormat
import java.util.*

class ExternalToolsHandler(private val context: Context) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val pythonExecutor = Executors.newSingleThreadExecutor()
    
    private val fileToolScript = """
import os
import json
import sys
import zipfile
import tempfile
from datetime import datetime
import time

def create_file(file_name, content, file_type=None, metadata=None):
    try:
        # Determine file type from extension if not provided
        if not file_type:
            file_type = file_name.split('.')[-1].lower() if '.' in file_name else 'txt'
        
        # Create downloads directory if it doesn't exist
        downloads_dir = os.path.expanduser('~/Downloads')
        if not os.path.exists(downloads_dir):
            downloads_dir = '/sdcard/Download'
            if not os.path.exists(downloads_dir):
                os.makedirs(downloads_dir, exist_ok=True)
        
        file_path = os.path.join(downloads_dir, file_name)
        
        if file_type in ['txt', 'html', 'css', 'js', 'json', 'xml', 'md']:
            # Text-based files
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        
        elif file_type == 'pdf':
            # Create simple PDF (requires reportlab or similar)
            try:
                # Simple HTML to PDF conversion using weasyprint
                import weasyprint
                weasyprint.HTML(string=content).write_pdf(file_path)
            except ImportError:
                # Fallback: create HTML file with PDF extension
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(f"<html><body><pre>{content}</pre></body></html>")
        
        elif file_type == 'zip':
            # Create ZIP file with content
            with zipfile.ZipFile(file_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                if metadata and 'files' in metadata:
                    # Multiple files in ZIP
                    for file_info in metadata['files']:
                        zipf.writestr(file_info['name'], file_info['content'])
                else:
                    # Single content file in ZIP
                    content_name = metadata.get('content_name', 'content.txt') if metadata else 'content.txt'
                    zipf.writestr(content_name, content)
        
        else:
            # Default: treat as text file
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        
        result = {
            'success': True,
            'message': f'File created successfully: {file_name}',
            'file_path': file_path,
            'file_size': os.path.getsize(file_path),
            'created_at': datetime.now().isoformat()
        }
        
        print(json.dumps(result))
        return result
            
    except Exception as e:
        error_result = {
            'success': False,
            'error': f'Failed to create file: {str(e)}',
            'file_name': file_name
        }
        print(json.dumps(error_result))
        return error_result

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(json.dumps({'success': False, 'error': 'Insufficient arguments'}))
        sys.exit(1)
    
    file_name = sys.argv[1]
    content = sys.argv[2]
    file_type = sys.argv[3] if len(sys.argv) > 3 else None
    metadata = json.loads(sys.argv[4]) if len(sys.argv) > 4 else None
    
    create_file(file_name, content, file_type, metadata)
"""
    
    private val communicationToolScript = """
import sys
import json
import urllib.parse
import webbrowser
import subprocess
import os
import time

def send_communication(operation, recipient, content, subject=None):
    try:
        if operation == "send_email":
            return prepare_email(recipient, content, subject)
        elif operation == "send_whatsapp":
            return prepare_whatsapp(recipient, content)
        elif operation == "send_sms":
            return prepare_sms(recipient, content)
        else:
            return {
                'success': False,
                'error': f'Unknown operation: {operation}'
            }
    except Exception as e:
        return {
            'success': False,
            'error': f'Communication tool error: {str(e)}'
        }

def prepare_email(recipient, content, subject=None):
    try:
        # Prepare email data for Android Intent
        result = {
            'success': True,
            'operation': 'email',
            'data': {
                'recipient': recipient,
                'subject': subject or 'Message from AhamAI',
                'content': content,
                'timestamp': str(int(time.time() * 1000))
            },
            'message': f'Email prepared for {recipient}'
        }
        
        print(json.dumps(result))
        return result
            
    except Exception as e:
        error_result = {
            'success': False,
            'error': f'Failed to prepare email: {str(e)}'
        }
        print(json.dumps(error_result))
        return error_result

def prepare_whatsapp(recipient, content):
    try:
        # Clean phone number
        phone = ''.join(filter(str.isdigit, recipient))
        if not phone.startswith('+'):
            phone = f'+{phone}'
        
        result = {
            'success': True,
            'operation': 'whatsapp',
            'data': {
                'recipient': phone,
                'content': content,
                'timestamp': str(int(time.time() * 1000))
            },
            'message': f'WhatsApp message prepared for {phone}'
        }
        
        print(json.dumps(result))
        return result
            
    except Exception as e:
        error_result = {
            'success': False,
            'error': f'Failed to prepare WhatsApp message: {str(e)}'
        }
        print(json.dumps(error_result))
        return error_result

def prepare_sms(recipient, content):
    try:
        # Clean phone number
        phone = ''.join(filter(str.isdigit, recipient))
        if not phone.startswith('+'):
            phone = f'+{phone}'
        
        result = {
            'success': True,
            'operation': 'sms',
            'data': {
                'recipient': phone,
                'content': content,
                'timestamp': str(int(time.time() * 1000))
            },
            'message': f'SMS prepared for {phone}'
        }
        
        print(json.dumps(result))
        return result
            
    except Exception as e:
        error_result = {
            'success': False,
            'error': f'Failed to prepare SMS: {str(e)}'
        }
        print(json.dumps(error_result))
        return error_result

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print(json.dumps({'success': False, 'error': 'Insufficient arguments'}))
        sys.exit(1)
    
    operation = sys.argv[1]
    recipient = sys.argv[2]
    content = sys.argv[3]
    subject = sys.argv[4] if len(sys.argv) > 4 else None
    
    send_communication(operation, recipient, content, subject)
"""
    
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

                val args = listOfNotNull(
                    fileName,
                    content,
                    fileType,
                    if (metadata.isNotEmpty()) JSONObject(metadata).toString() else null
                ).filterNot { it.isNullOrEmpty() }

                val executeResult = executePythonScript(fileToolScript, args)
                val parsedResult = parseJsonResult(executeResult)

                withContext(Dispatchers.Main) {
                    if (parsedResult["success"] == true) {
                        val filePath = parsedResult["file_path"] as? String
                        if (filePath != null) {
                            showFileCreatedNotification(fileName, filePath)
                        }
                    }
                    result.success(parsedResult)
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

                val args = listOfNotNull(operation, recipient, content, subject).filterNot { it.isNullOrEmpty() }
                val executeResult = executePythonScript(communicationToolScript, args)
                val parsedResult = parseJsonResult(executeResult)

                withContext(Dispatchers.Main) {
                    if (parsedResult["success"] == true) {
                        val data = parsedResult["data"] as? Map<String, Any>
                        if (data != null) {
                            launchCommunicationIntent(operation, data)
                        }
                    }
                    result.success(parsedResult)
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
    
    private fun executePythonScript(script: String, args: List<String>): String {
        return try {
            val tempDir = File(context.cacheDir, "python_scripts")
            if (!tempDir.exists()) {
                tempDir.mkdirs()
            }

            val scriptFile = File(tempDir, "script_${System.currentTimeMillis()}.py")
            scriptFile.writeText(script)

            val processBuilder = ProcessBuilder()
            processBuilder.directory(tempDir)
            
            val command = mutableListOf("python3", scriptFile.absolutePath)
            command.addAll(args)
            processBuilder.command(command)

            val process = processBuilder.start()
            val outputReader = process.inputStream.bufferedReader()
            val errorReader = process.errorStream.bufferedReader()

            val finished = process.waitFor(30, TimeUnit.SECONDS)
            
            if (!finished) {
                process.destroyForcibly()
                return JSONObject(mapOf(
                    "success" to false,
                    "error" to "Python script execution timed out"
                )).toString()
            }

            val output = outputReader.readText()
            val error = errorReader.readText()

            scriptFile.delete()

            if (process.exitValue() == 0 && output.isNotEmpty()) {
                output.trim()
            } else {
                JSONObject(mapOf(
                    "success" to false,
                    "error" to "Python execution failed: $error",
                    "output" to output
                )).toString()
            }

        } catch (e: Exception) {
            JSONObject(mapOf(
                "success" to false,
                "error" to "Script execution error: ${e.message}"
            )).toString()
        }
    }
    
    private fun parseJsonResult(jsonString: String): Map<String, Any> {
        return try {
            val jsonObject = JSONObject(jsonString)
            val result = mutableMapOf<String, Any>()
            
            jsonObject.keys().forEach { key ->
                result[key] = jsonObject.get(key)
            }
            
            result
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "error" to "Failed to parse result: ${e.message}",
                "raw_output" to jsonString
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
        pythonExecutor.shutdown()
    }
}