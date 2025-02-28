import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

    // Sabit boyutlar
    double fixedWidth = 350; // Sabit genişlik
    double fixedHeight = 700; // Sabit yükseklik

    List<List<String>> pages = [
      ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      ['h', 'i', 'j', 'k', 'l', 'm', 'n'],
      ['o', 'p', 'q', 'r', 's', 't', 'u'],
      ['v', 'w', 'x', 'y', 'z'],
      []
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

                    final doc = documents[index];
                    final data = doc.data() as Map<String,
                        dynamic>?; // 🔹 Firestore verisini Map olarak al

                    if (data == null)
                      return const SizedBox
                          .shrink(); // 🔹 Veri null ise boş widget dön

                    final bool isAnswer = data["isAnswer"] ?? false;
                    final String? videoUrl = data.containsKey("link")
                        ? data["link"]
                        : null; // Firestore'dan gelen YouTube linki

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
                            child: SizedBox(
                              width: fixedWidth, // Sabit genişlik
                              height: fixedHeight, // Sabit yükseklik
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // **Arka planda resim göster**
                                  Positioned.fill(
                                    child: FutureBuilder<File?>(
                                      future: _getCachedImage(
                                          'alphabet_$index.jpg'),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          return Image.file(
                                            snapshot.data!,
                                            fit: BoxFit
                                                .cover, // Resmi arka plan olarak göster
                                          );
                                        } else {
                                          return const Icon(Icons.broken_image,
                                              size: 100);
                                        }
                                      },
                                    ),
                                  ),

                                  // **Eğer `isAnswer == false` ve `link` varsa merkezde YouTube WebView göster**
                                  if (!isAnswer &&
                                      videoUrl != null &&
                                      videoUrl.isNotEmpty)
                                    Center(
                                      child: Container(
                                        width: 350, // Video boyutu
                                        height: 225,
                                        child: WebViewWidget(
                                          controller: WebViewController()
                                            ..setJavaScriptMode(
                                                JavaScriptMode.unrestricted)
                                            ..loadRequest(Uri.parse(
                                                "https://www.youtube.com/embed/${YoutubePlayer.convertUrlToId(videoUrl)}?autoplay=1&modestbranding=1&rel=0")),
                                        ),
                                      ),
                                    ),
                                  if (videoUrl == null || videoUrl.isEmpty)
                                    Positioned(
                                      right: fixedWidth * 0.05, // Sabit genişliğin %5'i kadar sağdan boşluk
                                      bottom: _currentPage == pages.length - 2
                                          ? fixedHeight * 0.25 // Son sayfada yükseklik %27
                                          : fixedHeight * 0.1075, // Diğer sayfalarda yükseklik %9
                                      child: Container(
                                        width: fixedWidth * 0.2, // Sabit genişliğin %20'si
                                        height: _currentPage == pages.length - 2
                                            ? fixedHeight * 0.63 // Son sayfada yükseklik %46
                                            : fixedHeight * 0.78, // Diğer sayfalarda yükseklik %64
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: words.map((word) {
                                            return ElevatedButton(
                                              onPressed: () => _speak(word),
                                              style: ElevatedButton.styleFrom(
                                                shape: CircleBorder(),
                                                padding: EdgeInsets.all(fixedWidth * 0.03), // Buton boyutu sabit genişliğe göre
                                                backgroundColor: Colors.orange,
                                              ),
                                              child: Icon(
                                                Icons.volume_up,
                                                color: Colors.white,
                                                size: fixedWidth * 0.05, // Icon boyutu sabit genişliğe göre
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Ana Menü Butonu
                Positioned(
                  bottom: _currentPage == pages.length - 1
                      ? fixedHeight * 0.15
                      : fixedHeight * 1.08,
                  left: _currentPage == pages.length - 1
                      ? fixedWidth * 0.52
                      : fixedWidth * 0.96,
                  child: IconButton(
                    icon: Icon(Icons.home, color: Colors.red, size: 34),
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
