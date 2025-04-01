import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/custom_button.dart';

class SelectRecipesPage extends StatefulWidget {
  final String mealType; // Meal type (Breakfast, Lunch, etc.)
  final DateTime selectedDate; // Selected date

  const SelectRecipesPage({required this.mealType, required this.selectedDate});

  @override
  _SelectRecipesPageState createState() => _SelectRecipesPageState();
}

class _SelectRecipesPageState extends State<SelectRecipesPage> {
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _filteredRecipes = [];
  List<Map<String, dynamic>> _selectedRecipes = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('tastyRecipes').get();
    List<Map<String, dynamic>> fetchedRecipes =
    snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    setState(() {
      _recipes = fetchedRecipes;
      _filteredRecipes = fetchedRecipes;
    });
  }

  void _filterRecipes(String query) {
    setState(() {
      _filteredRecipes = _recipes
          .where((recipe) => recipe["Name"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleSelection(Map<String, dynamic> recipe) {
    setState(() {
      if (_selectedRecipes.contains(recipe)) {
        _selectedRecipes.remove(recipe);
      } else {
        _selectedRecipes.add(recipe);
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedRecipes.isEmpty) {
      Navigator.pop(context, false); // Return false if no selection
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String formattedDate = widget.selectedDate.toIso8601String().split("T")[0]; // YYYY-MM-DD format
    CollectionReference mealsRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("loggedMeals");

    // Compute total nutrition
    double totalCalories = 0, totalSodium = 0, totalCarbs = 0, totalFat = 0;

    List<Map<String, dynamic>> mealFoods = _selectedRecipes.map((recipe) {
      totalCalories += recipe["Calories"] ?? 0;
      totalSodium += recipe["SodiumContent"] ?? 0;
      totalCarbs += recipe["CarbohydrateContent"] ?? 0;
      totalFat += recipe["FatContent"] ?? 0;

      return {
        "name": recipe["Name"],
        "calories": recipe["Calories"] ?? 0,
        "sodium": recipe["SodiumContent"] ?? 0,
        "carbs": recipe["CarbohydrateContent"] ?? 0,
        "fat": recipe["FatContent"] ?? 0
      };
    }).toList();

    // Check if meal for the same date & meal type exists
    QuerySnapshot existingMeals = await mealsRef
        .where("date", isEqualTo: formattedDate)
        .where("mealType", isEqualTo: widget.mealType)
        .get();

    if (existingMeals.docs.isNotEmpty) {
      // Update existing meal
      DocumentReference mealDoc = existingMeals.docs.first.reference;
      await mealDoc.update({
        "foods": FieldValue.arrayUnion(mealFoods),
        "totalCalories": FieldValue.increment(totalCalories),
        "totalSodium": FieldValue.increment(totalSodium),
        "totalCarbs": FieldValue.increment(totalCarbs),
        "totalFat": FieldValue.increment(totalFat),
      });
    } else {
      // Add a new meal
      await mealsRef.add({
        "mealType": widget.mealType,
        "date": formattedDate,
        "foods": mealFoods,
        "totalCalories": totalCalories,
        "totalSodium": totalSodium,
        "totalCarbs": totalCarbs,
        "totalFat": totalFat,
      });
    }

    Navigator.pop(context, true); // Return true if selection added
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("Log Meals"),
          scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0, bottom: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(labelText: "Search Recipes"),
                onChanged: _filterRecipes,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _filteredRecipes[index];
                  return CheckboxListTile(
                    title: Text(recipe["Name"]),
                    value: _selectedRecipes.contains(recipe),
                    onChanged: (bool? selected) => _toggleSelection(recipe),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "Log Meals",
                onPressed: _confirmSelection,
              ),
            ),
          ],
        ),
      )
    );
  }
}
