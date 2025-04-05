import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_button.dart';
import '../services/daily_nutrient_calculation.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _selectedActivityLevel; // store the selected activity level
  bool _isLoading = true;         // track if we are still fetching data

  @override
  void initState() {
    super.initState();
    _loadUserData(); // fetch Firestore data once in initState
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // set text fields and radio selection once
        _nameController.text = userData['name'] ?? '';
        _ageController.text = userData['age']?.toString() ?? '';
        _heightController.text = userData['height']?.toString() ?? '';
        _weightController.text = userData['weight']?.toString() ?? '';
        _selectedActivityLevel = userData['activityLevel'] ?? 'Sedentary';
      }
    } catch (e) {
      print("Error loading user data: $e");
    }

    // done loading
    setState(() {
      _isLoading = false;
    });
  }

  void _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Update the main user document with new profile data.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'age': _ageController.text.trim(),
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'activityLevel': _selectedActivityLevel,
      // Any other fields from profile can be updated here.
    });

    // 2. (Optionally) recalculate nutrient limits, etc.
    // ... same logic as before ...

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // If still loading from Firestore, show spinner
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Edit Profile"),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    // Otherwise, build your form with the local data
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Age"),
              ),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Height (cm)"),
              ),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Weight (kg)"),
              ),
              const SizedBox(height: 20),

              const Text("Activity Level",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildActivityRadio("Sedentary", "Little or no exercise, mostly sitting."),
              _buildActivityRadio("Lightly Active", "Light exercise 1-3 days per week."),
              _buildActivityRadio("Moderately Active", "Moderate exercise 3-5 days per week."),
              _buildActivityRadio("Active", "Hard exercise 6-7 days per week."),
              _buildActivityRadio("Very Active", "Very intense daily exercise or physical job."),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: "Save Changes",
                  onPressed: _saveChanges,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityRadio(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<String>(
            value: title,
            groupValue: _selectedActivityLevel,
            activeColor: Colors.red,
            onChanged: (String? value) {
              setState(() {
                _selectedActivityLevel = value;
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
