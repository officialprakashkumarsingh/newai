package com.aham.app

import android.content.Context
import android.webkit.WebView
import android.webkit.WebViewClient
import android.util.Base64
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.view.View
import kotlinx.coroutines.*
import java.util.concurrent.CompletableFuture

class MarkdownRenderer(private val context: Context) {
    
    companion object {
        private const val MARKDOWN_HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    
    <!-- Markdown-it library -->
    <script src="https://cdn.jsdelivr.net/npm/markdown-it@13.0.1/dist/markdown-it.min.js"></script>
    
    <!-- Syntax highlighting -->
    <script src="https://cdn.jsdelivr.net/npm/highlight.js@11.8.0/lib/highlight.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.8.0/styles/github.min.css" id="highlight-light">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.8.0/styles/github-dark.min.css" id="highlight-dark" disabled>
    
    <!-- MathJax for LaTeX -->
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    
    <script>
        // Configure MathJax
        window.MathJax = {
            tex: {
                inlineMath: [['$', '$'], ['\\(', '\\)']],
                displayMath: [['$$', '$$'], ['\\[', '\\]']],
                processEscapes: true,
                processEnvironments: true
            },
            options: {
                ignoreHtmlClass: 'tex2jax_ignore',
                processHtmlClass: 'tex2jax_process'
            },
            startup: {
                ready: () => {
                    MathJax.startup.defaultReady();
                    console.log('MathJax is ready!');
                }
            }
        };
        
        // Initialize markdown-it with plugins
        const md = markdownit({
            html: true,
            linkify: true,
            typographer: true,
            highlight: function (str, lang) {
                if (lang && hljs.getLanguage(lang)) {
                    try {
                        const highlighted = hljs.highlight(str, { language: lang }).value;
                        return '<pre class="hljs"><code class="hljs language-' + lang + '">' + highlighted + '</code></pre>';
                    } catch (__) {}
                }
                return '<pre class="hljs"><code>' + md.utils.escapeHtml(str) + '</code></pre>';
            }
        });
        
        function renderMarkdown(markdown, isDark, fontSize) {
            try {
                // Set theme
                setTheme(isDark);
                setFontSize(fontSize);
                
                // Render markdown to HTML
                const html = md.render(markdown);
                
                // Insert into container
                const container = document.getElementById('content-container');
                container.innerHTML = html;
                
                // Process LaTeX expressions
                MathJax.typesetPromise([container]).then(() => {
                    // Add copy buttons to code blocks
                    addCopyButtons();
                    
                    // Notify Android that rendering is complete
                    setTimeout(() => {
                        Android.onRenderComplete();
                    }, 100);
                }).catch((err) => {
                    console.error('MathJax rendering error:', err);
                    Android.onRenderError(err.toString());
                });
                
            } catch (error) {
                console.error('Markdown rendering error:', error);
                Android.onRenderError(error.toString());
            }
        }
        
        function setTheme(isDark) {
            document.body.classList.toggle('dark-theme', isDark);
            
            // Toggle highlight.js themes
            const lightTheme = document.getElementById('highlight-light');
            const darkTheme = document.getElementById('highlight-dark');
            
            if (isDark) {
                lightTheme.disabled = true;
                darkTheme.disabled = false;
            } else {
                lightTheme.disabled = false;
                darkTheme.disabled = true;
            }
        }
        
        function setFontSize(fontSize) {
            document.documentElement.style.setProperty('--base-font-size', fontSize + 'px');
        }
        
        function addCopyButtons() {
            const codeBlocks = document.querySelectorAll('pre.hljs');
            codeBlocks.forEach((block, index) => {
                const button = document.createElement('button');
                button.className = 'copy-btn';
                button.innerHTML = '📋';
                button.onclick = () => copyCode(block, button, index);
                
                const wrapper = document.createElement('div');
                wrapper.className = 'code-wrapper';
                block.parentNode.insertBefore(wrapper, block);
                wrapper.appendChild(block);
                wrapper.appendChild(button);
            });
        }
        
        function copyCode(block, button, index) {
            const code = block.querySelector('code').textContent;
            Android.copyToClipboard(code);
            
            // Visual feedback
            button.innerHTML = '✅';
            button.style.backgroundColor = '#4CAF50';
            setTimeout(() => {
                button.innerHTML = '📋';
                button.style.backgroundColor = '';
            }, 2000);
        }
        
        // Initialize highlight.js
        hljs.highlightAll();
    </script>
    
    <style>
        :root {
            --base-font-size: 16px;
            --bg-color: #ffffff;
            --text-color: #333333;
            --border-color: #e1e5e9;
            --code-bg: #f6f8fa;
            --blockquote-border: #dfe2e5;
            --link-color: #0366d6;
        }
        
        .dark-theme {
            --bg-color: #1a202c;
            --text-color: #e2e8f0;
            --border-color: #4a5568;
            --code-bg: #2d3748;
            --blockquote-border: #4a5568;
            --link-color: #63b3ed;
        }
        
        body {
            margin: 0;
            padding: 16px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            font-size: var(--base-font-size);
            line-height: 1.6;
            transition: all 0.3s ease;
        }
        
        #content-container {
            max-width: 100%;
            word-wrap: break-word;
        }
        
        /* Typography */
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 { font-size: 2em; border-bottom: 1px solid var(--border-color); padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid var(--border-color); padding-bottom: 0.3em; }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: 0.875em; }
        h6 { font-size: 0.85em; color: #6a737d; }
        
        p {
            margin-bottom: 16px;
        }
        
        /* Links */
        a {
            color: var(--link-color);
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        /* Lists */
        ul, ol {
            padding-left: 30px;
            margin-bottom: 16px;
        }
        
        li {
            margin-bottom: 4px;
        }
        
        /* Code */
        code {
            padding: 2px 4px;
            font-size: 85%;
            background-color: var(--code-bg);
            border-radius: 3px;
            font-family: SFMono-Regular, Consolas, 'Liberation Mono', Menlo, monospace;
        }
        
        .code-wrapper {
            position: relative;
            margin: 16px 0;
        }
        
        pre.hljs {
            padding: 16px;
            overflow-x: auto;
            font-size: 85%;
            line-height: 1.45;
            background-color: var(--code-bg) !important;
            border-radius: 6px;
            margin: 0;
        }
        
        .copy-btn {
            position: absolute;
            top: 8px;
            right: 8px;
            background: rgba(255, 255, 255, 0.8);
            border: 1px solid #ccc;
            border-radius: 4px;
            padding: 4px 8px;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.2s ease;
        }
        
        .dark-theme .copy-btn {
            background: rgba(0, 0, 0, 0.6);
            border-color: #555;
            color: white;
        }
        
        .copy-btn:hover {
            background: rgba(255, 255, 255, 1);
            transform: scale(1.05);
        }
        
        /* Blockquotes */
        blockquote {
            padding: 0 16px;
            margin: 0 0 16px 0;
            color: #6a737d;
            border-left: 4px solid var(--blockquote-border);
        }
        
        /* Tables */
        table {
            border-spacing: 0;
            border-collapse: collapse;
            margin-bottom: 16px;
            width: 100%;
        }
        
        table th,
        table td {
            padding: 6px 13px;
            border: 1px solid var(--border-color);
        }
        
        table th {
            font-weight: 600;
            background-color: var(--code-bg);
        }
        
        /* Horizontal rule */
        hr {
            height: 4px;
            margin: 24px 0;
            background-color: var(--border-color);
            border: 0;
        }
        
        /* Math expressions */
        .MathJax {
            font-size: 1.1em !important;
        }
        
        mjx-container[display="block"] {
            margin: 16px 0 !important;
        }
        
        /* Images */
        img {
            max-width: 100%;
            height: auto;
            border-radius: 6px;
            margin: 8px 0;
        }
        
        /* Responsive design */
        @media (max-width: 768px) {
            body {
                padding: 12px;
                font-size: 14px;
            }
            
            h1 { font-size: 1.8em; }
            h2 { font-size: 1.4em; }
            h3 { font-size: 1.2em; }
        }
    </style>
</head>
<body>
    <div id="content-container">Loading...</div>
</body>
</html>
        """
    }
    
    data class MarkdownRenderResult(
        val success: Boolean,
        val bitmap: Bitmap? = null,
        val error: String? = null,
        val width: Int = 0,
        val height: Int = 0
    )
    
    suspend fun renderMarkdownToBitmap(
        markdown: String,
        isDarkTheme: Boolean = false,
        fontSize: Float = 16f
    ): MarkdownRenderResult = withContext(Dispatchers.Main) {
        val future = CompletableFuture<MarkdownRenderResult>()
        
        try {
            val webView = WebView(context).apply {
                settings.apply {
                    javaScriptEnabled = true
                    domStorageEnabled = true
                    loadWithOverviewMode = true
                    useWideViewPort = true
                    builtInZoomControls = false
                    displayZoomControls = false
                    allowFileAccess = false
                    allowContentAccess = false
                }
                
                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        
                        // Render markdown
                        val escapedMarkdown = markdown
                            .replace("\\", "\\\\")
                            .replace("'", "\\'")
                            .replace("\n", "\\n")
                            .replace("\r", "\\r")
                        
                        val jsCode = """
                            renderMarkdown('$escapedMarkdown', $isDarkTheme, $fontSize);
                        """.trimIndent()
                        
                        evaluateJavascript(jsCode) { result ->
                            // JavaScript executed
                        }
                    }
                }
                
                // Add JavaScript interface
                addJavascriptInterface(object {
                    @android.webkit.JavascriptInterface
                    fun onRenderComplete() {
                        post {
                            try {
                                // Wait for content to fully load
                                postDelayed({
                                    try {
                                        measure(
                                            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
                                            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
                                        )
                                        
                                        val width = if (measuredWidth > 0) measuredWidth else 800
                                        val height = if (measuredHeight > 0) measuredHeight else 600
                                        
                                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                                        val canvas = Canvas(bitmap)
                                        
                                        if (!isDarkTheme) {
                                            canvas.drawColor(Color.WHITE)
                                        } else {
                                            canvas.drawColor(Color.parseColor("#1a202c"))
                                        }
                                        
                                        draw(canvas)
                                        
                                        future.complete(MarkdownRenderResult(
                                            success = true,
                                            bitmap = bitmap,
                                            width = width,
                                            height = height
                                        ))
                                    } catch (e: Exception) {
                                        future.complete(MarkdownRenderResult(
                                            success = false,
                                            error = "Failed to capture bitmap: ${e.message}"
                                        ))
                                    }
                                }, 500) // Wait 500ms for rendering to complete
                            } catch (e: Exception) {
                                future.complete(MarkdownRenderResult(
                                    success = false,
                                    error = "Failed to capture bitmap: ${e.message}"
                                ))
                            }
                        }
                    }
                    
                    @android.webkit.JavascriptInterface
                    fun onRenderError(error: String) {
                        future.complete(MarkdownRenderResult(
                            success = false,
                            error = error
                        ))
                    }
                    
                    @android.webkit.JavascriptInterface
                    fun copyToClipboard(text: String) {
                        // Handle clipboard copy - will be implemented via Flutter
                        // For now, just log
                        android.util.Log.d("MarkdownRenderer", "Copy to clipboard: $text")
                    }
                }, "Android")
            }
            
            // Load the HTML
            webView.loadDataWithBaseURL(
                "https://example.com",
                MARKDOWN_HTML_TEMPLATE,
                "text/html",
                "UTF-8",
                null
            )
            
            // Set timeout for rendering
            GlobalScope.launch {
                delay(15000) // 15 second timeout
                if (!future.isDone) {
                    future.complete(MarkdownRenderResult(
                        success = false,
                        error = "Rendering timeout"
                    ))
                }
            }
            
        } catch (e: Exception) {
            future.complete(MarkdownRenderResult(
                success = false,
                error = "Setup error: ${e.message}"
            ))
        }
        
        future.get()
    }
    
    /**
     * Render markdown and return as Base64 encoded image
     */
    suspend fun renderMarkdownToBase64(
        markdown: String,
        isDarkTheme: Boolean = false,
        fontSize: Float = 16f
    ): String? {
        val result = renderMarkdownToBitmap(markdown, isDarkTheme, fontSize)
        
        return if (result.success && result.bitmap != null) {
            val outputStream = java.io.ByteArrayOutputStream()
            result.bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            Base64.encodeToString(outputStream.toByteArray(), Base64.DEFAULT)
        } else {
            null
        }
    }
    
    /**
     * Extract and validate markdown content
     */
    fun processMarkdown(markdown: String): ProcessedMarkdown {
        val lines = markdown.split('\n')
        var hasCodeBlocks = false
        var hasLatex = false
        var hasTables = false
        var hasImages = false
        var hasLinks = false
        
        // Analyze content
        for (line in lines) {
            if (line.trim().startsWith("```")) hasCodeBlocks = true
            if (line.contains("$$") || line.contains("$")) hasLatex = true
            if (line.trim().startsWith("|") && line.contains("|")) hasTables = true
            if (line.contains("![") && line.contains("](")) hasImages = true
            if (line.contains("[") && line.contains("](")) hasLinks = true
        }
        
        return ProcessedMarkdown(
            content = markdown,
            hasCodeBlocks = hasCodeBlocks,
            hasLatex = hasLatex,
            hasTables = hasTables,
            hasImages = hasImages,
            hasLinks = hasLinks,
            lineCount = lines.size,
            wordCount = markdown.split("\\s+".toRegex()).size
        )
    }
    
    data class ProcessedMarkdown(
        val content: String,
        val hasCodeBlocks: Boolean,
        val hasLatex: Boolean,
        val hasTables: Boolean,
        val hasImages: Boolean,
        val hasLinks: Boolean,
        val lineCount: Int,
        val wordCount: Int
    )
}