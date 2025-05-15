import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    TextEditingController servingController = TextEditingController(text: "1");

    return showDialog<double>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter the serving size",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  recipe["Name"] ?? "Selected Recipe",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Input Field
                TextField(
                  controller: servingController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Serving Size",
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        double serving = double.tryParse(servingController.text) ?? 1.0;
                        Navigator.pop(context, serving);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Log Meal", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
            const SizedBox(height: 5),
            Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterRecipes,
                  decoration: InputDecoration(
                    hintText: 'Search recipes',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterRecipes('');
                      },
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _filteredRecipes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      onTap: () async {
                        double? serving = await _showLogMealDialog(recipe);
                        if (serving != null) {
                          await _logRecipe(recipe, serving);
                          Navigator.pop(context, true);
                        }
                      },
                      child: Row(
                        children: [
                          // Recipe Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              recipe["Images"] ?? "",
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name and Calories
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe["Name"] ?? "Unnamed",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${recipe["Calories"]?.toString() ?? "0"} kcal per serving",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Plus Icon
                          Container(
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.add_circle_outline, size: 25, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
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
