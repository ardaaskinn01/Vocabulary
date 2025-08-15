import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts paketi
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
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:math';

// Özel renk paleti
const Color primaryBlue = Color(0xFF5C6BC0);
const Color secondaryOrange = Color(0xFFFF8A65);
const Color accentGreen = Color(0xFF66BB6A);
const Color softWhite = Color(0xFFF5F5F5);
const Color lightBlue = Color(0xFFE3F2FD);
const Color darkGray = Color(0xFF424242);
const Color pastelBlue = Color(0xFFB3E5FC);
const Color pastelLightBlue = Color(0xFFE1F5FE);

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;
  Map<String, Map<String, dynamic>> categoryResults = {};
  late TabController _tabController;
  final TextEditingController _mathController = TextEditingController();
  int _num1 = 0;
  int _num2 = 0;

  Future<void> saveUnlockedCategory(String category) async {
    if (category != ("grammar") || category != "alphabet" || !category.contains("simplepresent") ) {
      await _firestore.collection("users").doc(userId).collection("unlockedCategories").doc(category).set({
        "unlocked": true,
      });
    }
  }

  final Map<String, IconData> categoryIcons = {
    "family tree": Icons.family_restroom,
    "colors": Icons.color_lens,
    "numbers": Icons.onetwothree,
    "fruits": Icons.apple,
    "animals": Icons.pets,
    "vegetables": Icons.local_dining,
    "adjectives": Icons.description,
    "bodyparts": Icons.accessibility,
    "clothes": Icons.checkroom,
    "countries": Icons.flag,
    "verbs": Icons.bolt,
    "verbs2": Icons.bolt_outlined,
    "shapes": Icons.circle_outlined,
    "emotions": Icons.face_retouching_natural,
    "jobs": Icons.work,
    "workplaces": Icons.business,
    "vehicles": Icons.car_rental,
    "households": Icons.home,
    "space": Icons.rocket_launch,
    "grammar": Icons.menu_book,
    "alphabet": Icons.sort_by_alpha,
    "simplepresent": Icons.schedule,
    "simplepresent2": Icons.schedule,
    "simplepresent3": Icons.schedule,
    "simplepresent4": Icons.schedule,
    "prepositions": Icons.location_on,
    "numbers2": Icons.looks_two,
    "directions": Icons.assistant_navigation,
    "basicmath": Icons.calculate,
    "basicmath2": Icons.calculate_outlined,
    "midverbs": Icons.flash_on,
    "midverbs2": Icons.flash_on_outlined,
    "midverbs3": Icons.flash_on,
    "midverbs4": Icons.flash_on_outlined,
    "midverbs5": Icons.flash_on,
    "midverbs6": Icons.flash_on_outlined,
    "midverbs7": Icons.flash_on,
    "midverbs8": Icons.flash_on_outlined,
    "midverbs9": Icons.flash_on,
    "midverbs10": Icons.flash_on_outlined,
    "school": Icons.school,
    "school2": Icons.school_outlined,
    "football": Icons.sports_soccer,
    "football2": Icons.sports_soccer,
    "football3": Icons.sports_soccer,
    "basketball": Icons.sports_basketball,
    "basketball2": Icons.sports_basketball,
    "othersports": Icons.sports_handball,
    "othersports2": Icons.sports_handball,
    "phrasalverbs": Icons.language,
    "phrasalverbs2": Icons.language_outlined,
    "idioms": Icons.chat,
    "chess": Icons.gamepad,
    "chess2": Icons.gamepad,
    "childrengames": Icons.videogame_asset,
    "carparts": Icons.car_repair,
    "carparts2": Icons.car_repair,
    "makeup": Icons.brush,
    "grammarpre": Icons.menu_book,
    "pasttense": Icons.history,
    "presentct": Icons.watch_later,
    "pastct": Icons.watch_later_outlined,
    "tellingthetime": Icons.access_time,
    "futuretense": Icons.update,
    "should": Icons.lightbulb,
    "must": Icons.task,
    "haveto": Icons.assignment_turned_in,
    "maymight": Icons.help,
    "presentpt": Icons.history,
    "pastpt": Icons.history,
    "ifclause": Icons.not_interested,
    "nounclause": Icons.notes,
    "relativeclause": Icons.label,
    "adverbialclause": Icons.label_important,
    "passivevoice": Icons.volume_mute,
    "compandsuper": Icons.sort_by_alpha,
    "gerundinf": Icons.swap_horiz,
    "articles": Icons.article,
    "grammarphrasal": Icons.language,
    "conjunctions": Icons.link,
    "conjunctions2": Icons.link,
    "commonmistakes": Icons.error,
    "economics": Icons.attach_money,
    "economics2": Icons.attach_money,
    "history": Icons.history,
    "history 2": Icons.history_edu,
    "technology": Icons.devices_other,
    "technology2": Icons.devices_other,
    "health": Icons.health_and_safety,
    "health2": Icons.health_and_safety,
    "biology": Icons.biotech,
    "biology2": Icons.biotech,
    "politics": Icons.gavel,
    "politics2": Icons.gavel,
  };

  // Her kategoriye özel toplam soru sayısı
  final Map<String, int> categoryTotalQuestions = {
    // Mevcut sorularınız...
    "family tree": 10,
    "colors": 11,
    "numbers": 20,
    "fruits": 20,
    "animals": 30,
    "vegetables": 20,
    "adjectives": 19,
    "bodyparts": 22,
    "clothes": 23,
    "countries": 13,
    "verbs": 22,
    "verbs2": 21,
    "shapes": 10,
    "emotions": 9,
    "jobs": 11,
    "workplaces": 22,
    "vehicles": 16,
    "households": 26,
    "space": 15,
    "grammar": 0,
    "alphabet": 0,
    "simplepresent": 0,
    "simplepresent2": 0,
    "simplepresent3": 0,
    "simplepresent4": 0,
    "prepositions": 10,
    "numbers2": 21,
    "directions": 18,
    "basicmath": 17,
    "basicmath2": 16,
    "midverbs": 19,
    "midverbs2": 20,
    "midverbs3": 20,
    "midverbs4": 20,
    "midverbs5": 19,
    "midverbs6": 19,
    "midverbs7": 17,
    "midverbs8": 17,
    "midverbs9": 16,
    "midverbs10": 24,
    "school": 18,
    "school2": 15,
    "football": 20,
    "football2": 20,
    "football3": 17,
    "basketball": 17,
    "basketball2": 15,
    "othersports": 16,
    "othersports2": 14,
    "phrasalverbs": 16,
    "phrasalverbs2": 14,
    "idioms": 20,
    "chess": 19,
    "chess2": 19,
    "childrengames": 17,
    "carparts": 20,
    "carparts2": 20,
    "makeup": 13,
    "grammarpre": 0,
    "pasttense": 0,
    "presentct": 0,
    "pastct": 0,
    "tellingthetime": 0,
    "futuretense": 0,
    "should": 0,
    "must": 0,
    "haveto": 0,
    "maymight": 0,
    "presentpt": 0,
    "pastpt": 0,
    "ifclause": 0,
    "nounclause": 0,
    "relativeclause": 0,
    "adverbialclause": 0,
    "passivevoice": 0,
    "compandsuper": 0,
    "gerundinf": 0,
    "articles": 0,
    "grammarphrasal": 0,
    "conjunctions": 0,
    "conjunctions2": 0,
    "commonmistakes": 0,
    "economics": 24,
    "economics2": 23,
    "history": 26,
    "history 2": 25,
    "technology": 26,
    "technology2": 26,
    "health": 24,
    "health2": 24,
    "biology": 23,
    "biology2": 21,
    "politics": 25,
    "politics2": 25,
  };

  // Kategorilerin kilidinin bir kez açılıp açılmadığını takip eden harita
  final Map<String, bool> categoryUnlockedStatus = {
    // Mevcut kilit durumlarınız...
    "family tree": false,
    "colors": false,
    "numbers": false,
    "fruits": false,
    "animals": false,
    "vegetables": false,
    "adjectives": false,
    "bodyparts": false,
    "clothes": false,
    "countries": false,
    "verbs": false,
    "verbs2": false,
    "shapes": false,
    "emotions": false,
    "jobs": false,
    "workplaces": false,
    "vehicles": false,
    "households": false,
    "space": false,
    "alphabet": false,
    "grammar": false,
    "simplepresent": false,
    "simplepresent2": false,
    "simplepresent3": false,
    "simplepresent4": false,
    "prepositions": false,
    "numbers2": false,
    "directions": false,
    "basicmath": false,
    "basicmath2": false,
    "midverbs": false,
    "midverbs2": false,
    "midverbs3": false,
    "midverbs4": false,
    "midverbs5": false,
    "midverbs6": false,
    "midverbs7": false,
    "midverbs8": false,
    "midverbs9": false,
    "midverbs10": false,
    "school": false,
    "school2": false,
    "football": false,
    "football2": false,
    "football3": false,
    "basketball": false,
    "basketball2": false,
    "othersports": false,
    "othersports2": false,
    "phrasalverbs": false,
    "phrasalverbs2": false,
    "idioms": false,
    "chess": false,
    "chess2": false,
    "childrengames": false,
    "carparts": false,
    "carparts2": false,
    "makeup": false,
    "grammarpre": false,
    "pasttense": false,
    "presentct": false,
    "pastct": false,
    "tellingthetime": false,
    "futuretense": false,
    "should": false,
    "must": false,
    "haveto": false,
    "maymight": false,
    "presentpt": false,
    "pastpt": false,
    "ifclause": false,
    "nounclause": false,
    "relativeclause": false,
    "adverbialclause": false,
    "passivevoice": false,
    "compandsuper": false,
    "gerundinf": false,
    "articles": false,
    "grammarphrasal": false,
    "conjunctions": false,
    "conjunctions2": false,
    "commonmistakes": false,
    "economics": false,
    "economics2": false,
    "history": false,
    "history 2": false,
    "technology": false,
    "technology2": false,
    "health": false,
    "health2": false,
    "biology": false,
    "biology2": false,
    "politics": false,
    "politics2": false,
  };

  @override
  void initState() {
    super.initState();
    final premiumProvider =
    Provider.of<PremiumProvider>(context, listen: false);
    premiumProvider.fetchPremiumStatus();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() async {
      await _getUserId(); // Önce userId atanmalı
      if (userId != null) {
        if (kDebugMode) {
          print(userId);
        }
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

  Future<void> fetchUnlockedCategories() async {
    final snapshot = await _firestore
        .collection("users")
        .doc(userId)
        .collection("unlockedCategories")
        .get();
    for (var doc in snapshot.docs) {
      categoryUnlockedStatus[doc.id] = doc["unlocked"] ?? false;
    }
    setState(() {});
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
        String category = doc.id;

        if (category == "alphabet" ||
            category == "grammar" ||
            category.contains("simplepresent")) {
          continue;
        }

        Map<String, dynamic> data = doc.data();

        // 🔥 **Yeni Liste Formatına Göre Doğru ve Yanlış Sayıları**
        List<int> correctList = List<int>.from(data["correct_answers"] ?? []);
        List<int> wrongList = List<int>.from(data["wrong_answers"] ?? []);

        tempResults[category] = {
          "correct": correctList.length, // Doğru cevap sayısı
          "total": correctList.length +
              wrongList.length, // Toplam çözülmüş soru sayısı
        };
      }

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
      if (kDebugMode) {
        print("Sıfırlama hatası: $e");
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Yeni modern kategori kartını oluşturan widget.
  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String category,
    bool isLocked = false,
  }) {
    // Stats calculation
    int correct = categoryResults[category]?["correct"] ?? 0;
    int solved = (categoryResults[category]?["total"]) ?? 0;
    int total = categoryTotalQuestions[category] ?? 0;
    double progress = total > 0 ? solved / total : 0.0;
    bool categoryLocked = isLocked;
    int score = 0;
    if (solved > 0) {
      score = (correct * 5) - ((solved - correct) * 2);
      updateScore(category, score);
    }
    final List<String> noProgressCategories = categoryTotalQuestions.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList();

    // Status variables
    String statusText;
    Color statusColor;
    Color cardColor = softWhite;
    double elevation = 4.0;

    if (categoryLocked) {
      statusText = "Kilitli";
      statusColor = Colors.grey.shade600;
      cardColor = Colors.grey.shade200;
    } else if (progress == 1.0) {
      statusText = "Tamamlandı!";
      statusColor = accentGreen;
      cardColor = lightBlue.withOpacity(0.7);
    } else if (progress > 0) {
      statusText = "Devam Ediyor";
      statusColor = primaryBlue;
    } else {
      statusText = "";
      statusColor = darkGray;
    }

    String accuracyText = solved > 0
        ? "${((correct / solved) * 100).toStringAsFixed(0)}% Doğru"
        : "";

    return Container(
      constraints: BoxConstraints(
        minHeight: 180, // Ensure minimum height
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!categoryLocked) {
              Widget nextScreen = category == "alphabet"
                  ? AlphabetScreen()
                  : CategoryScreen(category: category);
              Navigator.push(context, MaterialPageRoute(builder: (_) => nextScreen));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row - Icon and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      categoryIcons[category] ?? Icons.category_outlined,
                      color: categoryLocked ? Colors.grey : primaryBlue,
                      size: 32,
                    ),
                    if (categoryLocked)
                      const Icon(Icons.lock, color: Colors.grey, size: 24)
                    else if (progress == 1.0)
                      const Icon(Icons.check_circle, color: accentGreen, size: 24)
                    else if (progress > 0)
                        const Icon(Icons.star_half, color: secondaryOrange, size: 24)
                  ],
                ),

                // Title
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Progress and Stats
                const SizedBox(height: 16),
                if (!categoryLocked && !noProgressCategories.contains(category)) ...[
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: lightBlue,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? accentGreen : primaryBlue,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                ],

                // Bottom Row - Stats and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryLocked || noProgressCategories.contains(category)
                              ? statusText
                              : "${(progress * 100).toInt()}%",
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (accuracyText.isNotEmpty &&
                            !noProgressCategories.contains(category))
                          Text(
                            accuracyText,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: darkGray.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),

                    if (!categoryLocked && !noProgressCategories.contains(category))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.leaderboard, size: 20),
                            color: primaryBlue,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LeaderboardScreen(category: category),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => resetCategoryResults(category),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 24),
                            ),
                            child: Text(
                              "Sıfırla",
                              style: GoogleFonts.nunito(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Segment butonları oluşturmak için yardımcı widget
  Widget _buildSegmentButton(String text, int index) {
    bool isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? secondaryOrange : pastelLightBlue,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: secondaryOrange.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ]
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: isSelected ? softWhite : darkGray,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context);
    bool isPremium = premiumProvider.isPremium;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [pastelBlue, softWhite],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Kısım (Navigasyon Butonları ve Başlık)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_outline, color: darkGray, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileScreen()),
                        );
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.group, color: Colors.black, size: 27),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const FriendsScreen(),
                            );
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: darkGray, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Segment Butonlar (Beginner, Intermediate, Advanced)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildSegmentButton("Başlangıç", 0),
                    _buildSegmentButton("Orta", 1),
                    _buildSegmentButton("İleri", 2),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tutorial Butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.school, color: Colors.white, size: 24),
                  label: const Text(
                    "Tutorial",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    minimumSize: const Size(double.infinity, 50), // Genişliği doldur
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TutorialScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Ana içerik alanı (Sekme görünümü)
              Expanded(
                child: StreamBuilder<Map<String, Map<String, dynamic>>>(
                  stream: _fetchUserResultsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primaryBlue));
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Hata oluştu: ${snapshot.error}", style: GoogleFonts.quicksand()));
                    }

                    categoryResults = snapshot.data ?? {};

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCategoryGrid("Vocabulary", "Grammar", [
                          "family tree", "colors", "numbers", "fruits", "animals", "vegetables",
                          "adjectives", "bodyparts", "clothes", "countries", "verbs", "verbs2",
                          "shapes", "emotions", "jobs", "workplaces", "vehicles", "households", "space",
                        ], [
                          "alphabet", "grammar", "simplepresent", "simplepresent2", "simplepresent3", "simplepresent4",
                        ], isPremium: isPremium),

                        _buildCategoryGrid("Vocabulary", "Grammar", [
                          "prepositions", "numbers2", "directions", "basicmath", "basicmath2", "midverbs",
                          "midverbs2", "midverbs3", "midverbs4", "midverbs5", "midverbs6", "midverbs7",
                          "midverbs8", "midverbs9", "midverbs10", "school", "school2", "football",
                          "football2", "football3", "basketball", "basketball2", "othersports",
                          "phrasalverbs", "phrasalverbs2", "idioms", "chess", "chess2", "childrengames",
                          "carparts", "carparts2", "makeup",
                        ], [
                          "grammarpre", "pasttense", "presentct", "pastct", "tellingthetime", "futuretense",
                          "should", "must", "haveto", "maymight", "presentpt", "pastpt",
                          "ifclause", "nounclause", "relativeclause", "adverbialclause", "passivevoice",
                          "compandsuper", "gerundinf",
                        ], isPremium: isPremium),

                        _buildCategoryGrid("Vocabulary", "Grammar", [
                          "economics", "economics2", "history", "history 2", "technology", "technology2",
                          "health", "health2", "biology", "biology2", "politics", "politics2",
                        ], [
                          "articles", "grammarphrasal", "conjunctions", "conjunctions2", "commonmistakes",
                        ], isPremium: isPremium),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
      String vocabTitle,
      String grammarTitle,
      List<String> vocabCategories,
      List<String> grammarCategories,
      {required bool isPremium}
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vocabulary Section
          _buildSectionHeader(vocabTitle),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth / 2 - 24;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8, // Wider aspect ratio for taller cards
                  mainAxisExtent: cardWidth * 1.4, // Explicit height based on width
                ),
                itemCount: vocabCategories.length,
                itemBuilder: (context, index) {
                  final category = vocabCategories[index];
                  return _buildCategoryCard(
                    context: context,
                    title: _getCategoryTitle(category),
                    category: category,
                    isLocked: !isPremium && _isPremiumCategory(category),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Grammar Section
          _buildSectionHeader(grammarTitle),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth / 2 - 24;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                  mainAxisExtent: cardWidth * 1.4,
                ),
                itemCount: grammarCategories.length,
                itemBuilder: (context, index) {
                  final category = grammarCategories[index];
                  return _buildCategoryCard(
                    context: context,
                    title: _getCategoryTitle(category),
                    category: category,
                    isLocked: !isPremium && _isPremiumCategory(category),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkGray,
        ),
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

  // Kategori isimlerini daha okunaklı hale getiren yardımcı fonksiyon
  String _getCategoryTitle(String category) {
    // Vocabulary categories
    if (category == "family tree") return "Family Tree";
    if (category == "colors") return "Colors";
    if (category == "numbers") return "Numbers I";
    if (category == "fruits") return "Fruits";
    if (category == "animals") return "Animals";
    if (category == "vegetables") return "Vegetables";
    if (category == "adjectives") return "Adjectives";
    if (category == "bodyparts") return "Body Parts";
    if (category == "clothes") return "Clothes";
    if (category == "countries") return "Countries";
    if (category == "verbs") return "Verbs I";
    if (category == "verbs2") return "Verbs II";
    if (category == "shapes") return "Shapes";
    if (category == "emotions") return "Emotions";
    if (category == "jobs") return "Jobs";
    if (category == "workplaces") return "Workplaces";
    if (category == "vehicles") return "Vehicles";
    if (category == "households") return "Households";
    if (category == "space") return "Space";
    if (category == "prepositions") return "Prepositions";
    if (category == "numbers2") return "Numbers II";
    if (category == "directions") return "Directions";
    if (category == "basicmath") return "Basic Math I";
    if (category == "basicmath2") return "Basic Math II";
    if (category == "midverbs") return "Mid Verbs I";
    if (category == "midverbs2") return "Mid Verbs II";
    if (category == "midverbs3") return "Mid Verbs III";
    if (category == "midverbs4") return "Mid Verbs IV";
    if (category == "midverbs5") return "Mid Verbs V";
    if (category == "midverbs6") return "Mid Verbs VI";
    if (category == "midverbs7") return "Mid Verbs VII";
    if (category == "midverbs8") return "Mid Verbs VIII";
    if (category == "midverbs9") return "Mid Verbs IX";
    if (category == "midverbs10") return "Mid Verbs X";
    if (category == "school") return "School Items I";
    if (category == "school2") return "School Items II";
    if (category == "football") return "Football";
    if (category == "football2") return "Football II";
    if (category == "football3") return "Football III";
    if (category == "basketball") return "Basketball";
    if (category == "basketball2") return "Basketball II";
    if (category == "othersports") return "Other Sports";
    if (category == "phrasalverbs") return "Phrasal Verbs I";
    if (category == "phrasalverbs2") return "Phrasal Verbs II";
    if (category == "idioms") return "Idioms";
    if (category == "chess") return "Chess";
    if (category == "chess2") return "Chess II";
    if (category == "childrengames") return "Children Games";
    if (category == "carparts") return "Car Parts I";
    if (category == "carparts2") return "Car Parts II";
    if (category == "makeup") return "Make Up";
    if (category == "economics") return "Economics I";
    if (category == "economics2") return "Economics II";
    if (category == "history") return "History I";
    if (category == "history 2") return "History II";
    if (category == "technology") return "Technology I";
    if (category == "technology2") return "Technology II";
    if (category == "health") return "Health I";
    if (category == "health2") return "Health II";
    if (category == "biology") return "Biology I";
    if (category == "biology2") return "Biology II";
    if (category == "politics") return "Politics I";
    if (category == "politics2") return "Politics II";

    // Grammar categories
    if (category == "alphabet") return "Alphabet";
    if (category == "grammar") return "Grammar Basics";
    if (category == "simplepresent") return "Simple Present I";
    if (category == "simplepresent2") return "Simple Present II";
    if (category == "simplepresent3") return "Simple Present III";
    if (category == "simplepresent4") return "Simple Present IV";
    if (category == "grammarpre") return "Grammar: Prepositions";
    if (category == "pasttense") return "Past Tense";
    if (category == "presentct") return "Present Continuous";
    if (category == "pastct") return "Past Continuous";
    if (category == "tellingthetime") return "Telling Time";
    if (category == "futuretense") return "Future Tense";
    if (category == "should") return "Should/Ought To";
    if (category == "must") return "Must";
    if (category == "haveto") return "Have To";
    if (category == "maymight") return "May/Might";
    if (category == "presentpt") return "Present Perfect";
    if (category == "pastpt") return "Past Perfect";
    if (category == "ifclause") return "If Clauses";
    if (category == "nounclause") return "Noun Clauses";
    if (category == "relativeclause") return "Relative Clauses";
    if (category == "adverbialclause") return "Adverbial Clauses";
    if (category == "passivevoice") return "Passive Voice";
    if (category == "compandsuper") return "Comparatives/Superlatives";
    if (category == "gerundinf") return "Gerunds/Infinitives";
    if (category == "articles") return "Articles";
    if (category == "grammarphrasal") return "Grammar: Phrasal Verbs";
    if (category == "conjunctions") return "Conjunctions I";
    if (category == "conjunctions2") return "Conjunctions II";
    if (category == "commonmistakes") return "Common Mistakes";

    // Fallback for any unexpected categories
    return category
        .replaceAll("_", " ")
        .replaceAll("2", " II")
        .replaceAll("3", " III")
        .replaceAll("4", " IV")
        .replaceAllMapped(
      RegExp(r'\b(i+)\b', caseSensitive: false),
          (match) => match.group(0)!.toUpperCase(),
    )
        .split(' ')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  // Premium kategori kontrolü (sizin mantığınıza göre güncellenmeli)
  bool _isPremiumCategory(String category) {
    // Örnek: 'İleri' seviye kategoriler premium olsun
    List<String> advancedCategories = [
      "economics", "economics2", "history", "history 2", "technology",
      "technology2", "health", "health2", "biology", "biology2", "politics",
      "politics2", "articles", "grammarphrasal", "conjunctions",
      "conjunctions2", "commonmistakes",
    ];
    return advancedCategories.contains(category);
  }
}