import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ingilizce/tutorial.dart';
import 'category_screen.dart';
import 'login_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;
  Map<String, Map<String, dynamic>> categoryResults = {};
  late TabController _tabController;

  Future<void> saveUnlockedCategory(String category) async {
    await _firestore.collection("users").doc(userId).collection("unlockedCategories").doc(category).set({
      "unlocked": true,
    });
  }

  Future<void> fetchUnlockedCategories() async {
    final snapshot = await _firestore.collection("users").doc(userId).collection("unlockedCategories").get();
    for (var doc in snapshot.docs) {
      categoryUnlockedStatus[doc.id] = doc["unlocked"] ?? false;
    }
    setState(() {});
  }

  // Her kategoriye özel toplam soru sayısı
  final Map<String, int> categoryTotalQuestions = {
    "family tree": 10,
    "colors": 11,
    "numbers": 20,
    "fruits": 20,
    "animals": 30,
    "vegetables": 20,
    "adjectives": 19,
    "bodyparts": 22,
    "clothes": 24
  };

  // Kategorilerin kilidinin bir kez açılıp açılmadığını takip eden harita
  final Map<String, bool> categoryUnlockedStatus = {
    "family tree": false,
    "colors": false,
    "numbers": false,
    "fruits": false,
    "animals": false,
    "vegetables": false,
    "adjectives": false,
    "bodyparts": false,
    "clothes": false
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() async {
      await _getUserId();  // Önce userId atanmalı
      if (userId != null) {
        print(userId);
        await fetchUnlockedCategories();
        _fetchUserResultsStream();
      }
    });
  }

  _getUserId() {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  /// Kullanıcının UID'sini al ve Firestore'dan sonuçları getir.
  Stream<Map<String, Map<String, dynamic>>> _fetchUserResultsStream() {
    return _firestore
        .collection("users")
        .doc(userId)
        .collection("results")
        .snapshots()
        .map((snapshot) {
      Map<String, Map<String, dynamic>> tempResults = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        int correctAnswers = data.values.where((value) => value == true).length;
        int totalQuestions = data.length;

        tempResults[doc.id] = {
          "correct": correctAnswers,
          "total": totalQuestions,
        };
      }
      setState(() {
        categoryResults = tempResults;
      });
      return tempResults;
    });
  }

  // Kategori sonuçlarını sıfırlamak için Firestore'dan ilgili dokümanı silme işlemi
  Future<void> resetCategoryResults(String category) async {
    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("results")
          .doc(category)
          .delete(); // İlgili kategori dokümanını sil
    } catch (e) {
      print("Sıfırlama hatası: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut(); // Firebase Auth ile oturumu kapat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()), // Giriş ekranına yönlendir
      );
    } catch (e) {
      print("Çıkış yapma hatası: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
        elevation: 4,
        actions: [
          // Çıkış yapma butonu
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Başlangıç"),
            Tab(text: "Orta"),
            Tab(text: "İleri"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tutorial Butonu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TutorialScreen()),
                );
              },
              child: const Text(
                "Tutorial",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          // StreamBuilder ve Sekmeler
          Expanded(
            child: StreamBuilder<Map<String, Map<String, dynamic>>>( // StreamBuilder'ı burada açıyoruz
              stream: _fetchUserResultsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Hata oluştu: ${snapshot.error}"));
                }

                // Veriyi alıp işleme kısmı
                categoryResults = snapshot.data ?? {};

                return TabBarView(
                  controller: _tabController,
                  children: [
                    buildCategorySection(
                      [
                        buildCategoryCard(context, "Family Tree", "family tree"),
                        buildCategoryCard(context, "Colors", "colors", isLocked: true),
                        buildCategoryCard(context, "Numbers", "numbers", isLocked: true),
                        buildCategoryCard(context, "Fruits", "fruits", isLocked: true),
                        buildCategoryCard(context, "Animals", "animals", isLocked: true),
                        buildCategoryCard(context, "Vegetables", "vegetables", isLocked: true),
                        buildCategoryCard(context, "Adjectives", "adjectives", isLocked: true),
                        buildCategoryCard(context, "Body Parts", "bodyparts", isLocked: true),
                        buildCategoryCard(context, "Clothes", "clothes", isLocked: true),
                      ],
                      [
                      ],
                    ),
                    buildCategorySection([], []),
                    buildCategorySection([], []),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategorySection(
      List<Widget> vocabularyCards, List<Widget> grammarCards) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        "Vocabulary",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Column(children: vocabularyCards),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        "Grammar",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Column(children: grammarCards),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCategoryCard(BuildContext context, String title, String category, {bool isLocked = false}) {
    int correct = categoryResults[category]?["correct"] ?? 0;
    int solved = categoryResults[category]?["total"] ?? 0;
    int total = categoryTotalQuestions[category] ?? 0;

    bool categoryLocked = isLocked;

    // Kategoriler dizisi
    List<String> categoryOrder = [
      "family tree", "colors", "numbers", "fruits", "animals", "vegetables", "adjectives", "bodyparts", "clothes"
    ];

    // Kilit açma işlemini tek bir fonksiyonla yönetmek
    void unlockCategory(String currentCategory, String previousCategory) {
      if (category == currentCategory && (categoryResults[previousCategory]?["total"] ?? 0) == categoryTotalQuestions[previousCategory]) {
        if (!categoryUnlockedStatus[currentCategory]!) {
          categoryUnlockedStatus[currentCategory] = true;
          saveUnlockedCategory(currentCategory);
        }
      }
    }

    // Kategoriler için kilit açma fonksiyonunu sırayla çalıştırmak
    for (int i = 1; i < categoryOrder.length; i++) {
      unlockCategory(categoryOrder[i], categoryOrder[i - 1]);
    }

    // Mevcut kategori kilidini kontrol et
    if (categoryUnlockedStatus[category] == true) {
      categoryLocked = false;
    }

    String statusText = categoryLocked ? "Henüz kilidi açılmadı" : "Henüz test çözülmedi";
    Color statusColor = Colors.grey;

    if (!categoryLocked) {
      if (solved > 0 && solved < total) {
        statusText = "$correct/$solved Doğru (Devam Ediyor)";
        statusColor = Colors.amber;
      } else if (solved == total) {
        statusText = "$correct/$solved Doğru (Tamamlandı)";
        statusColor = Colors.green;
      }
    }

    return GestureDetector(
      onTap: () {
        if (!categoryLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryScreen(category: category),
            ),
          );
        }
      },
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade600,
                  letterSpacing: 0.8,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 16, color: statusColor),
                  ),
                ],
              ),
              trailing: Icon(
                categoryLocked ? Icons.lock : Icons.arrow_forward_ios,
                color: categoryLocked ? Colors.red : Colors.black,
                size: 24,
              ),
            ),
            if (!categoryLocked)
              TextButton(
                onPressed: () {
                  resetCategoryResults(category);
                },
                child: const Text(
                  "Sıfırla",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
