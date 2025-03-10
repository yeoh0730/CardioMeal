import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
    print("🛠️ Fetching details for recipeId: ${widget.recipeId}");

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
            "PrepTime": data["PrepTime"] ?? "N/A",
            "CookTime": data["CookTime"] ?? "N/A",
            "TotalTime": data["TotalTime"] ?? "N/A",
            "RecipeServings": data["RecipeServings"] ?? "N/A",
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
      return field.map((e) => e.toString()).toList();  // ✅ Ensure all elements are converted to Strings
    } else if (field is String) {
      return RegExp(r'\"(.*?)\"')  // ✅ Extracts text inside double quotes
          .allMatches(field)
          .map((match) => match.group(1) ?? "")
          .toList();
    }
    return [];
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _pageController,
          count: imageUrls.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Color.fromRGBO(244, 67, 54, 1),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Nutrition Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Calories: ${recipeDetails?["Calories"]} kcal"),
        Text("Fat: ${recipeDetails?["FatContent"]}g"),
        Text("Carbs: ${recipeDetails?["CarbohydrateContent"]}g"),
        Text("Fiber: ${recipeDetails?["FiberContent"]}g"),
        Text("Sugar: ${recipeDetails?["SugarContent"]}g"),
        Text("Protein: ${recipeDetails?["ProteinContent"]}g"),
        Text("Sodium: ${recipeDetails?["SodiumContent"]}mg"),
        Text("Cholesterol: ${recipeDetails?["CholesterolContent"]}mg"),
      ],
    );
  }

  Widget _buildRecipeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Prep Time: ${recipeDetails?["PrepTime"]}"),
        Text("Cook Time: ${recipeDetails?["CookTime"]}"),
        Text("Total Time: ${recipeDetails?["TotalTime"]}"),
        Text("Servings: ${recipeDetails?["RecipeServings"]}"),
        const SizedBox(height: 16),
        const Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recipeDetails!["Ingredients"].map((ingredient) => Text("• $ingredient")),
        const SizedBox(height: 16),
        const Text("Instructions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recipeDetails!["Instructions"].asMap().entries.map((entry) => Text("${entry.key + 1}. ${entry.value}")),
      ],
    );
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
      appBar: AppBar(title: Text(recipeDetails!["Name"] ?? "Recipe Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(recipeDetails!["Images"]),
            const SizedBox(height: 16),
            Text(recipeDetails!["Name"], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(recipeDetails!["Description"], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildRecipeDetails(),
            const SizedBox(height: 16),
            _buildNutritionInfo(),
          ],
        ),
      ),
    );
  }
}
