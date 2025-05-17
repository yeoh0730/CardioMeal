import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String totalTime;
  final String imageUrl;
  final String recipeId;
  final bool isFavorited;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onCardTap;

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
    final double imageHeight = MediaQuery.of(context).size.width * 0.4;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), // prevent text overflow from font scale
      child: GestureDetector(
        onTap: onCardTap ??
                () {
              Navigator.pushNamed(
                context,
                '/recipeDetail',
                arguments: recipeId,
              );
            },
        child: SizedBox(
          width: 180, // can be adjusted based on screen size or parent
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image container
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
                      Image.network(
                        imageUrl,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: imageHeight,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: imageHeight,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: InkWell(
                          onTap: onFavoriteTap,
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

              // Title
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

              // Total Time Row
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
        ),
      ),
    );
  }
}
