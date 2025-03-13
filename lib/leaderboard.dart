import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
      List<Future<void>> futures = [];

      for (var userDoc in usersSnapshot.docs) {
        futures.add(_fetchUserScore(userDoc, tempLeaderboard));
      }

      await Future.wait(futures);
      tempLeaderboard.sort((a, b) => b['score'].compareTo(a['score']));

      if (mounted) {
        setState(() {
          leaderboardData = tempLeaderboard;
        });
      }
    } catch (e) {
      print("❌ Liderlik tablosu verileri alınırken hata oluştu: $e");
    }
  }

  Future<void> _fetchUserScore(DocumentSnapshot userDoc, List<Map<String, dynamic>> tempLeaderboard) async {
    try {
      String userId = userDoc.id;
      String username = userDoc.data() != null && userDoc['name'] != null
          ? userDoc['name']
          : 'Bilinmeyen';

      // Avatar yoksa -1 olarak ata
      var userData = userDoc.data() as Map<String, dynamic>?; // Veriyi Map olarak alıyoruz
      int avatarNumber = userData != null && userData.containsKey('avatarNumber')
          ? userData['avatarNumber']
          : -1; // Eğer 'avatarNumber' yoksa -1 olarak ata

      DocumentSnapshot resultSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('results')
          .doc(widget.category)
          .get();

      if (!resultSnapshot.exists) {
        // Skor bilgisi olmayanları dahil etme
        return;
      }

      Map<String, dynamic>? resultData = resultSnapshot.data() as Map<String, dynamic>?;

      // Skor yoksa, kullanıcıyı ekleme
      if (resultData == null || !resultData.containsKey('score') || resultData['score'] == null) {
        return;
      }

      int score = resultData['score'] is int ? resultData['score'] : 0;

      // Tüm kullanıcıları skorlarına bakarak listeye ekle
      tempLeaderboard.add({
        'username': username,
        'score': score,
        'avatarNumber': avatarNumber, // Avatar bilgisi olmasa bile -1 olarak ekle
      });
    } catch (e) {
      print("⚠ Kullanıcı skoru alınırken hata oluştu: $e");
    }
  }



  /// **📌 Avatarları cache içinden kontrol eden fonksiyon**
  Future<ImageProvider> _getUserAvatar(int avatarNumber) async {
    if (avatarNumber == -1) {
      return const AssetImage('assets/avatars/default.png'); // **Varsayılan avatar**
    }

    final directory = await getApplicationDocumentsDirectory();
    final avatarPath = '${directory.path}/avatar$avatarNumber.jpg';
    final avatarFile = File(avatarPath);

    if (await avatarFile.exists()) {
      return FileImage(avatarFile);
    } else {
      return const AssetImage('assets/avatars/default.png'); // **Eğer dosya yoksa default göster**
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.category.toUpperCase()} Kategorisi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
      ),
      backgroundColor: Colors.yellow.shade100,
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
                  int avatarNumber = user['avatarNumber'];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      leading: FutureBuilder<ImageProvider>(
                        future: _getUserAvatar(avatarNumber),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            );
                          } else if (snapshot.hasData) {
                            return CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: snapshot.data!,
                            );
                          } else {
                            return const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            );
                          }
                        },
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
