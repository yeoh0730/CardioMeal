import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000"; // Adjust if hosted online

  // ✅ Fetch user data from Firestore
  static Future<Map<String, dynamic>?> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      return userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
    }
    return null;
  }

  // ✅ Fetch recommended recipes by meal category
  static Future<Map<String, List<dynamic>>> fetchMealRecommendations() async {
    final userData = await fetchUserData();
    if (userData == null) {
      throw Exception("User data not found in Firestore");
    }

    final url = Uri.parse("$baseUrl/recommend_meals"); // Endpoint for meal-based recommendations

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_metrics": {
          "Weight": userData["weight"] ?? 70,
          "Height": userData["height"] ?? 175,
          "Cholesterol": userData["cholesterol"] ?? 200,
          "Systolic_BP": userData["systolicBP"] ?? 120,
          "Diastolic_BP": userData["diastolicBP"] ?? 80,
          "Blood_Glucose": userData["bloodGlucose"] ?? 100,
          "Heart_Rate": userData["restingHeartRate"] ?? 75
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
