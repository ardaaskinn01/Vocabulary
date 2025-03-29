import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _soundEnabled = true; // Varsayılan olarak açık

  @override
  void initState() {
    super.initState();
    _loadSoundSetting();
  }

  Future<void> _restorePurchases() async {
    final InAppPurchase iap = InAppPurchase.instance;

    final bool available = await iap.isAvailable();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mağaza kullanılabilir değil!")),
      );
      return;
    }

    // Apple Store veya Google Play’den geçmiş satın alımları yükler
    iap.restorePurchases();

    // Satın alım bilgilerini almak için stream dinleyelim
    iap.purchaseStream.listen((List<PurchaseDetails> purchases) {
      if (purchases.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Geçmiş satın alımlar bulunamadı.")),
        );
        return;
      }

      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Satın alımlar geri yüklendi!")),
          );

          // Firestore verisini güncellemek gerekirse burada yapabilirsiniz.
          // örn: Firestore'a premium durumu kaydetme
          // FirebaseFirestore.instance.collection("users").doc(userId).update({"isPremium": true});
        }
      }
    });
  }

  /// 🔹 **Firestore'dan Kullanıcının `soundEnabled` Ayarını Yükle**
  Future<void> _loadSoundSetting() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _soundEnabled = userDoc.get("soundEnabled") ?? true;
        });
      }
    }
  }

  /// 🔹 **Logout İşlemi**
  Future<void> _logout() async {
    try {
      await _auth.signOut(); // Firebase Auth ile oturumu kapat
      // Kullanıcı çıkış yaptıktan sonra giriş ekranına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print("Çıkış yapma hatası: $e");
    }
  }

  /// 🔹 **Firestore'daki `soundEnabled` Alanını Güncelle**
  Future<void> _toggleSoundSetting(bool newValue) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "soundEnabled": newValue,
      });

      setState(() {
        _soundEnabled = newValue;
      });
    }
  }

  /// 🔹 **Hesap Silme İşlemi**
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Firestore'dan Kullanıcıyı Sil
        await FirebaseFirestore.instance.collection("users").doc(userId).delete();

        // Firebase Authentication'dan Kullanıcıyı Sil
        await user.delete();

        // Oturumu Kapat
        await _auth.signOut();

        // Giriş ekranına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesap silmek için tekrar giriş yapmalısınız.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hesap Ayarları',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 20),
              // 🔊 **Ses Aç/Kapat Ayarı**
              SwitchListTile(
                title: const Text(
                  "Ses Efektleri",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                value: _soundEnabled,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
                onChanged: (bool value) {
                  _toggleSoundSetting(value);
                },
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                onPressed: _restorePurchases,
                child: const Text(
                  "Satın Alımları Geri Yükle",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // 🚨 **Hesap Silme Butonu**
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                onPressed: () => _deleteAccount(context),
                child: const Text(
                  "Hesabımı Sil",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                onPressed: _logout,
                child: const Text(
                  "Çıkış Yap",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
