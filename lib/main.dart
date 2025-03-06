import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ingilizce/provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; // Android için
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; // iOS için
import 'login_screen.dart';
import 'main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    requestTrackingPermission();
    await MobileAds.instance.initialize();

    // WebViewPlatform'u platforma göre ayarla
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iOS için
      WebViewPlatform.instance = WebKitWebViewPlatform();
    } else {
      // Android için
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    // Provider'ları uygulamanın en üstüne yerleştir
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print("Firebase initialization error: $e");
  }
}

void requestTrackingPermission() async {
  var status = await Permission.appTrackingTransparency.request();
  if (status.isGranted) {
    print("İzin verildi!");
  } else {
    print("İzin reddedildi.");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // SplashScreen ana sayfa olarak atanıyor
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    await Future.delayed(const Duration(seconds: 3));
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      }
    } catch (e) {
      print("Firebase Auth error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mavi arka plan
          Positioned.fill(
            child: Container(
              color: Colors.blue, // Mavi arka plan rengi
            ),
          ),
          // Yükleniyor spinner'ı ve yazı
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.white, // Spinner rengi beyaz
                ),
                const SizedBox(height: 20),
                const Text(
                  "Oturum Yükleniyor...",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Yazı rengi beyaz
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}