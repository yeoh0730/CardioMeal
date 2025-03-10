import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/recipe_card.dart';

class RecipePage extends StatefulWidget {
  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<Map<String, dynamic>> recipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  // Fetch recipes from Firestore
  void _fetchRecipes() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('tastyRecipes').get();
      List<Map<String, dynamic>> loadedRecipes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> recipe = doc.data() as Map<String, dynamic>;

        // Extract valid image URL
        String imageUrl = extractFirstValidImage(recipe['Images']);

        if (imageUrl.isNotEmpty) {
          loadedRecipes.add({
            "RecipeId": doc.id,
            "Name": recipe["Name"] ?? "No Name",
            "Images": imageUrl,
            "Description": recipe["Description"] ?? "",
          });
        }
      }

      setState(() {
        recipes = loadedRecipes;
        filteredRecipes = loadedRecipes;
      });

      print("Loaded ${recipes.length} recipes!");
    } catch (e) {
      print("Error fetching recipes: $e");
    }
  }

  // Extracts the first valid image URL
  String extractFirstValidImage(dynamic imagesField) {
    if (imagesField == null || imagesField == "character(0)") {
      return ""; // Ignore invalid image fields
    }

    String imagesString = imagesField.toString();

    // Remove extra quotation marks if present
    imagesString = imagesString.replaceAll('"', '');

    // Split by commas (in case multiple URLs exist)
    List<String> imageUrls = imagesString.split(", ");

    // Check each URL and return the first valid one
    for (String url in imageUrls) {
      if (url.startsWith("https://")) {
        return url;
      }
    }

    return ""; // No valid image found
  }

  // Search filter
  void _filterRecipes(String query) {
    List<Map<String, dynamic>> results = recipes.where((recipe) {
      final name = recipe["Name"].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredRecipes = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterRecipes,
            decoration: InputDecoration(
              hintText: 'Search recipes',
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _filterRecipes('');
                },
              )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded, color: Colors.black),
            onPressed: () {
              // Filter action here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **NEW** Recipes Title
            const Text(
              "Recipes",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16), // Add spacing before grid

            // Recipe Grid
            Expanded(
              child: GridView.builder(
                itemCount: filteredRecipes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final recipe = filteredRecipes[index];
                  return RecipeCard(
                    title: recipe["Name"],
                    imageUrl: recipe["Images"],
                    description: recipe["Description"],
                    recipeId: recipe["RecipeId"],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
