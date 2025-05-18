import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(MyApp());
  OneSignal.initialize("f5e75c08-0865-4ccc-8ab4-bcf35eca0082");
  OneSignal.Notifications.requestPermission(true);
}

class MyApp extends StatelessWidget {
  final String initialUrl = "https://lacasadecors.com/";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meesaa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blueAccent,
        ),
      ),
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

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

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
          child: Image.asset('assets/icon/la.png', width: 150, height: 150),
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
  final String baseHost = "lacasadecors.com";
  bool isLoading = false;
  bool hasInternet = true;
  final Connectivity connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    checkInternetConnection();

    connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      ConnectivityResult result = _extractRelevantConnectivity(results);
      handleConnectivityChange(result);
    });

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
          final externalHosts = [
            'instagram.com',
            'facebook.com',
            'wa.me',
            'api.whatsapp.com',
            'web.whatsapp.com',
            'twitter.com',
            'youtube.com',
          ];

          if (!uri.host.contains(baseHost) &&
              externalHosts.any((host) => uri.host.contains(host))) {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
          }

          setState(() {
            isLoading = true;
          });

          return NavigationDecision.navigate;
        },
        onWebResourceError: (error) {
          checkInternetConnection();
        },
      ),
    );
  }

  Future<void> checkInternetConnection() async {
    List<ConnectivityResult> results = await connectivity.checkConnectivity();
    ConnectivityResult result = _extractRelevantConnectivity(results);
    handleConnectivityChange(result);
  }

  ConnectivityResult _extractRelevantConnectivity(
    List<ConnectivityResult> results,
  ) {
    for (var res in results) {
      if (res != ConnectivityResult.none) return res;
    }
    return ConnectivityResult.none;
  }

  void handleConnectivityChange(ConnectivityResult result) {
    setState(() {
      hasInternet = result != ConnectivityResult.none;
      if (hasInternet && !isLoading) {
        widget.controller.reload();
        isLoading = true;
      }
    });
  }

  void retryConnection() async {
    setState(() {
      isLoading = true;
    });

    await checkInternetConnection();

    if (hasInternet) {
      widget.controller.reload();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternet) {
      return buildNoInternetWidget();
    }

    return WillPopScope(
      onWillPop: () async {
        if (await widget.controller.canGoBack()) {
          widget.controller.goBack();
          return false;
        }
        return true;
      },
      child: Stack(
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
      ),
    );
  }

  Widget buildNoInternetWidget() {
    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icon/la.png', width: 120, height: 120),
          SizedBox(height: 30),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Please connect to the internet to access the app',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: retryConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Retry',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      child: Image.asset('assets/icon/la.png', width: 100, height: 100),
    );
  }
}
