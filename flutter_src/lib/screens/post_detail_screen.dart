//screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import '../design_system/colors/color_aliases.dart';
import '../design_system/colors/ui_colors.dart';
import '../utils/constants.dart';
import '../widgets/spot_card_swiper.dart';
import 'spot_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostDetailScreen({Key? key, required this.postData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final postType = postData['type'] ?? 'unknown';
    final userName = _getUserName(postData);

    return Scaffold(
      backgroundColor: ColorAliases.parchment,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: UIColors.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          userName,
          style: const TextStyle(
            color: UIColors.textHeadings,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [_buildPostTypeChip(postType), const SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildPostContent(postType),
        ),
      ),
    );
  }

  // =============================================================================
  // POST CONTENT BUILDERS
  // =============================================================================

  Widget _buildPostContent(String postType) {
    switch (postType) {
      case 'community':
        return _buildCommunityPostContent();
      case 'review':
        return _buildReviewPostContent();
      case 'list':
        return _buildListPostContent();
      default:
        return _buildGenericPostContent();
    }
  }

  Widget _buildCommunityPostContent() {
    final title =
        postData['title'] ??
        postData['community_title'] ??
        'Post da Comunidade';
    final description = postData['description'] ?? '';
    final createdDate = _parseDate(postData['created_date']);
    final listInfo = postData['list'] ?? {};
    final listName = listInfo['list_name'] ?? '';
    final spotsCount = listInfo['spots_count'] ?? 0;
    final spots = _extractSpots(postData); // Extract actual spots data

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post title
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: UIColors.textHeadings,
          ),
        ),
        const SizedBox(height: 8),

        // User info and date
        _buildUserInfoRow(createdDate),
        const SizedBox(height: 20),

        // Description
        if (description.isNotEmpty) ...[
          _buildSectionHeader('Descrição'),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: UIColors.textBody,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // List information
        _buildSectionHeader('Lista Associada'),
        const SizedBox(height: 8),
        _buildListInfoCard(listName, spotsCount, isHidden: true),
        const SizedBox(height: 24),

        // Real spots preview section
        if (spots.isNotEmpty) ...[
          _buildSpotsPreviewSection(spots),
        ] else if (spotsCount > 0) ...[
          // Fallback if spots data isn't available but count is
          _buildSpotsPlaceholder(spotsCount),
        ],
      ],
    );
  }

  Widget _buildReviewPostContent() {
    final description = postData['description'] ?? '';
    final createdDate = _parseDate(postData['created_date']);
    final rating = (postData['rating'] ?? 0).toDouble();
    final spotInfo = postData['spot'] ?? {};
    final spotName = spotInfo['spot_name'] ?? 'Local não especificado';
    final spotLocation = _buildLocationString(spotInfo);
    final spotCategory = spotInfo['category'] ?? '';
    final spotImageUrl = _extractImageUrl(spotInfo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spot information card
        _buildSpotInfoCard(spotName, spotLocation, spotCategory, spotImageUrl),
        const SizedBox(height: 20),

        // Rating section
        _buildSectionHeader('Avaliação'),
        const SizedBox(height: 8),
        _buildRatingDisplay(rating),
        const SizedBox(height: 8),

        // User info and date
        _buildUserInfoRow(createdDate),
        const SizedBox(height: 20),

        // Review content
        if (description.isNotEmpty) ...[
          _buildSectionHeader('Comentário'),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: UIColors.textBody,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListPostContent() {
    final title = postData['title'] ?? postData['list_title'] ?? 'Lista';
    final description = postData['description'] ?? '';
    final createdDate = _parseDate(postData['created_date']);
    final listInfo = postData['list'] ?? {};
    final listName = listInfo['list_name'] ?? title;
    final isPublic = listInfo['is_public'] ?? false;
    final spotsCount = listInfo['spots_count'] ?? 0;
    final spots = _extractSpots(postData); // Extract actual spots data

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post title
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: UIColors.textHeadings,
          ),
        ),
        const SizedBox(height: 8),

        // User info and date
        _buildUserInfoRow(createdDate),
        const SizedBox(height: 20),

        // Description
        if (description.isNotEmpty) ...[
          _buildSectionHeader('Descrição'),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: UIColors.textBody,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // List information
        _buildSectionHeader('Informações da Lista'),
        const SizedBox(height: 8),
        _buildListInfoCard(listName, spotsCount, isHidden: !isPublic),
        const SizedBox(height: 24),

        // Real spots preview section
        if (spots.isNotEmpty) ...[
          _buildSpotsPreviewSection(spots),
        ] else if (spotsCount > 0) ...[
          // Fallback if spots data isn't available but count is
          _buildSpotsPlaceholder(spotsCount),
        ],
      ],
    );
  }

  Widget _buildGenericPostContent() {
    final description = postData['description'] ?? '';
    final createdDate = _parseDate(postData['created_date']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info and date
        _buildUserInfoRow(createdDate),
        const SizedBox(height: 20),

        // Description
        if (description.isNotEmpty)
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: UIColors.textBody,
              height: 1.5,
            ),
          ),
      ],
    );
  }

  // =============================================================================
  // NEW SPOTS PREVIEW SECTION
  // =============================================================================

  Widget _buildSpotsPreviewSection(List<Map<String, dynamic>> spots) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with spot count
          Row(
            children: [
              Icon(Icons.place, color: UIColors.iconPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Locais (${spots.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Spots swiper container
          Container(
            decoration: BoxDecoration(
              color: ColorAliases.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: UIColors.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 340, // Slightly taller for better card display
                child: SpotCardSwiper(
                  spots: spots,
                  title: '', // Empty title since we have our own header
                  height: 340,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // HELPER METHODS FOR SPOTS DATA
  // =============================================================================

  List<Map<String, dynamic>> _extractSpots(Map<String, dynamic> postData) {
    final spots = <Map<String, dynamic>>[];

    try {
      // Try to get spots from different possible locations in the data structure

      // From list.spots (most common for community posts)
      final listInfo = postData['list'] ?? {};
      final listSpots = listInfo['spots'] ?? [];
      if (listSpots is List && listSpots.isNotEmpty) {
        for (final spot in listSpots) {
          if (spot is Map<String, dynamic>) {
            spots.add(spot);
          }
        }
      }

      // From direct spots array (alternative structure)
      final directSpots = postData['spots'] ?? [];
      if (directSpots is List && directSpots.isNotEmpty) {
        for (final spot in directSpots) {
          if (spot is Map<String, dynamic>) {
            // Avoid duplicates
            final spotId = spot['spot_id'] ?? spot['id'];
            final alreadyExists = spots.any(
              (existingSpot) =>
                  (existingSpot['spot_id'] ?? existingSpot['id']) == spotId,
            );
            if (!alreadyExists) {
              spots.add(spot);
            }
          }
        }
      }

      // From list_spots array (another possible structure)
      final listSpotsArray = postData['list_spots'] ?? [];
      if (listSpotsArray is List &&
          listSpotsArray.isNotEmpty &&
          spots.isEmpty) {
        for (final spot in listSpotsArray) {
          if (spot is Map<String, dynamic>) {
            spots.add(spot);
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting spots: $e');
    }

    return spots;
  }

  // =============================================================================
  // UI COMPONENTS
  // =============================================================================

  Widget _buildPostTypeChip(String postType) {
    String label;
    Color color;

    switch (postType) {
      case 'community':
        label = 'COMUNIDADE';
        color = ColorAliases.primaryDefault;
        break;
      case 'review':
        label = 'AVALIAÇÃO';
        color = ColorAliases.success300;
        break;
      case 'list':
        label = 'LISTA';
        color = ColorAliases.warning300;
        break;
      default:
        label = 'POST';
        color = UIColors.iconPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: UIColors.textHeadings,
      ),
    );
  }

  Widget _buildUserInfoRow(DateTime createdDate) {
    final userName = _getUserName(postData);

    return Row(
      children: [
        // User avatar
        _buildUserAvatar(null, userName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: UIColors.textBody,
                ),
              ),
              Text(
                _formatDate(createdDate),
                style: const TextStyle(
                  fontSize: 14,
                  color: UIColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpotInfoCard(
    String spotName,
    String spotLocation,
    String spotCategory,
    String? imageUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Spot image
          _buildSpotImage(imageUrl, spotCategory, spotName, size: 80),
          const SizedBox(width: 16),

          // Spot details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spotName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: UIColors.textHeadings,
                  ),
                ),
                if (spotLocation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 16,
                        color: UIColors.iconOnDisabled,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spotLocation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: UIColors.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDisplay(double rating) {
    return Row(
      children: [
        // Rating stars
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: 24, color: ColorAliases.warning300);
          } else if (index < rating.ceil() && rating % 1 != 0) {
            return Icon(
              Icons.star_half,
              size: 24,
              color: ColorAliases.warning300,
            );
          } else {
            return Icon(
              Icons.star_border,
              size: 24,
              color: UIColors.iconOnDisabled,
            );
          }
        }),
        const SizedBox(width: 12),
        Text(
          '${rating.toStringAsFixed(1)} estrelas',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: UIColors.textBody,
          ),
        ),
      ],
    );
  }

  Widget _buildListInfoCard(
    String listName,
    int spotsCount, {
    required bool isHidden,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Row(
        children: [
          Icon(
            isHidden ? Icons.lock : Icons.public,
            size: 24,
            color: UIColors.iconPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: UIColors.textBody,
                  ),
                ),
                Text(
                  isHidden ? 'Lista Privada' : 'Lista Pública',
                  style: const TextStyle(
                    fontSize: 14,
                    color: UIColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                spotsCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),
              Text(
                spotsCount == 1 ? 'local' : 'locais',
                style: const TextStyle(
                  fontSize: 12,
                  color: UIColors.textDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpotsPlaceholder(int spotsCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorAliases.neutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Column(
        children: [
          Icon(Icons.place, size: 48, color: UIColors.iconPrimary),
          const SizedBox(height: 12),
          Text(
            'Lista com $spotsCount ${spotsCount == 1 ? 'local' : 'locais'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: UIColors.textBody,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Carregando detalhes dos locais...',
            style: const TextStyle(fontSize: 14, color: UIColors.textDisabled),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // IMAGE HANDLING
  // =============================================================================

  Widget _buildSpotImage(
    String? imageUrl,
    String category,
    String spotName, {
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _buildImageWithFallbacks(
          imageUrl: imageUrl,
          category: category,
          fallbackText: spotName,
          width: size,
          height: size,
        ),
      ),
    );
  }

  Widget _buildUserAvatar(
    String? imageUrl,
    String userName, {
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: ClipOval(
        child: _buildImageWithFallbacks(
          imageUrl: imageUrl,
          category: 'user',
          fallbackText: userName,
          width: size,
          height: size,
          isAvatar: true,
        ),
      ),
    );
  }

  Widget _buildImageWithFallbacks({
    String? imageUrl,
    required String category,
    required String fallbackText,
    required double width,
    required double height,
    bool isAvatar = false,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageLoading(width, height);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImageFallback(
            category,
            fallbackText,
            width,
            height,
            isAvatar,
          );
        },
      );
    }

    return _buildImageFallback(category, fallbackText, width, height, isAvatar);
  }

  Widget _buildImageLoading(double width, double height) {
    return Container(
      width: width,
      height: height,
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

  Widget _buildImageFallback(
    String category,
    String fallbackText,
    double width,
    double height,
    bool isAvatar,
  ) {
    if (isAvatar) {
      return _buildAvatarFallback(fallbackText, width, height);
    }

    final placeholderUrl = AppConstants.getPlaceholderImage(category);

    return Image.network(
      placeholderUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildFinalImageFallback(category, width, height);
      },
    );
  }

  Widget _buildAvatarFallback(String name, double width, double height) {
    final initials = _getInitials(name);

    return Container(
      width: width,
      height: height,
      color: ColorAliases.primaryDefault.withOpacity(0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: ColorAliases.primaryDefault,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFinalImageFallback(
    String category,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      color: ColorAliases.neutral100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: width * 0.4,
            color: UIColors.iconPrimary,
          ),
          if (width > 50) ...[
            const SizedBox(height: 4),
            Text(
              category,
              style: TextStyle(
                color: UIColors.textDisabled,
                fontSize: width * 0.15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  String _getUserName(Map<String, dynamic> postData) {
    final userInfo = postData['user'] ?? {};
    return userInfo['display_name'] ??
        userInfo['username'] ??
        postData['display_name'] ??
        postData['username'] ??
        'Usuário';
  }

  DateTime _parseDate(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    if (dateString is DateTime) return dateString;
    return DateTime.tryParse(dateString.toString()) ?? DateTime.now();
  }

  String _buildLocationString(Map<String, dynamic> spotInfo) {
    final city = spotInfo['city'] ?? '';
    final country = spotInfo['country'] ?? '';

    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return '';
  }

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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return words[0][0].toUpperCase();
    }
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }
}
