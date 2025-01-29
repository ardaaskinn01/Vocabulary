import 'package:flutter/material.dart';
import 'category_screen.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kategoriler",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent, // Turuncu öncelikli renk
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            buildCategorySection(context, "Başlangıç Seviyesi", [
              buildCategoryCard(context, "Family Tree", "family tree"),
              buildCategoryCard(context, "Colors", "colors"),
            ]),
            buildCategorySection(context, "Orta Seviye", [
              // İlerleyen seviyeler için kartlar eklenebilir
            ]),
            buildCategorySection(context, "İleri Seviye", [
              // İlerleyen seviyeler için kartlar eklenebilir
            ]),
          ],
        ),
      ),
    );
  }

  Widget buildCategorySection(BuildContext context, String title, List<Widget> categoryCards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent, // Başlıkta turuncu renk
              letterSpacing: 1.5, // Başlıkları daha şık yapmak için harf aralığı
              shadows: [
                Shadow(
                  blurRadius: 7.0,
                  color: Colors.black,
                  offset: Offset(1.0, 2.0),
                ),
              ],
            ),
          ),
        ),
        Column(children: categoryCards),
      ],
    );
  }

  Widget buildCategoryCard(BuildContext context, String title, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(category: category),
          ),
        );
      },
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.orange[50], // Kartın rengi
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Colors.deepOrange, // Kart başlığında turuncu renk
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.deepOrange,
            size: 25,
          ),
        ),
      ),
    );
  }
}
