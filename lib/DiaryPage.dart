import 'package:flutter/material.dart';

class DiaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Log your daily food intake, monitor nutrient consumption, and track progress toward your health goals.",
            style: TextStyle(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
