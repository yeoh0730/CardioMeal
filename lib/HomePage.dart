import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Welcome to CardioMeal! Track your health metrics, log meals, and receive personalized meal recommendations to help you maintain a heart-healthy lifestyle.",
            style: TextStyle(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
