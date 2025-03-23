import 'dart:math';
import 'package:flutter/material.dart';

class ParentalGate extends StatefulWidget {
  final Function onSuccess;

  ParentalGate({required this.onSuccess});

  @override
  _ParentalGateState createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  int userAnswer = 0;
  late String question;
  late int correctAnswer;

  final Random _random = Random();

  // 20 tane farklı matematik sorusu oluşturacak fonksiyon
  void generateRandomQuestion() {
    // Rastgele 2 sayı seç
    int num1 = _random.nextInt(10) + 1; // 1 ile 10 arasında
    int num2 = _random.nextInt(10) + 1; // 1 ile 10 arasında
    int operation = _random.nextInt(4); // 4 farklı işlem

    switch (operation) {
      case 0:
        question = '$num1 + $num2';
        correctAnswer = num1 + num2;
        break;
      case 1:
        question = '$num1 - $num2';
        correctAnswer = num1 - num2;
        break;
      case 2:
        question = '$num1 * $num2';
        correctAnswer = num1 * num2;
        break;
      case 3:
        question = '$num1 / $num2';
        correctAnswer = (num1 / num2).toInt(); // Tam sayı olmasını sağla
        break;
      default:
        question = '$num1 + $num2';
        correctAnswer = num1 + num2;
    }
  }

  @override
  void initState() {
    super.initState();
    generateRandomQuestion(); // İlk soruyu oluştur
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Parental Gate')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Solve this puzzle to continue:'),
            Text(question, style: TextStyle(fontSize: 24)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    userAnswer = int.tryParse(value) ?? 0;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Your Answer',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (userAnswer == correctAnswer) {
                  widget.onSuccess(); // Başarılı ise, onSuccess fonksiyonunu çağır
                } else {
                  // Yanlış cevap verildiğinde
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Incorrect Answer'),
                        content: Text('Try again!'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() {
                                generateRandomQuestion(); // Yeni soru oluştur
                              });
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }
}
