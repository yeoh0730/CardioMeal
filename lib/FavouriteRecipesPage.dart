import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/recipe_card.dart';

class FavoriteRecipesPage extends StatefulWidget {
  @override
  _FavoriteRecipesPageState createState() => _FavoriteRecipesPageState();
}

class _FavoriteRecipesPageState extends State<FavoriteRecipesPage> {
  late Future<List<Map<String, dynamic>>> _favoriteRecipesFuture;

  @override
  void initState() {
    super.initState();
    _favoriteRecipesFuture = _fetchFavoriteRecipes();
  }

  Future<List<Map<String, dynamic>>> _fetchFavoriteRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Get favorite recipe IDs from the user's "favorites" subcollection.
    final favSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    List<String> recipeIds = favSnapshot.docs.map((doc) => doc.id).toList();

    // For each favorite recipe ID, fetch the recipe details from "tastyRecipes".
    List<Map<String, dynamic>> recipes = [];
    for (String id in recipeIds) {
      final doc = await FirebaseFirestore.instance
          .collection('tastyRecipes')
          .doc(id)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        recipes.add({
          "RecipeId": id,
          "Name": data["Name"] ?? "No Name",
          "TotalTime": data["TotalTime"] ?? "N/A",
          "Images": data["Images"] ?? "",
          // Add more fields if needed.
        });
      }
    }
    return recipes;
  }

  // Toggling a favorite in this page removes it.
  Future<void> _toggleFavorite(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final favDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId);

    // Remove the recipe from favorites.
    await favDocRef.delete();

    // Reload the favorites list.
    setState(() {
      _favoriteRecipesFuture = _fetchFavoriteRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F8F8),
        title: Text("Favorite Recipes"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            // This will pop back to whatever page pushed FavoriteRecipesPage,
            // typically your Profile page.
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoriteRecipesFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Error state
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final recipes = snapshot.data ?? [];
          if (recipes.isEmpty) {
            return Center(child: Text("No favorite recipes found."));
          }
          // Display favorite recipes using a GridView.
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              // In the favorites page, all recipes are favorited.
              bool isFavorited = true;
              return RecipeCard(
                title: recipe["Name"],
                totalTime: recipe["TotalTime"],
                imageUrl: recipe["Images"],
                recipeId: recipe["RecipeId"],
                isFavorited: isFavorited,
                onFavoriteTap: () => _toggleFavorite(recipe["RecipeId"]),
              );
            },
          );
        },
      ),
    );
  }
}
