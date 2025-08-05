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

class LatexRenderer(private val context: Context) {
    
    companion object {
        private const val MATHJAX_HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <script>
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
        
        function renderLatex(latex, isDisplay) {
            const container = document.getElementById('math-container');
            if (isDisplay) {
                container.innerHTML = '$$' + latex + '$$';
            } else {
                container.innerHTML = '$' + latex + '$';
            }
            
            MathJax.typesetPromise([container]).then(() => {
                // Notify Android that rendering is complete
                Android.onRenderComplete();
            }).catch((err) => {
                console.error('MathJax rendering error:', err);
                Android.onRenderError(err.toString());
            });
        }
        
        function setTheme(isDark) {
            document.body.style.backgroundColor = isDark ? '#2D3748' : '#FFFFFF';
            document.body.style.color = isDark ? '#FFFFFF' : '#000000';
        }
    </script>
    <style>
        body {
            margin: 0;
            padding: 16px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #FFFFFF;
            color: #000000;
        }
        #math-container {
            text-align: center;
            min-height: 50px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .MathJax {
            font-size: 1.2em !important;
        }
    </style>
</head>
<body>
    <div id="math-container">Loading...</div>
</body>
</html>
        """
    }
    
    data class LatexRenderResult(
        val success: Boolean,
        val bitmap: Bitmap? = null,
        val error: String? = null,
        val width: Int = 0,
        val height: Int = 0
    )
    
    suspend fun renderLatexToBitmap(
        latex: String,
        isDisplayMode: Boolean = false,
        isDarkTheme: Boolean = false,
        fontSize: Float = 16f
    ): LatexRenderResult = withContext(Dispatchers.Main) {
        val future = CompletableFuture<LatexRenderResult>()
        
        try {
            val webView = WebView(context).apply {
                settings.apply {
                    javaScriptEnabled = true
                    domStorageEnabled = true
                    loadWithOverviewMode = true
                    useWideViewPort = true
                    builtInZoomControls = false
                    displayZoomControls = false
                }
                
                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        
                        // Set theme and render LaTeX
                        val jsCode = """
                            setTheme($isDarkTheme);
                            renderLatex('${latex.replace("'", "\\'")}', $isDisplayMode);
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
                            // Capture the WebView as bitmap
                            try {
                                measure(
                                    View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
                                    View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
                                )
                                
                                val bitmap = Bitmap.createBitmap(
                                    if (measuredWidth > 0) measuredWidth else 400,
                                    if (measuredHeight > 0) measuredHeight else 200,
                                    Bitmap.Config.ARGB_8888
                                )
                                
                                val canvas = Canvas(bitmap)
                                if (!isDarkTheme) {
                                    canvas.drawColor(Color.WHITE)
                                } else {
                                    canvas.drawColor(Color.parseColor("#2D3748"))
                                }
                                
                                draw(canvas)
                                
                                future.complete(LatexRenderResult(
                                    success = true,
                                    bitmap = bitmap,
                                    width = bitmap.width,
                                    height = bitmap.height
                                ))
                            } catch (e: Exception) {
                                future.complete(LatexRenderResult(
                                    success = false,
                                    error = "Failed to capture bitmap: ${e.message}"
                                ))
                            }
                        }
                    }
                    
                    @android.webkit.JavascriptInterface
                    fun onRenderError(error: String) {
                        future.complete(LatexRenderResult(
                            success = false,
                            error = error
                        ))
                    }
                }, "Android")
            }
            
            // Load the HTML with MathJax
            webView.loadDataWithBaseURL(
                "https://example.com",
                MATHJAX_HTML_TEMPLATE,
                "text/html",
                "UTF-8",
                null
            )
            
            // Set timeout for rendering
            GlobalScope.launch {
                delay(10000) // 10 second timeout
                if (!future.isDone) {
                    future.complete(LatexRenderResult(
                        success = false,
                        error = "Rendering timeout"
                    ))
                }
            }
            
        } catch (e: Exception) {
            future.complete(LatexRenderResult(
                success = false,
                error = "Setup error: ${e.message}"
            ))
        }
        
        future.get()
    }
    
    /**
     * Render LaTeX and return as Base64 encoded image
     */
    suspend fun renderLatexToBase64(
        latex: String,
        isDisplayMode: Boolean = false,
        isDarkTheme: Boolean = false
    ): String? {
        val result = renderLatexToBitmap(latex, isDisplayMode, isDarkTheme)
        
        return if (result.success && result.bitmap != null) {
            val outputStream = java.io.ByteArrayOutputStream()
            result.bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            Base64.encodeToString(outputStream.toByteArray(), Base64.DEFAULT)
        } else {
            null
        }
    }
    
    /**
     * Simple LaTeX validation
     */
    fun isValidLatex(latex: String): Boolean {
        // Basic validation - check for balanced delimiters
        val openBraces = latex.count { it == '{' }
        val closeBraces = latex.count { it == '}' }
        val openParens = latex.count { it == '(' }
        val closeParens = latex.count { it == ')' }
        val openBrackets = latex.count { it == '[' }
        val closeBrackets = latex.count { it == ']' }
        
        return openBraces == closeBraces && 
               openParens == closeParens && 
               openBrackets == closeBrackets &&
               latex.isNotBlank()
    }
    
    /**
     * Extract LaTeX expressions from text
     */
    fun extractLatexExpressions(text: String): List<LatexExpression> {
        val expressions = mutableListOf<LatexExpression>()
        
        // Find display math $$...$$
        val displayRegex = Regex("""\$\$(.*?)\$\$""", RegexOption.DOT_MATCHES_ALL)
        displayRegex.findAll(text).forEach { match ->
            expressions.add(LatexExpression(
                original = match.value,
                latex = match.groupValues[1],
                isDisplay = true,
                start = match.range.first,
                end = match.range.last + 1
            ))
        }
        
        // Find inline math $...$
        val inlineRegex = Regex("""\$([^$]+)\$""")
        inlineRegex.findAll(text).forEach { match ->
            // Skip if this is inside a display math expression
            val isInsideDisplay = expressions.any { expr ->
                expr.isDisplay && match.range.first >= expr.start && match.range.last <= expr.end
            }
            
            if (!isInsideDisplay) {
                expressions.add(LatexExpression(
                    original = match.value,
                    latex = match.groupValues[1],
                    isDisplay = false,
                    start = match.range.first,
                    end = match.range.last + 1
                ))
            }
        }
        
        return expressions.sortedBy { it.start }
    }
    
    data class LatexExpression(
        val original: String,
        val latex: String,
        val isDisplay: Boolean,
        val start: Int,
        val end: Int
    )
}