import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:project/signUp/LoginPage.dart';
import 'package:project/signUp/QuestionnaireScreen.dart';
import '../models/custom_button.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePassword1 = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Instead of creating a user here, just pass the data to the questionnaire.
  void _goToQuestionnaire() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter an email and password.";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match.";
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

  // // Google Sign-Up integration.
  // void _signUpWithGoogle() async {
  //   final userCredential = await _authService.signInWithGoogle();
  //   if (userCredential == null) return;
  //   // If this is a new account created via Google, go to QuestionnaireScreen.
  //   if (userCredential.additionalUserInfo != null && userCredential.additionalUserInfo!.isNewUser) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => QuestionnaireScreen(
  //           email: userCredential.user!.email ?? "",
  //           password: "", // No password for Google sign in.
  //         ),
  //       ),
  //     );
  //   } else {
  //     // If the user already exists, you might navigate to LoginPage or HomeScreen.
  //     Navigator.pushReplacement(
  //         context, MaterialPageRoute(builder: (context) => LoginPage()));
  //   }
  // }

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
                const SizedBox(height: 15),

                // Confirm Password TextField
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(196, 196, 196, 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword1,
                    decoration: InputDecoration(
                      hintText: "Confirm your password",
                      hintStyle: TextStyle(
                          color: Colors.black.withAlpha((0.4 * 255).toInt())),
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword1 ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword1 = !_obscurePassword1;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: "Sign Up",
                      onPressed: _goToQuestionnaire,
                    )
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
                        text: "Log In",
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

                const SizedBox(height: 20),
                // // Divider with "OR"
                // _buildDividerWithText("OR"),
                // const SizedBox(height: 20),
                //
                // // Sign Up with Google Button
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton.icon(
                //     icon: Image.asset(
                //       'assets/googleLogo.png',
                //       height: 24,
                //       width: 24,
                //     ),
                //     label: const Text("Sign Up with Google"),
                //     onPressed: _signUpWithGoogle,
                //     style: ElevatedButton.styleFrom(
                //       foregroundColor: Colors.black,
                //       backgroundColor: Colors.white,
                //       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), // Button size
                //       side: BorderSide(color: Colors.grey.shade300),
                //     ),
                //   ),
                // ),

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
