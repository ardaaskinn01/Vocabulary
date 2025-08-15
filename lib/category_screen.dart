import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ingilizce/parentalgate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'main_page.dart';
import 'package:audioplayers/audioplayers.dart';

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
  bool isLoading = true;
  bool _isTestCompleted = false;
  double _messageOpacity = 0.0;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool isExist = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _checkLeaderboardExists();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSoundSetting() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        _soundEnabled = userDoc.get("soundEnabled") ?? true;
      }
    }
  }

  Future<void> _playCorrectSound() async {
    await _loadSoundSetting();
    if (_soundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
    }
  }

  Future<void> _playWrongSound() async {
    await _loadSoundSetting();
    if (_soundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    }
  }

  Future<void> _playPageTurnSound() async {
    await _loadSoundSetting();
    if (_soundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/page.mp3'));
    }
  }

  Future<File> _downloadAndSaveImage(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      return file;
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
      await _fetchUserAnswers(user.uid);
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

  Future<void> _checkLeaderboardExists() async {
    final leaderboardRef = FirebaseFirestore.instance
        .collection('leaderboards')
        .doc(widget.category);
    final docSnapshot = await leaderboardRef.get();

    // Liderlik tablosu dökümanı yoksa bir pop-up göster ve anasayfaya dön
    if (docSnapshot.exists) {
      isExist = true;
    }
  }

  Future<void> _fetchUserAnswers(String userId) async {
    DocumentReference categoryRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("results")
        .doc(widget.category);

    DocumentSnapshot snapshot = await categoryRef.get();

    if (!snapshot.exists && mounted) {
      await categoryRef.set({
        "correct_answers": [],
        "wrong_answers": [],
      });
      return;
    }

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
      final fileName = '${widget.category}_$i.jpg';
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
    if (selectedAnswers[index] != null) return;

    setState(() {
      selectedAnswers[index] = answerIndex;
    });

    if (answerIndex == correctAnswers[index]) {
      await _playCorrectSound();
    } else {
      await _playWrongSound();
    }

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
        Map<String, dynamic> data =
            snapshot.exists ? snapshot.data() as Map<String, dynamic> : {};

        Set<int> correctSet = Set<int>.from(data["correct_answers"] ?? []);
        Set<int> wrongSet = Set<int>.from(data["wrong_answers"] ?? []);

        if (isCorrect) {
          correctSet.add(index);
        } else {
          wrongSet.add(index);
        }

        transaction.set(
            categoryRef,
            {
              "correct_answers": correctSet.toList(),
              "wrong_answers": wrongSet.toList(),
            },
            SetOptions(merge: true));
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
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

  void _showCompletionMessage() {
    setState(() {
      _isTestCompleted = true;
      _messageOpacity = 1.0;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _messageOpacity = 0.0;
      });
    });
  }

  void showParentalGate(BuildContext context, String youtubeUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            "Ebeveyn Onayı",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          content: const Text(
            "Bu içeriğe erişmek için 17 yaşından büyük olmanız veya ebeveyn izni almanız gerekmektedir. Devam etmek istiyor musunuz?",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text("Hayır"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openYouTubeVideo(context, youtubeUrl);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text("Evet, Devam Et"),
            ),
          ],
        );
      },
    );
  }

  void openYouTubeVideo(BuildContext context, String youtubeUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Video")),
          body: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onNavigationRequest: (NavigationRequest request) {
                    if (request.url.contains("youtube.com") &&
                        !request.url.contains("embed")) {
                      return NavigationDecision.prevent;
                    }
                    return NavigationDecision.navigate;
                  },
                ),
              )
              ..loadRequest(Uri.parse(
                  "https://www.youtube.com/embed/${YoutubePlayer.convertUrlToId(youtubeUrl)}?autoplay=1&modestbranding=1&rel=0&controls=1&fs=0&disablekb=1&iv_load_policy=3")),
          ),
        ),
      ),
    );
  }

  Future<void> _showFinalResults() async {
    if (!mounted) return;

    // Tüm sorulara cevap verilmiş mi kontrolü
    bool allAnswered = selectedAnswers.every((answer) => answer != null);
    if (!allAnswered) {
      print("Tüm sorulara cevap verilmemiş, popup gösterilmiyor");
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    try {
      // 1. Kullanıcının mevcut skorunu hesapla
      DocumentSnapshot userResultSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .doc(widget.category)
          .get();

      if (!mounted) return;

      int userScore = 0;
      if (userResultSnapshot.exists) {
        Map<String, dynamic> resultData = userResultSnapshot.data() as Map<String, dynamic>;
        List<int> correctAnswers = List<int>.from(resultData['correct_answers'] ?? []);
        List<int> wrongAnswers = List<int>.from(resultData['wrong_answers'] ?? []);
        userScore = (correctAnswers.length * 5) - (wrongAnswers.length * 2);
      }

      // 2. Leaderboard dokümanını al
      DocumentSnapshot leaderboardDoc = await FirebaseFirestore.instance
          .collection('leaderboards')
          .doc(widget.category)
          .get();

      if (!mounted) return;

      if (!leaderboardDoc.exists) {
        print("Leaderboard dokümanı bulunamadı");
        return;
      }

      // 3. Tüm kullanıcı skorlarını ve sıralamayı hesapla
      Map<String, dynamic> leaderboardData = leaderboardDoc.data() as Map<String, dynamic>;

      // Dokümandaki tüm kullanıcıları al ve skorlarına göre sırala
      List<Map<String, dynamic>> userList = [];

      leaderboardData.forEach((userId, userData) {
        if (userData is Map && userData['score'] != null) {
          userList.add({
            'userId': userId,
            'score': userData['score'],
            'username': userData['username'] ?? 'Anonim'
          });
        }
      });

      // Skora göre büyükten küçüğe sırala
      userList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // 4. Kullanıcının sırasını bul
      int userRank = 0;
      for (int i = 0; i < userList.length; i++) {
        if (userList[i]['userId'] == user.uid) {
          userRank = i + 1;
          break;
        }
      }

      // Eğer kullanıcı liderlik tablosunda yoksa, şimdi ekleyelim
      if (userRank == 0) {
        // Kullanıcıyı liderlik tablosuna ekle
        await FirebaseFirestore.instance
            .collection('leaderboards')
            .doc(widget.category)
            .update({
          user.uid: {
            'score': userScore,
            'username': user.displayName ?? 'Anonim'
          }
        });

        // Tekrar sıralama yap
        userList.add({
          'userId': user.uid,
          'score': userScore,
          'username': user.displayName ?? 'Anonim'
        });

        userList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

        // Yeni sırayı bul
        userRank = userList.indexWhere((u) => u['userId'] == user.uid) + 1;
      }

      print("Kullanıcı sırası: $userRank, puan: $userScore");

      // 5. Popup göster
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: Column(
                children: [
                  Icon(
                    userRank == 1 ? Icons.emoji_events : Icons.star,
                    color: userRank == 1 ? Colors.amber : Colors.blueAccent,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    userRank == 1 ? "Tebrikler!" : "Testi Tamamladın!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Bu kategorideki sıralamanız:",
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "${userRank}. sıra",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Puanınız:",
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "$userScore",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Harika!",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Sıralama alınırken hata oluştu: $e");
    }
  }

  void _navigateToHome() async {
    // Tüm sorulara cevap verilmiş mi kontrolü
    bool allAnswered = selectedAnswers.every((answer) => answer != null);

    if (isExist && allAnswered && mounted) {
      await _showFinalResults();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double fixedWidth = 350;
    double fixedHeight = 700;

    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        body: isLoading
            ? buildSplashScreen()
            : Stack(
                children: [
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
                      _playPageTurnSound();
                    },
                    itemBuilder: (context, index) {
                      if (index >= documents.length) {
                        return const SizedBox.shrink();
                      }

                      final doc = documents[index];
                      final data = doc.data() as Map<String, dynamic>?;

                      if (data == null) return const SizedBox.shrink();

                      final bool isAnswer = data["isAnswer"] ?? false;
                      final String? videoUrl =
                          data.containsKey("link") ? data["link"] : null;

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
                              width: fixedWidth,
                              height: fixedHeight,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: FutureBuilder<File?>(
                                      future: _getCachedImage(
                                          '${widget.category}_$index.jpg'),
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
                                            fit: BoxFit.contain,
                                          );
                                        } else {
                                          return const Icon(Icons.broken_image,
                                              size: 100);
                                        }
                                      },
                                    ),
                                  ),
                                  if (!isAnswer &&
                                      videoUrl != null &&
                                      videoUrl.isNotEmpty)
                                    Center(
                                      child: SizedBox(
                                        width: 350,
                                        height: 225,
                                        child: GestureDetector(
                                          onTap: () {
                                            showParentalGate(context, videoUrl);
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                  "assets/images/youtube_placeholder.png",
                                                  fit: BoxFit.fill),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (isAnswer) ...[
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      width: fixedWidth,
                                      height: fixedHeight,
                                      child: SizedBox(
                                        width: fixedWidth,
                                        height: fixedHeight,
                                        child: Stack(
                                          children: [
                                            ...buildAnswerAreas(context, index,
                                                fixedWidth, fixedHeight),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (_isTestCompleted &&
                                      (widget.category != ("grammar") ||
                                          widget.category != "alphabet" ||
                                          !widget.category
                                              .contains("simplepresent")))
                                    Positioned(
                                      bottom: fixedHeight * 0.1,
                                      left: fixedWidth * 0.1,
                                      width: fixedWidth * 0.8,
                                      child: Center(
                                        child: AnimatedOpacity(
                                          opacity: _messageOpacity,
                                          duration: const Duration(seconds: 3),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Testi Tamamladınız!',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_currentPage == documents.length - 1) ...[
                                    Positioned(
                                      bottom: fixedHeight * 0.0375,
                                      left: fixedWidth * 0.43,
                                      child: IconButton(
                                        icon: const Icon(Icons.home,
                                            color: Colors.red, size: 32),
                                        onPressed: _navigateToHome,
                                      ),
                                    ),
                                  ] else ...[
                                    Positioned(
                                      bottom: fixedHeight * 0.0375,
                                      left: fixedWidth * 0.43,
                                      child: IconButton(
                                        icon: const Icon(Icons.home,
                                            color: Colors.red, size: 32),
                                        onPressed: _navigateToHome,
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
                ],
              ),
      ),
    );
  }

  List<Widget> buildAnswerAreas(
      BuildContext context, int index, double fixedWidth, double fixedHeight) {
    if (documents.isEmpty || index >= documents.length) {
      return [];
    }

    Map<String, dynamic>? data =
        documents[index].data() as Map<String, dynamic>?;

    if (data == null) return [];

    bool isQuiz = data.containsKey("quiz") ?? false;
    int quizValue = data["quiz"] ?? 0;
    List<Widget> answerWidgets = [];
    double answerWidth = fixedWidth * 0.2;
    double firstBottom = 0.9;
    double secondBottom = 0.5;

    if (isQuiz) {
      switch (quizValue) {
        case 1:
          answerWidth = fixedWidth * 0.58;
          firstBottom = 0.794;
          secondBottom = 0.744;
          break;
        case 2:
          answerWidth = fixedWidth * 0.58;
          firstBottom = 0.626;
          secondBottom = 0.576;
          break;
        case 3:
          answerWidth = fixedWidth * 0.58;
          firstBottom = 0.455;
          secondBottom = 0.405;
          break;
        case 4:
          answerWidth = fixedWidth * 0.58;
          firstBottom = 0.286;
          secondBottom = 0.236;
          break;
        case 5:
          answerWidth = fixedWidth * 0.58;
          firstBottom = 0.114;
          secondBottom = 0.064;
          break;
        default:
          answerWidth = fixedWidth * 0.58;
          firstBottom = 0.9;
          secondBottom = 0.5;
          break;
      }

      answerWidgets.add(buildAnswerArea(
          1, context, firstBottom, 0.36, index, answerWidth, fixedHeight));

      answerWidgets.add(buildAnswerArea(
          2, context, secondBottom, 0.36, index, answerWidth, fixedHeight));
    } else {
      if (data.containsKey("word3")) {
        answerWidgets.add(buildAnswerArea(
            1, context, 0.299, 0.185, index, fixedWidth * 0.72, fixedHeight));
        answerWidgets.add(buildAnswerArea(
            2, context, 0.208, 0.185, index, fixedWidth * 0.72, fixedHeight));
        answerWidgets.add(buildAnswerArea(
            3, context, 0.39, 0.185, index, fixedWidth * 0.72, fixedHeight));
      } else {
        answerWidgets.add(buildAnswerArea(
            1, context, 0.322, 0.185, index, fixedWidth * 0.72, fixedHeight));
        answerWidgets.add(buildAnswerArea(
            2, context, 0.208, 0.185, index, fixedWidth * 0.72, fixedHeight));
      }
    }

    return answerWidgets;
  }

  Widget buildAnswerArea(int answerIndex, BuildContext context, double bottom,
      double left, int index, double fixedWidth, double fixedHeight) {
    if (documents.isEmpty || index >= documents.length) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic>? data =
        documents[index].data() as Map<String, dynamic>?;

    if (data == null) return const SizedBox.shrink();

    String? word;
    if (answerIndex == 1) {
      word = data["word"];
    } else if (answerIndex == 2) {
      word = data["word2"];
    } else if (answerIndex == 3 && data.containsKey("word3")) {
      word = data["word3"];
    }

    if (word == null) return const SizedBox.shrink();

    return Positioned(
      left: fixedWidth * left,
      bottom: fixedHeight * bottom,
      width: fixedWidth,
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
            if (word != null)
              Positioned(
                left: 0,
                top: 2,
                child: IconButton(
                  icon:
                      const Icon(Icons.volume_up, color: Colors.blue, size: 27),
                  onPressed: () {
                    if (word!.isNotEmpty) {
                      _speak(word);
                    } else {
                      print("Kelime boş olduğu için seslendirme yapılmadı.");
                    }
                  },
                ),
              ),
            if (selectedAnswers[index] != null)
              Positioned(
                right: 7,
                top: 14,
                child: Icon(
                  selectedAnswers[index] == answerIndex
                      ? (selectedAnswers[index] == correctAnswers[index]
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined)
                      : (correctAnswers[index] == answerIndex &&
                              selectedAnswers[index] != correctAnswers[index]
                          ? Icons.check_circle_outline
                          : null),
                  color: selectedAnswers[index] == answerIndex
                      ? (selectedAnswers[index] == correctAnswers[index]
                          ? Colors.green
                          : Colors.red)
                      : Colors.green,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildSplashScreen() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          "assets/images/bg.jpg",
          fit: BoxFit.scaleDown,
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Text(
            "Görseller yükleniyor, lütfen bekleyin...",
            style: const TextStyle(
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
