import 'package:flutter/material.dart';
import '../design_system/colors/color_aliases.dart';
import '../design_system/colors/ui_colors.dart';
import 'trending_screen.dart'; // Importing for PlaceholderGrid

class PostScreen extends StatelessWidget {
  final String username;
  final String imageUrl;
  final String description;
  final DateTime datePosted;
  final String title;

  const PostScreen({
    Key? key,
    required this.username,
    required this.imageUrl,
    required this.description,
    required this.datePosted,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorAliases.parchment,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: UIColors.iconPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          username,
          style: const TextStyle(
            color: UIColors.textHeadings,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),

              const SizedBox(height: 12),

              // Date posted
              Text(
                _formatDate(datePosted),
                style: const TextStyle(
                  fontSize: 14,
                  color: UIColors.textDisabled,
                ),
              ),

              const SizedBox(height: 16),

              // Post image with padding
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: UIColors.borderPrimary),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 240,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 240,
                        color: ColorAliases.neutral100,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: UIColors.iconPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                )
                    : Container(
                  height: 240,
                  color: ColorAliases.neutral100,
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 40,
                      color: UIColors.iconPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Description heading
              const Text(
                "Description",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),

              const SizedBox(height: 8),

              // Description text
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: UIColors.textBody,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Related places heading
              const Text(
                "Related Places",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),

              const SizedBox(height: 16),

              // Related places grid (non-interactive as specified)
              PlaceholderGrid(count: 4, columns: 4, context: context),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format the date
  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}