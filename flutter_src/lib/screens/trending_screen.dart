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
          // Screen title
          Text('Descobrir', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),

          // Section 1 - Trending Spots
          _buildTrendingSection(context),

          const SizedBox(height: 32),

          // Section 2 - Popular by Category (placeholder for now)
          _buildCategorySection(
            context: context,
            title: 'Popular',
            subtitle: 'Os destinos mais visitados pelos viajantes',
            category: 'Praia', // Example category
          ),

          const SizedBox(height: 32),

          // Section 3 - Recent Additions
          _buildCategorySection(
            context: context,
            title: 'Adicionados Recentemente',
            subtitle: 'Novos destinos descobertos pela comunidade',
            category: 'Cachoeira', // Example category
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(BuildContext context) {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Em Alta',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Destinos em destaque descobertos recentemente',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error handling
            if (spotsProvider.hasError) ...[
              _buildErrorWidget(context, spotsProvider),
              const SizedBox(height: 16),
            ],

            // Content based on state
            SizedBox(
              height: 200,
              child: _buildTrendingContent(context, spotsProvider),
            ),
          ],
        );
      },
    );
  }

  /// Build trending content based on loading state
  Widget _buildTrendingContent(BuildContext context, SpotsProvider provider) {
    if (provider.isLoadingTrending) {
      // Show skeleton loading
      return const TrendingSkeleton(itemCount: 3);
    }

    if (provider.hasError && !provider.hasTrendingData) {
      // Show error with retry option
      return _buildEmptyStateWithRetry(context, provider);
    }

    if (!provider.hasTrendingData) {
      // No data available
      return _buildEmptyState(context);
    }

    // Show real data in swiper
    return _buildTrendingSwiper(context, provider.trendingSpots);
  }

  /// Build the swiper with real spot data
  Widget _buildTrendingSwiper(BuildContext context, List<Spot> spots) {
    return Swiper(
      itemBuilder: (BuildContext context, int index) {
        final spot = spots[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TouristSpotScreen(
                      name: spot.spot_name,
                      imageUrl:
                          spot.imageUrl ?? AppConstants.defaultSpotImageUrl,
                      country: spot.country,
                      city: spot.city,
                      category: spot.category,
                      description:
                          spot.description ?? 'Descrição não disponível',
                      rating: 4.5, // TODO: Get real rating from API
                    ),
              ),
            );
          },
          child: _buildSpotCard(spot),
        );
      },
      itemCount: spots.length,
      pagination: const SwiperPagination(),
      control: const SwiperControl(),
      viewportFraction: 0.6,
      scale: 0.9,
      curve: Curves.easeInOut,
      transformer: ScaleAndFadeTransformer(),
    );
  }

  /// Build individual spot card
  Widget _buildSpotCard(Spot spot) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              spot.imageUrl ?? AppConstants.defaultSpotImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: ColorAliases.neutral100,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: UIColors.iconPrimary,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: ColorAliases.neutral100,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Spot information
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spot.spot_name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.fullLocation,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorAliases.primaryDefault.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      spot.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category section (using sample data for now)
  Widget _buildCategorySection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String category,
  }) {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        // Get spots for this category from loaded trending spots
        final categorySpots = spotsProvider.getTrendingByCategory(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            SizedBox(
              height: 200,
              child:
                  categorySpots.isNotEmpty
                      ? _buildTrendingSwiper(
                        context,
                        categorySpots.take(5).toList(),
                      )
                      : _buildCategoryPlaceholder(context, category),
            ),
          ],
        );
      },
    );
  }

  /// Placeholder for categories with no data
  Widget _buildCategoryPlaceholder(BuildContext context, String category) {
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

  /// Error widget with retry option
  Widget _buildErrorWidget(BuildContext context, SpotsProvider provider) {
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

  /// Empty state with retry
  Widget _buildEmptyStateWithRetry(
    BuildContext context,
    SpotsProvider provider,
  ) {
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

  /// Empty state (no data)
  Widget _buildEmptyState(BuildContext context) {
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
            Text(
              'Nenhum spot encontrado',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
