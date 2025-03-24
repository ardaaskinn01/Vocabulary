import 'dart:math';
import 'package:flutter/material.dart';

class ParentalGate extends StatefulWidget {
  final Function(bool success) onSuccess;

  ParentalGate({required this.onSuccess});

  @override
  _ParentalGateState createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  int userAnswer = 0;
  late String question;
  late int correctAnswer;

  final Random _random = Random();

  void generateRandomQuestion() {
    int num1 = _random.nextInt(10) + 1;
    int num2 = _random.nextInt(10) + 1;
    int operation = _random.nextInt(3); // Bölmeyi çıkardım, çünkü tam sayı zor olur.

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
      default:
        question = '$num1 + $num2';
        correctAnswer = num1 + num2;
    }
  }

  @override
  void initState() {
    super.initState();
    generateRandomQuestion();
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
                  widget.onSuccess(true);
                } else {
                  widget.onSuccess(false);
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
