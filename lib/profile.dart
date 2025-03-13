import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _avatarPath;
  String? _userName;
  final TextEditingController _nameController = TextEditingController();
  List<String> _avatarPaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadAvatars();
  }

  Future<void> _loadUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc["name"] ?? "Kullanıcı Adı";
          });

          int avatarNumber = userDoc["avatarNumber"] ?? 0;
          _avatarPath = await _getAvatarFilePath(avatarNumber);
          setState(() {});
        }
      } catch (e) {
        print("❌ Kullanıcı bilgilerini yüklerken hata: $e");
      }
    }
  }

  Future<void> _loadAvatars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> avatars = [];
      for (int i = 1; i <= 10; i++) {
        avatars.add(await _getAvatarFilePath(i));
      }

      setState(() {
        _avatarPaths = avatars;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Avatarları yüklerken hata: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getAvatarFilePath(int avatarNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/avatar$avatarNumber.jpg';
    final file = File(filePath);

    if (await file.exists()) {
      print("sa");
      return filePath;
    }

    // Eğer dosya yoksa asset'ten al ve kaydet
    ByteData data = await rootBundle.load('assets/avatars/avatar$avatarNumber.jpg');
    List<int> bytes = data.buffer.asUint8List();
    await file.writeAsBytes(bytes);

    return filePath;
  }

  Future<void> _pickImage() async {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Avatar Seç",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _avatarPaths.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          await _updateAvatar(index + 1);
                          Navigator.pop(context);
                        },
                        child: Image.file(
                          File(_avatarPaths[index]),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateAvatar(int avatarNumber) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "avatarNumber": avatarNumber,
    });

    String newPath = await _getAvatarFilePath(avatarNumber);
    setState(() {
      _avatarPath = newPath;
    });
  }

  Future<void> _updateName() async {
    User? user = _auth.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({
          "name": _nameController.text,
        });

        setState(() {
          _userName = _nameController.text;
        });
      } catch (e) {
        print("❌ İsim güncellenirken hata: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Ayarları"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _avatarPath != null
                        ? FileImage(File(_avatarPath!))
                        : const AssetImage('assets/avatars/default.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.change_circle,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _userName ?? "Kullanıcı Adı",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "İsminizi Güncelleyin",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateName,
              child: const Text(
                "Güncelle",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
