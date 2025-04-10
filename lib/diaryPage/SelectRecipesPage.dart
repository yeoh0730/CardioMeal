import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/custom_button.dart';

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
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('recipes').get();
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
          .where((recipe) =>
          recipe["Name"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// Shows a dialog prompting the user to input a serving size.
  /// Returns the entered serving size, or null if canceled.
  Future<double?> _showLogMealDialog(Map<String, dynamic> recipe) async {
    TextEditingController servingController =
    TextEditingController(text: "1");
    double? result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Enter the serving size for ${recipe["Name"]}", style: TextStyle(fontSize: 20)),
          content: TextField(
            controller: servingController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Serving Size",
              hintText: "e.g., 1",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                double serving = double.tryParse(servingController.text) ?? 1.0;
                Navigator.pop(context, serving);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Log Meal", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return result;
  }

  /// Logs the recipe (with serving size) to Firestore.
  Future<void> _logRecipe(Map<String, dynamic> recipe, double servingSize) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String formattedDate =
    widget.selectedDate.toIso8601String().split("T")[0]; // YYYY-MM-DD
    CollectionReference mealsRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("loggedMeals");

    // Calculate nutrient totals based on serving size.
    double calories = (recipe["Calories"] ?? 0) * servingSize;
    double sodium = (recipe["SodiumContent"] ?? 0) * servingSize;
    double carbs = (recipe["CarbohydrateContent"] ?? 0) * servingSize;
    double fat = (recipe["FatContent"] ?? 0) * servingSize;

    // Prepare food item to store.
    Map<String, dynamic> foodItem = {
      "name": recipe["Name"],
      "calories": recipe["Calories"] ?? 0, // per serving nutrient info
      "sodium": recipe["SodiumContent"] ?? 0,
      "carbs": recipe["CarbohydrateContent"] ?? 0,
      "fat": recipe["FatContent"] ?? 0,
      "servingSize": servingSize,
    };

    // Check if a meal for the same date & meal type exists.
    QuerySnapshot existingMeals = await mealsRef
        .where("date", isEqualTo: formattedDate)
        .where("mealType", isEqualTo: widget.mealType)
        .get();

    if (existingMeals.docs.isNotEmpty) {
      DocumentReference mealDoc = existingMeals.docs.first.reference;
      await mealDoc.update({
        "foods": FieldValue.arrayUnion([foodItem]),
        "totalCalories": FieldValue.increment(calories),
        "totalSodium": FieldValue.increment(sodium),
        "totalCarbs": FieldValue.increment(carbs),
        "totalFat": FieldValue.increment(fat),
      });
    } else {
      await mealsRef.add({
        "mealType": widget.mealType,
        "date": formattedDate,
        "foods": [foodItem],
        "totalCalories": calories,
        "totalSodium": sodium,
        "totalCarbs": carbs,
        "totalFat": fat,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Log Meal"),
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding:
        const EdgeInsets.only(left: 16.0, right: 16.0, top: 0, bottom: 16.0),
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
                  return ListTile(
                    title: Text(recipe["Name"]),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      double? serving = await _showLogMealDialog(recipe);
                      if (serving != null) {
                        await _logRecipe(recipe, serving);
                        // Pop the SelectRecipesPage and return true so the DiaryPage can refresh.
                        Navigator.pop(context, true);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
