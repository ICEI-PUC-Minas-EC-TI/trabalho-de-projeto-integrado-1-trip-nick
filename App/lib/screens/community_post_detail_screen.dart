//screens/community_post_detail_screen.dart

import 'package:flutter/material.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../widgets/spot_card_swiper.dart';

class CommunityPostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> postData;

  const CommunityPostDetailScreen({Key? key, required this.postData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title =
        postData['title'] ??
        postData['community_title'] ??
        'Post da Comunidade';
    final description = postData['description'] ?? '';
    final userName = _getUserName(postData);
    final createdDate = _parseDate(postData['created_date']);
    final listInfo = postData['list'] ?? {};
    final spots = _extractSpots(postData);
    final postImageUrl = _extractPostImageUrl(postData);

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
          'Post da Comunidade',
          style: const TextStyle(
            color: UIColors.textHeadings,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [_buildPostTypeChip(), const SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with image and title
            _buildHeaderSection(title, postImageUrl),

            // User info section
            _buildUserInfoSection(userName, createdDate),

            // Description section
            if (description.isNotEmpty) _buildDescriptionSection(description),

            // Spots section with swiper
            if (spots.isNotEmpty) _buildSpotsSection(spots),

            // Bottom padding
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorAliases.primaryDefault.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorAliases.primaryDefault.withOpacity(0.3)),
      ),
      child: Text(
        'COMUNIDADE',
        style: TextStyle(
          color: ColorAliases.primaryDefault,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String title, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UIColors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post image if available
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            // Debug: Check image URL
            () {
              print('DEBUG: Image URL provided: $imageUrl');
              print('DEBUG: Image URL length: ${imageUrl.length}');
              return Container(); // Empty container, won't affect layout
            }(),

            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      print(
                        'DEBUG: Image loaded successfully for URL: $imageUrl',
                      );
                      return child;
                    }

                    // Debug loading progress
                    final progress =
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null;
                    print(
                      'DEBUG: Image loading progress: ${progress != null ? '${(progress * 100).toStringAsFixed(1)}%' : 'unknown'}',
                    );
                    print(
                      'DEBUG: Bytes loaded: ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes ?? 'unknown'}',
                    );

                    return Container(
                      color: ColorAliases.neutral100,
                      child: Center(
                        child: CircularProgressIndicator(value: progress),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Debug error information
                    print('DEBUG: Image loading failed for URL: $imageUrl');
                    print('DEBUG: Error: $error');
                    print('DEBUG: Stack trace: $stackTrace');

                    return Container(
                      color: ColorAliases.neutral100,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: UIColors.iconPrimary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            // Debug: No image case
            () {
              print(
                'DEBUG: No image to display - imageUrl is ${imageUrl == null ? 'null' : 'empty'}',
              );
              return Container(); // Empty container, won't affect layout
            }(),
          ],

          // Post title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: UIColors.textHeadings,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(String userName, DateTime createdDate) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: ColorAliases.primaryDefault.withOpacity(0.1),
            child: Text(
              _getInitials(userName),
              style: TextStyle(
                color: ColorAliases.primaryDefault,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
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
                const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: UIColors.iconPrimary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textHeadings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: UIColors.textBody,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotsSection(List<Map<String, dynamic>> spots) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: SpotCardSwiper(spots: spots, title: 'Locais do Post', height: 320),
    );
  }

  // Helper methods
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

  String? _extractPostImageUrl(Map<String, dynamic> postData) {
    final imageUrl =
        postData['post_image_url'] ??
        postData['imageUrl'] ??
        postData['image_url'] ??
        postData['blob_url'];

    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return imageUrl.toString();
    }
    return null;
  }

  List<Map<String, dynamic>> _extractSpots(Map<String, dynamic> postData) {
    // Try to get spots from different possible locations in the data structure
    final spots = <Map<String, dynamic>>[];

    // From list.spots
    final listInfo = postData['list'] ?? {};
    final listSpots = listInfo['spots'] ?? [];
    if (listSpots is List) {
      spots.addAll(listSpots.cast<Map<String, dynamic>>());
    }

    // From direct spots array
    final directSpots = postData['spots'] ?? [];
    if (directSpots is List) {
      spots.addAll(directSpots.cast<Map<String, dynamic>>());
    }

    return spots;
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
