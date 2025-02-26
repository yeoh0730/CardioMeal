import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/HomePage.dart';
import 'SignUpPage.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscurePassword = true;
  String _errorMessage = '';

  void _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "An error occurred";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Login')),
      resizeToAvoidBottomInset: true, // Prevents overflow when keyboard appears
      body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', width: 180),
                  SizedBox(height: 20),
                  Text("Welcome To CardioMeal", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,)),
                  SizedBox(height: 5),
                  Text("sign in to access your account.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w100,)),
                  SizedBox(height: 40),

                  // Email TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(196, 196, 196, 0.2), // Light grey background
                      borderRadius: BorderRadius.circular(15), // Rounded corners
                    ),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.4), // Make text slightly invisible
                        ),
                        prefixIcon: Icon(Icons.email, color: Colors.grey), // Email icon
                        border: InputBorder.none, // Remove default border
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  // Password TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(196, 196, 196, 0.2), // Light grey background
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.4), // Make text slightly invisible
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.grey), // Lock icon
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
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(244, 67, 54, 1), // Change button color
                      foregroundColor: Colors.white, // Change text color
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12), // Button size
                      // shape: RoundedRectangleBorder( // Rounded corners
                      //   borderRadius: BorderRadius.circular(15),
                      // )
                    ),
                    child: Text('Login', style: TextStyle(color: Colors.white),)
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don’t have an account? ",
                          style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                        ),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                          },
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          )
      )
    );
  }
}
