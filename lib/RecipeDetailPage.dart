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
  final PageController _pageController = PageController();  // ✅ Track page index

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  void _fetchRecipeDetails() async {
    print("🛠️ Fetching details for recipeId: ${widget.recipeId}");

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId.toString())  // ✅ Ensure `recipeId` is a string
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // ✅ Process images (ensure it handles both single and multiple images)
        List<String> imageUrls = _cleanImageUrls(data["Images"]);

        // ✅ Convert `RecipeIngredientParts`, `RecipeIngredientQuantities`, `RecipeInstructions` to lists safely
        List<String> ingredients = _convertToList(data["RecipeIngredientParts"]);
        List<String> quantities = _convertToList(data["RecipeIngredientQuantities"]);
        List<String> instructions = _convertToList(data["RecipeInstructions"]);

        setState(() {
          recipeDetails = {
            "Name": data["Name"] ?? "No Name",
            "Images": imageUrls,
            "Description": data["Description"] ?? "No description available.",
            "Ingredients": ingredients,
            "Quantities": quantities,
            "Instructions": instructions,
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

// ✅ Helper function to clean and handle multiple image URLs
  List<String> _cleanImageUrls(dynamic imagesField) {
    if (imagesField is String) {
      return imagesField
          .replaceAll('"', '')  // Remove extra quotes
          .split(", ")  // Split multiple image URLs
          .where((url) => url.startsWith("http"))  // Ensure valid URLs
          .toList();
    } else if (imagesField is List) {
      return List<String>.from(imagesField);
    }
    return [];
  }

// ✅ Helper function to safely convert Firestore fields to `List<String>`
  List<String> _convertToList(dynamic field) {
    if (field is List) {
      return field.map((e) => e.toString().replaceAll('"', '').trim()).toList();
    } else if (field is String) {
      return field
          .replaceAll('"', '')  // Remove extra quotes
          .split(RegExp(r',\s*'))  // Split by commas and whitespace
          .map((e) => e.trim())  // Trim spaces
          .toList();
    }
    return [];
  }


  // ✅ Swipeable Image Carousel
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
            controller: _pageController,  // ✅ Connect PageController
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
        const SizedBox(height: 8), // Space between image and dots

        // ✅ Add Dot Indicator Below Images
        SmoothPageIndicator(
          controller: _pageController,
          count: imageUrls.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Color.fromRGBO(244, 67, 54, 1), // Customize dot color
          ),
        ),
      ],
    );
  }

  // ✅ Display Ingredients Properly
  Widget _buildIngredientsSection(List<String> ingredients, List<String> quantities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(ingredients.length, (index) {
          String quantity = (index < quantities.length) ? quantities[index] : "";  // ✅ Prevent out-of-bounds error
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  "$quantity ${ingredients[index]}",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ✅ Display Steps Properly
  Widget _buildStepsSection(List<String> instructions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Steps", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(instructions.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text("${index + 1}. ${instructions[index]}", style: const TextStyle(fontSize: 16)),
          );
        }),
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
      // appBar: AppBar(title: Text(recipeDetails!["Name"] ?? "Recipe")),
      appBar: AppBar(title: Text('Recipe Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(recipeDetails!["Images"]),  // ✅ Swipable images
            const SizedBox(height: 16),
            Text(
              recipeDetails!["Name"] ?? "No Name",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(recipeDetails!["Description"], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildIngredientsSection(recipeDetails!["Ingredients"], recipeDetails!["Quantities"]), // ✅ Ingredients
            const SizedBox(height: 16),
            _buildStepsSection(recipeDetails!["Instructions"]), // ✅ Steps
          ],
        ),
      ),
    );
  }
}
