import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/custom_button.dart';

class EditDietPreferencePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditDietPreferencePage({required this.userData});

  @override
  _EditDietPreferencePageState createState() => _EditDietPreferencePageState();
}

class _EditDietPreferencePageState extends State<EditDietPreferencePage> {
  List<String> _selectedDietPreferences = [];

  final List<String> _dietaryOptions = [
    "None",
    // "Alcohol-Free",
    "Dairy-Free",
    "Gluten-Free",
    // "Halal",
    // "Keto",
    "High-Fiber",
    "High-Protein",
    "Low-Calorie",
    "Low-Carb",
    "Low-Fat",
    "Low-Sugar",
    "Vegan",
    "Vegetarian",
    // "Asian",
    // "European",
    // // "Filipino",
    // // "French",
    // "Fusion",
    // // "German",
    // // "Hawaiian",
    // // "Indian",
    // "Italian",
    // // "Japanese",
    // // "Korean",
    // // "Mexican",
    // // "Taiwanese",
    // // "Thai",
    // // "Vietnamese"
  ];

  @override
  void initState() {
    super.initState();
    _selectedDietPreferences = List<String>.from(widget.userData?['dietaryPreferences'] ?? []);
  }

  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietPreferences.contains(preference)) {
        _selectedDietPreferences.remove(preference);
      } else {
        _selectedDietPreferences.add(preference);
      }
    });
  }

  void _saveDietPreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'dietaryPreferences': _selectedDietPreferences,
      });

      Navigator.pop(context, true);  // ✅ Return true to indicate update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Diet Preferences"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select your dietary preferences:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // ✅ Wrap checkboxes inside SingleChildScrollView to make it scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _dietaryOptions.map((preference) => CheckboxListTile(
                    title: Text(preference),
                    value: _selectedDietPreferences.contains(preference),
                    onChanged: (value) {
                      _toggleDietaryPreference(preference);
                    },
                    activeColor: Colors.red,
                  )).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "Save Changes",
                onPressed: _saveDietPreferences,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
