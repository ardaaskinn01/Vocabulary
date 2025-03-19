import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ingilizce/premium.dart';
import 'package:ingilizce/profile.dart';
import 'package:ingilizce/provider.dart';
import 'package:ingilizce/settings.dart';
import 'package:ingilizce/tutorial.dart';
import 'package:provider/provider.dart';
import 'alphabet.dart';
import 'category_screen.dart';
import 'friends.dart';
import 'leaderboard.dart';
import 'login_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
    if (category != ("grammar") || category != "alphabet" || !category.contains("simplepresent") ) {
      await _firestore.collection("users").doc(userId).collection("unlockedCategories").doc(category).set({
        "unlocked": true,
      });
    }
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
    "family tree": 10, "colors": 11, "numbers": 20, "fruits": 20, "animals": 30, "vegetables": 20, "adjectives": 19, "bodyparts": 22, "clothes": 23, "countries": 13, "verbs": 22, "verbs2": 21, "shapes": 10, "emotions": 9, "jobs": 11, "workplaces": 22, "vehicles": 16, "households": 26, "space": 15, "grammar": 0, "alphabet": 0, "simplepresent": 0, "simplepresent2": 0, "simplepresent3": 0, "simplepresent4": 0
  };

  // Kategorilerin kilidinin bir kez açılıp açılmadığını takip eden harita
  final Map<String, bool> categoryUnlockedStatus = {
    "family tree": false, "colors": false, "numbers": false, "fruits": false, "animals": false, "vegetables": false, "adjectives": false, "bodyparts": false, "clothes": false, "countries": false, "verbs": false, "verbs2": false, "shapes": false, "emotions": false, "jobs": false, "workplaces": false, "vehicles": false, "households": false, "space": false, "alphabet": false, "grammar": false, "simplepresent": false, "simplepresent2": false, "simplepresent3": false, "simplepresent4": false
  };

  @override
  void initState() {
    super.initState();
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    premiumProvider.fetchPremiumStatus();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() async {
      await _getUserId();  // Önce userId atanmalı
      if (userId != null) {
        print(userId);
        await fetchUnlockedCategories();
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
        .collection("users").doc(userId).collection("results").snapshots().map((snapshot) {
      Map<String, Map<String, dynamic>> tempResults = {};

      for (var doc in snapshot.docs) {
        String category = doc.id;

        if (category == "alphabet" || category == "grammar" || category.contains("simplepresent")) {
          continue;
        }

        Map<String, dynamic> data = doc.data();

        // 🔥 **Yeni Liste Formatına Göre Doğru ve Yanlış Sayıları**
        List<int> correctList = List<int>.from(data["correct_answers"] ?? []);
        List<int> wrongList = List<int>.from(data["wrong_answers"] ?? []);

        tempResults[category] = {
          "correct": correctList.length,  // Doğru cevap sayısı
          "total": correctList.length + wrongList.length,  // Toplam çözülmüş soru sayısı
        };
      }

      return tempResults;
    });
  }

  // Kategori sonuçlarını sıfırlamak için Firestore'dan ilgili dokümanı silme işlemi
  Future<void> resetCategoryResults(String category) async {
    try {
      await _firestore
          .collection("users").doc(userId).collection("results").doc(category).delete(); // İlgili kategori dokümanını sil
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
    final premiumProvider = Provider.of<PremiumProvider>(context);
    bool isPremium = premiumProvider.isPremium;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        elevation: 4,
        automaticallyImplyLeading: false,
        actions: [
          // Profil Butonu (En Solda)
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 27),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),

          // Arkadaşlar butonu (Ortada)
          Expanded(
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.group, color: Colors.white, size: 27),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const FriendsScreen(),
                  );
                },
              ),
            ),
          ),

          // Ayarlar butonu (En Sağda)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 27),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
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

          Expanded(
            child: StreamBuilder<Map<String, Map<String, dynamic>>>(
              stream: _fetchUserResultsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Hata oluştu: ${snapshot.error}"));
                }

                // Kullanıcının sonuçlarını al
                categoryResults = snapshot.data ?? {};

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Başlangıç seviyesi (her zaman açık)
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
                        buildCategoryCard(context, "Countries", "countries", isLocked: true),
                        buildCategoryCard(context, "Verbs", "verbs", isLocked: true),
                        buildCategoryCard(context, "Verbs 2", "verbs2", isLocked: true),
                        buildCategoryCard(context, "Shapes", "shapes", isLocked: true),
                        buildCategoryCard(context, "Emotions", "emotions", isLocked: true),
                        buildCategoryCard(context, "Jobs", "jobs", isLocked: true),
                        buildCategoryCard(context, "Workplaces", "workplaces", isLocked: true),
                        buildCategoryCard(context, "Vehicles", "vehicles", isLocked: true),
                        buildCategoryCard(context, "Households", "households", isLocked: true),
                        buildCategoryCard(context, "Space", "space", isLocked: true),
                      ],
                      [
                        buildCategoryCard(context, "Alphabet", "alphabet"),
                        buildCategoryCard(context, "Grammar I", "grammar"),
                        buildCategoryCard(context, "Simple Present Tense I", "simplepresent"),
                        buildCategoryCard(context, "Simple Present Tense II", "simplepresent2"),
                        buildCategoryCard(context, "Simple Present Tense III", "simplepresent3"),
                        buildCategoryCard(context, "Simple Present Tense IIII", "simplepresent4"),
                      ],
                    ),

                    // Orta seviye (premium kontrolü)
                    isPremium
                        ? buildCategorySection(
                      [
                        buildCategoryCard(context, "Intermediate 1", "intermediate1"),
                        buildCategoryCard(context, "Intermediate 2", "intermediate2"),
                        // Diğer orta seviye kategoriler
                      ],
                      [],
                    )
                        : _buildLockedTab(),

                    // İleri seviye (premium kontrolü)
                    isPremium
                        ? buildCategorySection(
                      [
                        buildCategoryCard(context, "Advanced 1", "advanced1"),
                        buildCategoryCard(context, "Advanced 2", "advanced2"),
                        // Diğer ileri seviye kategoriler
                      ],
                      [],
                    )
                        : _buildLockedTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            "Bu içeriğe erişmek için premium hesap gereklidir.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isDismissible: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => PremiumPurchaseScreen(),
              );
            },
            child: const Text(
              "Premium Satın Al",
              style: TextStyle(fontSize: 18, color: Colors.white),
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

  void updateScore(String category, int score) async {
    if (!mounted) return; // Sayfa kapandıysa işlemi iptal et

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("results")
          .doc(category)
          .get();

      // Eğer belge hiç yoksa veya score alanı tanımlı değilse, varsayılan değeri 0 olarak ayarla
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      int existingScore = data != null && data.containsKey("score") ? data["score"] : 0;

      print("📌 Mevcut skor: $existingScore, Yeni skor: $score"); // Debugging için

      if (existingScore != score) {  // 🔥 Sadece farklıysa yaz
        if (!mounted) return; // Tekrar sayfa durumunu kontrol et
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("results")
            .doc(category)
            .set({"score": score}, SetOptions(merge: true));

        print("✅ Firestore güncellendi!"); // Firestore yazma işlemi başarılı mı?
      } else {
        print("ℹ️ Skor zaten güncel, değişiklik yapılmadı.");
      }
    } catch (e) {
      print("❌ Score güncellenirken hata oluştu: $e");
    }
  }




  Widget buildCategoryCard(BuildContext context, String title, String category, {bool isLocked = false}) {
    int correct = categoryResults[category]?["correct"] ?? 0;
    int solved = (categoryResults[category]?["total"]) ?? 0;
    int total = categoryTotalQuestions[category] ?? 0;
    int score = 0;
    if (solved > 0) {
      score = (correct * 5) - ((solved - correct) * 2);
      updateScore(category, score);
    }

    bool categoryLocked = isLocked;

    // Kategoriler dizisi
    List<String> categoryOrder = [
      "family tree", "colors", "numbers", "fruits", "animals", "vegetables", "adjectives", "bodyparts", "clothes", "countries", "verbs", "verbs2", "shapes", "emotions", "jobs", "workplaces", "vehicles", "households", "space",
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
    String scoreText = "Puan: ${score ?? 0}";

    if (category == "grammar" || category == "alphabet" || category.contains("simplepresent")) {
      statusText = "";
      scoreText = "";
    }
    else if (!categoryLocked) {
      if (solved > 0 && solved < total) {
        statusText = "$correct/$solved Doğru (Devam Ediyor)";
        statusColor = Colors.amber;
      } else if (solved == total) {
        statusText = "$correct/$solved Doğru (Tamamlandı)";
        statusColor = Colors.green;
      }
    }

    // Başlığın karakter uzunluğunu kontrol et
    int maxTitleLength = 15; // Başlığın maksimum karakter uzunluğu
    bool isTitleLong = title.length > maxTitleLength;

    return GestureDetector(
      onTap: () {
        if (!categoryLocked) {
          Widget nextScreen = category == "alphabet"
              ? AlphabetScreen() // Eğer kategori "alphabet" ise AlphabetScreen'e git
              : CategoryScreen(category: category); // Diğer kategoriler için CategoryScreen'e git

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
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
              title: AutoSizeText(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade600,
                  letterSpacing: 0.8,
                ),
                maxLines: isTitleLong ? 3 : 1,  // Uzun başlıklar için 2 satır, kısa başlıklar için 1 satır
                overflow: TextOverflow.visible,  // Taşan metinler için alt satıra geç
                minFontSize: 16,  // Fontun küçülebileceği minimum boyut
                stepGranularity: 1,  // Font boyutunun küçülme adımı
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 16, color: statusColor),
                  ),
                  if (!categoryLocked)
                    Text(
                      scoreText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                ],
              ),
              trailing: GestureDetector(
                onTap: () {
                  if ((!(category == ("grammar") || category == "alphabet" || category.contains("simplepresent"))) && !categoryLocked ) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LeaderboardScreen(category: category)),
                    );
                  }
                },
                child: Icon(
                  categoryLocked
                      ? Icons.lock // Kilitli kategorilerde kilit ikonu göster
                      : (category.contains("grammar") || category == "alphabet" || category.contains("simplepresent"))
                      ? Icons.arrow_forward_ios // Grammar ve Alphabet için ok ikonu
                      : Icons.leaderboard, // Diğer kategoriler için leaderboard ikonu
                  color: categoryLocked ? Colors.red : Colors.black,
                  size: 24,
                ),
              ),
            ),
            if (!categoryLocked && category != "alphabet")
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
