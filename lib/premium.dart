import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ingilizce/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

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
  bool _isLoading = false;
  bool _isPurchasing = false;
  String? _errorMessage;

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

  Future<void> _loadProducts() async {
    try {
      const Set<String> _productIds = {'premiumsub'};

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        _showMessage("❌ Ürün bulunamadı: ${response.notFoundIDs}");
      }

      if (response.productDetails.isEmpty) {
        _showMessage("⚠️ Ürün listesi boş geldi!");
      } else {
        setState(() {
          _products = response.productDetails;
        });
        _showMessage("✅ Ürünler başarıyla yüklendi!");
        if (mounted && _products.isNotEmpty) {
          Future.delayed(Duration(milliseconds: 100), () {
            _showPurchaseDialog(context);
          });
        }
      }
    } catch (e) {
      _showMessage("🔥 Ürünleri yüklerken hata oluştu: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Satın Al")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _products.isEmpty
          ? const Center(child: Text("Satın alma seçenekleri yüklenemedi."))
          : Center(
        child: Text("Premium bilgileri yüklendi."),
      ),
    );
  }

  // 📌 **Premium Satın Alma Pop-up'ını Açma**
  void _showPurchaseDialog(BuildContext context) {
    final premiumProvider =
        Provider.of<PremiumProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF3E0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: const [
                          Icon(Icons.star, size: 48, color: Colors.amber),
                          SizedBox(height: 8),
                          Text(
                            "🚀 Premium Erişim",
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "✨ Premium ile şunlara sahip olursunuz:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: const [
                        ListTile(
                          leading: Icon(Icons.lock_open_rounded,
                              color: Colors.orange),
                          title: Text(
                              "Orta ve İleri Seviye kategorilere tam erişim"),
                        ),
                        ListTile(
                          leading: Icon(Icons.block, color: Colors.orange),
                          title: Text("Reklamsız kullanım"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "📅 Aylık sadece 29.99₺ - İptal edilmediği sürece her ay otomatik yenilenir.",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            launchUrl(Uri.parse(
                                'https://abyssinian-halloumi-863.notion.site/Privacy-Policy-for-Learning-English-Vocabulary-1af0f189dd88800eb6add6a4bef6c827?pvs=73'));
                          },
                          icon: const Icon(Icons.privacy_tip_outlined),
                          label: const Text("Gizlilik Politikası"),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            launchUrl(Uri.parse(
                                'https://abyssinian-halloumi-863.notion.site/Kullan-m-Ko-ullar-1ba0f189dd888086809dfeba15c953f5'));
                          },
                          icon: const Icon(Icons.description_outlined),
                          label: const Text("Kullanım Koşulları"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _isPurchasing
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  _isPurchasing = true;
                                });
                                await _purchasePremium(premiumProvider);
                                setState(() {
                                  _isPurchasing = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 6,
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text("Aylık 29.99₺ ile Premium Ol", style: TextStyle(color: Colors.white),),
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 📌 **Satın alma işlemlerini dinle ve doğrula**
  void _listenToPurchases() {
    _inAppPurchase.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase);
      }
    });
  }

  void _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _showMessage("⏳ İşlem bekleniyor");
        break;

      case PurchaseStatus.purchased:
        await _verifyPurchase(purchase);
        await _inAppPurchase.completePurchase(purchase); // Kritik!
        break;

      case PurchaseStatus.error:
        _showMessage("❌ Hata: ${purchase.error?.message}");
        setState(() => _isPurchasing = false);
        break;

      case PurchaseStatus.canceled:
        _showMessage("❌ İptal edildi");
        setState(() => _isPurchasing = false);
        break;

      case PurchaseStatus.restored:
        await _verifyPurchase(purchase);
        break;
    }
  }

  Future<void> _purchasePremium(PremiumProvider provider) async {
    if (_products.isEmpty) {
      _showMessage("⚠️ Ürünler yüklenemedi");
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      // ✅ Ürünü güvenli şekilde bul
      final product = _products.firstWhereOrNull((p) => p.id == 'premiumsub');

      if (product == null) {
        _showMessage("⚠️ Ürün bulunamadı");
        return;
      }

      final param = PurchaseParam(
        productDetails: product,
        applicationUserName: userId, // iOS için önemlidir
      );

      // ✅ Satın alma işlemi başlat
      await _inAppPurchase.buyNonConsumable(purchaseParam: param);

    } catch (e) {
      _showMessage("⚠️ Satın alma sırasında hata: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }


  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    if (userId == null) return;

    try {
      // 🔄 Kullanıcıya yükleniyor mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⏳ Satın alma doğrulanıyor...")),
      );

      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse('https://verifypurchase-dy53ebmesa-uc.a.run.app/verifyPurchase'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "userId": userId,
          "purchaseToken": Platform.isAndroid
              ? purchase.verificationData.serverVerificationData
              : purchase.verificationData.localVerificationData,
          "platform": Platform.isAndroid ? "android" : "ios",
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          print("✅ Satın alma doğrulandı!");

          await _firestore.collection("users").doc(userId).update({
            "isPremium": true,
            "subscriptionEnd": responseData['expiresDate'],
          });

          _checkSubscriptionStatus();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🎉 Premium aboneliğiniz aktif!")),
          );
        } else {
          print("❌ Satın alma doğrulanamadı.");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Satın alma doğrulanamadı! ${responseData['error']}")),
          );
        }
      } else {
        String errorMessage = "❌ Sunucu hatası: ${response.statusCode}";
        if (response.statusCode == 400) {
          errorMessage = "⚠️ Geçersiz istek. Lütfen tekrar deneyin.";
        } else if (response.statusCode == 500) {
          errorMessage = "🚨 Sunucu hatası! Daha sonra tekrar deneyin.";
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print("🔥 Hata: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Satın alma işlemi başarısız: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _checkSubscriptionStatus() async {
    final userDoc = await _firestore.collection("users").doc(userId).get();

    if (userDoc.exists) {
      final data = userDoc.data();
      final int? subscriptionEnd = data?['subscriptionEnd'];

      if (subscriptionEnd != null && subscriptionEnd > DateTime.now().millisecondsSinceEpoch) {
        Provider.of<PremiumProvider>(context, listen: false).setPremium(true);
      } else {
        Provider.of<PremiumProvider>(context, listen: false).setPremium(false);
      }
    }
  }
}
