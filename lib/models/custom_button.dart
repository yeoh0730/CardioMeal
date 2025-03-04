import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color.fromRGBO(244, 67, 54, 1), // Default Red color
    this.textColor = Colors.white, // Default White text
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor, // Button color
        foregroundColor: textColor, // Text color
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), // Button size
      ),
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }
}
