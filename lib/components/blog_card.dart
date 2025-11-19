import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BlogCard extends StatelessWidget {
  final String image;
  final String title;
  final String time;
  final bool isDark;

  const BlogCard({
    super.key,
    required this.image,
    required this.title,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.grey[800] : Colors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: image,
            width: 150,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            memCacheHeight: 200, // بهینه‌سازی حافظه برای تصاویر
            memCacheWidth: 300,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: const TextStyle(fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
