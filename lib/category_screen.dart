import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _currentPage = 0;
  List<int?> selectedAnswers = [];
  List<int> correctAnswers = [];
  final PageController _pageController = PageController();
  List<DocumentSnapshot> documents = [];
  bool isLoading = true; // Splash ekranı için değişken

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  /// Firestore'dan verileri çeker ve listeleri doldurur.
  void _fetchQuestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(widget.category)
        .orderBy("queue")
        .get();

    if (snapshot.docs.isNotEmpty) {
      documents = snapshot.docs;
      correctAnswers = documents.map((doc) => doc["answer"] as int).toList();
      selectedAnswers = List.filled(documents.length, null);

      // Tüm görselleri önceden yükle
      await _preloadImages();

      setState(() {
        isLoading = false; // Görseller yüklendiğinde sayfayı aç
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Google Drive dosya linkini görsel olarak yüklenebilir hale getirir.
  String convertGoogleDriveUrl(String url) {
    final regex = RegExp(r"https://drive\.google\.com/file/d/([^/]+)/");
    final match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return "https://drive.google.com/uc?export=view&id=${match.group(1)}";
    }
    return url;
  }

  /// Tüm görselleri önbelleğe yükleme fonksiyonu
  Future<void> _preloadImages() async {
    List<Future<void>> futures = [];

    for (var doc in documents) {
      final rawUrl = doc["url"] ?? "";
      final imageUrl = convertGoogleDriveUrl(rawUrl);

      futures.add(
        precacheImage(NetworkImage(imageUrl), context).catchError((e) {
          print("Görsel yüklenirken hata oluştu: $e");
        }),
      );
    }

    // Bütün işlemleri **aynı anda başlatıp** bekler
    await Future.wait(futures);
  }

  void checkAnswer(int answerIndex, int index) {
    setState(() {
      // Cevap seçildiğinde seçilen cevapları güncelle
      selectedAnswers[index] = answerIndex == correctAnswers[index] ? correctAnswers[index] : answerIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? buildSplashScreen() // Yükleme tamamlanana kadar Splash ekranı
          : PageView.builder(
        controller: _pageController,
        itemCount: documents.length,
        onPageChanged: (int index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final doc = documents[index];
          final rawUrl = doc["url"] ?? "";
          final imageUrl = convertGoogleDriveUrl(rawUrl);

          return Center(
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1 / 2,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, size: 100),
                            );
                          },
                        ),
                      ),
                      buildAnswerArea(1, context, 0.203, index),
                      buildAnswerArea(2, context, 0.11, index),
                      buildAnswerArea(3, context, 0.28, index),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
            style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
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



  Widget buildAnswerArea(int answerIndex, BuildContext context, double bottom, int index) {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.156,
      bottom: MediaQuery.of(context).size.height * bottom,
      width: MediaQuery.of(context).size.width * 0.67,
      height: MediaQuery.of(context).size.height * 0.067,
      child: GestureDetector(
        onTap: () {
          checkAnswer(answerIndex, index); // Seçim yapıldığında cevabı kontrol et
        },
        child: Stack(
          children: [
            // Burada, boş bir alan bırakıyoruz
            Container(
              color: Colors.transparent,
            ),
            // Sadece seçilen cevabın doğru veya yanlış olduğunu göster
            if (selectedAnswers[index] == answerIndex) // Seçilen cevaba bakıyoruz
              Positioned(
                right: 7,
                top: 14,
                child: Icon(
                  selectedAnswers[index] == correctAnswers[index]
                      ? Icons.check_circle_outline // Doğru cevap
                      : Icons.cancel_outlined, // Yanlış cevap
                  color: selectedAnswers[index] == correctAnswers[index]
                      ? Colors.green // Doğru cevap için yeşil
                      : Colors.red, // Yanlış cevap için kırmızı
                  size: 30,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
