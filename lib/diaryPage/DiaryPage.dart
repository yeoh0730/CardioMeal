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

Map<String, bool> _hasShownWarningForDate = {};

class _DiaryPageState extends State<DiaryPage> {
  bool _isNutrientLimitsLoading = true;

  DateTime _selectedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _selectedMeals = {
    "Breakfast": [],
    "Lunch": [],
    "Dinner": [],
    "Snacks": []
  };

  /// We'll store the user’s daily calorie goal and nutrient limits here.
  double? _userCalories;   // e.g. dailyCalories
  double? _userSodiumLimit;
  double? _userFatLimit;
  double? _userCarbLimit;

  /// Track how much the user has consumed so far.
  /// In a more complete implementation, you'd sum the macros from all meals.
  double _consumedCalories = 0;
  double _consumedCarbs = 0;
  double _consumedSodium = 0;
  double _consumedFat = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserNutrientLimitsForDate();
    _fetchLoggedMeals();
  }

  Future<void> _fetchUserNutrientLimitsForDate() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // For the selected date, define the end-of-day timestamp.
    DateTime endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );
    Timestamp endTS = Timestamp.fromDate(endOfDay);

    // Query all nutrientHistory docs with a timestamp less than or equal to the end-of-day.
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("nutrientHistory")
        .where("timestamp", isLessThanOrEqualTo: endTS)
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      Map<String, dynamic> nutrientData =
      snapshot.docs.first.data() as Map<String, dynamic>;
      setState(() {
        _userCalories = nutrientData['dailyCalories'] != null
            ? (nutrientData['dailyCalories'] as num).toDouble()
            : 0;
        _userSodiumLimit = nutrientData['sodiumLimit'] != null
            ? (nutrientData['sodiumLimit'] as num).toDouble()
            : 0;
        _userFatLimit = nutrientData['fatLimit'] != null
            ? (nutrientData['fatLimit'] as num).toDouble()
            : 0;
        _userCarbLimit = nutrientData['carbLimit'] != null
            ? (nutrientData['carbLimit'] as num).toDouble()
            : 0;
        _isNutrientLimitsLoading = false; // Data is loaded!
      });
      print("Fetched nutrient limits for date $_selectedDate (endOfDay: $endOfDay):");
      print("Calories: $_userCalories, Sodium: $_userSodiumLimit, Fat: $_userFatLimit, Carbs: $_userCarbLimit");
    } else {
      // No document found for a timestamp <= the selected date's end. Clear or set default values.
      setState(() {
        _userCalories = 0;
        _userSodiumLimit = 0;
        _userFatLimit = 0;
        _userCarbLimit = 0;
        _isNutrientLimitsLoading = false; // Data fetching completed (even if empty)
      });
      print("No nutrient history found for date $_selectedDate");
    }
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

    // After we've updated _selectedMeals, recalculate the "consumed" macros.
    _recalculateConsumedTotals();
  }

  List<String> _notificationQueue = [];
  bool _isShowingNotification = false;

  void _queueTopNotification(String message, {Color color = Colors.red}) {
    _notificationQueue.add(message);
    _runNextNotification(color: color);
  }

  void _runNextNotification({Color color = Colors.red}) async {
    if (_isShowingNotification || _notificationQueue.isEmpty) return;

    _isShowingNotification = true;
    String message = _notificationQueue.removeAt(0);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    overlayEntry.remove();
                    _isShowingNotification = false;
                    _runNextNotification(color: color); // Proceed to next
                  },
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// Recompute how many calories, carbs, sodium, and fat the user has consumed so far.
  /// Recompute how many calories, carbs, sodium, and fat the user has consumed so far,
  /// taking into account the serving size for each food item.
  void _recalculateConsumedTotals() {
    double totalCals = 0;
    double totalCarbs = 0;
    double totalSodium = 0;
    double totalFat = 0;

    _selectedMeals.forEach((mealType, mealList) {
      for (var recipe in mealList) {
        // Use a default serving size of 1 if not provided.
        double servingSize = (recipe["servingSize"] as num?)?.toDouble() ?? 1.0;

        totalCals   += (recipe["calories"] ?? 0) * servingSize;
        totalCarbs  += (recipe["carbs"]    ?? 0) * servingSize;
        totalSodium += (recipe["sodium"]   ?? 0) * servingSize;
        totalFat    += (recipe["fat"]      ?? 0) * servingSize;
      }
    });

    setState(() {
      _consumedCalories = totalCals;
      _consumedCarbs    = totalCarbs;
      _consumedSodium   = totalSodium;
      _consumedFat      = totalFat;
    });

    String todayKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    if (!(_hasShownWarningForDate[todayKey] ?? false)) {
      _notificationQueue.clear();

      if (_consumedCalories > (_userCalories ?? 0)) {
        double exceeded = _consumedCalories - (_userCalories ?? 0);
        _queueTopNotification("Calorie intake exceeded by ${exceeded.toStringAsFixed(0)} kcal");
      }
      if (_consumedCarbs > (_userCarbLimit ?? 0)) {
        double exceeded = _consumedCarbs - (_userCarbLimit ?? 0);
        _queueTopNotification("Carbohydrate intake exceeded by ${exceeded.toStringAsFixed(0)} g");
      }
      if (_consumedSodium > (_userSodiumLimit ?? 0)) {
        double exceeded = _consumedSodium - (_userSodiumLimit ?? 0);
        _queueTopNotification("Sodium intake exceeded by ${exceeded.toStringAsFixed(0)} mg");
      }
      if (_consumedFat > (_userFatLimit ?? 0)) {
        double exceeded = _consumedFat - (_userFatLimit ?? 0);
        _queueTopNotification("Fat intake exceeded by ${exceeded.toStringAsFixed(0)} g");
      }

      _hasShownWarningForDate[todayKey] = true;
    }
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
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
      _fetchUserNutrientLimitsForDate();
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
      // Reset warning for today so it shows again after logging a meal
      String todayKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _hasShownWarningForDate[todayKey] = false;
      _fetchLoggedMeals();
    }
  }

  /// Calculate macros for a given meal, taking into account serving size.
  Map<String, double> _calculateMealNutrition(String mealTitle) {
    double totalCalories = 0, totalFat = 0, totalCarbs = 0, totalSodium = 0;

    for (var recipe in _selectedMeals[mealTitle]!) {
      // Use a default serving size of 1 if not provided.
      double servingSize = (recipe["servingSize"] != null)
          ? (recipe["servingSize"] as num).toDouble()
          : 1.0;

      totalCalories += (recipe["calories"] ?? 0) * servingSize;
      totalFat += (recipe["fat"] ?? 0) * servingSize;
      totalCarbs += (recipe["carbs"] ?? 0) * servingSize;
      totalSodium += (recipe["sodium"] ?? 0) * servingSize;
    }

    return {
      "Calories": totalCalories,
      "Fat": totalFat,
      "Carbohydrates": totalCarbs,
      "Sodium": totalSodium
    };
  }

  /// If we have userCalories, show that as the daily goal.
  /// Otherwise default to some placeholder or 0.
  double get dailyGoal => _userCalories ?? 0;

  double get consumed => _consumedCalories;
  double get rawLeft => dailyGoal - consumed;

  // For macros, we do something similar:
  double get userCarbLimit => _userCarbLimit ?? 0;
  double get userSodiumLimit => _userSodiumLimit ?? 0;
  double get userFatLimit => _userFatLimit ?? 0;

  // Build top "Daily Goal" portion with ring + macros
  Widget _buildDailyGoalSection() {  // If nutrient limits are still loading, show a spinner
    // If we don't have user data yet, show placeholders
    bool hasData = (dailyGoal > 0);

    double carbProgress = 0;
    double sodiumProgress = 0;
    double fatProgress = 0;

    if (hasData) {
      carbProgress = (_consumedCarbs / userCarbLimit).clamp(0, 1);
      sodiumProgress = (_consumedSodium / userSodiumLimit).clamp(0, 1);
      fatProgress = (_consumedFat / userFatLimit).clamp(0, 1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
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
          CircularPercentIndicator(
            radius: 75,
            lineWidth: 12,
            percent: (consumed / dailyGoal).clamp(0, 1),
            backgroundColor: Colors.grey[200]!,
            progressColor: Colors.red.shade400,
            circularStrokeCap: CircularStrokeCap.round,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasData
                      ? rawLeft < 0
                      ? "${rawLeft.abs().toStringAsFixed(0)}"
                      : "${rawLeft.toStringAsFixed(0)}"
                      : "0",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: rawLeft < 0 ? Colors.red : Colors.black,
                  ),
                ),
                rawLeft < 0 ? Text("calories over", style: TextStyle(fontSize: 14)) : Text("calories left", style: TextStyle(fontSize: 14)),

              ],
            ),
          ),
          const SizedBox(height: 15),
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
                    width: 70,
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 60,
                        height: 10,
                        child: Stack(
                          children: [
                            // Background bar
                            Container(
                              width: 70,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            // Foreground filled bar
                            FractionallySizedBox(
                              widthFactor: carbProgress, // between 0 and 1
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  borderRadius: BorderRadius.circular(20), // fully rounded ends
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  hasData
                      ? RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: _consumedCarbs.toStringAsFixed(0),
                          style: TextStyle(
                            color: _consumedCarbs > userCarbLimit ? Colors.red : Colors.black,
                              // fontWeight: _consumedCarbs > userCarbLimit ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        TextSpan(
                          text: "/${userCarbLimit!.toStringAsFixed(0)}g",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  )
                      : const Text("0/0g", style: TextStyle(fontSize: 14)),
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
                    width: 70,
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 60,
                        height: 10,
                        child: Stack(
                          children: [
                            // Background bar
                            Container(
                              width: 70,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            // Foreground filled bar
                            FractionallySizedBox(
                              widthFactor: sodiumProgress, // between 0 and 1
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade400,
                                  borderRadius: BorderRadius.circular(20), // fully rounded ends
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  hasData
                      ? RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: _consumedSodium.toStringAsFixed(0),
                          style: TextStyle(
                            color: _consumedSodium > userSodiumLimit ? Colors.red : Colors.black,
                              // fontWeight: _consumedSodium > userSodiumLimit ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        TextSpan(
                          text: "/${userSodiumLimit!.toStringAsFixed(0)}mg",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  )
                      : const Text("0/0mg", style: TextStyle(fontSize: 14)),
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
                    width: 70,
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 60,
                        height: 10,
                        child: Stack(
                          children: [
                            // Background bar
                            Container(
                              width: 70,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            // Foreground filled bar
                            FractionallySizedBox(
                              widthFactor: fatProgress, // between 0 and 1
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  borderRadius: BorderRadius.circular(20), // fully rounded ends
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  hasData
                      ? RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: _consumedFat.toStringAsFixed(0),
                          style: TextStyle(
                            color: _consumedFat > userFatLimit ? Colors.red : Colors.black,
                              // fontWeight: _consumedFat > userFatLimit ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        TextSpan(
                          text: "/${userFatLimit!.toStringAsFixed(0)}g",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  )
                      : const Text("0/0g", style: TextStyle(fontSize: 14)),
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
                  final double servingSize = (recipe["servingSize"] as num?)?.toDouble() ?? 1.0;
                  // If servingSize is an integer (e.g. 3.0), display just '3'; otherwise show the decimal.
                  String servingSizeStr = servingSize % 1 == 0
                      ? servingSize.toInt().toString()
                      : servingSize.toString();

                  final double totalCals = (recipe["calories"] ?? 0) * servingSize;
                  final double totalSodium = (recipe["sodium"] ?? 0) * servingSize;
                  final double totalFat = (recipe["fat"] ?? 0) * servingSize;
                  final double totalCarbs = (recipe["carbs"] ?? 0) * servingSize;

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
                                // Display scaled nutrient values + serving size
                                    "Serving size: $servingSizeStr\n"
                                    "Calories: ${totalCals.toStringAsFixed(0)} | "
                                    "Sodium: ${totalSodium.toStringAsFixed(0)} | "
                                    "Fat: ${totalFat.toStringAsFixed(0)} | "
                                    "Carbs: ${totalCarbs.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    if (_isNutrientLimitsLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

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




