import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_card.dart';
import '../services/api_service.dart';

class FavoriteRecipesPage extends StatefulWidget {
  @override
  _FavoriteRecipesPageState createState() => _FavoriteRecipesPageState();
}

class _FavoriteRecipesPageState extends State<FavoriteRecipesPage> {
  late Future<List<Map<String, dynamic>>> _favoriteRecipesFuture;
  List<Map<String, dynamic>> _recommendedFlatList = [];
  bool _recommendedLoading = true;
  Set<String> userFavorites = {};

  @override
  void initState() {
    super.initState();
    _loadUserFavorites();
    _favoriteRecipesFuture = _fetchFavoriteRecipes();
    _fetchRecommendedRecipes();
  }

  Future<void> _loadUserFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    setState(() {
      userFavorites = favSnapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFavoriteRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final favSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    List<String> recipeIds = favSnapshot.docs.map((doc) => doc.id).toList();

    List<Map<String, dynamic>> recipes = [];
    for (String id in recipeIds) {
      final doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(id)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        recipes.add({
          "RecipeId": id,
          "Name": data["Name"] ?? "No Name",
          "TotalTime": data["TotalTime"] ?? "N/A",
          "Images": data["Images"] ?? "",
        });
      }
    }
    return recipes;
  }

  Future<void> _fetchRecommendedRecipes() async {
    try {
      final recData = await ApiService.fetchMealRecommendations();
      // Flatten all categories into one list
      List<Map<String, dynamic>> flatList = [];
      recData.forEach((_, list) {
        if (list is List) {
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              flatList.add(item);
            }
          }
        }
      });

      setState(() {
        _recommendedFlatList = flatList;
        _recommendedLoading = false;
      });
    } catch (e) {
      print("Error fetching recommended: $e");
      setState(() => _recommendedLoading = false);
    }
  }

  Future<void> _toggleFavorite(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId);

    await favDocRef.delete();

    setState(() {
      _favoriteRecipesFuture = _fetchFavoriteRecipes();
      userFavorites.remove(recipeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        title: const Text("Favorite Recipes"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoriteRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final favoriteRecipes = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (favoriteRecipes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("No favorite recipes found.")),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: favoriteRecipes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final recipe = favoriteRecipes[index];
                        return RecipeCard(
                          title: recipe["Name"],
                          totalTime: recipe["TotalTime"],
                          imageUrl: recipe["Images"],
                          recipeId: recipe["RecipeId"],
                          isFavorited: true,
                          onFavoriteTap: () => _toggleFavorite(recipe["RecipeId"]),
                        );
                      },
                    ),
                  ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(
                    "You may also like",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                _recommendedLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(), // let outer scroll handle it
                    shrinkWrap: true,
                    itemCount: _recommendedFlatList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final recipe = _recommendedFlatList[index];
                      final recipeId = recipe["RecipeId"]?.toString() ?? "";
                      final isFavorited = userFavorites.contains(recipeId);

                      return RecipeCard(
                        title: recipe["Name"]?.toString() ?? "No Name",
                        totalTime: recipe["TotalTime"]?.toString() ?? "N/A",
                        imageUrl: recipe["Images"]?.toString() ?? "",
                        recipeId: recipeId,
                        isFavorited: isFavorited,
                        onFavoriteTap: () async {
                          final favDocRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('favorites')
                              .doc(recipeId);
                          if (isFavorited) {
                            await favDocRef.delete();
                            setState(() => userFavorites.remove(recipeId));
                          } else {
                            await favDocRef.set({'addedAt': FieldValue.serverTimestamp()});
                            setState(() => userFavorites.add(recipeId));
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/recipe_card.dart';
//
// class FavoriteRecipesPage extends StatefulWidget {
//   @override
//   _FavoriteRecipesPageState createState() => _FavoriteRecipesPageState();
// }
//
// class _FavoriteRecipesPageState extends State<FavoriteRecipesPage> {
//   late Future<List<Map<String, dynamic>>> _favoriteRecipesFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _favoriteRecipesFuture = _fetchFavoriteRecipes();
//   }
//
//   Future<List<Map<String, dynamic>>> _fetchFavoriteRecipes() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return [];
//
//     // Get favorite recipe IDs from the user's "favorites" subcollection.
//     final favSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('favorites')
//         .get();
//
//     List<String> recipeIds = favSnapshot.docs.map((doc) => doc.id).toList();
//
//     // For each favorite recipe ID, fetch the recipe details from "tastyRecipes".
//     List<Map<String, dynamic>> recipes = [];
//     for (String id in recipeIds) {
//       final doc = await FirebaseFirestore.instance
//           .collection('recipes')
//           .doc(id)
//           .get();
//       if (doc.exists) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         recipes.add({
//           "RecipeId": id,
//           "Name": data["Name"] ?? "No Name",
//           "TotalTime": data["TotalTime"] ?? "N/A",
//           "Images": data["Images"] ?? "",
//           // Add more fields if needed.
//         });
//       }
//     }
//     return recipes;
//   }
//
//   // Toggling a favorite in this page removes it.
//   Future<void> _toggleFavorite(String recipeId) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//     final favDocRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('favorites')
//         .doc(recipeId);
//
//     // Remove the recipe from favorites.
//     await favDocRef.delete();
//
//     // Reload the favorites list.
//     setState(() {
//       _favoriteRecipesFuture = _fetchFavoriteRecipes();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF8F8F8),
//       appBar: AppBar(
//         backgroundColor: Color(0xFFF8F8F8),
//         title: Text("Favorite Recipes"),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context);
//             // This will pop back to whatever page pushed FavoriteRecipesPage,
//             // typically your Profile page.
//           },
//         ),
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _favoriteRecipesFuture,
//         builder: (context, snapshot) {
//           // Loading state
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           // Error state
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }
//           final recipes = snapshot.data ?? [];
//           if (recipes.isEmpty) {
//             return Center(child: Text("No favorite recipes found."));
//           }
//           // Display favorite recipes using a GridView.
//           return GridView.builder(
//             padding: const EdgeInsets.all(16),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.7,
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//             ),
//             itemCount: recipes.length,
//             itemBuilder: (context, index) {
//               final recipe = recipes[index];
//               // In the favorites page, all recipes are favorited.
//               bool isFavorited = true;
//               return RecipeCard(
//                 title: recipe["Name"],
//                 totalTime: recipe["TotalTime"],
//                 imageUrl: recipe["Images"],
//                 recipeId: recipe["RecipeId"],
//                 isFavorited: isFavorited,
//                 onFavoriteTap: () => _toggleFavorite(recipe["RecipeId"]),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
