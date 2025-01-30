import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'category_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;
  Map<String, Map<String, dynamic>> categoryResults = {};

  // Her kategoriye özel toplam soru sayısı
  final Map<String, int> categoryTotalQuestions = {
    "family tree": 10,
    "colors": 11,
    "numbers": 11,
  };

  @override
  void initState() {
    super.initState();
    _fetchUserResultsStream();
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
        int totalQuestions = data["toplam"] ?? data.length;

        tempResults[doc.id] = {
          "correct": correctAnswers,
          "total": totalQuestions,
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
      print("Sıfırlama hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kategoriler",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
        elevation: 4,
      ),
      body: StreamBuilder<Map<String, Map<String, dynamic>>>(
        stream: _fetchUserResultsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata oluştu: ${snapshot.error}"));
          }

          // Güncellenen veriyi al
          categoryResults = snapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                buildCategorySection(context, "Başlangıç Seviyesi", [
                  buildCategoryCard(context, "Family Tree", "family tree"),
                  buildCategoryCard(context, "Colors", "colors"),
                  buildCategoryCard(context, "Numbers", "numbers"),
                ]),
                buildCategorySection(context, "Orta Seviye", []),
                buildCategorySection(context, "İleri Seviye", []),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildCategorySection(BuildContext context, String title, List<Widget> categoryCards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Column(children: categoryCards),
      ],
    );
  }

  Widget buildCategoryCard(BuildContext context, String title, String category) {
    int correct = categoryResults[category]?["correct"] ?? 0;
    int solved = categoryResults[category]?["total"] ?? 0;
    int total = categoryTotalQuestions[category]!;

    String statusText = "Henüz test çözülmedi";
    Color statusColor = Colors.grey;

    if (correct > 0 && solved < total) {
      statusText = "$correct/$total Doğru (Devam Ediyor)";
      statusColor = Colors.amber;
    } else if (solved == total) {
      statusText = "$correct/$total Doğru (Tamamlandı)";
      statusColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(category: category),
          ),
        );
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
              subtitle: Text(
                statusText,
                style: TextStyle(fontSize: 16, color: statusColor),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 24,
              ),
            ),
            // Sıfırlama butonu ekleniyor
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
