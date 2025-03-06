import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  RecipeDetailPage({required this.recipeId});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? recipeDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  void _fetchRecipeDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      if (doc.exists) {
        setState(() {
          recipeDetails = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching recipe details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Recipe Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (recipeDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Recipe Details")),
        body: const Center(child: Text("Recipe not found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(recipeDetails!["Name"] ?? "Recipe")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipeDetails!["Images"] != null && recipeDetails!["Images"].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(recipeDetails!["Images"], fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(
              recipeDetails!["Name"] ?? "No Name",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              recipeDetails!["Description"] ?? "No Description",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (recipeDetails!.containsKey("Ingredients"))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  (recipeDetails!["Ingredients"] as List<dynamic>).length,
                      (index) => Text("- ${recipeDetails!["Ingredients"][index]}"),
                ),
              ),
            const SizedBox(height: 16),
            const Text("Steps", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (recipeDetails!.containsKey("Steps"))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  (recipeDetails!["Steps"] as List<dynamic>).length,
                      (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("${index + 1}. ${recipeDetails!["Steps"][index]}"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
