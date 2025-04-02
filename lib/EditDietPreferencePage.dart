import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/custom_button.dart';

class EditDietPreferencePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditDietPreferencePage({Key? key, required this.userData})
      : super(key: key);

  @override
  _EditDietPreferencePageState createState() => _EditDietPreferencePageState();
}

class _EditDietPreferencePageState extends State<EditDietPreferencePage> {
  // List to hold standard (checkbox) dietary preferences
  List<String> _selectedDietPreferences = [];
  // Controller for free-form dietary preferences
  late TextEditingController _freePreferenceController;

  // Predefined standard dietary options
  final List<String> _dietaryOptions = [
    "None",
    "Dairy-Free",
    "Gluten-Free",
    "High-Fiber",
    "High-Protein",
    "Low-Calorie",
    "Low-Carb",
    "Low-Fat",
    "Low-Sugar",
    "Vegan",
    "Vegetarian",
  ];

  @override
  void initState() {
    super.initState();
    // Initialize _selectedDietPreferences from Firestore data.
    _selectedDietPreferences =
    List<String>.from(widget.userData?['dietaryPreferences'] ?? []);
    // Separate free-form preferences: those NOT in _dietaryOptions.
    String freePrefs = _selectedDietPreferences
        .where((pref) => !_dietaryOptions.contains(pref))
        .join(", ");
    _freePreferenceController = TextEditingController(text: freePrefs);
  }

  // Toggle standard checkbox preferences.
  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietPreferences.contains(preference)) {
        // If this standard preference was already selected, unselect it.
        _selectedDietPreferences.remove(preference);
      } else {
        // 1) If user toggles any standard preference, remove all free-form items.
        _selectedDietPreferences.removeWhere((item) => !_dietaryOptions.contains(item));
        // 2) Clear the free-form text field.
        _freePreferenceController.clear();
        // 3) Add the newly selected preference.
        _selectedDietPreferences.add(preference);
      }
    });
  }

  // Save preferences: if any checkbox is selected, use those; otherwise, use free-form input.
  void _saveDietPreferences() async {
    // Parse free text: split by commas, trim each entry.
    final freeInput = _freePreferenceController.text.trim();
    List<String> freePrefs = [];
    if (freeInput.isNotEmpty) {
      freePrefs = freeInput.split(',').map((e) => e.trim()).toList();
    }

    // Use free input exclusively if it's non-empty; otherwise, use checkbox selections.
    List<String> combinedPrefs = freePrefs.isNotEmpty
        ? freePrefs
        : _selectedDietPreferences;

    // Remove duplicates.
    combinedPrefs = combinedPrefs.toSet().toList();

    // DEBUG: Print the final combined preferences.
    print("DEBUG: Final combinedPrefs = $combinedPrefs");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'dietaryPreferences': combinedPrefs,
      });

      Navigator.pop(context, true); // Return true to indicate update.
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe your preference in your own words:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _freePreferenceController,
              decoration: InputDecoration(
                hintText:
                "e.g., I prefer dairy-free dishes or meals that contain salmon.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              maxLines: null,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "Or select from the list below:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Wrap checkboxes in an Expanded SingleChildScrollView.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _dietaryOptions.map((preference) {
                    return CheckboxListTile(
                      title: Text(preference),
                      value: _selectedDietPreferences.contains(preference),
                      onChanged: (bool? value) {
                        _toggleDietaryPreference(preference);
                      },
                      activeColor: Colors.red,
                    );
                  }).toList(),
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
