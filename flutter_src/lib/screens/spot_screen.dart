import 'package:flutter/material.dart';
import '../design_system/colors/color_aliases.dart';
import '../design_system/colors/ui_colors.dart';

class TouristSpotScreen extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String country;
  final String city;
  final String category;
  final String description;
  final double rating;

  const TouristSpotScreen({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.country,
    required this.city,
    required this.category,
    required this.description,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorAliases.parchment,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        title: Text(
          name,
          style: const TextStyle(
            color: UIColors.textOnAction,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and info section in a row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image of the spot
                    Expanded(
                      flex: 3,
                      child: AspectRatio(
                        aspectRatio: 180 / 246,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ColorAliases.neutral100,
                            border: Border.all(
                              color: UIColors.borderPrimary,
                              width: 1,
                            ),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          )
                              : const Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: UIColors.iconPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Info section to the right of the image
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem("Country", country),
                          const SizedBox(height: 16),
                          _buildInfoItem("City", city),
                          const SizedBox(height: 16),
                          _buildInfoItem("Category", category),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description section
                const Text(
                  "Description",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: UIColors.textHeadings,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: UIColors.textBody,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 24),

                // Ratings section
                const Text(
                  "Ratings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: UIColors.textHeadings,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Star rating display
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          color: ColorAliases.warningDefault,
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    // Numeric rating
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: UIColors.textHeadings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build the small info items (Country, City, Category)
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: UIColors.textHeadings,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: ColorAliases.white,
            border: Border.all(color: UIColors.borderPrimary),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: UIColors.textBody,
            ),
          ),
        ),
      ],
    );
  }
}