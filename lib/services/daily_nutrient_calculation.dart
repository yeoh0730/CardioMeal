import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Calculates BMR using the Mifflin‑St Jeor equation.
double calculateBMR({
  required double weight, // in kg
  required double height, // in cm
  required int age,
  required String gender, // "male" or "female"
}) {
  if (gender.toLowerCase() == 'male') {
    return (10 * weight) + (6.25 * height) - (5 * age) + 5;
  } else {
    return (10 * weight) + (6.25 * height) - (5 * age) - 161;
  }
}

/// Returns the activity factor based on the activity level.
double getActivityFactor(String activityLevel) {
  switch (activityLevel.toLowerCase()) {
    case "sedentary":
      return 1.2;
    case "lightly active":
      return 1.375;
    case "moderately active":
      return 1.55;
    case "active":
      return 1.725;
    case "very active":
      return 1.9;
    default:
      return 1.2;
  }
}

/// Determines the risk category based on user metrics.
/// If the user meets ANY high‑risk threshold, they are "High Risk".
/// Else if they meet ANY moderate‑risk threshold, they are "Moderate Risk".
/// Otherwise, they are "Low Risk".
String determineRiskCategory({
  required double bmi,
  required double totalCholesterol,
  required double systolicBP,
  required double diastolicBP,
  required double fastingGlucose,
  required double restingHR,
}) {
  // High risk: if any metric meets or exceeds the high-risk threshold.
  if (bmi >= 30 ||
      totalCholesterol >= 240 ||
      systolicBP >= 140 ||
      diastolicBP >= 90 ||
      fastingGlucose >= 126 ||
      restingHR >= 100) {
    return "High Risk";
  }
  // Moderate risk: if any metric is in the moderate range.
  else if ((bmi >= 25 && bmi < 30) ||
      (totalCholesterol >= 200 && totalCholesterol < 240) ||
      (systolicBP >= 120 && systolicBP < 140) ||
      (diastolicBP >= 80 && diastolicBP < 90) ||
      (fastingGlucose >= 100 && fastingGlucose < 126) ||
      (restingHR >= 80 && restingHR < 100)) {
    return "Moderate Risk";
  }
  // Otherwise, low risk.
  else {
    return "Low Risk";
  }
}

/// Calculates the user's daily calorie needs (TDEE) and nutrient limits,
/// then stores them in the Firestore users collection.
///
/// The [userData] map should include:
///   - 'weight' (kg)
///   - 'height' (cm)
///   - 'age' (years)
///   - 'gender' ("male" or "female")
///   - 'activityLevel' (e.g. "moderately active")
///   - Also, the following metrics are used for risk categorization:
///       'cholesterol', 'systolicBP', 'diastolicBP', 'bloodGlucose', 'heartRate'
Future<void> calculateAndStoreNutrientLimits(Map<String, dynamic> userData) async {
  // Extract user metrics
  double weight = double.parse(userData['weight'].toString());
  double height = double.parse(userData['height'].toString());
  int age = int.parse(userData['age'].toString());
  String gender = userData['gender'];
  String activityLevel = userData['activityLevel'];

  // Calculate BMI first (height in meters)
  double bmi = weight / ((height / 100) * (height / 100));

  // Extract additional metrics for risk categorization
  double totalCholesterol = double.parse(userData['cholesterol'].toString());
  double systolicBP = double.parse(userData['systolicBP'].toString());
  double diastolicBP = double.parse(userData['diastolicBP'].toString());
  double bloodGlucose = double.parse(userData['bloodGlucose'].toString());
  double heartRate = double.parse(userData['heartRate'].toString());

  // Determine the risk category based on the thresholds.
  String riskCategory = determineRiskCategory(
    bmi: bmi,
    totalCholesterol: totalCholesterol,
    systolicBP: systolicBP,
    diastolicBP: diastolicBP,
    fastingGlucose: bloodGlucose,
    restingHR: heartRate,
  );

  // Calculate BMR and TDEE (Total Daily Energy Expenditure)
  double bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender);
  double tdee = bmr * getActivityFactor(activityLevel);

  // Example Nutrient Limits:
  // Sodium: 1500 mg for high risk; 2300 mg for low/moderate risk.
  double sodiumLimit = (riskCategory.toLowerCase() == "high risk") ? 1500 : 2300;

  // Fat: Assume 30% of calories from fat (1g fat = 9 kcal)
  double fatLimit = (tdee * 0.30) / 9;

  // Carbohydrates: Assume 55% of calories from carbs (1g carb = 4 kcal)
  double carbLimit = (tdee * 0.55) / 4;

  // Protein: Example: 1 g per kg body weight.
  double proteinLimit = weight * 1;

  // Get the current user
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Update the risk category in the main user document
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'riskCategory': riskCategory,
    });

    // Store daily nutrient values in a subcollection "nutrientHistory"
    String timestamp = DateTime.now().toIso8601String();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('nutrientHistory')
        .doc(timestamp)
        .set({
      'dailyCalories': tdee,
      'sodiumLimit': sodiumLimit,
      'fatLimit': fatLimit,
      'carbLimit': carbLimit,
      'proteinLimit': proteinLimit,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("Nutrient limits updated for user ${user.uid}:");
    print("TDEE: ${tdee.toStringAsFixed(0)} kcal, Sodium: ${sodiumLimit} mg, Fat: ${fatLimit.toStringAsFixed(1)} g, Carbs: ${carbLimit.toStringAsFixed(1)} g, Protein: ${proteinLimit.toStringAsFixed(1)} g");
    print("Risk Category: $riskCategory");
  }
}


/// Calculates the user's daily calorie needs (TDEE) and nutrient limits
/// but does NOT store them in Firestore.
/// Returns a map with all the calculated values.
Future<Map<String, dynamic>> calculateNutrientLimitsWithoutStoring(
    Map<String, dynamic> userData) async {
  // Extract and parse user metrics with default values if null.
  double weight = double.tryParse(userData['weight']?.toString() ?? "") ?? 0.0;
  double height = double.tryParse(userData['height']?.toString() ?? "") ?? 0.0;
  int age = int.tryParse(userData['age']?.toString() ?? "") ?? 0;
  String gender = userData['gender'] ?? 'male';
  String activityLevel = userData['activityLevel'] ?? 'sedentary';

  // Calculate BMI (ensure height is non-zero)
  double bmi = (height > 0) ? weight / ((height / 100) * (height / 100)) : 0.0;

  // Extract additional health metrics with default values if null.
  double totalCholesterol = double.tryParse(userData['cholesterol']?.toString() ?? "") ?? 0.0;
  double systolicBP = double.tryParse(userData['systolicBP']?.toString() ?? "") ?? 0.0;
  double diastolicBP = double.tryParse(userData['diastolicBP']?.toString() ?? "") ?? 0.0;
  double bloodGlucose = double.tryParse(userData['bloodGlucose']?.toString() ?? "") ?? 0.0;
  double heartRate = double.tryParse(userData['heartRate']?.toString() ?? "") ?? 0.0;

  // Determine risk category.
  String riskCategory = determineRiskCategory(
    bmi: bmi,
    totalCholesterol: totalCholesterol,
    systolicBP: systolicBP,
    diastolicBP: diastolicBP,
    fastingGlucose: bloodGlucose,
    restingHR: heartRate,
  );

  // Calculate BMR and TDEE.
  double bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender);
  double tdee = bmr * getActivityFactor(activityLevel);

  // Calculate nutrient limits.
  double sodiumLimit = (riskCategory.toLowerCase() == "high risk") ? 1500 : 2300;
  double fatLimit = (tdee * 0.30) / 9;
  double carbLimit = (tdee * 0.55) / 4;
  double proteinLimit = weight; // 1g protein per kg

  return {
    'riskCategory': riskCategory,
    'dailyCalories': tdee,
    'sodiumLimit': sodiumLimit,
    'fatLimit': fatLimit,
    'carbLimit': carbLimit,
    'proteinLimit': proteinLimit,
  };
}

/// Checks whether the newly calculated nutrient data differs from the old data.
/// Returns true if there's a meaningful difference.
bool nutrientDataHasChanged(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
    ) {
  if (oldData['dailyCalories'] != null && newData['dailyCalories'] != null) {
    double oldCalories = oldData['dailyCalories'].toDouble();
    double newCalories = newData['dailyCalories'].toDouble();
    if ((oldCalories - newCalories).abs() > 0.1) {
      return true;
    }
  }
  if (oldData['sodiumLimit'] != newData['sodiumLimit']) return true;
  if (oldData['fatLimit'] != newData['fatLimit']) return true;
  if (oldData['carbLimit'] != newData['carbLimit']) return true;
  if (oldData['proteinLimit'] != newData['proteinLimit']) return true;
  if (oldData['riskCategory'] != newData['riskCategory']) return true;

  return false;
}

/// Stores the new nutrient limits in Firestore and updates the risk category.
Future<void> storeNutrientLimits(String uid, Map<String, dynamic> newLimits) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'riskCategory': newLimits['riskCategory'],
  });

  String timestampId = DateTime.now().toIso8601String(); // or any format you prefer

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('nutrientHistory')
      .doc(timestampId) // Use this string as the document ID
      .set({
    'dailyCalories': newLimits['dailyCalories'],
    'sodiumLimit': newLimits['sodiumLimit'],
    'fatLimit': newLimits['fatLimit'],
    'carbLimit': newLimits['carbLimit'],
    'proteinLimit': newLimits['proteinLimit'],
    'timestamp': FieldValue.serverTimestamp(),
  });

}