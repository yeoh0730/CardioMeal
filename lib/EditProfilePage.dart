import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/custom_button.dart';
import 'services/daily_nutrient_calculation.dart';

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
    _fetchUserData();  // Fetch Firestore data from main user document
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        print("Fetched Firestore Data: ${userDoc.data()}");
        return userDoc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  void _saveChanges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Update the main user document with new profile data.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'activityLevel': _selectedActivityLevel,
        // Any other fields from profile can be updated here.
      });

      // 2. Refetch the updated main user document.
      DocumentSnapshot updatedUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic>? updatedUserData =
      updatedUserDoc.data() as Map<String, dynamic>?;

      if (updatedUserData != null) {
        // 3. Fetch the latest health metrics from the "healthMetrics" subcollection.
        QuerySnapshot healthMetricsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('healthMetrics')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (healthMetricsSnap.docs.isNotEmpty) {
          Map<String, dynamic> healthMetricsData =
          healthMetricsSnap.docs.first.data() as Map<String, dynamic>;
          // Merge health metrics into the main user data.
          updatedUserData.addAll({
            'cholesterol': healthMetricsData['cholesterol'],
            'systolicBP': healthMetricsData['systolicBP'],
            'diastolicBP': healthMetricsData['diastolicBP'],
            'bloodGlucose': healthMetricsData['bloodGlucose'],
            'heartRate': healthMetricsData['heartRate'],
          });
        }

        // 4. Calculate new nutrient limits using the merged data.
        Map<String, dynamic> newLimits =
        await calculateNutrientLimitsWithoutStoring(updatedUserData);

        // 5. Retrieve the latest nutrientHistory entry.
        QuerySnapshot lastNutrientSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('nutrientHistory')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        bool shouldUpdate = true;
        if (lastNutrientSnap.docs.isNotEmpty) {
          DocumentSnapshot lastDoc = lastNutrientSnap.docs.first;
          Map<String, dynamic>? lastData =
          lastDoc.data() as Map<String, dynamic>?;
          if (lastData != null) {
            // Compare new data with the last entry.
            shouldUpdate = nutrientDataHasChanged(lastData, newLimits);
          }
        }

        if (shouldUpdate) {
          // 6. Update risk category and store new nutrient limits.
          await storeNutrientLimits(user.uid, newLimits);
        } else {
          print("No changes in nutrient limits. Not storing a new document.");
        }
      }

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
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Failed to load data"));
          }

          var userData = snapshot.data!;
          _nameController.text = userData['name'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _heightController.text = userData['height']?.toString() ?? '';
          _weightController.text = userData['weight']?.toString() ?? '';
          _selectedActivityLevel = userData['activityLevel'] ?? 'Sedentary';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name")),
                  TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Age")),
                  TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: "Height (cm)")),
                  TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: "Weight (kg)")),
                  const SizedBox(height: 20),
                  const Text("Activity Level",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildActivityRadio("Sedentary",
                      "Little or no exercise, mostly sitting."),
                  _buildActivityRadio("Lightly Active",
                      "Light exercise 1-3 days per week."),
                  _buildActivityRadio("Moderately Active",
                      "Moderate exercise 3-5 days per week."),
                  _buildActivityRadio("Active",
                      "Hard exercise 6-7 days per week."),
                  _buildActivityRadio("Very Active",
                      "Very intense daily exercise or physical job."),
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
