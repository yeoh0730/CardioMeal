import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'SelectRecipesPage.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class DiaryPage extends StatefulWidget {
  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
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
      mealData['id'] = doc.id;

      newMeals[mealType] = List<Map<String, dynamic>>.from(mealData["foods"] ?? []);
    }

    setState(() {
      _selectedMeals = newMeals;
    });
  }

  Future<void> _deleteFood(String mealType, Map<String, dynamic> foodItem) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("loggedMeals")
        .where("date", isEqualTo: formattedDate)
        .where("mealType", isEqualTo: mealType)
        .get();

    if (snapshot.docs.isNotEmpty) {
      DocumentReference mealDoc = snapshot.docs.first.reference;
      await mealDoc.update({
        "foods": FieldValue.arrayRemove([foodItem])
      });
      _fetchLoggedMeals();
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
      MaterialPageRoute(
        builder: (context) => SelectRecipesPage(
          mealType: mealTitle,
          selectedDate: _selectedDate,
        ),
      ),
    );
    if (mealAdded == true) {
      _fetchLoggedMeals();
    }
  }

  /// Calculate macros for a given meal
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

  /// Example daily goal placeholders
  final double dailyGoal = 1618; // In a real app, fetch from user profile
  final double consumed = 0;     // Placeholder
  double get left => (dailyGoal - consumed).clamp(0, dailyGoal);

  /// Build top "Daily Goal" portion with a larger ring + macros
  Widget _buildDailyGoalSection() {
    // We'll wrap this entire design in a container with a shadow
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Slight shadow to make it pop
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Larger circular indicator for "calories left"
          // We can use a CircularPercentIndicator or our own approach
          // Here, let's use the percent_indicator package for a nice ring
          CircularPercentIndicator(
            radius: 60, // bigger radius
            lineWidth: 12, // thicker ring
            percent: (consumed / dailyGoal).clamp(0, 1),
            backgroundColor: Colors.grey[200]!,
            progressColor: Colors.green,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  left.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text("calories left", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Macros row: Carbs, Sodium, Fat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Carbs
              Column(
                children: const [
                  Text(
                    "Carbs",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text("0/192g", style: TextStyle(fontSize: 14)),
                ],
              ),
              // Sodium
              Column(
                children: const [
                  Text(
                    "Sodium",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text("0/99g", style: TextStyle(fontSize: 14)),
                ],
              ),
              // Fat
              Column(
                children: const [
                  Text(
                    "Fat",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text("0/45g", style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the main ListView: daily goal + date row + meal sections
  Widget _buildDiaryList() {
    bool isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return ListView(
      children: [
        // 1) Top daily goal card
        _buildDailyGoalSection(),

        // 2) The date row
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

        // 3) The meal sections
        _buildMealSection('Breakfast', Colors.red),
        _buildMealSection('Lunch', Colors.orange),
        _buildMealSection('Dinner', Colors.indigo),
        _buildMealSection('Snacks', Colors.deepPurple),
      ],
    );
  }

  /// Build each meal section card
  Widget _buildMealSection(String mealTitle, Color color) {
    final mealNutrition = _calculateMealNutrition(mealTitle);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row + add button
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

  /// Main build
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildDiaryList(),
      ),
    );
  }
}
