import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  EditProfilePage({required this.userData});

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
    _nameController.text = widget.userData?['name'] ?? '';
    _ageController.text = widget.userData?['age'] ?? '';
    _heightController.text = widget.userData?['height'] ?? '';
    _weightController.text = widget.userData?['weight'] ?? '';
    _selectedActivityLevel = widget.userData?['activityLevel'] ?? ''; // Fixed key name
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
        title: Text("Edit Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Age")),
              TextField(controller: _heightController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Height (cm)")),
              TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Weight (kg)")),
              SizedBox(height: 20),

              // Display Current Activity Level
              Text("Activity Level", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildActivityRadio("Sedentary", "Little or no exercise, mostly sitting."),
              _buildActivityRadio("Lightly Active", "Light exercise 1-3 days per week."),
              _buildActivityRadio("Moderately Active", "Moderate exercise 3-5 days per week."),
              _buildActivityRadio("Active", "Hard exercise 6-7 days per week."),
              _buildActivityRadio("Very Active", "Very intense daily exercise or physical job."),

              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Radio Button Selection for Activity Level (Shows Current Selection)
  Widget _buildActivityRadio(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<String>(
            value: title,
            groupValue: _selectedActivityLevel, // Ensure this matches stored value
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
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
