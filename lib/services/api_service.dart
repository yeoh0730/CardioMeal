import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000"; // Adjust if hosted online

  static Future<Map<String, dynamic>?> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

      // ✅ Fetch latest health metrics
      Map<String, dynamic>? latestHealthMetrics = await fetchLatestHealthMetrics(user.uid);

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // ✅ Overwrite old values with the latest health metrics
        if (latestHealthMetrics != null) {
          // userData["Cholesterol"] = latestHealthMetrics["cholesterol"] ?? userData["cholesterol"];
          // userData["Systolic_BP"] = latestHealthMetrics["systolicBP"] ?? userData["systolicBP"];
          // userData["Diastolic_BP"] = latestHealthMetrics["diastolicBP"] ?? userData["diastolicBP"];
          // userData["Blood_Glucose"] = latestHealthMetrics["bloodGlucose"] ?? userData["bloodGlucose"];
          // userData["Heart_Rate"] = latestHealthMetrics["heartRate"] ?? userData["restingHeartRate"];

          userData["Cholesterol"] = latestHealthMetrics["Cholesterol"] ?? userData["Cholesterol"];
          userData["Systolic_BP"] = latestHealthMetrics["Systolic_BP"] ?? userData["Systolic_BP"];
          userData["Diastolic_BP"] = latestHealthMetrics["Diastolic_BP"] ?? userData["Diastolic_BP"];
          userData["Blood_Glucose"] = latestHealthMetrics["Blood_Glucose"] ?? userData["Blood_Glucose"];
          userData["Heart_Rate"] = latestHealthMetrics["Heart_Rate"] ?? userData["Heart_Rate"];
        }

        // ✅ Debug print to confirm the merged data
        print("📢 Merged User Data: $userData");
        return userData;
      }
    }
    return null;
  }

  // static Future<Map<String, dynamic>?> fetchLatestHealthMetrics(String userId) async {
  //   QuerySnapshot snapshot = await FirebaseFirestore.instance
  //       .collection("users")
  //       .doc(userId)
  //       .collection("healthMetrics")
  //       .orderBy("timestamp", descending: true) // Get the latest record
  //       .limit(1)
  //       .get();
  //
  //   if (snapshot.docs.isNotEmpty) {
  //     var latestData = snapshot.docs.first.data() as Map<String, dynamic>;
  //     print("📢 Latest Health Metrics: $latestData"); // Debugging Log
  //     return latestData;
  //   }
  //   print("⚠️ No Health Metrics Found!");
  //   return null;
  // }

  static Future<Map<String, dynamic>?> fetchLatestHealthMetrics(String userId) async {
    final firestore = FirebaseFirestore.instance;

    final metricCollections = {
      "Cholesterol": "cholesterolMetrics",
      "Systolic_BP": "systolicbpMetrics",
      "Diastolic_BP": "diastolicbpMetrics",
      "Blood_Glucose": "bloodglucoseMetrics",
      "Heart_Rate": "heartrateMetrics",
    };

    Map<String, dynamic> latestMetrics = {};

    for (var entry in metricCollections.entries) {
      final snapshot = await firestore
          .collection("users")
          .doc(userId)
          .collection(entry.value)
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final value = snapshot.docs.first.data()["value"];
        latestMetrics[entry.key] = value;
      }
    }

    print("📢 Latest Individual Health Metrics: $latestMetrics");
    return latestMetrics;
  }

  // ✅ Fetch recommended recipes by meal category using the latest health data
  static Future<Map<String, List<dynamic>>> fetchMealRecommendations() async {
    User? user = FirebaseAuth.instance.currentUser;

    final userData = await fetchUserData();
    if (user == null || userData == null) {
      throw Exception("User or user data not found in Firestore");
    }

    final url = Uri.parse("$baseUrl/recommend_meals"); // Endpoint for meal-based recommendations

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": user.uid,
        "user_metrics": {
          "Weight": userData["weight"] ?? 70,
          "Height": userData["height"] ?? 175,
          "Cholesterol": userData["Cholesterol"] ?? 200,
          "Systolic_BP": userData["Systolic_BP"] ?? 120,
          "Diastolic_BP": userData["Diastolic_BP"] ?? 80,
          "Blood_Glucose": userData["Blood_Glucose"] ?? 100,
          "Heart_Rate": userData["Heart_Rate"] ?? 75
        },
        "dietary_preferences": userData["dietaryPreferences"] ?? []
      }),
    );

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      if (decodedResponse is Map) {
        return decodedResponse.map((key, value) => MapEntry(key, List<dynamic>.from(value)));
      } else {
        throw Exception("Unexpected API response format");
      }
    } else {
      throw Exception("Failed to load meal recommendations");
    }
  }
}
