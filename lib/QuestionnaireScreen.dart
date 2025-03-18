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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  final TextEditingController _bloodGlucoseController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();

  // State
  String? _gender;
  List<String> _selectedDietaryPreferences = [];
  String? _selectedActivityLevel;
  String _errorMessage = "";

  // Adjust this to your total number of pages/steps
  final int totalSteps = 7;

  // ======== NAVIGATION ========
  void _nextPage() {
    setState(() {
      _errorMessage = ""; // reset before validation

      // Basic validations for each page
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

      // Move to next or finish
      if (_currentPage < totalSteps - 1) {
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

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      });
    }
  }

  // ======== FIRESTORE SAVE ========
  void _saveUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Merge Basic User Profile
      await firestore.collection("users").doc(user.uid).set({
        "name": _firstNameController.text.trim(),
        "age": _ageController.text.trim(),
        "gender": _gender,
        "height": _heightController.text.trim(),
        "weight": _weightController.text.trim(),
        "dietaryPreferences": _selectedDietaryPreferences,
        "activityLevel": _selectedActivityLevel,
      }, SetOptions(merge: true));

      // Store Health Metrics in a Sub-Collection
      String timestamp = DateTime.now().toIso8601String();
      await firestore
          .collection("users")
          .doc(user.uid)
          .collection("healthMetrics")
          .doc(timestamp)
          .set({
        "cholesterol": _cholesterolController.text.trim(),
        "systolicBP": _systolicBPController.text.trim(),
        "diastolicBP": _diastolicBPController.text.trim(),
        "bloodGlucose": _bloodGlucoseController.text.trim(),
        "restingHeartRate": _heartRateController.text.trim(),
        "timestamp": timestamp,
      });

      print("✅ Health metrics saved with timestamp: $timestamp");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  // ======== DIETARY PREFERENCE HELPER ========
  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietaryPreferences.contains(preference)) {
        _selectedDietaryPreferences.remove(preference);
      } else {
        _selectedDietaryPreferences.add(preference);
      }
    });
  }

  // ======== TOP BAR ========
  Widget _buildTopBar() {
    // Calculate progress fraction
    final double progress = (_currentPage + 1) / totalSteps;

    return Column(
      children: [
        // Row with back arrow and step text
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Show back arrow if not on the first page
            if (_currentPage > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            else
            // If you want an empty space on the first page, you can do:
              const SizedBox(width: 48), // same width as IconButton for alignment

            Expanded(
              child: Center(
                child: Text(
                  "Step ${_currentPage + 1} of $totalSteps",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // If you want symmetrical space on the right side:
            const SizedBox(width: 48),
          ],
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: progress,
            // The active (filled) color
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color.fromRGBO(244, 67, 54, 1),
            ),
            // Optional background color for the unfilled portion
            backgroundColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  // ======== BOTTOM BAR (ONLY NEXT/FINISH BUTTON) ========
  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error message (if any)
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Next/Finish Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: _currentPage < totalSteps - 1 ? "Next" : "Finish",
              onPressed: _nextPage,
            ),
          ),
        ],
      ),
    );
  }

  // ======== BUILD PAGES ========
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CustomInputField(
            controller: _firstNameController,
            labelText: "What can we call you?",
            labelText1: "Enter your first name",
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CustomInputField(
            controller: _ageController,
            labelText: "How old are you?",
            labelText1: "Enter your age",
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What is your gender?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _gender,
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ),
            ),
            dropdownColor: Colors.white,
            hint: Text(
              "Select your gender",
              style: TextStyle(
                color: Colors.black.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            items: ["Male", "Female"].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() => _gender = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CustomInputField(
            controller: _heightController,
            labelText: "How tall are you?",
            labelText1: "Enter your height (cm)",
            keyboardType: TextInputType.number,
          ),
          CustomInputField(
            controller: _weightController,
            labelText: "How much do you weigh?",
            labelText1: "Enter your weight (kg)",
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPage5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What is your level of activity?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildActivityOption("Sedentary", "Little or no exercise, mostly sitting."),
          _buildActivityOption("Lightly Active", "Light exercise 1-3 days per week."),
          _buildActivityOption("Moderately Active", "Moderate exercise 3-5 days per week."),
          _buildActivityOption("Active", "Hard exercise 6-7 days per week."),
          _buildActivityOption("Very Active", "Very intense daily exercise or physical job."),
        ],
      ),
    );
  }

  Widget _buildPage6() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CustomInputField(
            controller: _cholesterolController,
            labelText: "What is your cholesterol level?",
            labelText1: "Enter your cholesterol level (mg/dl)",
            keyboardType: TextInputType.number,
          ),
          CustomInputField(
            controller: _systolicBPController,
            labelText: "What is your systolic blood pressure?",
            labelText1: "Enter your systolic blood pressure (mmHg)",
            keyboardType: TextInputType.number,
          ),
          CustomInputField(
            controller: _diastolicBPController,
            labelText: "What is your diastolic blood pressure?",
            labelText1: "Enter your diastolic blood pressure (mmHg)",
            keyboardType: TextInputType.number,
          ),
          CustomInputField(
            controller: _bloodGlucoseController,
            labelText: "What is your blood glucose level?",
            labelText1: "Enter your blood glucose level (mg/dl)",
            keyboardType: TextInputType.number,
          ),
          CustomInputField(
            controller: _heartRateController,
            labelText: "What is your resting heart rate?",
            labelText1: "Enter your resting heart rate (bpm)",
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPage7() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Do you have any dietary preference(s)?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildCheckbox("None"),
          _buildCheckbox("Alcohol-Free"),
          _buildCheckbox("Dairy-Free"),
          _buildCheckbox("Gluten-Free"),
          _buildCheckbox("Halal"),
          _buildCheckbox("Keto"),
          _buildCheckbox("High-Fiber"),
          _buildCheckbox("High-Protein"),
          _buildCheckbox("Low-Calorie"),
          _buildCheckbox("Low-Carb"),
          _buildCheckbox("Low-Fat"),
          _buildCheckbox("Low-Sugar"),
          _buildCheckbox("Vegan"),
          _buildCheckbox("Vegetarian"),
          _buildCheckbox("Asian"),
          _buildCheckbox("European"),
          _buildCheckbox("Filipino"),
          _buildCheckbox("French"),
          _buildCheckbox("Fusion"),
          _buildCheckbox("German"),
          _buildCheckbox("Hawaiian"),
          _buildCheckbox("Indian"),
          _buildCheckbox("Italian"),
          _buildCheckbox("Japanese"),
          _buildCheckbox("Korean"),
          _buildCheckbox("Mexican"),
          _buildCheckbox("Taiwanese"),
          _buildCheckbox("Thai"),
          _buildCheckbox("Vietnamese"),
        ],
      ),
    );
  }

  // ======== ACTIVITY RADIO TILES ========
  Widget _buildActivityOption(String title, String description) {
    return RadioListTile<String>(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
      value: title,
      groupValue: _selectedActivityLevel,
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _selectedActivityLevel = value);
        }
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
    );
  }

  // ======== CHECKBOX FOR DIETARY PREFERENCES ========
  Widget _buildCheckbox(String title) {
    return CheckboxListTile(
      title: Text(title),
      value: _selectedDietaryPreferences.contains(title),
      onChanged: (bool? value) {
        _toggleDietaryPreference(title);
      },
    );
  }

  // ======== MAIN BUILD ========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // We remove the AppBar to create our custom top layout
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back arrow, step text, and progress
            _buildTopBar(),

            // Expanded content for PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                  _buildPage5(),
                  _buildPage6(),
                  _buildPage7(),
                ],
              ),
            ),

            // Bottom bar with only Next/Finish
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}
