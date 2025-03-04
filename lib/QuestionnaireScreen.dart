import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'models/custom_button.dart';
import 'models/custom_input_field.dart';

class QuestionnaireScreen extends StatefulWidget {
  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  final TextEditingController _bloodGlucoseController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  String? _gender;
  List<String> _selectedDietaryPreferences = [];
  String? _selectedActivityLevel;

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
      if (_currentPage == 2 && (_gender == null || _gender!.isEmpty)) {
        _errorMessage = "Please select a gender.";
        return;
      }
      if (_currentPage == 3 && _heightController.text.trim().isEmpty) {
        _errorMessage = "Please enter your height.";
        return;
      }
      if (_currentPage == 3 && _weightController.text.trim().isEmpty) {
        _errorMessage = "Please enter your weight.";
        return;
      }
      if (_currentPage == 4 && (_selectedActivityLevel == null || _selectedActivityLevel!.isEmpty)) {
        _errorMessage = "Please select your level of activity.";
        return;
      }
      if (_currentPage == 5 && _cholesterolController.text.trim().isEmpty) {
        _errorMessage = "Please enter your cholesterol level.";
        return;
      }
      if (_currentPage == 5 && _systolicBPController.text.trim().isEmpty) {
        _errorMessage = "Please enter your systolic blood pressure.";
        return;
      }
      if (_currentPage == 5 && _diastolicBPController.text.trim().isEmpty) {
        _errorMessage = "Please enter your diastolic blood pressure.";
        return;
      }
      if (_currentPage == 5 && _bloodGlucoseController.text.trim().isEmpty) {
        _errorMessage = "Please enter your blood glucose level.";
        return;
      }
      if (_currentPage == 5 && _heartRateController.text.trim().isEmpty) {
        _errorMessage = "Please enter your resting heart rate.";
        return;
      }
      if (_currentPage == 6 && _selectedDietaryPreferences.isEmpty) {
        _errorMessage = "Please select at least one dietary preference.";
        return;
      }

      if (_currentPage < 6) {
        _currentPage++;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
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
        "height": _heightController.text.trim(),
        "weight": _weightController.text.trim(),
        "cholesterol": _cholesterolController.text.trim(),
        "systolicBP": _systolicBPController.text.trim(),
        "diastolicBP": _diastolicBPController.text.trim(),
        "bloodGlucose": _bloodGlucoseController.text.trim(),
        "restingHeartRate": _heartRateController.text.trim(),
        "dietaryPreferences": _selectedDietaryPreferences, // Store list in Firestore
        "activityLevel": _selectedActivityLevel, // Store list in Firestore
      }, SetOptions(merge: true));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Prevents keyboard overflow
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Complete Your Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              setState(() {
                _currentPage--;
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
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
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
                _buildPage4(),
                _buildPage5(), // Activity Level Page
                _buildPage6(),
                _buildPage7(),
              ],
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // Page 1: First Name
  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomInputField(controller: _firstNameController, labelText: "What can we call you?", labelText1: "Enter your first name"),
            Center(child: CustomButton(text: "Next", onPressed: _nextPage)),
          ],
        ),
      ),
    );
  }

  // Page 2: Age
  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomInputField(controller: _ageController, labelText: "How old are you?", labelText1: "Enter your age", keyboardType: TextInputType.number),
            Center(child: CustomButton(text: "Next", onPressed: _nextPage)),
          ],
        ),
      ),
    );
  }

  // Page 3: Gender
  Widget _buildPage3() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What is your gender?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _gender, // Initially null, so hint text will show
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
              dropdownColor: Colors.white, // Ensure the dropdown background is white
              hint: Text(
                "Select your gender",
                style: TextStyle(color: Colors.black.withAlpha((0.4 * 255).toInt())), // Lighter hint text
              ),
              items: ["Male", "Female"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 30),
            Center(child: CustomButton(text: "Next", onPressed: _nextPage)),
          ],
        ),
      ),
    );
  }

  // Page 4: Height and Weight
  Widget _buildPage4() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomInputField(controller: _heightController, labelText: "How tall are you?", labelText1: "Enter your height (cm)", keyboardType: TextInputType.number),
            CustomInputField(controller: _weightController, labelText: "How much do you weigh?", labelText1: "Enter your weight (kg)", keyboardType: TextInputType.number),
            Center(child: CustomButton(text: "Next", onPressed: _nextPage)),
          ],
        ),
      ),
    );
  }

  // ✅ Page 5: Activity Level with Radio Buttons & Descriptions
  Widget _buildPage5() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What is your level of activity?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _buildActivityOption("Sedentary", "Little or no exercise, mostly sitting."),
            _buildActivityOption("Lightly Active", "Light exercise 1-3 days per week."),
            _buildActivityOption("Moderately Active", "Moderate exercise 3-5 days per week."),
            _buildActivityOption("Active", "Hard exercise 6-7 days per week."),
            _buildActivityOption("Very Active", "Very intense daily exercise or physical job."),

            const SizedBox(height: 20),
            Center(child: CustomButton(text: "Next", onPressed: _nextPage)),
          ],
        ),
      ),
    );
  }

  // Page 6: Health metrics
  Widget _buildPage6() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomInputField(controller: _cholesterolController, labelText: "What is your cholesterol level?", labelText1: "Enter your cholesterol level (mg/dl)", keyboardType: TextInputType.number),
            CustomInputField(controller: _systolicBPController, labelText: "What is your systolic blood pressure?", labelText1: "Enter your systolic blood pressure (mmHg)", keyboardType: TextInputType.number),
            CustomInputField(controller: _diastolicBPController, labelText: "What is your diastolic blood pressure?", labelText1: "Enter your diastolic blood pressure (mmHg)", keyboardType: TextInputType.number),
            CustomInputField(controller: _bloodGlucoseController, labelText: "What is your blood glucose level?", labelText1: "Enter your blood glucose level (mg/dl)", keyboardType: TextInputType.number),
            CustomInputField(controller: _heartRateController, labelText: "What is your resting heart rate?", labelText1: "Enter your resting heart rate (bpm)", keyboardType: TextInputType.number),
            Center(child: CustomButton(text: "Next", onPressed: _nextPage)),
          ],
        ),
      ),
    );
  }

  // Page 7: Dietary Preferences (Fixed Overflow Issue)
  Widget _buildPage7() {
    return SingleChildScrollView( // Wrap content to allow scrolling
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Do you have any dietary preference(s)?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,)
            ),
            const SizedBox(height: 20),
            _buildCheckbox("None"),
            _buildCheckbox("Low Protein"),
            _buildCheckbox("Low Cholesterol"),
            _buildCheckbox("Lactose Free"),
            _buildCheckbox("Asian"),
            _buildCheckbox("Indian"),
            _buildCheckbox("European"),
            _buildCheckbox("Mexican"),
            const SizedBox(height: 20),
            Center(child: CustomButton(text: "Finish", onPressed: _nextPage)),
          ],
        ),
      ),
    );
  }


  // Radio Button Selection for Activity Level
  Widget _buildActivityOption(String title, String description) {
    return RadioListTile<String>(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to left
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)), // Activity Level
          const SizedBox(height: 4), // Small spacing
          Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)), // Description
        ],
      ),
      value: title,
      groupValue: _selectedActivityLevel,
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedActivityLevel = value; // Store selected value
          });
        }
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 2), // Reduce padding
    );
  }

  // Checkbox Selection for Dietary Preferences
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


