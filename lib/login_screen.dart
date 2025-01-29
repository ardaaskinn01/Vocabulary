import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    String username = _emailController.text.trim();
    String email = "$username@example.com";
    String password = _passwordController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Giriş başarısız: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı adı veya şifre boş bırakılamaz.")),
      );
    }
  }

  void _showRegisterDialog() {
    final TextEditingController registerNameController =
    TextEditingController();
    final TextEditingController registerEmailController =
    TextEditingController();
    final TextEditingController registerPasswordController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Kayıt Ol"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: registerNameController,
              decoration: const InputDecoration(
                labelText: "İsim",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: registerEmailController,
              decoration: const InputDecoration(
                labelText: "Kullanıcı Adı",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: registerPasswordController,
              decoration: const InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String name = registerNameController.text.trim();
              String username = registerEmailController.text.trim();
              String password = registerPasswordController.text.trim();

              if (name.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
                try {
                  String email = "$username@example.com";
                  // Firebase Auth ile kullanıcı oluşturma
                  UserCredential userCredential =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  // Firestore'a kullanıcıyı ekleme
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(userCredential.user!.uid)
                      .set({
                    "name": name,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  print("Kayıt başarılı ve Firestore'a eklendi!");
                  Navigator.pop(context); // Pop-up kapatılır.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kayıt başarılı!")),
                  );
                } catch (e) {
                  print("Kayıt başarısız: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Kayıt başarısız: $e")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                      Text("İsim, kullanıcı adı veya şifre boş bırakılamaz.")),
                );
              }
            },
            child: const Text("Kayıt Ol"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/bg.jpg",
              height: MediaQuery.of(context).size.height * 0.4, // Üst kısma yerleşim
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Hoş Geldiniz",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Kullanıcı Adı",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.account_circle_sharp),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Şifre",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Giriş Yap",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _showRegisterDialog,
                      child: const Text(
                        "Hesabınız yok mu? Kayıt olun.",
                        style: TextStyle(color: Colors.deepPurple, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
