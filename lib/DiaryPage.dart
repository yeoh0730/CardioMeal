import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'SelectRecipesPage.dart';
import 'models/DashboardView.dart';
import 'models/custom_toggle_bar.dart';

class DiaryPage extends StatefulWidget {
  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  bool isLogMealSelected = true;
  DateTime _selectedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _selectedMeals = {
    "Breakfast": [],
    "Lunch": [],
    "Dinner": [],
    "Snacks": []
  };

  @override
  void initState() {
    super.initState();
    _fetchLoggedMeals();
  }

  Future<void> _fetchLoggedMeals() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("loggedMeals")
        .where("date", isEqualTo: formattedDate)
        .get();

    Map<String, List<Map<String, dynamic>>> newMeals = {
      "Breakfast": [],
      "Lunch": [],
      "Dinner": [],
      "Snacks": []
    };

    for (var doc in snapshot.docs) {
      Map<String, dynamic> mealData = doc.data() as Map<String, dynamic>;
      String mealType = mealData["mealType"];
      mealData['id'] = doc.id; // Store meal document ID for deletion

      newMeals[mealType] = List<Map<String, dynamic>>.from(mealData["foods"]);
    }

    setState(() {
      _selectedMeals = newMeals;
    });
  }

  Future<void> _deleteFood(String mealType, Map<String, dynamic> foodItem) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Find the meal document for the given meal type
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("loggedMeals")
        .where("date", isEqualTo: formattedDate)
        .where("mealType", isEqualTo: mealType)
        .get();

    if (snapshot.docs.isNotEmpty) {
      DocumentReference mealDoc = snapshot.docs.first.reference;

      // Remove only the selected food item
      await mealDoc.update({
        "foods": FieldValue.arrayRemove([foodItem])
      });

      _fetchLoggedMeals(); // Refresh UI after deletion
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _fetchLoggedMeals();
    }
  }

  Future<void> _navigateToRecipeSelection(String mealTitle) async {
    bool? mealAdded = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectRecipesPage(mealType: mealTitle, selectedDate: _selectedDate)),
    );

    if (mealAdded == true) {
      _fetchLoggedMeals();
    }
  }

  Map<String, double> _calculateMealNutrition(String mealTitle) {
    double totalCalories = 0, totalFat = 0, totalCarbs = 0, totalSodium = 0;

    for (var recipe in _selectedMeals[mealTitle]!) {
      totalCalories += recipe["calories"] ?? 0;
      totalFat += recipe["fat"] ?? 0;
      totalCarbs += recipe["carbs"] ?? 0;
      totalSodium += recipe["sodium"] ?? 0;
    }

    return {
      "Calories": totalCalories,
      "Fat": totalFat,
      "Carbohydrates": totalCarbs,
      "Sodium": totalSodium
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Diary',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: CustomToggleBar(
              isSelected: isLogMealSelected,
              onToggle: (bool isSelected) {
                setState(() {
                  isLogMealSelected = isSelected;
                });
              },
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: isLogMealSelected ? _buildLogMealView() : DashboardView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogMealView() {
    bool isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isToday ? "Today" : DateFormat('yyyy-MM-dd').format(_selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.black),
                onPressed: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMealSection('Breakfast', Colors.red),
          _buildMealSection('Lunch', Colors.orange),
          _buildMealSection('Dinner', Colors.indigo),
          _buildMealSection('Snacks', Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealTitle, Color color) {
    // Calculate macros for this meal
    Map<String, double> mealNutrition = _calculateMealNutrition(mealTitle);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // Wrap the Row in IntrinsicHeight
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Now valid with IntrinsicHeight
            children: [
              // Left color strip
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // Right side: meal info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mealTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.red),
                            onPressed: () => _navigateToRecipeSelection(mealTitle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Nutrition summary
                      Text(
                        "Total: ${mealNutrition["Calories"]} kcal | "
                            "Sodium: ${mealNutrition["Sodium"]} mg | "
                            "Fat: ${mealNutrition["Fat"]} g | "
                            "Carbs: ${mealNutrition["Carbohydrates"]} g",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),

                      // Only show a divider if there are items
                      if (_selectedMeals[mealTitle]!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                      ],

                      // Foods list
                      Column(
                        children: _selectedMeals[mealTitle]!.map((recipe) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe["name"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Calories: ${recipe["calories"]} kcal | "
                                            "Sodium: ${recipe["sodium"]} mg | "
                                            "Fat: ${recipe["fat"]} g | "
                                            "Carbs: ${recipe["carbs"]} g",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFood(mealTitle, recipe),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
