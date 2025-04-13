import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/custom_button.dart';
import '../services/api_service.dart';
import '../models/recipe_card.dart';

class RecipePage extends StatefulWidget {
  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> with SingleTickerProviderStateMixin {
  // ====== For "All Recipes" Pagination & Search ======
  List<Map<String, dynamic>> recipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  Set<String> userFavorites = {};
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  // ====== Loading state for recommended recipes =====
  bool _recommendedLoading = false;

  // Filter
  final List<String> mealTypes = ["Breakfast", "Lunch", "Dinner", "Dessert", "Snack", "Brunch"];
  final List<String> dietTypes = ["Dairy-Free", "Gluten-Free", "High-Fiber", "High-Protein", "Low-Calorie", "Low-Carb", "Low-Fat", "Low-Sugar", "Vegan", "Vegetarian"];
  List<String> selectedFilters = [];

  // Search
  TextEditingController _searchController = TextEditingController();

  // ====== For "Recommended" tab, grouped by category ======
  Map<String, List<Map<String, dynamic>>> _recommendedByCategory = {};
  final List<String> _recommendedMealCategories = ["Breakfast", "Lunch", "Dinner", "Snacks"];

  // ====== TabBar Controller ======
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Initialize TabController for 2 tabs: "Recommended" & "All Recipes"
    _tabController = TabController(length: 2, vsync: this);

    // Start pagination for "All Recipes"
    _fetchAllPages();

    // Fetch recommended recipes (grouped by category)
    _fetchRecommendedRecipes();

    // NEW: Fetch the user's favorite IDs
    _loadUserFavorites();
  }

  // Fetch favorite docs for the logged-in user
  Future<void> _loadUserFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // handle not logged in if needed

    try {
      final favSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      // The document IDs in 'favorites' are the recipe IDs
      final favoriteIds = favSnapshot.docs.map((doc) => doc.id).toSet();

      setState(() {
        userFavorites = favoriteIds;
      });
    } catch (e) {
      print("Error loading user favorites: $e");
    }
  }

  // Toggle a recipe's favorite status
  Future<void> _toggleFavorite(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // handle not logged in if needed

    final favDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId);

    // If it’s already in favorites, remove it; otherwise add it
    if (userFavorites.contains(recipeId)) {
      await favDocRef.delete();
      setState(() {
        userFavorites.remove(recipeId);
      });
    } else {
      await favDocRef.set({
        'addedAt': FieldValue.serverTimestamp(),
        // Optionally store more fields, e.g. recipe title or image
      });
      setState(() {
        userFavorites.add(recipeId);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ================================
  //  RECOMMENDED RECIPES (with loading state)
  // ================================
  Future<void> _fetchRecommendedRecipes() async {
    setState(() => _recommendedLoading = true); // Start loading
    try {
      final recData = await ApiService.fetchMealRecommendations();
      // recData might look like:
      // { "Breakfast": [...], "Lunch": [...], "Dinner": [...], "Snacks": [...] }

      Map<String, List<Map<String, dynamic>>> byCat = {};
      recData.forEach((cat, recList) {
        if (recList is List) {
          List<Map<String, dynamic>> items = [];
          for (var item in recList) {
            if (item is Map<String, dynamic>) {
              items.add(item);
            }
          }
          byCat[cat] = items;
        }
      });

      setState(() {
        _recommendedByCategory = byCat;
      });
      print("Loaded recommended recipes (grouped by category).");
    } catch (error) {
      print("Error fetching recommended recipes: $error");
    } finally {
      setState(() => _recommendedLoading = false); // Done loading
    }
  }

  // ================================
  //  PAGINATION FOR ALL RECIPES
  // ================================
  Future<void> _fetchAllPages({int limit = 20}) async {
    while (_hasMore && mounted) {
      await _fetchRecipes(limit: limit);
    }
  }

  Future<void> _fetchRecipes({int limit = 20}) async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('recipes')
        .limit(limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      List<Map<String, dynamic>> newRecipes = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;
        newRecipes.add({
          "RecipeId": doc.id,
          "Name": recipeData["Name"] ?? "No Name",
          "TotalTime": recipeData["TotalTime"] ?? "N/A",
          "Images": recipeData["Images"] ?? "",
          "Keywords": recipeData["Keywords"] ?? "",
        });
      }
      setState(() {
        recipes.addAll(newRecipes);

        final isFiltering = selectedFilters.isNotEmpty;
        final isSearching = _searchController.text.isNotEmpty;

        // Prevent overwriting filteredRecipes
        if (!isFiltering && !isSearching) {
          filteredRecipes = List.from(recipes);
        }
      });

    } else {
      setState(() {
        _hasMore = false;
      });
    }
    setState(() => _isLoading = false);
  }

  // ================================
  //  LOCAL SEARCH
  // ================================
  void _filterRecipes(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredRecipes = List.from(recipes);
      });
      return;
    }
    final results = recipes.where((recipe) {
      final name = recipe["Name"].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      filteredRecipes = results;
    });
  }

  // ================================
  //  FILTER DIALOG
  // ================================
  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Search Filter",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ===== Meal Filters =====
                    const Text("Meal", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: mealTypes.map((mealType) {
                        final isSelected = selectedFilters.contains(mealType);
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(mealType),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setModalState(() {
                              if (selected) {
                                selectedFilters.add(mealType);
                              } else {
                                selectedFilters.remove(mealType);
                              }
                            });
                          },
                          selectedColor: Colors.red,
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // ===== Diet Filters =====
                    const Text("Diet", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dietTypes.map((dietType) {
                        final isSelected = selectedFilters.contains(dietType);
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(dietType),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setModalState(() {
                              if (selected) {
                                selectedFilters.add(dietType);
                              } else {
                                selectedFilters.remove(dietType);
                              }
                            });
                          },
                          selectedColor: Colors.red,
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ===== Buttons =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Reset with red outline
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedFilters.clear();
                              filteredRecipes = List.from(recipes);
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        // Apply button (your custom component)
                        CustomButton(
                          text: "Apply",
                          onPressed: () {
                            _applyFilter();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _applyFilter() {
    if (selectedFilters.isEmpty) {
      setState(() {
        filteredRecipes = List.from(recipes);
      });
      return;
    }
    final results = recipes.where((recipe) {
      final keywords = recipe["Keywords"].toLowerCase();
      return selectedFilters.any((filter) => keywords.contains(filter.toLowerCase()));
    }).toList();

    setState(() {
      filteredRecipes = results;
    });
  }

  void _removeFilter(String filter) {
    setState(() {
      selectedFilters.remove(filter);
      _applyFilter(); // re-apply filter after removing
    });
  }

  // ================================
  //  RECOMMENDED TAB (Horizontal Rows)
  // ================================
  Widget _buildRecommendedTab() {
    // 1) If still loading recommended recipes, show spinner
    if (_recommendedLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    // 2) If done loading but empty
    if (_recommendedByCategory.isEmpty) {
      return const Center(child: Text("No recommended recipes found."));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _recommendedMealCategories.map((category) {
        final categoryList = _recommendedByCategory[category] ?? [];
        if (categoryList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Title
            Text(
              category,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Single horizontal row
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryList.length,
                itemBuilder: (context, index) {
                  final recipe = categoryList[index];
                  final recipeId = (recipe["RecipeId"] ?? "").toString();
                  bool isFavorited = userFavorites.contains(recipeId);
                  // Optionally remove right margin for the last item
                  final isLast = (index == categoryList.length - 1);
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: RecipeCard(
                      title: recipe["Name"] ?? "No Name",
                      totalTime: recipe["TotalTime"] ?? "N/A",
                      imageUrl: recipe["Images"] ?? "",
                      recipeId: (recipe["RecipeId"] ?? "").toString(),
                      isFavorited: isFavorited,
                      onFavoriteTap: () => _toggleFavorite(recipeId),
                      onCardTap: () async {
                        await Navigator.pushNamed(
                          context,
                          '/recipeDetail',
                          arguments: recipeId,
                        );
                        // When coming back, reload the favorites.
                        _loadUserFavorites();
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  // ================================
  //  ALL RECIPES TAB (Grid)
  // ================================
  Widget _buildAllRecipesTab() {
    return Column(
      children: [
        // Search bar & filter for All Recipes tab
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              // Expanded search bar
              Expanded(
                child: Container(
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
              ),
              const SizedBox(width: 8),
              // Filter button
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.red),
                onPressed: _openFilterDialog,
              ),
            ],
          ),
        ),

        if (selectedFilters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedFilters.map((filter) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        filter,
                        style: const TextStyle(color: Colors.white),
                      ),
                      deleteIcon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3), // background color of the circle
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      onDeleted: () => _removeFilter(filter),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // The recipes grid
        Expanded(
          child: Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: filteredRecipes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final recipe = filteredRecipes[index];
                  bool isFavorited = userFavorites.contains(recipe["RecipeId"]);
                  return RecipeCard(
                    title: recipe["Name"],
                    totalTime: recipe["TotalTime"],
                    imageUrl: recipe["Images"],
                    recipeId: recipe["RecipeId"],
                    isFavorited: isFavorited,
                    onFavoriteTap: () => _toggleFavorite(
                      recipe["RecipeId"],
                    ),
                    onCardTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/recipeDetail',
                        arguments: recipe["RecipeId"],
                      );
                      // When coming back, reload the favorites.
                      _loadUserFavorites();
                    },
                  );
                },
              ),
              // if (_isLoading)
              //   const Align(
              //     alignment: Alignment.bottomCenter,
              //     child: Padding(
              //       padding: EdgeInsets.all(8.0),
              //       child: CircularProgressIndicator(),
              //     ),
              //   ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================
  //  BUILD
  // ================================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // "Recommended" & "All Recipes"
      child: Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48), // or your custom height
          child: AppBar(
            backgroundColor: Color(0xFFF8F8F8),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            bottom: TabBar(
              tabs: [
                Tab(text: "Recommended"),
                Tab(text: "All Recipes"),
              ],
              labelColor: Colors.red,
              // unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red,
              // Here is the overlayColor property that changes the pressed/ripple color:
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    // Return your custom pressed color here:
                    return Colors.grey[100];
                  }
                  return null; // default ripple color if not pressed
                },
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // 1) Recommended Tab
            _buildRecommendedTab(),

            // 2) All Recipes Tab
            _buildAllRecipesTab(),
          ],
        ),
      ),
    );
  }
}
