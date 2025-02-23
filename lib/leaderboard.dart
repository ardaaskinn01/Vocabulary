import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  final String category;

  const LeaderboardScreen({Key? key, required this.category}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      QuerySnapshot usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> tempLeaderboard = [];

      // Tüm Firestore çağrılarını paralel çalıştır
      List<Future<void>> futures = [];

      for (var userDoc in usersSnapshot.docs) {
        futures.add(_fetchUserScore(userDoc, tempLeaderboard));
      }

      // Tüm işlemleri paralel olarak çalıştır
      await Future.wait(futures);

      // Skorları büyükten küçüğe sırala
      tempLeaderboard.sort((a, b) => b['score'].compareTo(a['score']));

      // ❗ Ekranın hala aktif olup olmadığını kontrol et
      if (mounted) {
        setState(() {
          leaderboardData = tempLeaderboard;
        });
      }
    } catch (e) {
      print("❌ Liderlik tablosu verileri alınırken hata oluştu: $e");
    }
  }

// Kullanıcının skorunu alıp listeye ekleyen fonksiyon
  Future<void> _fetchUserScore(DocumentSnapshot userDoc, List<Map<String, dynamic>> tempLeaderboard) async {
    try {
      String userId = userDoc.id;
      String username = userDoc.data() != null && userDoc['name'] != null ? userDoc['name'] : 'Bilinmeyen';

      DocumentSnapshot resultSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('results')
          .doc(widget.category)
          .get();

      if (!resultSnapshot.exists) return;

      Map<String, dynamic>? resultData = resultSnapshot.data() as Map<String, dynamic>?;

      int score = resultData != null && resultData.containsKey('score') && resultData['score'] is int
          ? resultData['score']
          : 0;

      tempLeaderboard.add({
        'username': username,
        'score': score,
      });
    } catch (e) {
      print("⚠ Kullanıcı skoru alınırken hata oluştu: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.category.toUpperCase()} Kategorisi", style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.orange.shade700,
      ),
      backgroundColor: Colors.yellow.shade100, // Soluk sarı arka plan
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Liderlik Tablosu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: leaderboardData.isEmpty
                  ? const Center(
                child: Text(
                  "Henüz testi çözen bulunamadı!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: leaderboardData.length,
                itemBuilder: (context, index) {
                  var user = leaderboardData[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade600,
                        child: Text(
                          "#${index + 1}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        user['username'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        "${user['score']} Puan",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
