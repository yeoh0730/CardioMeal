import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SignUpPage.dart';
import 'main.dart';
import 'models/custom_button.dart'; // Import the button component

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
                const Text("Welcome To CardioMeal", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("sign in to access your account.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w100)),
                const SizedBox(height: 40),

                // Email Input
                _buildInputField(_emailController, "Enter your email", Icons.email),
                const SizedBox(height: 15),

                // Password Input
                _buildPasswordInput(),
                const SizedBox(height: 30),

                // ✅ Reusable Login Button
                SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: "Log In",
                      onPressed: _signIn,
                    )
                ),

                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Don’t have an account? ",
                        style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                      ),
                      TextSpan(
                        text: "Sign Up",
                        style: const TextStyle(color: Colors.red),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Reusable Input Field
  Widget _buildInputField(TextEditingController controller, String hintText, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(196, 196, 196, 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black.withAlpha((0.4 * 255).toInt())),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  // ✅ Reusable Password Input Field
  Widget _buildPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(196, 196, 196, 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: "Password",
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
    );
  }
}
