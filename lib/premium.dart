import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ingilizce/provider.dart';
import 'package:provider/provider.dart';

class PremiumPurchaseScreen extends StatefulWidget {
  @override
  _PremiumPurchaseScreenState createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;
  bool isLoading = true; // Kullanıcı ID'si yüklenirken loading göstermek için

  @override
  void initState() {
    super.initState();
    _getUserId(); // Kullanıcı ID'sini al
  }

  // Kullanıcı ID'sini al
  Future<void> _getUserId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
        isLoading = false; // Yükleme tamamlandı
      });
    } else {
      setState(() {
        isLoading = false; // Yükleme tamamlandı, ancak kullanıcı yok
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Satın Al"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Yükleme durumu
          : Center(
        child: ElevatedButton(
          onPressed: () {
            // Satın alma işlemini başlat
            _purchasePremium(premiumProvider);
          },
          child: const Text("Premium Satın Al"),
        ),
      ),
    );
  }

  // Premium satın alma işlemi
  void _purchasePremium(PremiumProvider provider) async {
    await updatePremiumStatus(true); // Firestore'u güncelle
    provider.setPremium(true); // Provider'ı güncelle

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Premium hesaba yükseltildi!")),
    );

    Navigator.pop(context);
  }

  // Firestore'da premium durumunu güncelle
  Future<void> updatePremiumStatus(bool isPremium) async {
    if (userId == null) return;

    await _firestore
        .collection("users")
        .doc(userId)
        .update({"isPremium": isPremium});
  }
}