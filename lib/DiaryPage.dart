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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          // Start with your existing theme or a base theme:
          data: ThemeData.light().copyWith(
            // Customize the color scheme:
            colorScheme: const ColorScheme.light(
              primary: Colors.red,   // header background color (month selector, etc.)
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
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
  final double consumed = 1000;     // Placeholder
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
        border: Border.all(
          color: Colors.grey.shade300, // Outline color (you can adjust opacity or use withOpacity)
          width: 2,                    // Outline thickness
        ),
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
            radius: 75, // bigger radius
            lineWidth: 12, // thicker ring
            percent: (consumed / dailyGoal).clamp(0, 1),
            backgroundColor: Colors.grey[200]!,
            progressColor: Colors.red,
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

          const SizedBox(height: 15),

          // Macros row: Carbs, Sodium, Fat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Carbs
              Column(
                children: [
                  const Text(
                    "Carbs",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6), // adjust for desired roundness
                      child: LinearProgressIndicator(
                        value: 0.5, // dummy progress value
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("100/192g", style: TextStyle(fontSize: 14)),
                ],
              ),
              // Sodium
              Column(
                children: [
                  const Text(
                    "Sodium",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6), // adjust for desired roundness
                      child: LinearProgressIndicator(
                        value: 0.5, // dummy progress value
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("50/99g", style: TextStyle(fontSize: 14)),
                ],
              ),
              // Fat
              Column(
                children: [
                  const Text(
                    "Fat",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6), // adjust for desired roundness
                      child: LinearProgressIndicator(
                        value: 0.5, // dummy progress value
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("40/45g", style: TextStyle(fontSize: 14)),
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
        // The date row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isToday ? "Today" : DateFormat('yyyy-MM-dd').format(_selectedDate),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.black),
              onPressed: _pickDate,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Top daily goal card
        _buildDailyGoalSection(),

        const SizedBox(height: 8),

        Text(
          "Meals",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // The meal sections
        _buildMealSection('Breakfast', Colors.red),
        _buildMealSection('Lunch', Colors.orange),
        _buildMealSection('Dinner', Colors.blue),
        _buildMealSection('Snacks', Colors.purple),
      ],
    );
  }

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
        // Optional: extra padding to add space inside the card
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: icon, meal title, bigger "Add" button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        _getMealIcon(mealTitle),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      iconSize: 30, // Make the "Add" icon bigger
                      icon: const Icon(Icons.add_circle, color: Colors.red),
                      onPressed: () => _navigateToRecipeSelection(mealTitle),
                    ),
                  ],
                ),
              ),

              // Divider if there are foods logged
              if (_selectedMeals[mealTitle]!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                ),

              // Foods list
              Column(
                children: _selectedMeals[mealTitle]!.map((recipe) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe["name"] ?? "No Name",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Calories: ${recipe["calories"]} | "
                                    "Sodium: ${recipe["sodium"]} | "
                                    "Fat: ${recipe["fat"]} | "
                                    "Carbs: ${recipe["carbs"]} ",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete button (aligned to the right)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
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
    );
  }

  /// Returns an appropriate icon for each meal type.
  IconData _getMealIcon(String mealTitle) {
    switch (mealTitle.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining; // coffee cup icon
      case 'lunch':
        return Icons.lunch_dining; // lunch icon
      case 'dinner':
        return Icons.dinner_dining; // dinner icon
      case 'snacks':
        return Icons.cookie; // fast food icon
      default:
        return Icons.restaurant; // default meal icon
    }
  }


  /// Main build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   elevation: 0,
      //   scrolledUnderElevation: 0,
      //   backgroundColor: Color(0xFFF8F8F8),
      //   title: const Text(
      //     'Diary',
      //     style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
      //   ),
      //   // centerTitle: true,
      // ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          top: 16.0,
          right: 16.0,
          bottom: 0,
        ),
        child: _buildDiaryList(),
      ),
    );
  }
}




