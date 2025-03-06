import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PremiumProvider with ChangeNotifier {
  bool _isPremium = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isPremium => _isPremium;

  // Premium durumunu güncelle
  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners(); // Durum değiştiğinde dinleyicilere haber ver
  }

  // Firestore'dan premium durumunu çek ve Provider'ı güncelle
  Future<void> fetchPremiumStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();

      bool premiumStatus = snapshot.exists ? snapshot["isPremium"] ?? false : false;
      setPremium(premiumStatus); // Provider'ı güncelle
    }
  }
}