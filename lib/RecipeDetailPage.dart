import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({required this.recipeId});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? recipeDetails;
  bool isLoading = true;
  bool isFavorited = false; // Track favorite status

  // Controller for PageView (images carousel)
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _checkIfFavorited();
  }

  // Fetch recipe details from Firestore
  void _fetchRecipeDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('tastyRecipes')
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
    if (user == null) return; // Optionally, prompt login
    final favDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.recipeId);

    if (isFavorited) {
      // Remove favorite
      await favDocRef.delete();
      setState(() {
        isFavorited = false;
      });
    } else {
      // Add favorite
      await favDocRef.set({
        'addedAt': FieldValue.serverTimestamp(),
        // Optionally store more fields, like recipe title or image.
      });
      setState(() {
        isFavorited = true;
      });
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
                  height: 300,
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
            const SizedBox(height: 10),
            // Recipe Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Name
                  Text(
                    recipeDetails!["Name"],
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Description
                  Text(
                    recipeDetails!["Description"],
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // Ingredients
                  Text("Ingredients (For ${recipeDetails!["ServingSize"]} servings)", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  for (var ingredient in ingredientsList)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              _capitalizeFirstWord(ingredient),
                              style: const TextStyle(fontSize: 16),
                              softWrap: true,
                            ),
                          )
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Instructions
                  const Text("Instructions", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  for (int i = 0; i < instructionsList.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${i + 1}. ", style: const TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              instructionsList[i],
                              style: const TextStyle(fontSize: 16),
                              softWrap: true,
                            ),
                          )
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Nutrition Info
                  const Text("Nutrition Info (Per serving)", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildNutritionRow("Calories", "${recipeDetails?["Calories"]} kcal"),
                  _buildNutritionRow("Fat", "${recipeDetails?["FatContent"]} g"),
                  _buildNutritionRow("Carbs", "${recipeDetails?["CarbohydrateContent"]} g"),
                  _buildNutritionRow("Protein", "${recipeDetails?["ProteinContent"]} g"),
                  _buildNutritionRow("Sodium", "${recipeDetails?["SodiumContent"]} mg"),
                  _buildNutritionRow("Cholesterol", "${recipeDetails?["CholesterolContent"]} mg"),
                  const SizedBox(height: 20),
                  // Tags/Keywords
                  const Text("Tags", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: keywordsList.map((keyword) {
                      return Chip(
                        label: Text(keyword),
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
