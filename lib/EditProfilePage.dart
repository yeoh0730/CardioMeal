import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? _selectedActivityLevel; // Store the selected activity level

  @override
  void initState() {
    super.initState();
    _fetchUserData();  // ✅ Fetch Firestore data properly before setting values
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        print("Fetched Firestore Data: ${userDoc.data()}"); // Debugging output

        return userDoc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  void _saveChanges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'activityLevel': _selectedActivityLevel, // Ensure this key is correctly written
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(), // ✅ Wait for Firestore data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Failed to load data"));
          }

          // ✅ Set controllers only after data is loaded
          var userData = snapshot.data!;
          _nameController.text = userData['name'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _heightController.text = userData['height']?.toString() ?? '';
          _weightController.text = userData['weight']?.toString() ?? '';
          _selectedActivityLevel = userData['activityLevel'] ?? 'Sedentary';

          // print("Selected Activity Level from Firestore: $_selectedActivityLevel"); // Debugging

          return SingleChildScrollView(  // ✅ Wrap content to prevent overflow
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
                  TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Age")),
                  TextField(controller: _heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Height (cm)")),
                  TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Weight (kg)")),
                  const SizedBox(height: 20),

                  // Activity Level Section
                  const Text("Activity Level", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildActivityRadio("Sedentary", "Little or no exercise, mostly sitting."),
                  _buildActivityRadio("Lightly Active", "Light exercise 1-3 days per week."),
                  _buildActivityRadio("Moderately Active", "Moderate exercise 3-5 days per week."),
                  _buildActivityRadio("Active", "Hard exercise 6-7 days per week."),
                  _buildActivityRadio("Very Active", "Very intense daily exercise or physical job."),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            groupValue: _selectedActivityLevel, // ✅ This should now properly reflect Firestore data
            onChanged: (String? value) {
              setState(() {
                _selectedActivityLevel = value;
                // print("Updated Selected Activity Level: $_selectedActivityLevel"); // Debugging
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
