import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  FlutterTts flutterTts = FlutterTts();
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
        .collection(widget.category)
        .orderBy("queue")
        .get();

    if (snapshot.docs.isNotEmpty) {
      documents = snapshot.docs;
      correctAnswers = documents.map((doc) => doc["answer"] as int).toList();
      selectedAnswers = List.filled(documents.length, null);

      // Kullanıcının verdiği cevapları getir
      await _fetchUserAnswers(user.uid);

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

  Future<void> _fetchUserAnswers(String userId) async {
    DocumentReference categoryRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("results")
        .doc(widget.category);

    DocumentSnapshot snapshot = await categoryRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      for (int i = 0; i < documents.length; i++) {
        String key = "soru$i";
        if (data.containsKey(key)) {
          bool isCorrect = data[key];

          // Eğer doğruysa `correctAnswers[i]`, yanlışsa farklı bir değer ata
          selectedAnswers[i] = isCorrect ? correctAnswers[i] : (correctAnswers[i] == 1 ? 2 : 1);
        }
      }
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

    for (var i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final rawUrl = doc["url"] ?? "";
      final imageUrl = convertGoogleDriveUrl(rawUrl);
      final fileName = '${widget.category}_$i.jpg'; // Kategoriye göre dosya ismi

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

  void checkAnswer(int answerIndex, int index) async {
    setState(() {
      if (selectedAnswers[index] == null) {
        selectedAnswers[index] = answerIndex;
      }
    });

    // Kullanıcının UID’sini al
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Kullanıcı giriş yapmamışsa işlemi yapma

    String userId = user.uid;
    String categoryName = widget.category; // Kategori adı

    // Doğru olup olmadığını kontrol et
    bool isCorrect = (answerIndex == correctAnswers[index]);

    // Firestore referanslarını ayarla
    DocumentReference userRef =
    FirebaseFirestore.instance.collection("users").doc(userId);

    DocumentReference categoryRef = userRef.collection("results").doc(categoryName);

    // Firestore'a ekleme
    await categoryRef.set({
      "soru$index": isCorrect, // Örn: "soru1": true, "soru2": false
    }, SetOptions(merge: true)); // Merge kullanarak sadece güncellenecek alanları değiştirelim.
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) {
      print("Boş metin seslendirilemez.");
      return;
    }

    print("Seslendiriliyor: $text");

    await flutterTts.setLanguage("en-US"); // Dil ayarla
    await flutterTts.setPitch(1.0); // Ses tonu normal
    await flutterTts.awaitSpeakCompletion(true); // Konuşmanın bitmesini bekle
    await flutterTts.speak(text);
  }


  @override
  void dispose() {
    flutterTts.stop(); // Sayfa kapatılırken sesi durdur
    super.dispose();
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
          final bool isAnswer = doc["isAnswer"] ?? false;

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
                        child: FutureBuilder<File?>(
                          future: _getCachedImage('${widget.category}_$index.jpg'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasData && snapshot.data != null) {
                              return Image.file(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              );
                            } else {
                              return Icon(Icons.broken_image);
                            }
                          },
                        ),
                      ),
                      if (isAnswer) ...[
                        buildAnswerArea(1, context, 0.193, index),
                        buildAnswerArea(2, context, 0.11, index),
                        buildAnswerArea(3, context, 0.275, index),
                      ],
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
    // Firestore'dan dökümanı al ve Map olarak işle
    Map<String, dynamic>? data = documents[index].data() as Map<String, dynamic>?;

    if (data == null) return const SizedBox.shrink();

    String? word;
    if (answerIndex == 1) {
      word = data["word"];
    } else if (answerIndex == 2) {
      word = data["word2"];
    } else if (answerIndex == 3 && data.containsKey("word3")) {
      word = data["word3"];
    }

    // 3. seçenek (word3) yoksa, hizalamayı değiştir
    bool hasThirdOption = data.containsKey("word3") && data["word3"] != null;
    if (!hasThirdOption) {
      if (answerIndex == 1) bottom = 0.203; // 3. şık yoksa, 1. şıkkın hizasını düzelt
    }

    // Eğer "word3" yoksa üçüncü şık gösterilmeyecek
    bool shouldShowOption = answerIndex < 3 || (answerIndex == 3 && word != null);

    return shouldShowOption
        ? Positioned(
      left: MediaQuery.of(context).size.width * 0.156,
      bottom: MediaQuery.of(context).size.height * bottom,
      width: MediaQuery.of(context).size.width * 0.67,
      height: MediaQuery.of(context).size.height * 0.067,
      child: GestureDetector(
        onTap: () {
          checkAnswer(answerIndex, index);
        },
        child: Stack(
          children: [
            // Arka plan
            Container(
              color: Colors.transparent,
            ),
            // Dinleme Butonu (Sesli Telaffuz)
            if (word != null)
              Positioned(
                left: 0,
                top: 2,
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: Colors.blue, size: 28),
                  onPressed: () {
                    if (word != null && word.isNotEmpty) {
                      _speak(word);
                    } else {
                      print("Kelime boş olduğu için seslendirme yapılmadı.");
                    }
                  },
                ),
              ),
            // Doğru/yanlış ikonları
            if (selectedAnswers[index] == answerIndex)
              Positioned(
                right: 7,
                top: 14,
                child: Icon(
                  selectedAnswers[index] == correctAnswers[index]
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: selectedAnswers[index] == correctAnswers[index] ? Colors.green : Colors.red,
                  size: 30,
                ),
              ),
          ],
        ),
      ),
    )
        : const SizedBox.shrink(); // Eğer üçüncü şık yoksa, boş alan göstermesin
  }
}
