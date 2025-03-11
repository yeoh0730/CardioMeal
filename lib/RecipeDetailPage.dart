import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({required this.recipeId});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? recipeDetails;
  bool isLoading = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  void _fetchRecipeDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('tastyRecipes')
          .doc(widget.recipeId.toString())
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        List<String> imageUrls = _cleanImageUrls(data["Images"]);
        List<String> ingredients = _convertToList(data["RecipeIngredientParts"]);
        List<String> instructions = _convertToList(data["RecipeInstructions"]);

        setState(() {
          recipeDetails = {
            "Name": data["Name"] ?? "No Name",
            "Images": imageUrls,
            "Description": data["Description"] ?? "No description available.",
            "TotalTime": data["TotalTime"] ?? "N/A",
            "Ingredients": ingredients,
            "Instructions": instructions,
            "Calories": data["Calories"].toString(),
            "FatContent": data["FatContent"].toString(),
            "CarbohydrateContent": data["CarbohydrateContent"].toString(),
            "FiberContent": data["FiberContent"].toString(),
            "SugarContent": data["SugarContent"].toString(),
            "ProteinContent": data["ProteinContent"].toString(),
            "SodiumContent": data["SodiumContent"].toString(),
            "CholesterolContent": data["CholesterolContent"].toString(),
          };
          isLoading = false;
        });
      } else {
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

  List<String> _cleanImageUrls(dynamic imagesField) {
    if (imagesField is String) {
      return imagesField.replaceAll('"', '').split(", ").where((url) => url.startsWith("http")).toList();
    } else if (imagesField is List) {
      return List<String>.from(imagesField);
    }
    return [];
  }

  List<String> _convertToList(dynamic field) {
    if (field is List) {
      return field.map((e) => e.toString()).toList();
    } else if (field is String) {
      return RegExp(r'\"(.*?)\"')
          .allMatches(field)
          .map((match) => match.group(1) ?? "")
          .toList();
    }
    return [];
  }

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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (recipeDetails == null) {
      return Scaffold(
        body: const Center(child: Text("Recipe not found.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Recipe Image with Bookmark Icon
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: recipeDetails!["Images"].length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        recipeDetails!["Images"][index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          );
                        },
                      );
                    },
                  ),
                ),
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
                Positioned(
                  top: 40,
                  right: 15,
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.bookmark_border, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Recipe Name
                  Text(
                    recipeDetails!["Name"],
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Description
                  Text(
                    recipeDetails!["Description"],
                    style: const TextStyle(fontSize: 16, color: Colors.black54,),
                    // textAlign: TextAlign.justify
                  ),
                  const SizedBox(height: 20),

                  // ✅ Ingredients Section
                  const Text("Ingredients", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...recipeDetails!["Ingredients"].map(
                        (ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(fontSize: 16)),
                          Expanded(
                              child: Text(
                                _capitalizeFirstWord(ingredient),  // ✅ Apply function to capitalize each word
                                style: const TextStyle(fontSize: 16),
                                softWrap: true,
                              )
                          )
                        ],
                      )
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Instructions Section
                  const Text("Instructions", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...recipeDetails!["Instructions"].asMap().entries.map(
                        (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${entry.key + 1}. ", style: const TextStyle(fontSize: 16)),
                          Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 16),
                                softWrap: true,
                              )
                          )
                        ],
                      )
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Nutrition Facts
                  const Text("Nutrition Facts", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildNutritionRow("Calories", "${recipeDetails?["Calories"]} kcal"),
                  _buildNutritionRow("Fat", "${recipeDetails?["FatContent"]} g"),
                  _buildNutritionRow("Carbs", "${recipeDetails?["CarbohydrateContent"]} g"),
                  _buildNutritionRow("Protein", "${recipeDetails?["ProteinContent"]} g"),
                  _buildNutritionRow("Sodium", "${recipeDetails?["SodiumContent"]} mg"),
                  _buildNutritionRow("Cholesterol", "${recipeDetails?["CholesterolContent"]} mg"),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Function to Build Nutrition Row
  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }
}
