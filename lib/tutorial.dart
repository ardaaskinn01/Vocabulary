import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  _TutorialScreenState createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> tutorialImages = [
    "assets/images/tutorial1.png",
    "assets/images/tutorial2.png",
    "assets/images/tutorial3.png",
    "assets/images/tutorial4.png",
    "assets/images/tutorial5.png",
    "assets/images/tutorial6.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutorial"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: tutorialImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(tutorialImages[index], fit: BoxFit.contain),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(tutorialImages.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10),
                width: _currentPage == index ? 16 : 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.orangeAccent : Colors.grey,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_currentPage == tutorialImages.length - 1) {
                  Navigator.pop(context);
                } else {
                  _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                }
              },
              child: Text(
                _currentPage == tutorialImages.length - 1 ? "Tamamla" : "İleri",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}