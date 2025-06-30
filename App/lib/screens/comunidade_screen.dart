//screens/comunidade_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../providers/posts_provider.dart';
import '../utils/constants.dart';
import 'community_post_detail_screen.dart';
import 'list_post_detail_screen.dart';
import 'spot_screen.dart';

// Note: Removed the PostDetailScreen class as it's now replaced by specific post detail screens

class ComunidadeScreen extends StatefulWidget {
  const ComunidadeScreen({Key? key}) : super(key: key);

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> {
  // ScrollController for infinite scroll
  late ScrollController _scrollController;

  // Pagination state
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setupScrollListener();
    _loadInitialPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Setup scroll listener for pagination
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Trigger pagination when user scrolls to 85% of content
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.85) {
        _loadMorePosts();
      }
    });
  }

  /// Load initial posts (first page)
  void _loadInitialPosts() {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.loadAllPosts(page: 1, limit: 20, forceRefresh: true);
  }

  /// Load more posts for pagination
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _hasReachedEnd) return;

    setState(() {
      _isLoadingMore = true;
    });

    final postsProvider = Provider.of<PostsProvider>(context, listen: false);

    try {
      final nextPage = _currentPage + 1;
      await postsProvider.loadAllPosts(page: nextPage, limit: 20);

      // If we got fewer posts than requested, we've reached the end
      final newPostsCount =
          postsProvider.allPosts.length - ((_currentPage - 1) * 20);
      if (newPostsCount < 20) {
        _hasReachedEnd = true;
      }

      _currentPage = nextPage;
    } catch (e) {
      debugPrint('Error loading more posts: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// Pull to refresh handler
  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _hasReachedEnd = false;
      _isLoadingMore = false;
    });

    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    await postsProvider.loadAllPosts(page: 1, limit: 20, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, child) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Screen Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Comunidade',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),

              // Posts Content
              _buildPostsContent(postsProvider),
            ],
          ),
        );
      },
    );
  }

  /// Build posts content based on current state
  Widget _buildPostsContent(PostsProvider postsProvider) {
    // Initial loading state
    if (postsProvider.isLoadingPosts && postsProvider.allPosts.isEmpty) {
      return _buildInitialLoadingState();
    }

    // Error state (only show if no posts loaded)
    if (postsProvider.postsErrorMessage != null &&
        postsProvider.allPosts.isEmpty) {
      return _buildErrorState(postsProvider.postsErrorMessage!);
    }

    // Empty state
    if (postsProvider.allPosts.isEmpty && !postsProvider.isLoadingPosts) {
      return _buildEmptyState();
    }

    // Posts list with pagination
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Show posts
          if (index < postsProvider.allPosts.length) {
            return _buildPostCard(postsProvider.allPosts[index]);
          }

          // Show loading indicator at bottom
          if (index == postsProvider.allPosts.length && _isLoadingMore) {
            return _buildPaginationLoadingIndicator();
          }

          // Show pagination error if needed
          if (index == postsProvider.allPosts.length &&
              postsProvider.postsErrorMessage != null &&
              !postsProvider.isLoadingPosts) {
            return _buildPaginationErrorIndicator(
              postsProvider.postsErrorMessage!,
            );
          }

          return null;
        },
        childCount:
            postsProvider.allPosts.length +
            (_isLoadingMore || postsProvider.postsErrorMessage != null ? 1 : 0),
      ),
    );
  }

  /// Build initial loading state (skeleton)
  Widget _buildInitialLoadingState() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildPostCardSkeleton(),
        childCount: 5, // Show 5 skeleton cards
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String errorMessage) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: UIColors.iconError),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar posts',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: UIColors.textDisabled),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadInitialPosts,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 64, color: UIColors.iconPrimary),
              const SizedBox(height: 16),
              Text(
                'Nenhum post encontrado',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Seja o primeiro a compartilhar uma experiência com a comunidade!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: UIColors.textDisabled),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build pagination loading indicator
  Widget _buildPaginationLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ColorAliases.primaryDefault,
          ),
        ),
      ),
    );
  }

  /// Build pagination error indicator
  Widget _buildPaginationErrorIndicator(String errorMessage) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.error100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UIColors.borderError),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: UIColors.iconError),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Erro ao carregar mais posts: $errorMessage',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: UIColors.textError),
            ),
          ),
          TextButton(
            onPressed: _loadMorePosts,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  /// Build post card skeleton (placeholder)
  Widget _buildPostCardSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post type chip skeleton
          Row(
            children: [
              _buildShimmerContainer(width: 80, height: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),

          // Title skeleton
          _buildShimmerContainer(width: double.infinity, height: 20),
          const SizedBox(height: 8),
          _buildShimmerContainer(width: 180, height: 20),
          const SizedBox(height: 12),

          // User info skeleton
          Row(
            children: [
              _buildShimmerContainer(width: 16, height: 16, isCircular: true),
              const SizedBox(width: 8),
              _buildShimmerContainer(width: 100, height: 14),
              const Spacer(),
              _buildShimmerContainer(width: 60, height: 14),
            ],
          ),
          const SizedBox(height: 12),

          // Description skeleton
          _buildShimmerContainer(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          _buildShimmerContainer(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          _buildShimmerContainer(width: 200, height: 14),
        ],
      ),
    );
  }

  /// Build enhanced skeleton with shimmer effect
  Widget _buildShimmerContainer({
    required double width,
    required double height,
    bool isCircular = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: width == double.infinity ? null : width,
          height: height,
          decoration: BoxDecoration(
            color: ColorAliases.neutral200.withOpacity(value),
            borderRadius:
                isCircular
                    ? BorderRadius.circular(height / 2)
                    : BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  /// Build individual post card with polymorphic rendering
  Widget _buildPostCard(Map<String, dynamic> postData) {
    final postType = postData['type'] ?? 'unknown';

    switch (postType) {
      case 'community':
        return _buildCommunityPostCard(postData);
      case 'review':
        return _buildReviewPostCard(postData);
      case 'list':
        return _buildListPostCard(postData);
      default:
        return _buildGenericPostCard(postData);
    }
  }

  /// Build community post card
  Widget _buildCommunityPostCard(Map<String, dynamic> postData) {
    final title =
        postData['title'] ??
        postData['community_title'] ??
        'Post da Comunidade';
    final description = postData['description'] ?? '';
    final userName = _getUserName(postData);
    final createdDate = _parseDate(postData['created_date']);
    final listInfo = postData['list'] ?? {};
    final spotsCount = listInfo['spots_count'] ?? 0;

    return PostCardContainer(
      onTap: () => _navigateToPostDetail(postData),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post type indicator
          _buildPostTypeChip('COMUNIDADE', ColorAliases.primaryDefault),
          const SizedBox(height: 12),

          // Post title
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // User info and date
          _buildUserInfo(userName, createdDate),
          const SizedBox(height: 12),

          // Description
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // Spots count info
          _buildSpotsCountInfo(spotsCount),
        ],
      ),
    );
  }

  /// Build review post card
  Widget _buildReviewPostCard(Map<String, dynamic> postData) {
    final description = postData['description'] ?? '';
    final userName = _getUserName(postData);
    final createdDate = _parseDate(postData['created_date']);
    final rating = (postData['rating'] ?? 0).toDouble();
    final spotInfo = postData['spot'] ?? {};
    final spotName = spotInfo['spot_name'] ?? 'Local não especificado';
    final spotLocation = _buildLocationString(spotInfo);
    final spotCategory = spotInfo['category'] ?? '';
    final spotImageUrl = _extractImageUrl(spotInfo);

    return PostCardContainer(
      onTap: () => _navigateToPostDetail(postData),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post type indicator
          _buildPostTypeChip('AVALIAÇÃO', ColorAliases.success300),
          const SizedBox(height: 12),

          // Spot info with image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spot image
              _buildSpotImage(spotImageUrl, spotCategory, spotName),
              const SizedBox(width: 12),

              // Spot details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spotName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (spotLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: 14,
                            color: UIColors.iconOnDisabled,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              spotLocation,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: UIColors.textDisabled),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Rating stars
                    _buildRatingStars(rating),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User info and date
          _buildUserInfo(userName, createdDate),
          const SizedBox(height: 12),

          // Review description
          if (description.isNotEmpty)
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  /// Build list post card
  Widget _buildListPostCard(Map<String, dynamic> postData) {
    final title = postData['title'] ?? postData['list_title'] ?? 'Lista';
    final description = postData['description'] ?? '';
    final userName = _getUserName(postData);
    final createdDate = _parseDate(postData['created_date']);
    final listInfo = postData['list'] ?? {};
    final listName = listInfo['list_name'] ?? title;
    final isPublic = listInfo['is_public'] ?? false;
    final spotsCount = listInfo['spots_count'] ?? 0;

    return PostCardContainer(
      onTap: () => _navigateToPostDetail(postData),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post type indicator
          _buildPostTypeChip('LISTA', ColorAliases.warning300),
          const SizedBox(height: 12),

          // List title
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // User info and date
          _buildUserInfo(userName, createdDate),
          const SizedBox(height: 12),

          // Description
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // List info
          Row(
            children: [
              // List visibility
              Icon(
                isPublic ? Icons.public : Icons.lock,
                size: 16,
                color: UIColors.iconPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                isPublic ? 'Lista Pública' : 'Lista Privada',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
              ),
              const Spacer(),
              _buildSpotsCountInfo(spotsCount),
            ],
          ),
        ],
      ),
    );
  }

  /// Build generic post card for unknown types
  Widget _buildGenericPostCard(Map<String, dynamic> postData) {
    final description = postData['description'] ?? '';
    final userName = _getUserName(postData);
    final createdDate = _parseDate(postData['created_date']);

    return PostCardContainer(
      onTap: () => _navigateToPostDetail(postData),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generic post indicator
          _buildPostTypeChip('POST', UIColors.iconPrimary),
          const SizedBox(height: 12),

          // User info and date
          _buildUserInfo(userName, createdDate),
          const SizedBox(height: 12),

          // Description
          if (description.isNotEmpty)
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // =============================================================================
  // POST CARD COMPONENTS
  // =============================================================================

  /// Build post type chip
  Widget _buildPostTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Build user info row with avatar
  Widget _buildUserInfo(String userName, DateTime createdDate) {
    return Row(
      children: [
        // User avatar (small)
        _buildUserAvatar(
          null,
          userName,
        ), // TODO: Add user image URL when available
        const SizedBox(width: 8),
        Text(
          userName,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
        ),
        const Spacer(),
        Text(
          _formatDate(createdDate),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
        ),
      ],
    );
  }

  /// Build rating stars
  Widget _buildRatingStars(double rating) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: 16, color: ColorAliases.warning300);
          } else if (index < rating.ceil() && rating % 1 != 0) {
            return Icon(
              Icons.star_half,
              size: 16,
              color: ColorAliases.warning300,
            );
          } else {
            return Icon(
              Icons.star_border,
              size: 16,
              color: UIColors.iconOnDisabled,
            );
          }
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Build spots count info
  Widget _buildSpotsCountInfo(int spotsCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place, size: 16, color: UIColors.iconPrimary),
        const SizedBox(width: 4),
        Text(
          '$spotsCount ${spotsCount == 1 ? 'local' : 'locais'}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
        ),
      ],
    );
  }

  /// Build category icon
  Widget _buildCategoryIcon(String category) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorAliases.primaryDefault.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getCategoryIcon(category),
        size: 20,
        color: ColorAliases.primaryDefault,
      ),
    );
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Get user name from post data
  String _getUserName(Map<String, dynamic> postData) {
    final userInfo = postData['user'] ?? {};
    return userInfo['display_name'] ??
        userInfo['username'] ??
        postData['display_name'] ??
        postData['username'] ??
        'Usuário';
  }

  /// Parse date string to DateTime
  DateTime _parseDate(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    if (dateString is DateTime) return dateString;
    return DateTime.tryParse(dateString.toString()) ?? DateTime.now();
  }

  /// Build location string from spot info
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

  // =============================================================================
  // IMAGE HANDLING METHODS
  // =============================================================================

  /// Extract image URL from spot or post data
  String? _extractImageUrl(Map<String, dynamic> data) {
    // Try different possible image URL fields
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

  /// Build spot image with smart loading and fallbacks
  Widget _buildSpotImage(String? imageUrl, String category, String spotName) {
    return Container(
      width: 60,
      height: 60,
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
          width: 60,
          height: 60,
        ),
      ),
    );
  }

  /// Build user avatar image
  Widget _buildUserAvatar(String? imageUrl, String userName) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: ClipOval(
        child: _buildImageWithFallbacks(
          imageUrl: imageUrl,
          category: 'user',
          fallbackText: userName,
          width: 32,
          height: 32,
          isAvatar: true,
        ),
      ),
    );
  }

  /// Build image with comprehensive fallback strategy
  Widget _buildImageWithFallbacks({
    String? imageUrl,
    required String category,
    required String fallbackText,
    required double width,
    required double height,
    bool isAvatar = false,
  }) {
    // If we have a valid image URL, try to load it
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageLoading(width, height, loadingProgress);
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

    // No image URL, show fallback immediately
    return _buildImageFallback(category, fallbackText, width, height, isAvatar);
  }

  /// Build image loading indicator
  Widget _buildImageLoading(
    double width,
    double height,
    ImageChunkEvent loadingProgress,
  ) {
    final progress =
        loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null;

    return Container(
      width: width,
      height: height,
      color: ColorAliases.neutral100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: width * 0.4,
              height: width * 0.4,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ColorAliases.primaryDefault,
                ),
              ),
            ),
            if (width > 50) ...[
              const SizedBox(height: 4),
              Text(
                progress != null ? '${(progress * 100).toInt()}%' : '...',
                style: const TextStyle(
                  fontSize: 10,
                  color: UIColors.textDisabled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build image fallback with category-appropriate placeholder
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

    // Try category-specific placeholder from Unsplash
    final placeholderUrl = AppConstants.getPlaceholderImage(category);

    return Image.network(
      placeholderUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildImageLoading(width, height, loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFinalImageFallback(category, fallbackText, width, height);
      },
    );
  }

  /// Build avatar fallback with initials
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

  /// Build final fallback when all image loading fails
  Widget _buildFinalImageFallback(
    String category,
    String fallbackText,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category,
                style: TextStyle(
                  color: UIColors.textDisabled,
                  fontSize: width * 0.15,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return words[0][0].toUpperCase();
    }
  }

  /// Get category icon
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

  /// Navigate to post detail screen - THIS IS THE KEY CHANGE
  void _navigateToPostDetail(Map<String, dynamic> postData) {
    final postType = postData['type'] ?? 'unknown';

    switch (postType) {
      case 'community':
        // Navigate to community post detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostDetailScreen(postData: postData),
          ),
        );
        break;

      case 'review':
        // Navigate directly to the reviewed spot
        final spotInfo = postData['spot'] ?? {};
        final spotName = spotInfo['spot_name'] ?? 'Local';
        final spotCategory = spotInfo['category'] ?? '';
        final spotCity = spotInfo['city'] ?? '';
        final spotCountry = spotInfo['country'] ?? '';
        final spotDescription = spotInfo['description'] ?? '';
        final spotImageUrl = _extractImageUrl(spotInfo);
        final spotId = spotInfo['spot_id'] ?? spotInfo['id'] ?? 0;
        final rating = (postData['rating'] ?? 0.0).toDouble();

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
        break;

      case 'list':
        // Navigate to list post detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListPostDetailScreen(postData: postData),
          ),
        );
        break;

      default:
        // For unknown post types, show a simple message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tipo de post não suportado: $postType'),
            backgroundColor: UIColors.iconError,
          ),
        );
    }
  }

  /// Get post title based on type
  String _getPostTitle(Map<String, dynamic> postData) {
    final postType = postData['type'] ?? 'unknown';

    switch (postType) {
      case 'community':
        return postData['title'] ??
            postData['community_title'] ??
            'Post da Comunidade';
      case 'review':
        final spotInfo = postData['spot'] ?? {};
        return 'Avaliação: ${spotInfo['spot_name'] ?? 'Local'}';
      case 'list':
        return postData['title'] ?? postData['list_title'] ?? 'Lista';
      default:
        return 'Post';
    }
  }

  /// Format date for display
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

// =============================================================================
// POST CARD CONTAINER WIDGET
// =============================================================================

/// Reusable container for all post card types
class PostCardContainer extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const PostCardContainer({Key? key, required this.onTap, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: child,
      ),
    );
  }
}
