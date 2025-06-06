import 'package:flutter/material.dart';
import 'spot_screen.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import 'package:flutter_custom_carousel/flutter_custom_carousel.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen title
          Text(
            'Descobrir',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 24),

          // Section 1
          _buildSection(
            context: context,
            title: 'Perto de Você',
            subtitle: 'Destinos incríveis próximos à sua localização',
            count: 4,
            columns: 2,
          ),

          const SizedBox(height: 32),

          // Section 2
          _buildSection(
            context: context,
            title: 'Popular',
            subtitle: 'Os destinos mais visitados pelos viajantes',
            count: 6,
            columns: 3,
          ),

          const SizedBox(height: 32),

          // Section 3
          _buildSection(
            context: context,
            title: 'Recomendações Sazonais',
            subtitle: 'Perfeito para a época atual do ano',
            count: 4,
            columns: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int count,
    required int columns,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid
        PlaceholderGrid(
          count: count,
          columns: columns,
          context: context,
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

class PlaceholderGrid extends StatelessWidget {
  final int count;
  final int columns;
  final BuildContext context;

  const PlaceholderGrid({
    Key? key,
    required this.count,
    required this.columns,
    required this.context,
  }) : super(key: key);

  Map<String, dynamic> getSampleData(int index) {
    final List<Map<String, dynamic>> sampleSpots = [
      {
        'name': 'Praia do Rosa',
        'imageUrl': '',
        'country': 'Brasil',
        'city': 'Imbituba',
        'category': 'Praia',
        'description': 'Uma bela praia localizada no sul de Santa Catarina, conhecida por suas águas cristalinas e belezas naturais.',
        'rating': 4.8,
      },
      {
        'name': 'Serra do Cipó',
        'imageUrl': '',
        'country': 'Brasil',
        'city': 'Santana do Riacho',
        'category': 'Montanha',
        'description': 'Parque nacional com belas cachoeiras, trilhas e formações rochosas únicas.',
        'rating': 4.6,
      },
      {
        'name': 'Fernando de Noronha',
        'imageUrl': '',
        'country': 'Brasil',
        'city': 'Fernando de Noronha',
        'category': 'Ilha',
        'description': 'Arquipélago paradisíaco com praias de águas cristalinas e rica vida marinha.',
        'rating': 4.9,
      },
      {
        'name': 'Chapada dos Veadeiros',
        'imageUrl': '',
        'country': 'Brasil',
        'city': 'Alto Paraíso de Goiás',
        'category': 'Parque Nacional',
        'description': 'Área de conservação com belas cachoeiras, cânions e formações rochosas antigas.',
        'rating': 4.7,
      },
      {
        'name': 'Bonito',
        'imageUrl': '',
        'country': 'Brasil',
        'city': 'Bonito',
        'category': 'Ecoturismo',
        'description': 'Destino famoso pelas águas cristalinas, grutas e atividades de ecoturismo.',
        'rating': 4.5,
      },
      {
        'name': 'Lençóis Maranhenses',
        'imageUrl': '',
        'country': 'Brasil',
        'city': 'Barreirinhas',
        'category': 'Parque Nacional',
        'description': 'Paisagem única com dunas de areia branca e lagoas de água doce cristalina.',
        'rating': 4.8,
      },
    ];

    return sampleSpots[index % sampleSpots.length];
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: List.generate(
        count,
            (index) => _buildSpotCard(context, index),
      ),
    );
  }

  Widget _buildSpotCard(BuildContext context, int index) {
    final spotData = getSampleData(index);

    return Container(
      decoration: BoxDecoration(
        color: ColorAliases.white,
        border: Border.all(color: UIColors.borderPrimary),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TouristSpotScreen(
                    name: spotData['name'],
                    imageUrl: spotData['imageUrl'],
                    country: spotData['country'],
                    city: spotData['city'],
                    category: spotData['category'],
                    description: spotData['description'],
                    rating: spotData['rating'],
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorAliases.neutral100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: UIColors.borderPrimary),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 32,
                      color: UIColors.iconPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Spot name
              Expanded(
                flex: 1,
                child: Text(
                  spotData['name'],
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 4),

              // Location and rating
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${spotData['city']}, ${spotData['country']}',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star,
                    size: 14,
                    color: ColorAliases.warningDefault,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    spotData['rating'].toString(),
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}