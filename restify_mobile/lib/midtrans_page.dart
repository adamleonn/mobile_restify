import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransPage extends StatefulWidget {
  final String snapToken;

  const MidtransPage({
    super.key,
    required this.snapToken,
  });

  @override
  State<MidtransPage> createState() => _MidtransPageState();
}

class _MidtransPageState extends State<MidtransPage> {
  late final WebViewController controller;
  bool _hasPopped = false;

  void _handleFinished() {
    if (!_hasPopped && mounted) {
      _hasPopped = true;
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (url.contains("finish") ||
                url.contains("unfinish") ||
                url.contains("error") ||
                url.contains("ngrok-free.dev") ||
                url.contains("localhost") ||
                url.contains("127.0.0.1")) {
              _handleFinished();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            final lowerUrl = url.toLowerCase();
            if (lowerUrl.contains("finish") ||
                lowerUrl.contains("unfinish") ||
                lowerUrl.contains("error") ||
                lowerUrl.contains("ngrok-free.dev") ||
                lowerUrl.contains("localhost") ||
                lowerUrl.contains("127.0.0.1")) {
              _handleFinished();
            }
          },
          onPageFinished: (url) {
            debugPrint("URL: $url");

            final lowerUrl = url.toLowerCase();
            if (lowerUrl.contains("finish") ||
                lowerUrl.contains("unfinish") ||
                lowerUrl.contains("error") ||
                lowerUrl.contains("ngrok-free.dev") ||
                lowerUrl.contains("localhost") ||
                lowerUrl.contains("127.0.0.1")) {
              _handleFinished();
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          "https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}",
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}