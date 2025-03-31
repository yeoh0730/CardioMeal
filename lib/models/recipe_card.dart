import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String totalTime;
  final String imageUrl;
  final String recipeId;
  final bool isFavorited;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onCardTap; // New optional callback

  const RecipeCard({
    required this.title,
    required this.totalTime,
    required this.imageUrl,
    required this.recipeId,
    required this.isFavorited,
    required this.onFavoriteTap,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap ??
              () {
            Navigator.pushNamed(
              context,
              '/recipeDetail',
              arguments: recipeId,
            );
          },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) Container that holds only the image (with a slight shadow)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // The recipe image
                  Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      );
                    },
                  ),

                  // Bookmark (or favorite) icon on top-right
                  // FAVORITE ICON on top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      // behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // This callback will handle the toggle without triggering the parent tap.
                        onFavoriteTap();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? Colors.red : Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 2) Title text (outside any box)
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // 3) Cooking time row (also outside the box)
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  totalTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
