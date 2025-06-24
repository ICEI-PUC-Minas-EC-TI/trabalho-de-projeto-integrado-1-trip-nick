import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';

import 'spot_screen.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../providers/spots_provider.dart';
import '../models/core/spot.dart';
import '../widgets/loading_skeleton.dart';
import '../utils/constants.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({Key? key}) : super(key: key);

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  @override
  void initState() {
    super.initState();
    // Load trending spots when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().loadTrendingSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenTitle(),
          const SizedBox(height: 24),
          _buildTrendingSection(),
          const SizedBox(height: 32),
          _buildPopularSection(),
          const SizedBox(height: 32),
          _buildRecentSection(),
        ],
      ),
    );
  }

  // =============================================================================
  // MAIN SECTIONS
  // =============================================================================

  Widget _buildScreenTitle() {
    return Text('Descobrir', style: Theme.of(context).textTheme.displayMedium);
  }

  Widget _buildTrendingSection() {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        return _buildSection(
          title: 'Em Alta',
          subtitle: 'Destinos em destaque descobertos recentemente',
          content: _buildTrendingContent(spotsProvider),
          errorProvider: spotsProvider,
        );
      },
    );
  }

  Widget _buildPopularSection() {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        final categorySpots = spotsProvider.getTrendingByCategory('Praia');

        return _buildSection(
          title: 'Popular',
          subtitle: 'Os destinos mais visitados pelos viajantes',
          content: _buildCategoryContent(categorySpots, 'Praia'),
          errorProvider: null, // Don't show errors for secondary sections
        );
      },
    );
  }

  Widget _buildRecentSection() {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        final categorySpots = spotsProvider.getTrendingByCategory('Cachoeira');

        return _buildSection(
          title: 'Adicionados Recentemente',
          subtitle: 'Novos destinos descobertos pela comunidade',
          content: _buildCategoryContent(categorySpots, 'Cachoeira'),
          errorProvider: null,
        );
      },
    );
  }

  // =============================================================================
  // SECTION BUILDER
  // =============================================================================

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget content,
    SpotsProvider? errorProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, subtitle),
        const SizedBox(height: 16),
        if (errorProvider?.hasError == true) ...[
          _buildErrorWidget(errorProvider!),
          const SizedBox(height: 16),
        ],
        SizedBox(height: 200, child: content),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  // =============================================================================
  // CONTENT BUILDERS
  // =============================================================================

  Widget _buildTrendingContent(SpotsProvider provider) {
    if (provider.isLoadingTrending) {
      return const TrendingSkeleton(itemCount: 3);
    }

    if (provider.hasError && !provider.hasTrendingData) {
      return _buildEmptyStateWithRetry(provider);
    }

    if (!provider.hasTrendingData) {
      return _buildEmptyState('Nenhum spot encontrado');
    }

    return _buildSpotSwiper(provider.trendingSpots);
  }

  Widget _buildCategoryContent(List<Spot> categorySpots, String category) {
    if (categorySpots.isNotEmpty) {
      return _buildSpotSwiper(categorySpots.take(5).toList());
    }

    return _buildCategoryPlaceholder(category);
  }

  // =============================================================================
  // SWIPER AND SPOT CARDS
  // =============================================================================

  Widget _buildSpotSwiper(List<Spot> spots) {
    return Swiper(
      itemBuilder: (context, index) => _buildSpotCard(spots[index]),
      itemCount: spots.length,
      pagination: const SwiperPagination(),
      control: const SwiperControl(),
      viewportFraction: 0.6,
      scale: 0.9,
      curve: Curves.easeInOut,
      transformer: ScaleAndFadeTransformer(),
    );
  }

  Widget _buildSpotCard(Spot spot) {
    return GestureDetector(
      onTap: () => _navigateToSpotDetail(spot),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _buildCardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildSpotImage(spot),
              _buildImageGradient(),
              _buildSpotInfo(spot),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // SPOT CARD COMPONENTS
  // =============================================================================

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildSpotImage(Spot spot) {
    final imageUrl = AppConstants.getImageUrlWithFallback(
      spot.imageUrl,
      spot.category,
    );

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageError(spot),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildImageLoading(loadingProgress);
      },
    );
  }

  Widget _buildImageError(Spot spot) {
    // Try category placeholder as fallback
    return Image.network(
      AppConstants.getPlaceholderImage(spot.category),
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) => _buildFinalImageFallback(spot),
    );
  }

  Widget _buildFinalImageFallback(Spot spot) {
    return Container(
      color: ColorAliases.neutral100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 50,
            color: UIColors.iconPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            spot.category,
            style: const TextStyle(color: UIColors.textBody, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLoading(ImageChunkEvent loadingProgress) {
    return Container(
      color: ColorAliases.neutral100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: ColorAliases.primaryDefault,
            ),
            const SizedBox(height: 8),
            Text(
              'Carregando...',
              style: TextStyle(color: UIColors.textDisabled, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
    );
  }

  Widget _buildSpotInfo(Spot spot) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpotName(spot.spot_name),
          const SizedBox(height: 4),
          _buildSpotLocation(spot.fullLocation),
          const SizedBox(height: 4),
          _buildSpotTags(spot),
        ],
      ),
    );
  }

  Widget _buildSpotName(String name) {
    return Text(
      name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSpotLocation(String location) {
    return Text(
      location,
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
  }

  Widget _buildSpotTags(Spot spot) {
    return Row(
      children: [
        _buildCategoryTag(spot.category),
        const Spacer(),
        if (spot.hasValidImageUrl) _buildImageIndicator(),
      ],
    );
  }

  Widget _buildCategoryTag(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorAliases.primaryDefault.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildImageIndicator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorAliases.successDefault.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.photo, color: Colors.white, size: 16),
    );
  }

  // =============================================================================
  // EMPTY STATES AND ERRORS
  // =============================================================================

  Widget _buildEmptyState(String message) {
    return Container(
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 48, color: UIColors.iconPrimary),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithRetry(SpotsProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: UIColors.iconPrimary),
            const SizedBox(height: 12),
            Text(
              'Falha ao carregar spots',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => provider.loadTrendingSpots(forceRefresh: true),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPlaceholder(String category) {
    return Container(
      decoration: BoxDecoration(
        color: ColorAliases.neutral100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 48, color: UIColors.iconPrimary),
            const SizedBox(height: 12),
            Text(
              'Nenhum spot de $category encontrado',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(SpotsProvider provider) {
    return Container(
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
              provider.errorMessage ?? 'Erro desconhecido',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: UIColors.textError),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearError();
              provider.loadTrendingSpots(forceRefresh: true);
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // NAVIGATION
  // =============================================================================

  void _navigateToSpotDetail(Spot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TouristSpotScreen(
              name: spot.spot_name,
              imageUrl: AppConstants.getImageUrlWithFallback(
                spot.imageUrl,
                spot.category,
              ),
              country: spot.country,
              city: spot.city,
              category: spot.category,
              description: spot.description ?? 'Descrição não disponível',
              rating: 4.0, // TODO: Get real rating from API
            ),
      ),
    );
  }
}
