import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'services/api_service.dart';
import 'models/recipe_card.dart'; // Import the RecipeCard model

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<Map<String, dynamic>>> _categorizedRecipes = {};
  String _username = "User"; // Default username before fetching

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchRecommendations(); // Fetch data when screen loads
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _username = userDoc["name"] ?? "User";  // ✅ Update username
          });
        }
      }
    } catch (error) {
      print("⚠️ Error fetching user data: $error");
    }
  }

  Future<void> _fetchRecommendations() async {
    try {
      Map<String, List<dynamic>> recommendations = await ApiService.fetchMealRecommendations();
      Map<String, List<Map<String, dynamic>>> formattedRecipes = {};

      recommendations.forEach((category, recipes) {
        List<Map<String, dynamic>> categoryRecipes = [];

        for (var recipe in recipes) {
          String imageUrl = extractValidImage(recipe['Images']);

          if (imageUrl.isNotEmpty) {
            categoryRecipes.add({
              "RecipeId": recipe["RecipeId"] ?? "",
              "Name": recipe["Name"] ?? "No Name",
              "TotalTime": recipe["TotalTime"] ?? "N/A",
              "Images": imageUrl,
            });
          }
        }

        if (categoryRecipes.isNotEmpty) {
          formattedRecipes[category] = categoryRecipes;
        }
      });

      setState(() {
        _categorizedRecipes = formattedRecipes;
      });

      print("Loaded recommendations by category!");
    } catch (error) {
      print("Error fetching recommendations: $error");
    }
  }

  // Extracts the first valid image URL
  String extractValidImage(dynamic imagesField) {
    if (imagesField == null || imagesField == "character(0)") {
      return ""; // Ignore invalid image fields
    }

    String imagesString = imagesField.toString();
    imagesString = imagesString.replaceAll('"', '');

    List<String> imageUrls = imagesString.split(", ");

    for (String url in imageUrls) {
      if (url.startsWith("https://")) {
        return url;
      }
    }

    return ""; // No valid image found
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show Recommendations By Category in Correct Order
    List<String> orderedCategories = ["Breakfast", "Lunch", "Dinner", "Snacks"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Hi $_username!',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "View more",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // Nutrient Progress Cards
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularPercentIndicator(
                        radius: 40.0,
                        lineWidth: 8.0,
                        percent: 0.1,
                        center: const Text("10%"),
                        progressColor: Colors.yellow,
                        footer: const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text("Sodium"),
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 40.0,
                        lineWidth: 8.0,
                        percent: 0.65,
                        center: const Text("65%"),
                        progressColor: Colors.blue,
                        footer: const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text("Fat"),
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 40.0,
                        lineWidth: 8.0,
                        percent: 0.85,
                        center: const Text("85%"),
                        progressColor: Colors.purple,
                        footer: const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text("Carbs"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Recommendations Header
              const Text(
                "Recommendations",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),

          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (String category in orderedCategories)
              if (_categorizedRecipes.containsKey(category)) ...[
                Text(
                  category,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _categorizedRecipes[category]!.length,
                  itemBuilder: (context, index) {
                    final recipe = _categorizedRecipes[category]![index];
                    return RecipeCard(
                      title: recipe["Name"],
                      totalTime: recipe["TotalTime"],
                      imageUrl: recipe["Images"],
                      recipeId: recipe["RecipeId"].toString(),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
          ],
        ),


        ],
          ),
        ),
      ),
    );
  }
}
