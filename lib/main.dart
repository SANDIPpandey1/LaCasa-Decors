import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      home: SplashScreen(url: initialUrl),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final String url;

  SplashScreen({required this.url});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebViewController _webViewController;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();

    // Initialize WebViewController and load URL in background
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) {
                setState(() {
                  _isWebViewReady = true;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));

    // Animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // Navigate to main screen after splash duration
    Future.delayed(Duration(milliseconds: 3700), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => SafeArea(
                  child: Scaffold(
                    body: WebViewContainer(
                      url: widget.url,
                      controller: _webViewController,
                    ),
                  ),
                ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset('assets/icon/fab.png', width: 150, height: 150),
        ),
      ),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  final String url;
  final WebViewController controller;

  WebViewContainer({required this.url, required this.controller});

  @override
  _WebViewContainerState createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  final String baseHost = "meesaa.com";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Setup navigation handler with loading indicator
    widget.controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            isLoading = true;
          });
        },
        onPageFinished: (url) {
          setState(() {
            isLoading = false;
          });
        },
        onNavigationRequest: (NavigationRequest request) async {
          Uri uri = Uri.parse(request.url);

          // If it's not meesaa.com, launch externally
          if (!uri.host.contains(baseHost)) {
            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
          }

          // Show loading indicator before navigation
          setState(() {
            isLoading = true;
          });

          // Otherwise, allow inside app
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: widget.controller),
        if (isLoading)
          Container(
            color: Colors.white.withOpacity(1),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(child: RotatingLogo()),
          ),
      ],
    );
  }
}

// New class for the rotating splash image
class RotatingLogo extends StatefulWidget {
  @override
  _RotatingLogoState createState() => _RotatingLogoState();
}

class _RotatingLogoState extends State<RotatingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Image.asset('assets/icon/fab.png', width: 100, height: 100),
    );
  }
}
