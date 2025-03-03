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

  final List<String> _activityLevels = [
    "Sedentary",
    "Lightly Active",
    "Moderately Active",
    "Active",
    "Very Active"
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData?['name'] ?? '';
    _ageController.text = widget.userData?['age'] ?? '';
    _heightController.text = widget.userData?['height'] ?? '';
    _weightController.text = widget.userData?['weight'] ?? '';
    _selectedActivityLevel = widget.userData?['activityLevel'] ?? ''; // ✅ Fixed key
  }

  void _saveChanges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'activityLevel': _selectedActivityLevel, // ✅ Correctly saving activity level
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
              SizedBox(height: 10),

              // ✅ Dynamic Radio Buttons with Current Selection
              Column(
                children: _activityLevels.map((level) {
                  return RadioListTile<String>(
                    title: Text(level, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    value: level,
                    groupValue: _selectedActivityLevel, // ✅ Default value pre-selected
                    onChanged: (String? value) {
                      setState(() {
                        _selectedActivityLevel = value;
                      });
                    },
                    contentPadding: EdgeInsets.symmetric(vertical: 2), // Reduce padding
                  );
                }).toList(),
              ),

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
}
