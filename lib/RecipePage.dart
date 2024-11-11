import 'package:flutter/material.dart';

class RecipePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Explore heart-healthy recipes tailored to your needs. Filter recipes by ingredients, meal type, or dietary restrictions to find the perfect dish.",
            style: TextStyle(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
