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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      // Leaderboard koleksiyonundan, kategoriye ait dökümanı al
      DocumentSnapshot leaderboardSnapshot = await FirebaseFirestore.instance
          .collection('leaderboards')
          .doc(widget.category)
          .get();

      List<Map<String, dynamic>> tempLeaderboard = [];
      List<Future<void>> futures = [];

      if (leaderboardSnapshot.exists) {
        // Durum 1: Leaderboard dökümanı zaten varsa, direkt ondan veriyi çek
        Map<String, dynamic>? data =
        leaderboardSnapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          // Mevcut dökümandaki her kullanıcı verisini al
          for (var entry in data.entries) {
            String userId = entry.key;
            var userData = entry.value;

            if (userData is Map && userData.containsKey('score')) {
              // Kullanıcı avatar numarasını çekmek için ayrı bir Future oluştur
              futures.add(() async {
                String username = userData['username'] ?? 'Bilinmeyen';
                int score = userData['score'] ?? 0;

                // Avatar numarasını user dökümanından çekiyoruz
                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get();

                // `avatarNumber` alanının varlığını kontrol et
                int avatarNumber = (userDoc.exists &&
                    (userDoc.data() as Map<String, dynamic>).containsKey('avatarNumber') &&
                    userDoc['avatarNumber'] != null)
                    ? userDoc['avatarNumber']
                    : -1;

                tempLeaderboard.add({
                  'username': username,
                  'score': score,
                  'avatarNumber': avatarNumber,
                });
              }());
            }
          }
          // Tüm avatar çekme işlemleri tamamlanana kadar bekle
          await Future.wait(futures);
        }
      } else {
        // Durum 2: Leaderboard dökümanı yoksa, tüm kullanıcıları çek ve yeni dökümanı oluştur
        print("Leaderboard dökümanı bulunamadı. Yeni döküman oluşturuluyor...");
        QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

        Map<String, dynamic> leaderboardDataForDb = {};

        for (var userDoc in usersSnapshot.docs) {
          futures.add(() async {
            String userId = userDoc.id;
            var userData = userDoc.data() as Map<String, dynamic>?;

            if (userData != null) {
              String username = userData['name'] ?? 'Bilinmeyen';

              // `avatarNumber` alanının varlığını kontrol et
              int avatarNumber = (userData.containsKey('avatarNumber') &&
                  userData['avatarNumber'] != null)
                  ? userData['avatarNumber']
                  : -1;

              // Kullanıcının kategori puanını al
              DocumentSnapshot resultSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('results')
                  .doc(widget.category)
                  .get();

              if (resultSnapshot.exists) {
                Map<String, dynamic>? resultData =
                resultSnapshot.data() as Map<String, dynamic>?;

                int score = 0;
                if (resultData != null) {
                  // Skor varsa direkt kullan, yoksa hesapla
                  if (resultData.containsKey('score')) {
                    score = resultData['score'] is int ? resultData['score'] : 0;
                  } else if (resultData.containsKey('correct_answers') &&
                      resultData.containsKey('wrong_answers')) {
                    List<int> correctAnswers =
                    List<int>.from(resultData['correct_answers'] ?? []);
                    List<int> wrongAnswers =
                    List<int>.from(resultData['wrong_answers'] ?? []);
                    score = (correctAnswers.length * 5) - (wrongAnswers.length * 2);
                  }
                }

                // Koşulu 'score > 0' yerine 'resultSnapshot.exists' olarak değiştiriyoruz
                if (resultSnapshot.exists) {
                  tempLeaderboard.add({
                    'username': username,
                    'score': score,
                    'avatarNumber': avatarNumber,
                  });
                  leaderboardDataForDb[userId] = {
                    'username': username,
                    'score': score,
                  };
                }
              }
            }
          }());
        }

        await Future.wait(futures);

        // Yeni leaderboard dökümanını oluştur
        await FirebaseFirestore.instance
            .collection('leaderboards')
            .doc(widget.category)
            .set(leaderboardDataForDb);
      }

      tempLeaderboard.sort((a, b) => b['score'].compareTo(a['score']));

      if (mounted) {
        setState(() {
          leaderboardData = tempLeaderboard;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Liderlik tablosu verileri alınırken hata oluştu: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<ImageProvider> _getUserAvatar(int avatarNumber) async {
    if (avatarNumber == -1) {
      return const AssetImage('assets/avatars/default.png');
    }

    final directory = await getApplicationDocumentsDirectory();
    final avatarPath = '${directory.path}/avatar$avatarNumber.jpg';
    final avatarFile = File(avatarPath);

    if (await avatarFile.exists()) {
      return FileImage(avatarFile);
    } else {
      return const AssetImage('assets/avatars/default.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.category.toUpperCase()} Kategorisi",
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1E1E2C),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Liderlik Tablosu",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
                  : leaderboardData.isEmpty
                  ? const Center(
                child: Text(
                  "Henüz testi çözen bulunamadı!",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: leaderboardData.length,
                itemBuilder: (context, index) {
                  var user = leaderboardData[index];
                  int avatarNumber = user['avatarNumber'];
                  Color rankColor = Colors.white;
                  IconData? rankIcon;

                  if (index == 0) {
                    rankColor = Colors.amber.shade700;
                    rankIcon = Icons.emoji_events;
                  } else if (index == 1) {
                    rankColor = Colors.blueGrey.shade300;
                    rankIcon = Icons.emoji_events;
                  } else if (index == 2) {
                    rankColor = Colors.brown.shade400;
                    rankIcon = Icons.emoji_events;
                  }

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: const Color(0xFF2B2B43),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: index < 3
                                ? rankColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                          ),
                          FutureBuilder<ImageProvider>(
                            future: _getUserAvatar(avatarNumber),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person,
                                      color: Colors.white),
                                );
                              } else if (snapshot.hasData) {
                                return CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: snapshot.data!,
                                );
                              } else {
                                return const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person,
                                      color: Colors.white),
                                );
                              }
                            },
                          ),
                          if (rankIcon != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Icon(
                                rankIcon,
                                color: rankColor,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        user['username'],
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      subtitle: Text(
                        "${index + 1}. Sıra",
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400),
                      ),
                      trailing: Text(
                        "${user['score']} Puan",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow),
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
