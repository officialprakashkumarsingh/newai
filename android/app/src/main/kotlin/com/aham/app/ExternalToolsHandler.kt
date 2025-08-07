package com.aham.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.widget.Toast
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.text.SimpleDateFormat
import java.util.*

class ExternalToolsHandler(private val context: Context) {

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val pythonExecutor = Executors.newSingleThreadExecutor()
    
    // Python scripts for different tools
    private val fileToolScript = """
import os
import json
import sys
import zipfile
import tempfile
from datetime import datetime

def create_file(file_name, content, file_type=None, metadata=None):
    """Create various types of files with content"""
    try:
        # Determine output directory
        downloads_dir = os.path.expanduser("~/Downloads")
        if not os.path.exists(downloads_dir):
            downloads_dir = "/storage/emulated/0/Download"
            if not os.path.exists(downloads_dir):
                downloads_dir = "/tmp"
        
        output_path = os.path.join(downloads_dir, file_name)
        
        # Handle different file types
        if file_type and file_type.lower() == 'pdf':
            return create_pdf(output_path, content, metadata)
        elif file_type and file_type.lower() == 'zip':
            return create_zip(output_path, content, metadata)
        elif file_type and file_type.lower() == 'html':
            return create_html(output_path, content, metadata)
        elif file_type and file_type.lower() == 'css':
            return create_css(output_path, content, metadata)
        else:
            # Plain text or other formats
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(content)
        
        return {
            "success": True,
            "message": f"File created successfully: {file_name}",
            "path": output_path,
            "size": os.path.getsize(output_path)
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": f"Failed to create file: {str(e)}"
        }

def create_pdf(output_path, content, metadata):
    """Create PDF using basic text content"""
    try:
        # Try to import reportlab for PDF creation
        try:
            from reportlab.pdfgen import canvas
            from reportlab.lib.pagesizes import letter
            from reportlab.lib.styles import getSampleStyleSheet
            from reportlab.platypus import SimpleDocTemplate, Paragraph
            
            doc = SimpleDocTemplate(output_path, pagesize=letter)
            styles = getSampleStyleSheet()
            story = []
            
            # Add title if in metadata
            if metadata and 'title' in metadata:
                title = Paragraph(metadata['title'], styles['Title'])
                story.append(title)
            
            # Add content
            paragraphs = content.split('\n\n')
            for para in paragraphs:
                if para.strip():
                    p = Paragraph(para, styles['Normal'])
                    story.append(p)
            
            doc.build(story)
            
        except ImportError:
            # Fallback: Create a simple text-based PDF structure
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write("%PDF-1.4\n")
                f.write("1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n")
                f.write("2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n")
                f.write("3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/Contents 4 0 R\n>>\nendobj\n")
                f.write("4 0 obj\n<<\n/Length " + str(len(content)) + "\n>>\nstream\n")
                f.write("BT\n/F1 12 Tf\n50 750 Td\n")
                # Simple text rendering
                lines = content.split('\n')
                for i, line in enumerate(lines[:40]):  # Limit to 40 lines
                    f.write(f"({line}) Tj\n0 -15 Td\n")
                f.write("ET\nendstream\nendobj\n")
                f.write("xref\n0 5\n0000000000 65535 f\n")
                f.write("trailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n%%EOF\n")
        
        return True
        
    except Exception as e:
        raise Exception(f"PDF creation failed: {str(e)}")

def create_zip(output_path, content, metadata):
    """Create ZIP file with content"""
    try:
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # If content is structured (JSON), create multiple files
            try:
                content_data = json.loads(content)
                if isinstance(content_data, dict):
                    for filename, file_content in content_data.items():
                        zipf.writestr(filename, str(file_content))
                else:
                    zipf.writestr('content.txt', content)
            except:
                # Single file content
                main_filename = metadata.get('filename', 'content.txt') if metadata else 'content.txt'
                zipf.writestr(main_filename, content)
                
                # Add metadata file if provided
                if metadata:
                    zipf.writestr('metadata.json', json.dumps(metadata, indent=2))
        
        return True
        
    except Exception as e:
        raise Exception(f"ZIP creation failed: {str(e)}")

def create_html(output_path, content, metadata):
    """Create HTML file with proper structure"""
    try:
        title = metadata.get('title', 'AI Generated Document') if metadata else 'AI Generated Document'
        author = metadata.get('author', 'AI Assistant') if metadata else 'AI Assistant'
        
        html_content = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <meta name="author" content="{author}">
    <style>
        body {{
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f9f9f9;
        }}
        .container {{
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        h1 {{ color: #333; border-bottom: 2px solid #4285F4; padding-bottom: 10px; }}
        .meta {{ color: #666; font-size: 0.9em; margin-bottom: 20px; }}
        .content {{ margin-top: 20px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>{title}</h1>
        <div class="meta">
            <p><strong>Created by:</strong> {author}</p>
            <p><strong>Generated on:</strong> {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        </div>
        <div class="content">
            {content.replace(chr(10), '<br>' + chr(10))}
        </div>
    </div>
</body>
</html>'''
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        return True
        
    except Exception as e:
        raise Exception(f"HTML creation failed: {str(e)}")

def create_css(output_path, content, metadata):
    """Create CSS file with proper formatting"""
    try:
        css_header = f'''/* 
 * CSS File Generated by AI Assistant
 * Created: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
 * Description: {metadata.get('description', 'AI-generated stylesheet') if metadata else 'AI-generated stylesheet'}
 */

'''
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(css_header + content)
        
        return True
        
    except Exception as e:
        raise Exception(f"CSS creation failed: {str(e)}")

# Main execution
if __name__ == "__main__":
    try:
        # Read parameters from command line arguments
        file_name = sys.argv[1]
        content = sys.argv[2]
        file_type = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "null" else None
        metadata = json.loads(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4] != "null" else None
        
        result = create_file(file_name, content, file_type, metadata)
        print(json.dumps(result))
        
    except Exception as e:
        error_result = {
            "success": False,
            "error": f"File tool execution failed: {str(e)}"
        }
        print(json.dumps(error_result))
"""

    private val communicationToolScript = """
import sys
import json
import urllib.parse
import webbrowser
import subprocess
import os

def send_communication(operation, recipient, content, subject=None):
    """Handle different communication methods"""
    try:
        if operation == "email":
            return send_email(recipient, content, subject)
        elif operation == "whatsapp":
            return send_whatsapp(recipient, content)
        elif operation == "sms":
            return send_sms(recipient, content)
        else:
            return {
                "success": False,
                "error": f"Unknown communication operation: {operation}"
            }
    except Exception as e:
        return {
            "success": False,
            "error": f"Communication failed: {str(e)}"
        }

def send_email(recipient, content, subject):
    """Open email client with pre-filled content"""
    try:
        subject_text = subject or "Message from AI Assistant"
        
        # URL encode the parameters
        encoded_subject = urllib.parse.quote(subject_text)
        encoded_content = urllib.parse.quote(content)
        
        # Create mailto URL
        mailto_url = f"mailto:{recipient}?subject={encoded_subject}&body={encoded_content}"
        
        # Try to open default email client
        try:
            # For Android, we'll return intent data
            return {
                "success": True,
                "action": "launch_intent",
                "intent_type": "email",
                "data": {
                    "recipient": recipient,
                    "subject": subject_text,
                    "content": content,
                    "mailto_url": mailto_url
                },
                "message": f"Email prepared for {recipient}"
            }
        except:
            return {
                "success": True,
                "action": "manual_copy",
                "data": {
                    "recipient": recipient,
                    "subject": subject_text,
                    "content": content
                },
                "message": "Email content prepared. Please copy and paste into your email client."
            }
            
    except Exception as e:
        raise Exception(f"Email preparation failed: {str(e)}")

def send_whatsapp(recipient, content):
    """Open WhatsApp with pre-filled message"""
    try:
        # Clean phone number
        phone = recipient.replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
        if not phone.startswith("+"):
            phone = "+" + phone
        
        # URL encode the message
        encoded_message = urllib.parse.quote(content)
        
        # Create WhatsApp URL
        whatsapp_url = f"https://wa.me/{phone.replace('+', '')}?text={encoded_message}"
        
        return {
            "success": True,
            "action": "launch_intent",
            "intent_type": "whatsapp",
            "data": {
                "recipient": phone,
                "content": content,
                "whatsapp_url": whatsapp_url
            },
            "message": f"WhatsApp message prepared for {phone}"
        }
        
    except Exception as e:
        raise Exception(f"WhatsApp preparation failed: {str(e)}")

def send_sms(recipient, content):
    """Open SMS app with pre-filled message"""
    try:
        # Clean phone number
        phone = recipient.replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
        
        return {
            "success": True,
            "action": "launch_intent", 
            "intent_type": "sms",
            "data": {
                "recipient": phone,
                "content": content
            },
            "message": f"SMS prepared for {phone}"
        }
        
    except Exception as e:
        raise Exception(f"SMS preparation failed: {str(e)}")

# Main execution
if __name__ == "__main__":
    try:
        operation = sys.argv[1]
        recipient = sys.argv[2]
        content = sys.argv[3]
        subject = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] != "null" else None
        
        result = send_communication(operation, recipient, content, subject)
        print(json.dumps(result))
        
    except Exception as e:
        error_result = {
            "success": False,
            "error": f"Communication tool execution failed: {str(e)}"
        }
        print(json.dumps(error_result))
"""

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "executeFileTool" -> {
                val operation = call.argument<String>("operation") ?: ""
                val fileName = call.argument<String>("fileName") ?: ""
                val content = call.argument<String>("content") ?: ""
                val fileType = call.argument<String>("fileType")
                val metadata = call.argument<Map<String, Any>>("metadata") ?: emptyMap()
                
                executeFileTool(operation, fileName, content, fileType, metadata, result)
            }
            "executeCommunicationTool" -> {
                val operation = call.argument<String>("operation") ?: ""
                val recipient = call.argument<String>("recipient") ?: ""
                val content = call.argument<String>("content") ?: ""
                val subject = call.argument<String>("subject")
                
                executeCommunicationTool(operation, recipient, content, subject, result)
            }
            "listAvailableTools" -> {
                listAvailableTools(result)
            }
            "getToolCapabilities" -> {
                val toolName = call.argument<String>("toolName") ?: ""
                getToolCapabilities(toolName, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun executeFileTool(
        operation: String,
        fileName: String,
        content: String,
        fileType: String?,
        metadata: Map<String, Any>,
        result: MethodChannel.Result
    ) {
        scope.launch {
            try {
                val metadataJson = JSONObject(metadata).toString()
                val pythonResult = executePythonScript(
                    fileToolScript,
                    listOf(fileName, content, fileType ?: "null", metadataJson)
                )
                
                val resultMap = parseJsonResult(pythonResult)
                
                // If file was created successfully, handle Android-specific actions
                if (resultMap["success"] == true) {
                    val filePath = resultMap["path"] as? String
                    if (filePath != null) {
                        withContext(Dispatchers.Main) {
                            showFileCreatedNotification(fileName, filePath)
                        }
                    }
                }
                
                withContext(Dispatchers.Main) {
                    result.success(resultMap)
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

    private fun executeCommunicationTool(
        operation: String,
        recipient: String,
        content: String,
        subject: String?,
        result: MethodChannel.Result
    ) {
        scope.launch {
            try {
                val pythonResult = executePythonScript(
                    communicationToolScript,
                    listOf(operation, recipient, content, subject ?: "null")
                )
                
                val resultMap = parseJsonResult(pythonResult)
                
                // Handle Android intent launching
                if (resultMap["success"] == true && resultMap["action"] == "launch_intent") {
                    val data = resultMap["data"] as? Map<String, Any>
                    if (data != null) {
                        withContext(Dispatchers.Main) {
                            launchCommunicationIntent(operation, data)
                        }
                    }
                }
                
                withContext(Dispatchers.Main) {
                    result.success(resultMap)
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
            // Create temporary script file
            val tempDir = File(context.cacheDir, "python_scripts")
            if (!tempDir.exists()) {
                tempDir.mkdirs()
            }
            
            val scriptFile = File(tempDir, "script_${System.currentTimeMillis()}.py")
            scriptFile.writeText(script)
            
            // Execute Python script
            val command = mutableListOf("python3", scriptFile.absolutePath)
            command.addAll(args)
            
            val processBuilder = ProcessBuilder(command)
            processBuilder.redirectErrorStream(true)
            
            val process = processBuilder.start()
            val output = process.inputStream.bufferedReader().readText()
            
            val exitCode = process.waitFor(30, TimeUnit.SECONDS)
            
            // Clean up
            scriptFile.delete()
            
            if (!exitCode) {
                process.destroyForcibly()
                throw IOException("Python script execution timed out")
            }
            
            if (process.exitValue() != 0) {
                throw IOException("Python script failed with exit code: ${process.exitValue()}")
            }
            
            output.trim()
            
        } catch (e: Exception) {
            JSONObject().apply {
                put("success", false)
                put("error", "Python execution failed: ${e.message}")
            }.toString()
        }
    }

    private fun parseJsonResult(jsonString: String): Map<String, Any> {
        return try {
            val jsonObject = JSONObject(jsonString)
            val map = mutableMapOf<String, Any>()
            
            jsonObject.keys().forEach { key ->
                val value = jsonObject.get(key)
                map[key] = value
            }
            
            map
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "error" to "Failed to parse result: ${e.message}",
                "raw_output" to jsonString
            )
        }
    }

    private fun showFileCreatedNotification(fileName: String, filePath: String) {
        Toast.makeText(
            context,
            "File created: $fileName\nSaved to: ${File(filePath).parent}",
            Toast.LENGTH_LONG
        ).show()
    }

    private fun launchCommunicationIntent(operation: String, data: Map<String, Any>) {
        try {
            val intent = when (operation) {
                "email" -> createEmailIntent(data)
                "whatsapp" -> createWhatsAppIntent(data)
                "sms" -> createSmsIntent(data)
                else -> null
            }
            
            intent?.let { 
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(it)
            }
            
        } catch (e: Exception) {
            Toast.makeText(context, "Failed to launch $operation: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun createEmailIntent(data: Map<String, Any>): Intent {
        return Intent(Intent.ACTION_SENDTO).apply {
            this.data = Uri.parse("mailto:")
            putExtra(Intent.EXTRA_EMAIL, arrayOf(data["recipient"] as String))
            putExtra(Intent.EXTRA_SUBJECT, data["subject"] as String)
            putExtra(Intent.EXTRA_TEXT, data["content"] as String)
        }
    }

    private fun createWhatsAppIntent(data: Map<String, Any>): Intent {
        val whatsappUrl = data["whatsapp_url"] as String
        return Intent(Intent.ACTION_VIEW, Uri.parse(whatsappUrl))
    }

    private fun createSmsIntent(data: Map<String, Any>): Intent {
        return Intent(Intent.ACTION_SENDTO).apply {
            this.data = Uri.parse("smsto:${data["recipient"]}")
            putExtra("sms_body", data["content"] as String)
        }
    }

    private fun listAvailableTools(result: MethodChannel.Result) {
        val tools = mapOf(
            "file_tools" to listOf(
                mapOf(
                    "name" to "create_file",
                    "description" to "Create files of various types (txt, html, css, pdf, zip)",
                    "supported_formats" to listOf("txt", "html", "css", "pdf", "zip", "json", "xml")
                )
            ),
            "communication_tools" to listOf(
                mapOf(
                    "name" to "send_email",
                    "description" to "Send email via default email client"
                ),
                mapOf(
                    "name" to "send_whatsapp",
                    "description" to "Send WhatsApp message"
                ),
                mapOf(
                    "name" to "send_sms",
                    "description" to "Send SMS text message"
                )
            )
        )
        
        result.success(mapOf("success" to true, "tools" to tools))
    }

    private fun getToolCapabilities(toolName: String, result: MethodChannel.Result) {
        val capabilities = when (toolName) {
            "create_file" -> mapOf(
                "supports_metadata" to true,
                "supports_multiple_formats" to true,
                "max_file_size" to "10MB",
                "supported_formats" to listOf("txt", "html", "css", "pdf", "zip", "json", "xml")
            )
            "send_email" -> mapOf(
                "supports_attachments" to false,
                "supports_html" to true,
                "requires_email_client" to true
            )
            "send_whatsapp" -> mapOf(
                "supports_media" to false,
                "requires_whatsapp_installed" to true,
                "supports_groups" to false
            )
            "send_sms" -> mapOf(
                "supports_media" to false,
                "character_limit" to 160,
                "supports_long_messages" to true
            )
            else -> mapOf("error" to "Unknown tool: $toolName")
        }
        
        result.success(mapOf("success" to true, "capabilities" to capabilities))
    }

    fun cleanup() {
        pythonExecutor.shutdown()
        scope.cancel()
    }
}