import 'package:flutter/material.dart';
import '../design_system/colors/color_aliases.dart';
import '../design_system/colors/ui_colors.dart';
import 'review_screen.dart';

class TouristSpotScreen extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String country;
  final String city;
  final String category;
  final String description;
  final double rating;
  final int spotId;

  const TouristSpotScreen({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.country,
    required this.city,
    required this.category,
    required this.description,
    required this.rating,
    required this.spotId,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem + informações principais
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                          child:
                              imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, fit: BoxFit.cover)
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
                  ),
                  const SizedBox(width: 20),
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

              const SizedBox(height: 28),

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
                style: const TextStyle(color: UIColors.textBody, fontSize: 16),
              ),

              const SizedBox(height: 32),
              const Divider(thickness: 1, color: UIColors.borderPrimary),
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  "Ratings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: UIColors.textHeadings,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Estrelas fixas com média
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      int starIndex = index + 1;
                      return Icon(
                        Icons.star_rounded,
                        color:
                            rating >= starIndex
                                ? ColorAliases.warningDefault
                                : UIColors.iconPrimary,
                        size: 32,
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
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

              const SizedBox(height: 32),

              // Botão Avaliar
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ReviewScreen(
                              spotName: name,
                              spotId:
                                  spotId
                                      .toString(), // ← FIX: Convert spotId to string
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text("Avaliar este local"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Componente para mostrar cada informação textual
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ColorAliases.white,
            border: Border.all(color: UIColors.borderPrimary),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: UIColors.textBody),
          ),
        ),
      ],
    );
  }
}
