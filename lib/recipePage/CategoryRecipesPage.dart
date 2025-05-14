import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/recipe_card.dart';

class CategoryRecipesPage extends StatelessWidget {
  final String categoryTitle;
  final List<Map<String, dynamic>> recipes;

  const CategoryRecipesPage({
    required this.categoryTitle,
    required this.recipes,
    Key? key, required String category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$categoryTitle'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GridView.builder(
        itemCount: recipes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          final recipeId = recipe["RecipeId"].toString();
          final title = recipe["Name"].toString();
          final totalTime = recipe["TotalTime"].toString();
          final imageUrl = recipe["Images"].toString();

          return RecipeCard(
            title: title,
            totalTime: totalTime,
            imageUrl: imageUrl,
            recipeId: recipeId,
            isFavorited: false, // replace with real logic if needed
            onFavoriteTap: () {}, // implement if needed
            onCardTap: () {
              Navigator.pushNamed(context, '/recipeDetail', arguments: recipeId);
            },
          );
        },
      ),
    );
  }
}
