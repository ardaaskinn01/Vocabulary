import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userId;
  String? myName;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _getUserId();
    _tabController = TabController(length: 3, vsync: this);
    _getMyName().then((name) {
      myName = name;
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Text("Arkadaşlar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            // TabBar
            TabBar(
              controller: _tabController,
              labelColor: Colors.orangeAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orangeAccent,
              tabs: const [
                Tab(text: "Arkadaşlar"),
                Tab(text: "Arkadaş Ekle"),
                Tab(text: "İstekler"),
              ],
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsList(),
                  _buildAddFriendsSection(),
                  _buildRequestsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(userId).collection("friends").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Henüz arkadaşın yok."));
        }

        var friends = snapshot.data!.docs;
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            var friend = friends[index];
            String friendId = friend.id;
            String? friendName = friend["name"];

            if (friendName == null || friendName.isEmpty) {
              return const SizedBox.shrink(); // Eğer isim yoksa, listeye ekleme
            }

            return ListTile(
              leading: const Icon(Icons.person, color: Colors.orangeAccent),
              title: Text(friendName),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showRemoveFriendDialog(friendId, friendName);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showRemoveFriendDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Arkadaşlıktan Çıkar"),
          content: Text("$friendName adlı kişiyi arkadaşlıktan çıkarmak istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Diyaloğu kapat
              },
              child: const Text("Hayır", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _removeFriend(friendId, friendName);
                Navigator.of(context).pop(); // Diyaloğu kapat
              },
              child: const Text("Evet", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  /// 🔹 Arkadaşlıktan Çıkarma
  void _removeFriend(String friendId, String friendName) async {
    // 1. Kendi arkadaş listesinden çıkar
    await FirebaseFirestore.instance.collection("users").doc(userId).collection("friends").doc(friendId).delete();

    // 2. Arkadaşın listesinden de seni çıkar
    await FirebaseFirestore.instance.collection("users").doc(friendId).collection("friends").doc(userId).delete();

    // 3. Kullanıcıya bilgi ver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$friendName arkadaşlıktan çıkarıldı!"), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildAddFriendsSection() {

    return Column(
      children: [
        // Arama Alanı
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Kullanıcı ara...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              _searchQuery = value.toLowerCase();
            },
          ),
        ),

        // Arkadaş Ekleme Listesi
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Sistemde kullanıcı bulunamadı."));
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .collection("friends")
                    .snapshots(),
                builder: (context, friendsSnapshot) {
                  if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<String> friendIds = [];
                  if (friendsSnapshot.hasData) {
                    friendIds = friendsSnapshot.data!.docs.map((doc) => doc.id).toList();
                  }

                  var users = userSnapshot.data!.docs.where((user) {
                    final data = user.data() as Map<String, dynamic>?; // 🔹 Veriyi Map olarak al

                    if (data == null || !data.containsKey('name') || data['name'] == null || data['name'].toString().isEmpty) {
                      return false; // İsmi olmayanları gösterme
                    }

                    String currentUserId = user.id;
                    String currentUserName = data['name'].toLowerCase();

                    return currentUserId != userId && !friendIds.contains(currentUserId) && currentUserName.contains(_searchQuery);
                  }).toList();

                  if (users.isEmpty) {
                    return const Center(child: Text("Ekleyebileceğiniz yeni kullanıcı bulunamadı."));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index];
                      String userName = user['name'];
                      String userId = user.id;

                      return ListTile(
                        title: Text(userName),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () async {
                            if (myName != null) {
                              _sendFriendRequest(userId, userName, myName!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Arkadaşlık isteği gönderildi!")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Adınız alınamadı! Lütfen tekrar deneyin.")),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Future<String?> _getMyName() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(userId).get();

    if (userDoc.exists) {
      return userDoc["name"];
    }
    return null;
  }

  /// 🔹 Kullanıcının Gelen Arkadaşlık İstekleri
  Widget _buildRequestsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(userId).collection("requests").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Gelen istek yok."));
        }

        var requests = snapshot.data!.docs.where((request) => request["name"] != null && request["name"].toString().isNotEmpty).toList();

        if (requests.isEmpty) {
          return const Center(child: Text("Gelen istek yok."));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            var request = requests[index];
            String senderId = request.id;
            String senderName = request["name"];

            return ListTile(
              title: Text(senderName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      _acceptFriendRequest(senderId, senderName);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      _rejectFriendRequest(senderId);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  /// 🔹 Arkadaşlık İsteği Gönderme
  void _sendFriendRequest(String friendId, String friendName, String myName) async {

    await FirebaseFirestore.instance
        .collection("users")
        .doc(friendId)
        .collection("requests")
        .doc(userId)
        .set({
      "name": myName, // Kendi adımızı ekledik!
      "requestedAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$friendName adlı kişiye istek gönderildi!"), duration: const Duration(seconds: 2)),
    );
  }


  /// 🔹 Arkadaşlık İsteğini Kabul Etme
  void _acceptFriendRequest(String senderId, String senderName) async {
    // 1. Sender'ı kendi arkadaş listeme ekle
    await FirebaseFirestore.instance.collection("users").doc(userId).collection("friends").doc(senderId).set({
      "name": senderName,
      "addedAt": Timestamp.now(),
    });

    // 2. Kendimi sender'ın arkadaş listesine ekle
    await FirebaseFirestore.instance.collection("users").doc(senderId).collection("friends").doc(userId).set({
      "name": myName, // Auth ile kullanıcı adı alınmalı
      "addedAt": Timestamp.now(),
    });

    // 3. İstekler listesinden kaldır
    await FirebaseFirestore.instance.collection("users").doc(userId).collection("requests").doc(senderId).delete();
  }

  /// 🔹 Arkadaşlık İsteğini Reddetme
  void _rejectFriendRequest(String senderId) async {
    await FirebaseFirestore.instance.collection("users").doc(userId).collection("requests").doc(senderId).delete();
  }
}
