import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../models/core/spot.dart';
import '../utils/constants.dart';
import '../screens/spot_screen.dart';

class SpotCardSwiper extends StatelessWidget {
  final List<Map<String, dynamic>> spots;
  final String title;
  final double height;

  const SpotCardSwiper({
    Key? key,
    required this.spots,
    required this.title,
    this.height = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.place, color: UIColors.iconPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),
              const Spacer(),
              Text(
                '${spots.length} ${spots.length == 1 ? 'local' : 'locais'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: UIColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: Swiper(
            itemBuilder:
                (context, index) => _buildSpotCard(context, spots[index]),
            itemCount: spots.length,
            pagination: const SwiperPagination(
              builder: DotSwiperPaginationBuilder(
                color: ColorAliases.neutral200,
                activeColor: ColorAliases.primaryDefault,
                size: 8,
                activeSize: 10,
              ),
            ),
            control: const SwiperControl(
              iconPrevious: Icons.arrow_back_ios,
              iconNext: Icons.arrow_forward_ios,
              color: ColorAliases.primaryDefault,
              size: 20,
            ),
            viewportFraction: 0.85,
            scale: 0.9,
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }

  Widget _buildSpotCard(BuildContext context, Map<String, dynamic> spotData) {
    final spotName = spotData['spot_name'] ?? spotData['name'] ?? 'Local';
    final spotCategory = spotData['category'] ?? 'Categoria';
    final spotCity = spotData['city'] ?? '';
    final spotCountry = spotData['country'] ?? '';
    final spotDescription = spotData['description'] ?? '';
    final spotImageUrl = _extractImageUrl(spotData);
    final spotId = spotData['spot_id'] ?? spotData['id'] ?? 0;

    final location = _buildLocationString(spotCity, spotCountry);

    return GestureDetector(
      onTap: () => _navigateToSpotDetail(context, spotData),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: ColorAliases.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UIColors.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spot image
              Expanded(
                flex: 3,
                child: _buildSpotImage(spotImageUrl, spotCategory, spotName),
              ),

              // Spot info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Spot name
                      Text(
                        spotName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UIColors.textHeadings,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Location
                      if (location.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: UIColors.iconOnDisabled,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: UIColors.textDisabled,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorAliases.primaryDefault.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          spotCategory,
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorAliases.primaryDefault,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Description preview (if available and space permits)
                      if (spotDescription.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            spotDescription,
                            style: const TextStyle(
                              fontSize: 13,
                              color: UIColors.textBody,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpotImage(String? imageUrl, String category, String spotName) {
    return Container(
      width: double.infinity,
      color: ColorAliases.neutral100,
      child:
          imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildImageLoading();
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildImageFallback(category, spotName);
                },
              )
              : _buildImageFallback(category, spotName),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      color: ColorAliases.neutral100,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(
            ColorAliases.primaryDefault,
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(String category, String spotName) {
    return Container(
      color: ColorAliases.neutral100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 48,
            color: UIColors.iconPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: const TextStyle(fontSize: 14, color: UIColors.textDisabled),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.neutral100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 48, color: UIColors.iconPrimary),
            const SizedBox(height: 12),
            Text(
              'Nenhum local encontrado',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: UIColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String? _extractImageUrl(Map<String, dynamic> data) {
    final imageUrl =
        data['spot_image_url'] ??
        data['imageUrl'] ??
        data['image_url'] ??
        data['blob_url'];

    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return imageUrl.toString();
    }
    return null;
  }

  String _buildLocationString(String city, String country) {
    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return '';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'praia':
        return Icons.beach_access;
      case 'cachoeira':
        return Icons.water;
      case 'montanha':
        return Icons.landscape;
      case 'parque nacional':
        return Icons.park;
      case 'centro histórico':
        return Icons.account_balance;
      case 'museu':
        return Icons.museum;
      case 'igreja':
        return Icons.church;
      case 'mirante':
        return Icons.visibility;
      case 'trilha':
        return Icons.hiking;
      case 'lagoa':
      case 'rio':
        return Icons.water;
      case 'gruta':
        return Icons.explore;
      case 'hotel':
        return Icons.hotel;
      case 'pousada':
        return Icons.bed;
      case 'camping':
        return Icons.outdoor_grill;
      case 'praça':
        return Icons.park;
      case 'monumento':
      case 'memorial':
        return Icons.account_balance;
      case 'estádio':
        return Icons.stadium;
      case 'chalé':
        return Icons.cabin;
      default:
        return Icons.place;
    }
  }

  void _navigateToSpotDetail(
    BuildContext context,
    Map<String, dynamic> spotData,
  ) {
    final spotName = spotData['spot_name'] ?? spotData['name'] ?? 'Local';
    final spotCategory = spotData['category'] ?? '';
    final spotCity = spotData['city'] ?? '';
    final spotCountry = spotData['country'] ?? '';
    final spotDescription = spotData['description'] ?? '';
    final spotImageUrl = _extractImageUrl(spotData);
    final spotId = spotData['spot_id'] ?? spotData['id'] ?? 0;
    final rating = (spotData['rating'] ?? 0.0).toDouble();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TouristSpotScreen(
              name: spotName,
              imageUrl: spotImageUrl ?? '',
              country: spotCountry,
              city: spotCity,
              category: spotCategory,
              description: spotDescription,
              rating: rating,
              spotId: spotId,
            ),
      ),
    );
  }
}
