// lib/screens/webview_screen.dart
import '../providers/event_service_provider.dart';
import '../models/screen_args_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/common_gradient_header_widget.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel args;

  const WebViewScreen({required this.args, super.key});

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  late final WebViewController _controller;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isWebViewReady = true;
            });
          },
        ),
      );
  }

  void _loadHtmlContent(String htmlContent) {
    final styledHtml =
        '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          
        </head>
        <body>
          $htmlContent
        </body>
      </html>
    ''';
    _controller.loadHtmlString(styledHtml);
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have pageId or webUrl
    final pageId = widget.args.data['page_id'] as int?;
    final webUrl = widget.args.data['web_url'] as String?;

    return Scaffold(
      body: Column(
        children: [
          // Gradient Header
          CommonGradientHeader(
            title: widget.args.name,
            onRefresh: pageId != null ? () {
              ref.invalidate(htmlContentProvider(pageId));
              setState(() {
                _isWebViewReady = false;
              });
            } : null,
          ),

          // WebView Content
          Expanded(
            child: pageId != null
                ? _buildHtmlContentView(pageId)
                : _buildWebUrlView(webUrl),
          ),
        ],
      ),
    );
  }

  // Build view for HTML content from API
  Widget _buildHtmlContentView(int pageId) {
    final htmlContentAsync = ref.watch(htmlContentProvider(pageId));

    return htmlContentAsync.when(
      data: (htmlContent) {
        // Load HTML into WebView
        if (!_isWebViewReady) {
          if (htmlContent.isSuccess == true && htmlContent.data.isNotEmpty) {
            _loadHtmlContent(htmlContent.data[0]['html_content'] as String);
          } else {
            _loadHtmlContent("<h2>" + htmlContent.message + "</h2>");
          }
        }

        return Stack(
          children: [
            AnimatedOpacity(
              opacity: _isWebViewReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              child: WebViewWidget(controller: _controller),
            ),
            if (!_isWebViewReady)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading content...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Refresh the provider
                  ref.invalidate(htmlContentProvider(pageId));
                  setState(() {
                    _isWebViewReady = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build view for direct web URL
  Widget _buildWebUrlView(String? webUrl) {
    if (webUrl == null || webUrl.isEmpty) {
      return const Center(
        child: Text(
          'No URL provided',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Load URL on first build
    if (!_isWebViewReady) {
      _controller.loadRequest(Uri.parse(webUrl));
    }

    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _isWebViewReady ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          child: WebViewWidget(controller: _controller),
        ),
        if (!_isWebViewReady)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
      ],
    );
  }
}
