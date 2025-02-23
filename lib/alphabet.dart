import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import 'main_page.dart';

class AlphabetScreen extends StatefulWidget {
  @override
  _AlphabetScreenState createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  FlutterTts flutterTts = FlutterTts();
  int _currentPage = 0;
  List<int?> selectedAnswers = [];
  List<int> correctAnswers = [];
  final PageController _pageController = PageController();
  List<DocumentSnapshot> documents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<File> _downloadAndSaveImage(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      return file; // Dosya zaten varsa direkt dön
    }

    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<File?> _getCachedImage(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Firestore'dan verileri çeker ve listeleri doldurur.
  void _fetchQuestions() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("alphabet")
        .orderBy("queue")
        .get();

    if (snapshot.docs.isNotEmpty) {
      documents = snapshot.docs;
      correctAnswers = documents.map((doc) => doc["answer"] as int).toList();
      selectedAnswers = List.filled(documents.length, null);

      // Tüm görselleri önceden yükle
      await _preloadImages();

      setState(() {
        isLoading = false; // Yükleme tamamlandı
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) {
      print("Boş metin seslendirilemez.");
      return;
    }
    print("Seslendiriliyor: $text");
    await flutterTts.setSharedInstance(true);
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    await flutterTts.setLanguage("en-US"); // Dil ayarla
    await flutterTts.setPitch(1.0); // Ses tonu normal
    await flutterTts.awaitSpeakCompletion(true); // Konuşmanın bitmesini bekle
    await flutterTts.speak(text);
  }

  String convertGoogleDriveUrl(String url) {
    final regex = RegExp(r"https://drive\.google\.com/file/d/([^/]+)/");
    final match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return url;
  }

  Future<void> _preloadImages() async {
    List<Future<void>> futures = [];

    for (var i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final rawUrl = doc["url"] ?? "";
      final imageUrl = convertGoogleDriveUrl(rawUrl);
      final fileName = 'alphabet_$i.jpg'; // Kategoriye göre dosya ismi

      futures.add(
        _downloadAndSaveImage(imageUrl, fileName).then((file) {
          print("Görsel kaydedildi: ${file.path}");
        }).catchError((e) {
          print("Görsel kaydedilirken hata oluştu: $e");
        }),
      );
    }

    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double imageWidth = screenWidth * 0.9; // Görsel genişliği ekranın %60'ı
    double imageHeight = screenHeight * 0.9; // Görsel yüksekliği ekranın %50'si

    List<List<String>> pages = [
      ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      ['h', 'i', 'j', 'k', 'l', 'm', 'n'],
      ['o', 'p', 'q', 'r', 's', 't', 'u'],
      ['v', 'w', 'x', 'y', 'z']
    ];

    return Scaffold(
      body: isLoading
          ? buildSplashScreen()
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              List<String> words = pages[index];

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.all(16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: imageWidth,
                              height: imageHeight,
                              child: FutureBuilder<File?>(
                                future: _getCachedImage('alphabet_$index.jpg'),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasData && snapshot.data != null) {
                                    return Image.file(
                                      snapshot.data!,
                                      width: imageWidth,
                                      height: imageHeight,
                                      fit: BoxFit.contain,
                                    );
                                  } else {
                                    return Center(child: Icon(Icons.broken_image, size: 50));
                                  }
                                },
                              ),
                            ),
                          ),

                          // Ses Butonları
                          Positioned(
                            right: screenWidth * 0.1, // Sağdan yüzde 5 boşluk bırak
                            bottom: _currentPage == pages.length - 1
                                ? screenHeight * 0.27 // Son sayfada yükseklik yüzde 40
                                : screenHeight * 0.09, // Ekran yüksekliğinin yüzde 30'una yerleştir
                            child: Container(
                              width: screenWidth * 0.1, // Konteyner genişliği ekran genişliğinin yüzde 20'si
                              height: _currentPage == pages.length - 1
                                  ? screenHeight * 0.46 // Son sayfada yükseklik yüzde 40
                                  : screenHeight * 0.64, // Konteyner yüksekliği ekran yüksekliğinin yüzde 40'ı
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Widget'ları eşit aralıklarla yerleştir
                                children: words.map((word) {
                                  return ElevatedButton(
                                    onPressed: () => _speak(word),
                                    style: ElevatedButton.styleFrom(
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(screenWidth * 0.03), // Buton boyutunu ekran genişliğine göre ayarla
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: Icon(
                                      Icons.volume_up,
                                      color: Colors.white,
                                      size: screenWidth * 0.04, // Icon boyutunu ekran genişliğine göre ayarla
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Ana Menü Butonu
          Positioned(
            bottom: _currentPage == pages.length - 1 ? screenHeight * 0.12 : screenHeight * 0.82,
            left: _currentPage == pages.length - 1 ? screenWidth * 0.43 : screenWidth * 0.85,
            child: IconButton(
              icon: Icon(Icons.home, color: Colors.red, size: 35),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  /// Splash ekranını oluşturan fonksiyon
  Widget buildSplashScreen() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          "assets/images/bg.jpg", // Splash görselin buraya eklenmeli
          fit: BoxFit.scaleDown, // Ekranı tamamen kaplasın
        ),
        Positioned(
          bottom: 50, // Yazının ekranın altında olmasını sağlar
          left: 0,
          right: 0,
          child: Text(
            "Görseller yükleniyor, lütfen bekleyin...",
            style: TextStyle(
                color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }
}
