import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
  OneSignal.initialize("f5e75c08-0865-4ccc-8ab4-bcf35eca0082");
  OneSignal.Notifications.requestPermission(true);
}

class MyApp extends StatelessWidget {
  final String initialUrl = "https://meesaa.com/";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meesaa',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: WebViewContainer(url: initialUrl)),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  final String url;

  WebViewContainer({required this.url});

  @override
  _WebViewContainerState createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late final WebViewController _controller;
  final String baseHost = "meesaa.com";

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) async {
                Uri uri = Uri.parse(request.url);

                // If it's not meesaa.com, launch externally
                if (!uri.host.contains(baseHost)) {
                  if (await canLaunchUrl(uri)) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                    return NavigationDecision.prevent;
                  }
                }

                // Otherwise, allow inside app
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
