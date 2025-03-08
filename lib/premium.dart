import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ingilizce/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

class PremiumPurchaseScreen extends StatefulWidget {
  @override
  _PremiumPurchaseScreenState createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  String? userId;
  bool isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _getUserId();
    _loadProducts();
    _listenToPurchases(); // 📌 Satın alma akışını dinleyelim
  }

  Future<void> _getUserId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 📌 Google Play ve App Store'daki ürünleri yükleyelim
  Future<void> _loadProducts() async {
    const Set<String> _productIds = {'premium_subscription'}; // 📌 Abonelik ürün kimliği
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      print("❌ Ürün bulunamadı: ${response.notFoundIDs}");
    } else {
      setState(() {
        _products = response.productDetails;
      });
    }
  }

  // 📌 **Satın alma işlemlerini dinle ve doğrula**
  void _listenToPurchases() {
    _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> purchases) async {
      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          await _verifyPurchase(purchase);
          Provider.of<PremiumProvider>(context, listen: false).setPremium(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Premium hesaba yükseltildi!")),
          );
        } else if (purchase.status == PurchaseStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Satın alma başarısız! Lütfen tekrar deneyin.")),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Satın Al")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text("Satın alma seçenekleri henüz uygulamaya yüklenmedi."))
          : Center(
        child: ElevatedButton(
          onPressed: () => _showPurchaseDialog(context),
          child: const Text("Premium Satın Al"),
        ),
      ),
    );
  }

  // 📌 **Premium Satın Alma Pop-up'ını Açma**
  void _showPurchaseDialog(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "🚀 Premium Abonelik",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Reklamsız kullanım ve özel içeriklere erişim için Premium abone olun!",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _isPurchasing
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _isPurchasing = true;
                  });
                  await _purchasePremium(premiumProvider);
                  setState(() {
                    _isPurchasing = false;
                  });
                },
                icon: const Icon(Icons.lock_open),
                label: const Text("Şimdi Abone Ol"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 📌 **Abonelik satın alma işlemini başlat**
  Future<void> _purchasePremium(PremiumProvider provider) async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ürünler yüklenemedi, lütfen tekrar deneyin.")),
      );
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: _products.first);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam); // 📌 Abonelik için değiştirdik
  }

  // 📌 **Ödemeyi doğrula ve Firestore'a kaydet**
  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    if (userId == null) return;

    await _firestore.collection("users").doc(userId).update({"isPremium": true});
  }
}
