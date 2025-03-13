import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ingilizce/provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; // Android için
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; // iOS için
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final RequestConfiguration requestConfiguration = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
    );

    MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    // WebViewPlatform'u platforma göre ayarla
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    } else {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    // Avatarları kopyalama işlemini başlat
    await _copyAvatarsToAppDir();

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

// assets/avatars içindeki tüm görselleri uygulama dizinine kopyalar
Future<void> _copyAvatarsToAppDir() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${appDir.path}/avatars');

    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    List<String> avatarFiles = [
      "avatar1.jpg",
      "avatar2.jpg",
      "avatar3.jpg",
      "avatar4.jpg",
      "avatar5.jpg",
      "avatar6.jpg",
      "avatar7.jpg",
      "avatar8.jpg",
      "avatar9.jpg",
      "avatar10.jpg",
      "default.png"
    ];

    for (String fileName in avatarFiles) {
      final assetPath = 'assets/avatars/$fileName';
      final localFile = File('${avatarDir.path}/$fileName');

      if (!await localFile.exists()) {
        final byteData = await rootBundle.load(assetPath);
        final buffer = byteData.buffer.asUint8List();
        await localFile.writeAsBytes(buffer);
        print("✅ $fileName kopyalandı.");
      } else {
        print("✔ $fileName zaten mevcut, atlanıyor.");
      }
    }
  } catch (e) {
    print("⚠ Avatar kopyalama hatası: $e");
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
      home: const SplashScreen(),
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
          Positioned.fill(
            child: Container(color: Colors.blue),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Oturum Yükleniyor...",
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
