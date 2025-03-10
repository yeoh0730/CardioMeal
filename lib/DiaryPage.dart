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

      newMeals[mealType] = List<Map<String, dynamic>>.from(mealData["foods"]);
    }

    setState(() {
      _selectedMeals = newMeals;
    });
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
                isToday
                    ? "Today"
                    : DateFormat('yyyy-MM-dd').format(_selectedDate), // Show "Today" if it's today's date
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.black),
                onPressed: _pickDate, // Open date picker
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMealSection('Breakfast', Colors.red),
          _buildMealSection('Lunch', Colors.orange),
          _buildMealSection('Dinner', Colors.teal),
          _buildMealSection('Snacks', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealTitle, Color color) {
    Map<String, double> mealNutrition = _calculateMealNutrition(mealTitle);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 5, height: 40, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(mealTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.red),
                    onPressed: () => _navigateToRecipeSelection(mealTitle),
                  ),
                ],
              ),
              ..._selectedMeals[mealTitle]!.map((recipe) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Text(recipe["name"], style: const TextStyle(fontSize: 14, color: Colors.black87)),
              )),
              if (_selectedMeals[mealTitle]!.isNotEmpty) const Divider(),
              if (_selectedMeals[mealTitle]!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Sodium: ${mealNutrition["Sodium"]!.toStringAsFixed(1)} mg", style: const TextStyle(color: Colors.grey)),
                      Text("Fat: ${mealNutrition["Fat"]!.toStringAsFixed(1)} g", style: const TextStyle(color: Colors.grey)),
                      Text("Carb: ${mealNutrition["Carbohydrates"]!.toStringAsFixed(1)} g", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
