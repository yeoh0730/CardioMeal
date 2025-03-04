import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String labelText1;
  final TextInputType keyboardType;

  CustomInputField({
    required this.controller,
    required this.labelText,
    required this.labelText1,
    this.keyboardType = TextInputType.text,
  });

  @override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _isFocused = false; // Track focus state

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text left
      children: [
        Text(
          widget.labelText,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 15),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              color: Colors.black, // Text color when typing
            ),
            decoration: InputDecoration(
              labelText: widget.labelText1,
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: _isFocused ? Colors.black : Colors.black.withOpacity(0.4), // Opaque hint text
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2.0), // **Bold black border when focused**
                borderRadius: BorderRadius.circular(8.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 2.0), // **Default border**
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
}
