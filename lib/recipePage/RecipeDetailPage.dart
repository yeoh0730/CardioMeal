import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recipe_card.dart';
import '../services/api_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({required this.recipeId});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? recipeDetails;
  List<Map<String, dynamic>> similarRecipes = [];
  bool isLoadingSimilar = true;

  bool isLoading = true;
  bool isFavorited = false; // Track favorite status

  // Controller for PageView (images carousel)
  final PageController _pageController = PageController();

  final Set<String> allowedTags = {
    "5 Ingredients Or Less", "African", "Alcohol-Free", "Appetizers", "Asian", "Beef", "Beverages", "Brazilian",
    "British", "Brunch", "Budget", "Central & South American", "Chicken", "Chilis", "Chinese", "Cocktails",
    "Coffee", "Comfort Food", "Dairy", "Dairy-Free", "Desserts", "Dietary", "Difficulty", "Dinner", "Drinks",
    "Easy", "European", "Filipino", "Freezer Friendly", "French", "Fusion", "German", "Gin", "Gluten",
    "Gluten-Free", "Halal", "Hawaiian", "Healthy", "High-Fiber", "High-Protein", "Indian", "Italian", "Jamaican",
    "Japanese", "Jewish", "Keto", "Kid-Friendly", "Korean", "Kosher", "Low-Calorie", "Low-Carb", "Low-Fat",
    "Low-Sugar", "Lunch", "Mediterranean", "Mexican", "Middle Eastern", "Mocktails", "No Bake Desserts",
    "North American", "Pastries", "Peanuts", "Pork", "Puddings", "Quiches", "Rum", "Salads", "Sandwiches",
    "Seafood", "Seafood Pasta", "Shellfish", "Sides", "Snacks", "Soups", "South African", "Southern",
    "Southwestern", "Swedish", "Sweet Breakfasts", "Taiwanese", "Thai", "Under 1 Hour", "Under 15 Minutes",
    "Under 30 Minutes", "Under 45 Minutes", "Vegan", "Vegetarian", "Vietnamese", "West African"
  };

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _checkIfFavorited();
  }

  void _fetchRecipeDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Convert various fields to lists safely
        List<String> imageUrls = _cleanImageUrls(data["Images"]);
        List<String> ingredients = _convertToList(data["RecipeIngredientParts"]);
        List<String> instructions = _convertToList(data["RecipeInstructions"]);
        List<String> keywords = _convertToList(data["Keywords"]);

        setState(() {
          recipeDetails = {
            "Name": data["Name"] ?? "No Name",
            "Images": imageUrls,
            "Description": data["Description"] ?? "No description available.",
            "TotalTime": data["TotalTime"] ?? "N/A",
            "Ingredients": ingredients,
            "ServingSize": data["RecipeServings"]?.toString() ?? "0",
            "Instructions": instructions,
            "Keywords": keywords,
            "Calories": data["Calories"]?.toString() ?? "0",
            "FatContent": data["FatContent"]?.toString() ?? "0",
            "CarbohydrateContent": data["CarbohydrateContent"]?.toString() ?? "0",
            "FiberContent": data["FiberContent"]?.toString() ?? "0",
            "SugarContent": data["SugarContent"]?.toString() ?? "0",
            "ProteinContent": data["ProteinContent"]?.toString() ?? "0",
            "SodiumContent": data["SodiumContent"]?.toString() ?? "0",
            "CholesterolContent": data["CholesterolContent"]?.toString() ?? "0",
          };
          isLoading = false;
        });

        // ✅ Fetch similar recipes
        print("🔍 Calling fetchSimilarRecipes for: ${widget.recipeId}");

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userData = await ApiService.fetchUserData();

          final userMetrics = {
            "Weight": userData?["weight"] ?? 70,
            "Height": userData?["height"] ?? 175,
            "Cholesterol": userData?["Cholesterol"] ?? 200,
            "Systolic_BP": userData?["Systolic_BP"] ?? 120,
            "Diastolic_BP": userData?["Diastolic_BP"] ?? 80,
            "Blood_Glucose": userData?["Blood_Glucose"] ?? 100,
            "Heart_Rate": userData?["Heart_Rate"] ?? 75,
          };

          try {
            final similar = await ApiService.fetchSimilarRecipes(
              recipeId: widget.recipeId,
              userMetrics: userMetrics,
            );

            print("✅ Similar recipes fetched: ${similar.length}");
            setState(() {
              similarRecipes = List<Map<String, dynamic>>.from(similar);
              isLoadingSimilar = false;
            });
          } catch (e) {
            print("❌ Error fetching similar recipes: $e");
            setState(() {
              isLoadingSimilar = false;
            });
          }
        }

      } else {
        // Document doesn't exist
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("⚠️ Error fetching recipe details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  // Check if the recipe is already favorited by the user
  Future<void> _checkIfFavorited() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final favDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.recipeId)
        .get();
    setState(() {
      isFavorited = favDoc.exists;
    });
  }

  // Toggle the favorite status of the recipe
  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.recipeId);

    if (isFavorited) {
      await favDocRef.delete();
      setState(() {
        isFavorited = false;
      });

      // ❗ Show removed confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully removed from My Favourites.'),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      await favDocRef.set({
        'addedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        isFavorited = true;
      });

      // ✅ Show added confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully added to My Favourites!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/favoriteRecipes'); // Make sure this route is defined
            },
          ),
        ),
      );
    }
  }


  /// Converts the "Images" field, which might be a string or list, into a List of URLs.
  List<String> _cleanImageUrls(dynamic imagesField) {
    if (imagesField == null) {
      return [];
    }
    if (imagesField is String) {
      // Remove extra quotes, split by commas, keep only valid http links
      return imagesField
          .replaceAll('"', '')
          .split(", ")
          .where((url) => url.startsWith("http"))
          .toList();
    } else if (imagesField is List) {
      // Already a list; ensure all elements are strings
      return List<String>.from(imagesField);
    }
    return [];
  }

  /// Converts a field (could be a List, a quoted string, or null) into a List<String>.
  List<String> _convertToList(dynamic field) {
    if (field == null) {
      return [];
    } else if (field is List) {
      return field.map((e) => e.toString()).toList();
    } else if (field is String) {
      // Example: ""Meal", "Dinner", "Seafood""
      return RegExp(r'\"(.*?)\"')
          .allMatches(field)
          .map((match) => match.group(1) ?? "")
          .toList();
    }
    return [];
  }

  /// Capitalizes the first word of a string (used for ingredient lines).
  String _capitalizeFirstWord(String text) {
    if (text.isEmpty) return text;
    List<String> words = text.split(" ");
    words[0] = words[0][0].toUpperCase() + words[0].substring(1);
    return words.join(" ");
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (recipeDetails == null) {
      return Scaffold(
        body: const Center(child: Text("Recipe not found.")),
      );
    }

    // -------------------------------------------
    // SAFELY RETRIEVE LIST FIELDS
    // -------------------------------------------
    final dynamic imagesField = recipeDetails?["Images"];
    final List<String> imageUrls = (imagesField is List<String>) ? imagesField : <String>[];

    final dynamic ingredientsField = recipeDetails?["Ingredients"];
    final List<String> ingredientsList = (ingredientsField is List<String>) ? ingredientsField : <String>[];

    final dynamic instructionsField = recipeDetails?["Instructions"];
    final List<String> instructionsList = (instructionsField is List<String>) ? instructionsField : <String>[];

    final dynamic keywordsField = recipeDetails?["Keywords"];
    final List<String> keywordsList = (keywordsField is List<String>) ? keywordsField : <String>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Carousel
            Stack(
              children: [
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Back button
                Positioned(
                  top: 40,
                  left: 15,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),
                // Favorite icon (clickable)
                Positioned(
                  top: 40,
                  right: 15,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    behavior: HitTestBehavior.opaque,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Recipe Body
            Transform.translate(
              offset: const Offset(0, -30),
              child:             ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe Name
                      Text(
                        recipeDetails!["Name"],
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Time | Calories | Servings row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: Column(
                                children: [
                                  Text(
                                    recipeDetails!["TotalTime"] ?? "0",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const Text("Total Time", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  recipeDetails!["Calories"] ?? "0",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const Text("kcal/serving", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Flexible(
                              child: Column(
                                children: [
                                  Text(
                                    recipeDetails!["ServingSize"] ?? "1",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const Text("Serving", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filtered Tags
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: keywordsList
                              .where((keyword) => allowedTags.contains(keyword))
                              .map((keyword) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                keyword,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Description
                      Text(
                        recipeDetails!["Description"],
                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),

                      // Ingredients
                      const Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      for (var ingredient in ingredientsList)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontSize: 15)),
                              Expanded(
                                child: Text(
                                  _capitalizeFirstWord(ingredient),
                                  style: const TextStyle(fontSize: 15),
                                  softWrap: true,
                                ),
                              )
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Instructions
                      const Text("Instructions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      for (int i = 0; i < instructionsList.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${i + 1}. ", style: const TextStyle(fontSize: 15)),
                              Expanded(
                                child: Text(
                                  instructionsList[i],
                                  style: const TextStyle(fontSize: 15),
                                  softWrap: true,
                                ),
                              )
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Nutrition Info
                      const Text("Nutrition Info (Per serving)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildNutritionRow("Calories", "${recipeDetails?["Calories"]} kcal"),
                      _buildNutritionRow("Fat", "${recipeDetails?["FatContent"]} g"),
                      _buildNutritionRow("Carbs", "${recipeDetails?["CarbohydrateContent"]} g"),
                      _buildNutritionRow("Protein", "${recipeDetails?["ProteinContent"]} g"),
                      _buildNutritionRow("Sodium", "${recipeDetails?["SodiumContent"]} mg"),
                      _buildNutritionRow("Cholesterol", "${recipeDetails?["CholesterolContent"]} mg"),
                      const SizedBox(height: 30),

                      if (isLoadingSimilar)
                        const Center(child: CircularProgressIndicator())
                      else if (similarRecipes.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("You May Also Like", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: similarRecipes.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemBuilder: (context, index) {
                                final recipe = similarRecipes[index];
                                return RecipeCard(
                                  title: recipe["Name"] ?? "No Name",
                                  totalTime: recipe["TotalTime"]?.toString() ?? "N/A",
                                  imageUrl: recipe["Images"]?.toString() ?? "",
                                  recipeId: recipe["RecipeId"]?.toString() ?? "",
                                  isFavorited: recipe["isFavorited"] == true, // ✅ use dynamic value
                                  onFavoriteTap: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) return;

                                    final recipeId = recipe["RecipeId"].toString();
                                    final favDocRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('favorites')
                                        .doc(recipeId);

                                    final isCurrentlyFavorited = recipe["isFavorited"] == true;

                                    if (isCurrentlyFavorited) {
                                      await favDocRef.delete();
                                    } else {
                                      await favDocRef.set({'addedAt': FieldValue.serverTimestamp()});
                                    }

                                    setState(() {
                                      recipe["isFavorited"] = !isCurrentlyFavorited;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isCurrentlyFavorited
                                              ? 'Successfully removed from My Favourites.'
                                              : 'Successfully added to My Favourites!',
                                        ),
                                        backgroundColor: isCurrentlyFavorited ? Colors.grey[800] : Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        duration: const Duration(seconds: 2),
                                        action: !isCurrentlyFavorited
                                            ? SnackBarAction(
                                          label: 'View',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            Navigator.pushNamed(context, '/favoriteRecipes');
                                          },
                                        )
                                            : null,
                                      ),
                                    );
                                  },
                                  onCardTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RecipeDetailPage(recipeId: recipe["RecipeId"].toString()),
                                      ),
                                    );
                                    setState(() {}); // ✅ refresh after returning if needed
                                  },
                                );

                              },
                            ),
                          ],
                        )

                    ],
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }

  /// Helper to build each row in "Nutrition Facts"
  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
