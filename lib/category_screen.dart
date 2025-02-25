import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import 'main_page.dart';

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
  bool _isTestCompleted = false;
  double _messageOpacity = 0.0;

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
        .collection(widget.category).orderBy("queue").get();

    if (snapshot.docs.isNotEmpty) {
      documents = snapshot.docs;
      correctAnswers = documents.map((doc) => doc["answer"] as int).toList();
      selectedAnswers = List.filled(documents.length, null);
      await _fetchUserAnswers(user!.uid);
      // Listeleri başla
      await _preloadImages();
      setState(() {
        isLoading = false;
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

    // Eğer döküman yoksa, yeni bir döküman oluştur
    if (!snapshot.exists) {
      await categoryRef.set({
        "correct_answers": [],
        "wrong_answers": [],
      });
      return;
    }

    // Döküman varsa, verileri al
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<int> correctList = List<int>.from(data["correct_answers"] ?? []);
    List<int> wrongList = List<int>.from(data["wrong_answers"] ?? []);

    for (int i = 0; i < documents.length; i++) {
      if (correctList.contains(i)) {
        selectedAnswers[i] = correctAnswers[i];
      } else if (wrongList.contains(i)) {
        selectedAnswers[i] = (correctAnswers[i] == 1 ? 2 : 1);
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
      final fileName =
          '${widget.category}_$i.jpg'; // Kategoriye göre dosya ismi

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
    if (selectedAnswers[index] != null) return; // Zaten seçildiyse işlem yapma

    setState(() {
      selectedAnswers[index] = answerIndex;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    String categoryName = widget.category;
    bool isCorrect = (answerIndex == correctAnswers[index]);

    DocumentReference categoryRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("results")
        .doc(categoryName);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(categoryRef);
        Map<String, dynamic> data = snapshot.exists ? snapshot.data() as Map<String, dynamic> : {};

        // **🔹 Listeyi set olarak kullanarak aynı index'in tekrar eklenmesini önlüyoruz**
        Set<int> correctSet = Set<int>.from(data["correct_answers"] ?? []);
        Set<int> wrongSet = Set<int>.from(data["wrong_answers"] ?? []);

        if (isCorrect) {
          correctSet.add(index);
        } else {
          wrongSet.add(index);
        }

        // **Firestore'a liste olarak güncelle**
        transaction.set(categoryRef, {
          "correct_answers": correctSet.toList(),
          "wrong_answers": wrongSet.toList(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print("🔥 Firestore işlemi sırasında hata: $e");
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
        IosTextToSpeechAudioCategoryOptions.allowBluetooth, IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP, IosTextToSpeechAudioCategoryOptions.mixWithOthers, IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    await flutterTts.setLanguage("en-US"); // Dil ayarla
    await flutterTts.setPitch(1.0); // Ses tonu normal
    await flutterTts.awaitSpeakCompletion(true); // Konuşmanın bitmesini bekle
    await flutterTts.speak(text);
  }

  void _showCompletionMessage() {
    setState(() {
      _isTestCompleted = true;
      _messageOpacity = 1.0;
    });

    // 3 saniye sonra mesajı kaybolacak şekilde ayarlıyoruz
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _messageOpacity = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Sabit boyutlar
    double fixedWidth = 350; // Sabit genişlik
    double fixedHeight = 700; // Sabit yükseklik

    return Scaffold(
      body: isLoading
          ? buildSplashScreen() // Yükleme tamamlanana kadar Splash ekranı
          : Stack(
        children: [
          // Sayfa içerikleri
          PageView.builder(
            controller: _pageController,
            itemCount: documents.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
              if (_currentPage == documents.length - 1) {
                _showCompletionMessage();
              }
            },
            itemBuilder: (context, index) {
              if (index >= documents.length) {
                return const SizedBox.shrink(); // Geçersiz indeks durumunda boş widget döndür
              }

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
                    child: SizedBox(
                      width: fixedWidth, // Sabit genişlik
                      height: fixedHeight, // Sabit yükseklik
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
                            // AnswerArea'ları sabit bir Container içine al
                            Positioned(
                              left: 0,
                              top: 0,
                              width: fixedWidth,
                              height: fixedHeight,
                              child: Container(
                                width: fixedWidth,
                                height: fixedHeight,
                                child: Stack(
                                  children: [
                                    buildAnswerArea(1, context, 0.309, index, fixedWidth, fixedHeight),
                                    buildAnswerArea(2, context, 0.2185, index, fixedWidth, fixedHeight),
                                    buildAnswerArea(3, context, 0.3995, index, fixedWidth, fixedHeight),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Ana menü butonu ekleme
          if (_currentPage == documents.length - 1) ...[
            Positioned(
              bottom: screenHeight * 0.1, // Ekranın altından %14 mesafe
              left: screenWidth * 0.43, // Ortada hizalama
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.home, color: Colors.red, size: 34),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            Positioned(
              bottom: screenHeight * 0.8, // Ekranın altından %14 mesafe
              left: screenWidth * 0.82, // Ortada hizalama
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

          // "Testi Tamamladınız!" mesajı
          if (_isTestCompleted && (!widget.category.contains("grammar")))
            Positioned(
              bottom: screenHeight * 0.85, // Ekranın altından %5 mesafe
              left: screenWidth * 0.275,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _messageOpacity,
                  duration: Duration(seconds: 3),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.green,
                    child: Text(
                      'Testi Tamamladınız!',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildAnswerArea(
      int answerIndex, BuildContext context, double bottom, int index, double fixedWidth, double fixedHeight) {
    if (documents.isEmpty || index >= documents.length) {
      return const SizedBox.shrink(); // Boş veya geçersiz indeks durumunda boş widget döndür
    }

    Map<String, dynamic>? data = documents[index].data() as Map<String, dynamic>?;
    String? word;
    if (answerIndex == 1) {
      word = data!["word"];
    } else if (answerIndex == 2) {
      word = data!["word2"];
    } else if (answerIndex == 3 && data!.containsKey("word3")) {
      word = data["word3"];
    }

    bool hasThirdOption = data!.containsKey("word3") && data["word3"] != null;
    if (!hasThirdOption) {
      if (answerIndex == 1) bottom = 0.3185; // 3. şık yoksa, 1. şıkkın hizasını düzelt
    }

    bool shouldShowOption = answerIndex < 3 || (answerIndex == 3 && word != null);

    return shouldShowOption
        ? Positioned(
      left: fixedWidth * 0.18,
      bottom: fixedHeight * bottom,
      width: fixedWidth * 0.67,
      height: fixedHeight * 0.067,
      child: GestureDetector(
        onTap: selectedAnswers[index] == null
            ? () {
          checkAnswer(answerIndex, index);
        }
            : null,
        child: Stack(
          children: [
            Container(color: Colors.transparent),

            // Dinleme Butonu (Sesli Telaffuz)
            if (word != null)
              Positioned(
                left: 0,
                top: 2,
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: Colors.blue, size: 27),
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
            if (selectedAnswers[index] != null)
              Positioned(
                right: 7,
                top: 14,
                child: Icon(
                  selectedAnswers[index] == answerIndex
                      ? (selectedAnswers[index] == correctAnswers[index]
                      ? Icons.check_circle_outline // ✅ Doğru ise tik işareti
                      : Icons.cancel_outlined) // ❌ Yanlış ise çarpı işareti
                      : (correctAnswers[index] == answerIndex &&
                      selectedAnswers[index] != correctAnswers[index]
                      ? Icons.check_circle_outline // ✅ Yanlış seçildiğinde doğru şıkta tik çıksın
                      : null),
                  color: selectedAnswers[index] == answerIndex
                      ? (selectedAnswers[index] == correctAnswers[index]
                      ? Colors.green
                      : Colors.red)
                      : Colors.green, // Yanlış cevapta doğru olanı yeşil göster
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    )
        : const SizedBox.shrink();
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
