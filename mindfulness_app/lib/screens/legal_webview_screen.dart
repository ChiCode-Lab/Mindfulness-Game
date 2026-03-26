import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Base URL where both HTML files are hosted on GitHub Pages.
// Replace with your actual GitHub Pages URL before publishing.
const String _kPrivacyPolicyUrl =
    'https://chicode-lab.github.io/Mindfulness-Game/privacy';
const String _kTermsOfUseUrl =
    'https://chicode-lab.github.io/Mindfulness-Game/terms';

enum LegalDocument { privacyPolicy, termsOfUse }

class LegalWebViewScreen extends StatefulWidget {
  final LegalDocument document;

  const LegalWebViewScreen({super.key, required this.document});

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final url = widget.document == LegalDocument.privacyPolicy
        ? _kPrivacyPolicyUrl
        : _kTermsOfUseUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.document == LegalDocument.privacyPolicy
        ? 'Privacy Policy'
        : 'Terms of Use';

    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A233A),
        foregroundColor: const Color(0xFFF8F9FA),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8A66)),
            ),
        ],
      ),
    );
  }
}
