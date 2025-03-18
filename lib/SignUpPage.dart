import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/LoginPage.dart';
import 'package:project/QuestionnaireScreen.dart';
import 'models/custom_button.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Instead of creating a user here, just pass the data to the questionnaire.
  void _goToQuestionnaire() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter an email and password.";
      });
      return;
    }

    // Navigate to questionnaire, passing email & password
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuestionnaireScreen(
              email: email,
              password: password,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 180),
                const SizedBox(height: 20),
                const Text("Get Started", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("by creating a free account.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w100)),
                const SizedBox(height: 40),

                // Email TextField
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(196, 196, 196, 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      hintStyle: TextStyle(color: Colors.black.withAlpha((0.4 * 255).toInt())),
                      prefixIcon: const Icon(Icons.email, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Password TextField
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(196, 196, 196, 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Create a password",
                      hintStyle: TextStyle(color: Colors.black.withAlpha((0.4 * 255).toInt())),
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                  text: "Sign Up",
                  onPressed: _goToQuestionnaire,
                ),
                const SizedBox(height: 8),

                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                      ),
                      TextSpan(
                        text: "Login",
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                        },
                      ),
                    ],
                  ),
                ),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
