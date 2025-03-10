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
  List<String> selectedFilters = []; // Selected filters
  TextEditingController _searchController = TextEditingController();

  final List<String> mealTypes = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Dessert",
    "Snack",
    "Brunch"
  ]; // Filter options

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
            "Keywords": recipe["Keywords"] ?? "", // Extract keywords for filtering
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
      return "";
    }

    String imagesString = imagesField.toString();
    imagesString = imagesString.replaceAll('"', '');

    List<String> imageUrls = imagesString.split(", ");
    for (String url in imageUrls) {
      if (url.startsWith("https://")) {
        return url;
      }
    }
    return "";
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

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Optional: Rounded corners
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filter by Meal Type"),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black), // ✅ Close button
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: mealTypes.map((mealType) {
                  return CheckboxListTile(
                    title: Text(mealType),
                    value: selectedFilters.contains(mealType),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedFilters.add(mealType);
                        } else {
                          selectedFilters.remove(mealType);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedFilters.clear(); // Clear filters
                      filteredRecipes = List.from(recipes); // Show all recipes
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Reset"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _applyFilter();
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Apply filter based on selected meal types
  void _applyFilter() {
    if (selectedFilters.isEmpty) {
      setState(() {
        filteredRecipes = List.from(recipes); // Show all recipes if no filters
      });
      return;
    }

    List<Map<String, dynamic>> results = recipes.where((recipe) {
      String keywords = recipe["Keywords"].toString().toLowerCase();
      return selectedFilters.any((filter) => keywords.contains(filter.toLowerCase()));
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
            onPressed: _openFilterDialog, // Open filter dialog
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipes Title
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
