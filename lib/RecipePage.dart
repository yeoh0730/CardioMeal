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
  List<String> selectedFilters = [];
  TextEditingController _searchController = TextEditingController();

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;  // True if we still have more pages to load
  bool _isLoading = false; // True if we're currently loading a page

  final List<String> mealTypes = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Dessert",
    "Snack",
    "Brunch"
  ];

  @override
  void initState() {
    super.initState();

    // 1) Listen for search bar changes
    _searchController.addListener(() {
      final text = _searchController.text;
      if (text.isNotEmpty) {
        // User typed something => stop auto-loading so we don't overwrite search results
        // We don't do anything special here, just let them search locally
      } else {
        // User cleared search => optionally resume auto-loading
        // if we haven't loaded everything yet
        if (_hasMore && !_isLoading) {
          _fetchAllPages();
        }
        // Also revert to showing all loaded recipes
        setState(() {
          filteredRecipes = List.from(recipes);
        });
      }
    });

    // 2) Start auto-fetching all pages in the background
    _fetchAllPages();
  }

  // ===== AUTO-FETCH ALL PAGES =====
  Future<void> _fetchAllPages({int limit = 20}) async {
    // Keep fetching while we have more docs,
    // the widget is still mounted,
    // and the user hasn't started typing a query.
    while (_hasMore && mounted && _searchController.text.isEmpty) {
      await _fetchRecipes(limit: limit);
    }
  }

  // ===== PAGINATED FETCH (One Page) =====
  Future<void> _fetchRecipes({int limit = 20}) async {
    if (_isLoading || !_hasMore) return; // Prevent duplicate calls
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('tastyRecipes')
        .limit(limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last; // new last doc
      List<Map<String, dynamic>> newRecipes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;
        newRecipes.add({
          "RecipeId": doc.id,
          "Name": recipeData["Name"] ?? "No Name",
          "TotalTime": recipeData["TotalTime"] ?? "N/A",
          "Images": recipeData['Images'] ?? '',
          "Keywords": recipeData["Keywords"] ?? "",
        });
      }

      setState(() {
        recipes.addAll(newRecipes);
        // If the user hasn't typed a search, show all loaded recipes
        if (_searchController.text.isEmpty) {
          filteredRecipes = List.from(recipes);
        }
      });
    } else {
      // No more docs
      setState(() {
        _hasMore = false;
      });
    }

    setState(() => _isLoading = false);
  }

  // ===== LOCAL SEARCH FILTER =====
  void _filterRecipes(String query) {
    // Filter among the currently loaded recipes
    List<Map<String, dynamic>> results = recipes.where((recipe) {
      final name = recipe["Name"].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredRecipes = results;
    });
  }

  // ===== FILTER DIALOG =====
  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filter by Meal Type"),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
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
                      selectedFilters.clear();
                      filteredRecipes = List.from(recipes);
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

  // ===== APPLY FILTER =====
  void _applyFilter() {
    if (selectedFilters.isEmpty) {
      setState(() {
        filteredRecipes = List.from(recipes);
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

  // ===== MAIN BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            onChanged: _filterRecipes, // local filtering among loaded recipes
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
            onPressed: _openFilterDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recipes",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
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
                          totalTime: recipe["TotalTime"],
                          imageUrl: recipe["Images"],
                          recipeId: recipe["RecipeId"],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
