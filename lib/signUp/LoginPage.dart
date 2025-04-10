import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SignUpPage.dart';
import '../main.dart';
import '../models/custom_button.dart';
import '../services/auth_service.dart';
import 'QuestionnaireScreen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscurePassword = true;
  String _errorMessage = '';

  // Email/Password Sign-In
  void _signInWithEmail() async {
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

  // // Google Sign-In
  // void _signInWithGoogle() async {
  //   final userCredential = await _authService.signInWithGoogle();
  //   if (userCredential == null) return;
  //
  //   // If this is a new account, navigate to the questionnaire.
  //   if (userCredential.additionalUserInfo != null &&
  //       userCredential.additionalUserInfo!.isNewUser) {
  //     Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //             builder: (context) => QuestionnaireScreen(
  //               email: userCredential.user!.email ?? "",
  //               password: "", // For Google users, password isn't set.
  //             )));
  //   } else {
  //     Navigator.pushReplacement(
  //         context, MaterialPageRoute(builder: (context) => HomeScreen()));
  //   }
  // }

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

  // Divider with "OR"
  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: Colors.grey.shade300,
            endIndent: 8,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: Colors.grey.shade300,
            indent: 8,
          ),
        ),
      ],
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
                      onPressed: _signInWithEmail,
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

                const SizedBox(height: 20),
                // // Divider with "OR"
                // _buildDividerWithText("OR"),
                // const SizedBox(height: 20),
                //
                // // Google Sign-In Button
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton.icon(
                //     icon: Image.asset(
                //       'assets/googleLogo.png',
                //       height: 24,
                //       width: 24,
                //     ),
                //     label: const Text("Sign In with Google"),
                //     onPressed: _signInWithGoogle,
                //     style: ElevatedButton.styleFrom(
                //       foregroundColor: Colors.black,
                //       backgroundColor: Colors.white,
                //       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), // Button size
                //       side: BorderSide(color: Colors.grey.shade300),
                //     ),
                //   ),
                // ),

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
}
