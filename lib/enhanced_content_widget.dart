import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:flutter_html_iframe/flutter_html_iframe.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_video/flutter_html_video.dart';
import 'package:flutter_html_audio/flutter_html_audio.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class EnhancedContentWidget extends StatelessWidget {
  final String content;
  final bool isUserMessage;
  final bool isThinkingMode;

  const EnhancedContentWidget({
    super.key,
    required this.content,
    this.isUserMessage = false,
    this.isThinkingMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Convert markdown to HTML and render with flutter_html
    return _buildHtmlContent(context);
  }

  Widget _buildHtmlContent(BuildContext context) {
    // Convert markdown to HTML
    final String htmlContent = md.markdownToHtml(
      content,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    return Html(
      data: htmlContent,
      extensions: [
        TableHtmlExtension(),
        IframeHtmlExtension(),
        SvgHtmlExtension(),
        VideoHtmlExtension(),
        AudioHtmlExtension(),
      ],
      style: {
        "body": Style(
          fontSize: FontSize(16.0),
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          lineHeight: const LineHeight(1.4),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "h1": Style(
          fontSize: FontSize(24.0),
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineLarge?.color,
          margin: Margins.only(bottom: 16.0),
        ),
        "h2": Style(
          fontSize: FontSize(20.0),
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineMedium?.color,
          margin: Margins.only(bottom: 14.0),
        ),
        "h3": Style(
          fontSize: FontSize(18.0),
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineSmall?.color,
          margin: Margins.only(bottom: 12.0),
        ),
        "h4": Style(
          fontSize: FontSize(16.0),
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineSmall?.color,
          margin: Margins.only(bottom: 10.0),
        ),
        "h5": Style(
          fontSize: FontSize(14.0),
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineSmall?.color,
          margin: Margins.only(bottom: 8.0),
        ),
        "h6": Style(
          fontSize: FontSize(12.0),
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineSmall?.color,
          margin: Margins.only(bottom: 6.0),
        ),
        "p": Style(
          fontSize: FontSize(16.0),
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          lineHeight: const LineHeight(1.4),
          margin: Margins.only(bottom: 12.0),
        ),
        "code": Style(
          backgroundColor: Theme.of(context).cardColor,
          fontFamily: 'monospace',
          fontSize: FontSize(14.0),
          padding: HtmlPaddings.symmetric(horizontal: 4.0, vertical: 2.0),
        ),
        "pre": Style(
          backgroundColor: Theme.of(context).cardColor,
          padding: HtmlPaddings.all(12.0),
          margin: Margins.only(bottom: 12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        "pre code": Style(
          backgroundColor: Colors.transparent,
          fontFamily: 'monospace',
          fontSize: FontSize(14.0),
          padding: HtmlPaddings.zero,
        ),
        "blockquote": Style(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
          border: Border(
            left: BorderSide(
              color: Colors.grey.shade400,
              width: 4.0,
            ),
          ),
          padding: HtmlPaddings.only(left: 16.0),
          margin: Margins.only(bottom: 12.0),
        ),
        "ul": Style(
          margin: Margins.only(bottom: 12.0),
          padding: HtmlPaddings.only(left: 20.0),
        ),
        "ol": Style(
          margin: Margins.only(bottom: 12.0),
          padding: HtmlPaddings.only(left: 20.0),
        ),
        "li": Style(
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          margin: Margins.only(bottom: 4.0),
        ),
        "a": Style(
          color: Colors.blue,
          textDecoration: TextDecoration.underline,
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
        "table": Style(
          border: Border.all(color: Colors.grey.shade300),
          margin: Margins.only(bottom: 12.0),
        ),
        "th": Style(
          backgroundColor: Colors.grey.shade100,
          padding: HtmlPaddings.all(8.0),
          border: Border.all(color: Colors.grey.shade300),
          fontWeight: FontWeight.bold,
        ),
        "td": Style(
          padding: HtmlPaddings.all(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
      },
      onLinkTap: (url, attributes, element) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      onAnchorTap: (url, attributes, element) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}