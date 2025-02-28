import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'services/api_service.dart';
import 'models/recipe_card.dart'; // Import the RecipeCard model

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _recipes = []; // Store API response

  @override
  void initState() {
    super.initState();
    _fetchRecommendations(); // Fetch data when screen loads
  }

  Future<void> _fetchRecommendations() async {
    try {
      List<dynamic> recommendations = await ApiService.fetchRecommendations();
      List<Map<String, dynamic>> formattedRecipes = [];

      for (var recipe in recommendations) {
        String imageUrl = extractValidImage(recipe['Images']);

        if (imageUrl.isNotEmpty) {
          formattedRecipes.add({
            "Name": recipe["Name"] ?? "No Name",
            "Images": imageUrl,
            "Description": recipe["Description"] ?? "",
          });
        }
      }

      setState(() {
        _recipes = formattedRecipes;
      });

      print("Loaded ${_recipes.length} recommendations!");
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Hi Yeoh!',
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
                  Text(
                    "Today's Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
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
                        center: Text("10%"),
                        progressColor: Colors.yellow,
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Sodium"),
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 40.0,
                        lineWidth: 8.0,
                        percent: 0.65,
                        center: Text("65%"),
                        progressColor: Colors.blue,
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Fat"),
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 40.0,
                        lineWidth: 8.0,
                        percent: 0.85,
                        center: Text("85%"),
                        progressColor: Colors.purple,
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Carbs"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Recommendations Header
              Text(
                "Recommendations",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 16),

              // Show Loading Indicator While Fetching Data
              _recipes.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];

                  return RecipeCard(
                    title: recipe["Name"],
                    imageUrl: recipe["Images"],
                    description: recipe["Description"],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
