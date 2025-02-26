import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/HomePage.dart';
import 'main.dart';

class QuestionnaireScreen extends StatefulWidget {
  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = "Male";
  List<String> _selectedDietaryPreferences = [];

  String _errorMessage = "";

  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietaryPreferences.contains(preference)) {
        _selectedDietaryPreferences.remove(preference);
      } else {
        _selectedDietaryPreferences.add(preference);
      }
    });
  }

  void _nextPage() {
    setState(() {
      _errorMessage = ""; // Reset error message before validation

      // Validation for each page
      if (_currentPage == 0 && _firstNameController.text.trim().isEmpty) {
        _errorMessage = "Please enter your first name.";
        return;
      }
      if (_currentPage == 1 && _ageController.text.trim().isEmpty) {
        _errorMessage = "Please enter your age.";
        return;
      }
      if (_currentPage == 2 && _gender.isEmpty) {
        _errorMessage = "Please select a gender.";
        return;
      }
      if (_currentPage == 3 && _selectedDietaryPreferences.isEmpty) {
        _errorMessage = "Please select at least one dietary preference.";
        return;
      }

      if (_currentPage < 3) {
        _currentPage++;
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      } else {
        _saveUserProfile();
      }
    });
  }

  void _saveUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": _firstNameController.text.trim(),
        "age": _ageController.text.trim(),
        "gender": _gender,
        "dietaryPreferences": _selectedDietaryPreferences, // Store list in Firestore
      }, SetOptions(merge: true));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Prevents keyboard overflow
      appBar: AppBar(
        title: Text("Complete Your Profile"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              setState(() {
                _currentPage--; // Move back a question
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              });
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
                _buildPage4(),
              ],
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // Page 1: First Name
  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 250),
            SizedBox(height: 20),
            Text("Welcome", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft, // Align text to the left
              child: Text(
                "What can we call you?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: "First Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 40),
            Center(child: ElevatedButton(onPressed: _nextPage, child: Text("Next")),),
          ],
        ),
      ),
    );
  }

  // Page 2: Age
  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How old are you?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            SizedBox(height: 20),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter your age",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 40),
            Center(child: ElevatedButton(onPressed: _nextPage, child: Text("Next")),),
          ],
        ),
      ),
    );
  }

  // Page 3: Gender
  Widget _buildPage3() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What is your gender?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _gender,
              items: ["Male", "Female", "Prefer not to say"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) => setState(() => _gender = value!),
            ),
            SizedBox(height: 40),
            Center(child: ElevatedButton(onPressed: _nextPage, child: Text("Next")),),
          ],
        ),
      ),
    );
  }

  // Page 4: Dietary Preferences (Fixed Overflow Issue)
  Widget _buildPage4() {
    return SingleChildScrollView( // Wrap content to allow scrolling
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Do you have any dietary preference(s)?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')
            ),
            SizedBox(height: 20),
            _buildCheckbox("None"),
            _buildCheckbox("Low Protein"),
            _buildCheckbox("Low Cholesterol"),
            _buildCheckbox("Lactose Free"),
            _buildCheckbox("Asian"),
            _buildCheckbox("Indian"),
            _buildCheckbox("European"),
            _buildCheckbox("Mexican"),
            SizedBox(height: 20),
            Center( // Center the button
              child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text("Finish")
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for creating checkboxes
  Widget _buildCheckbox(String title) {
    return CheckboxListTile(
      title: Text(title),
      value: _selectedDietaryPreferences.contains(title),
      onChanged: (bool? value) {
        _toggleDietaryPreference(title);
      },
    );
  }
}

