import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    "Low Protein",
    "Low Cholesterol",
    "Lactose Free",
    "Asian",
    "Indian",
    "European",
    "Mexican"
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

            // Generate checkboxes dynamically
            ..._dietaryOptions.map((preference) => CheckboxListTile(
              title: Text(preference),
              value: _selectedDietPreferences.contains(preference),
              onChanged: (value) {
                _toggleDietaryPreference(preference);
              },
            )),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveDietPreferences,
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
