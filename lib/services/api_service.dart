import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000"; // Change if hosted online

  // Fetch recommended recipes from Flask API
  static Future<List<dynamic>> fetchRecommendations() async {
    final url = Uri.parse("$baseUrl/recommend");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_metrics": {
          "Weight": 70,
          "Height": 175,
          "Cholesterol": 210,
          "Systolic_BP": 125,
          "Diastolic_BP": 85,
          "Blood_Glucose": 110,
          "Heart_Rate": 85
        },
        "dietary_preferences": ["Low Cholesterol"]
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load recommendations");
    }
  }
}
