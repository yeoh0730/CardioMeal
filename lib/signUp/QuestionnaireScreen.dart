import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/custom_button.dart';
import '../models/custom_input_field.dart';
import '../services/daily_nutrient_calculation.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String email;
  final String password;

  // Accept email & password from sign-up page
  QuestionnaireScreen({required this.email, required this.password});

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  OverlayEntry? _activeTooltip;
  void _dismissTooltip() {
    _activeTooltip?.remove();
    _activeTooltip = null;
  }

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFocused = false; // Track focus state
  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  final TextEditingController _bloodGlucoseController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _freePreferenceController = TextEditingController();

  // State
  String? _gender;
  List<String> _selectedDietaryPreferences = [];
  String? _selectedActivityLevel;
  String _errorMessage = "";

  double selectedHeight = 160.0; // default starting value in cm
  double selectedWeight = 45.0;  // default starting value in kg
  int selectedAge = 40;

  // Adjust this to your total number of pages/steps
  final int totalSteps = 8;

  // ======== NAVIGATION ========
  void _nextPage() {
    setState(() {
      _errorMessage = ""; // reset before validation

      // Basic validations for each page
      if (_currentPage == 0 && _firstNameController.text.trim().isEmpty) {
        _errorMessage = "Please enter your first name.";
        return;
      }
      if (_currentPage == 2 && (_gender == null || _gender!.isEmpty)) {
        _errorMessage = "Please select your gender.";
        return;
      }
      if (_currentPage == 5 && (_selectedActivityLevel == null || _selectedActivityLevel!.isEmpty)) {
        _errorMessage = "Please select your level of activity.";
        return;
      }
      if (_currentPage == 6 && _cholesterolController.text.trim().isEmpty) {
        _errorMessage = "Please enter your cholesterol level.";
        return;
      }
      if (_currentPage == 6 && _systolicBPController.text.trim().isEmpty) {
        _errorMessage = "Please enter your systolic blood pressure.";
        return;
      }
      if (_currentPage == 6 && _diastolicBPController.text.trim().isEmpty) {
        _errorMessage = "Please enter your diastolic blood pressure.";
        return;
      }
      if (_currentPage == 6 && _bloodGlucoseController.text.trim().isEmpty) {
        _errorMessage = "Please enter your blood glucose level.";
        return;
      }
      if (_currentPage == 6 && _heartRateController.text.trim().isEmpty) {
        _errorMessage = "Please enter your resting heart rate.";
        return;
      }
      if (_currentPage == 7) {
        // Either the user must have at least one checkbox selected,
        // OR they must have typed something in the free-form field.
        if (_selectedDietaryPreferences.isEmpty && _freePreferenceController.text.trim().isEmpty) {
          _errorMessage = "Please enter or select at least one dietary preference.";
          return;
        }
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

  // ======== FIRESTORE SAVE & Nutrient Calculation ========
  void _saveUserProfile() async {
    try {
      // 1) Create user in Firebase Auth using the email/password from sign-up
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = "Failed to create user in Auth.";
        });
        return;
      }

      // If the user typed a free-form preference, add it to the list
      final customPref = _freePreferenceController.text.trim();
      if (customPref.isNotEmpty) {
        _selectedDietaryPreferences.add(customPref);
      }

      // (Optionally remove duplicates)
      _selectedDietaryPreferences = _selectedDietaryPreferences.toSet().toList();

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Save the basic user profile data
      await firestore.collection("users").doc(user.uid).set({
        "email": user.email,
        "createdAt": DateTime.now(),
        "name": _firstNameController.text.trim(),
        "age": selectedAge.toString(),
        "gender": _gender,
        'height': selectedHeight.toString(),
        'weight': selectedWeight.toString(),

        "dietaryPreferences": _selectedDietaryPreferences,
        "activityLevel": _selectedActivityLevel,
      }, SetOptions(merge: true));

      // Save each health metric in its own subcollection
      final timestamp = DateTime.now().toIso8601String();
      final serverTime = FieldValue.serverTimestamp();

      final metrics = {
        "Cholesterol": double.tryParse(_cholesterolController.text.trim()) ?? 0,
        "SystolicBP": double.tryParse(_systolicBPController.text.trim()) ?? 0,
        "DiastolicBP": double.tryParse(_diastolicBPController.text.trim()) ?? 0,
        "BloodGlucose": double.tryParse(_bloodGlucoseController.text.trim()) ?? 0,
        "HeartRate": double.tryParse(_heartRateController.text.trim()) ?? 0,
      };

      for (var entry in metrics.entries) {
        await firestore
            .collection("users")
            .doc(user.uid)
            .collection("${entry.key.toLowerCase()}Metrics")
            .doc(timestamp)
            .set({
          "value": entry.value,
          "timestamp": serverTime,
        });
      }

      final nutrientData = {
        'weight': selectedWeight.toString(),
        'height': selectedHeight.toString(),

        'age': selectedAge.toString(),
        'gender': _gender,
        'activityLevel': _selectedActivityLevel,
        'cholesterol': _cholesterolController.text.trim(),
        'systolicBP': _systolicBPController.text.trim(),
        'diastolicBP': _diastolicBPController.text.trim(),
        'bloodGlucose': _bloodGlucoseController.text.trim(),
        'heartRate': _heartRateController.text.trim(),
      };

      // Call the nutrient calculation function (from your profile_service.dart)
      await calculateAndStoreNutrientLimits(nutrientData);

      // 3) Navigate to Home
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));

    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Error creating user in Auth.";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    }
  }

  // ======== DIETARY PREFERENCE HELPER ========
  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietaryPreferences.contains(preference)) {
        _selectedDietaryPreferences.remove(preference);
      } else {
        _selectedDietaryPreferences.add(preference);
        _freePreferenceController.clear();
      }
    });
  }

  // ======== TOP BAR ========
  Widget _buildTopBar() {
    final double progress = (_currentPage + 1) / totalSteps;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (_currentPage == 0)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: const Color.fromRGBO(244, 67, 54, 1),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: const Color.fromRGBO(244, 67, 54, 1),
                onPressed: _previousPage,
              ),
            Expanded(
              child: Center(
                child: Text(
                  "Step ${_currentPage + 1} of $totalSteps",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: progress,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color.fromRGBO(244, 67, 54, 1),
            ),
            backgroundColor: Colors.grey[300],
          ),
        ),
      ],
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
      activeColor: Colors.red,
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _selectedActivityLevel = value);
        }
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
    );
  }

  Widget _buildCheckbox(String title, {String? infoText}) {
    final GlobalKey iconKey = GlobalKey();

    void _showTooltip() {
      final renderBox = iconKey.currentContext
          ?.findRenderObject() as RenderBox?;
      final overlay = Overlay
          .of(context)
          .context
          .findRenderObject() as RenderBox?;
      if (renderBox == null || overlay == null) return;

      final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

      _dismissTooltip(); // hide any previous tooltip

      _activeTooltip = OverlayEntry(
        builder: (context) =>
            Positioned(
              left: position.dx,
              top: position.dy + renderBox.size.height + 5,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxWidth: 260),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    infoText ?? "",
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
      );

      Overlay.of(context).insert(_activeTooltip!);
    }

    void _toggleTooltip() {
      if (_activeTooltip != null) {
        _dismissTooltip();
      } else {
        _showTooltip();
      }
    }

    return CheckboxListTile(
      activeColor: Colors.red,
      controlAffinity: ListTileControlAffinity.trailing,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (infoText != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              key: iconKey,
              onTap: _toggleTooltip,
              child: const Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
      value: _selectedDietaryPreferences.contains(title),
      onChanged: (bool? value) {
        setState(() {
          _toggleDietaryPreference(title);
          _dismissTooltip();
        });
      },
    );
  }

    Widget _buildGenderOption(String label, String imagePath, Color borderColor) {
    final bool isSelected = _gender == label;

    return GestureDetector(
      onTap: () => setState(() => _gender = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.red),
          ],
        ),
      ),
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
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: Color.fromRGBO(244, 67, 54, 1),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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

  Widget _buildQuestionPage({
    required String title,
    required String caption,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(caption, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What Would You Like Us to Call You?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: "Enter your first name",
              floatingLabelStyle: const TextStyle(
                color: Colors.red, // 🔴 This changes label color when focused
                fontWeight: FontWeight.w500,
              ),
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: _isFocused ? Colors.black : Colors.black.withAlpha((0.4 * 255).toInt()), // Opaque hint text
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder( // Red border when focused
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.red,
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder( // Default border when not focused
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 2.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildPage2() {
    int initialIndex = selectedAge - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "How Old Are You?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Your age helps us estimate your daily calorie and nutrient needs.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              height: 250,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 60,
                controller: FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (value) => setState(() => selectedAge = value + 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final age = index + 1;
                    return Center(
                      child: Text(
                        "$age",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: selectedAge == age ? FontWeight.bold : FontWeight.normal,
                          color: selectedAge == age ? Colors.red : Colors.grey,
                        ),
                      ),
                    );
                  },
                  childCount: 120,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage3() => _buildQuestionPage(
    title: "What is Your Gender?",
    caption: "This helps us better tailor your recommendations.",
    child: Column(
      children: [
        _buildGenderOption("Male", "assets/male_icon.png", Colors.blue),
        const SizedBox(height: 16),
        _buildGenderOption("Female", "assets/female_icon.png", Colors.pink),
      ],
    ),
  );

  Widget _buildPage4() {
    int initialIndex = (selectedHeight - 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "What is Your Height?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Your height is important to calculate your BMI for health analysis.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              height: 250,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 60,
                controller: FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (value) =>
                    setState(() => selectedHeight = 100 + value.toDouble()),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final height = 100 + index;
                    return Center(
                      child: Text(
                        "$height cm",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: selectedHeight.toInt() == height
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedHeight.toInt() == height
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    );
                  },
                  childCount: 121,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage5() {
    int initialIndex = (selectedWeight - 30).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "What is Your Weight?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Your weight is important to calculate your BMI for health analysis.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              height: 250,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 60,
                controller: FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (value) =>
                    setState(() => selectedWeight = 30 + value.toDouble()),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final weight = 30 + index;
                    return Center(
                      child: Text(
                        "$weight kg",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: selectedWeight.toInt() == weight
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedWeight.toInt() == weight
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    );
                  },
                  childCount: 121,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage6() => _buildQuestionPage(
    title: "What is Your Level of Activity?",
    caption: "We use this to estimate your daily calorie burn.",
    child: Column(
      children: [
        _buildActivityOption("Sedentary", "Little or no exercise, mostly sitting."),
        _buildActivityOption("Lightly Active", "Light exercise 1-3 days per week."),
        _buildActivityOption("Moderately Active", "Moderate exercise 3-5 days per week."),
        _buildActivityOption("Active", "Hard exercise 6-7 days per week."),
        _buildActivityOption("Very Active", "Very intense daily exercise or physical job."),
      ],
    ),
  );

  Widget _buildPage7() => _buildQuestionPage(
    title: "Tell Us About Your Health",
    caption: "These values help us assess your heart health and set nutrition goals for your personalise recommendations.",
    child: Column(
      children: [
        CustomInputField(
          controller: _cholesterolController,
          labelText: "Cholesterol Level",
          labelText1: "Enter your cholesterol (mg/dl)",
          keyboardType: TextInputType.number,
        ),
        CustomInputField(
          controller: _systolicBPController,
          labelText: "Systolic Blood Pressure",
          labelText1: "Enter your systolic BP (mmHg)",
          keyboardType: TextInputType.number,
        ),
        CustomInputField(
          controller: _diastolicBPController,
          labelText: "Diastolic Blood Pressure",
          labelText1: "Enter your diastolic BP (mmHg)",
          keyboardType: TextInputType.number,
        ),
        CustomInputField(
          controller: _bloodGlucoseController,
          labelText: "Blood Glucose Level",
          labelText1: "Enter your glucose (mg/dl)",
          keyboardType: TextInputType.number,
        ),
        CustomInputField(
          controller: _heartRateController,
          labelText: "Resting Heart Rate",
          labelText1: "Enter your resting heart rate (bpm)",
          keyboardType: TextInputType.number,
        ),
      ],
    ),
  );

  Widget _buildPage8() => _buildQuestionPage(
    title: "Do You Have Any Dietary Preference(s)?",
    caption: "We use this to recommend recipes that match your preferences and dietary needs.",
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Describe in your own words:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _freePreferenceController,
          maxLines: null,
          decoration: InputDecoration(
            hintText: "e.g., I prefer dairy-free dishes or meals that contain salmon.",
            hintStyle: TextStyle(color: Colors.grey.shade500),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Or select from the list below:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        _buildCheckbox("None"),
        _buildCheckbox("Dairy-Free"),
        _buildCheckbox("Gluten-Free"),
        _buildCheckbox("High-Fiber"),
        _buildCheckbox("High-Protein"),
        _buildCheckbox("Low-Calorie"),
        _buildCheckbox("Low-Carb"),
        _buildCheckbox("Low-Fat"),
        _buildCheckbox("Low-Sugar"),
        _buildCheckbox("Vegan"),
        _buildCheckbox("Vegetarian"),
      ],
    ),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(), _buildPage2(), _buildPage3(), _buildPage4(),
                  _buildPage5(), _buildPage6(), _buildPage7(), _buildPage8(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}

