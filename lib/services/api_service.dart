import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000"; // Change if hosted online

  // ✅ Fetch user data from Firestore
  static Future<Map<String, dynamic>?> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      return userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
    }
    return null;
  }

  // ✅ Fetch recommended recipes dynamically
  static Future<List<dynamic>> fetchRecommendations() async {
    final userData = await fetchUserData(); // Get user info from Firestore
    if (userData == null) {
      throw Exception("User data not found in Firestore");
    }

    final url = Uri.parse("$baseUrl/recommend");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_metrics": {
          "Weight": userData["weight"] ?? 70,  // Default values in case of missing fields
          "Height": userData["height"] ?? 175,
          "Cholesterol": userData["cholesterol"] ?? 200,
          "Systolic_BP": userData["systolicBP"] ?? 120,
          "Diastolic_BP": userData["diastolicBP"] ?? 80,
          "Blood_Glucose": userData["bloodGlucose"] ?? 100,
          "Heart_Rate": userData["restingHeartRate"] ?? 75
        },
        "dietary_preferences": userData["dietaryPreferences"] ?? []  // Retrieve diet preferences
      }),
    );

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      if (decodedResponse is List) {
        // ✅ Ensure `RecipeId` is treated as a string in Flutter
        return decodedResponse.map((recipe) {
          return {
            "RecipeId": recipe["RecipeId"].toString(), // ✅ Ensure RecipeId is a string
            "Name": recipe["Name"] ?? "Unknown",
            "Images": recipe["Images"] ?? "",
            "Description": recipe["Description"] ?? "",
          };
        }).toList();
      } else if (decodedResponse is Map && decodedResponse.containsKey("message")) {
        throw Exception(decodedResponse["message"]);
      } else {
        throw Exception("Unexpected API response format");
      }
    } else {
      throw Exception("Failed to load recommendations");
    }
  }
}
