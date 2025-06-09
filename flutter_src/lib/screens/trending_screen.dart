import 'package:flutter/material.dart';
import 'spot_screen.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import 'package:card_swiper/card_swiper.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({Key? key}) : super(key: key);

  // Sample data for Swiper cards
  static const Map<String, dynamic> swiperSampleData = {
    'name': 'Igreja Matriz de Nossa Senhora da Conceição',
    'imageUrl': 'https://store321307560.blob.core.windows.net/images/pompeu.jpg',
    'country': 'Brasil',
    'city': 'Pompéu',
    'category': 'Igreja',
    'description': 'Igreja histórica no centro da cidade de Pompéu, Minas Gerais.',
    'rating': 4.7,
  };

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
          ),

          const SizedBox(height: 32),

          // Section 2
          _buildSection(
            context: context,
            title: 'Popular',
            subtitle: 'Os destinos mais visitados pelos viajantes',
            count: 6,
          ),

          const SizedBox(height: 32),

          // Section 3
          _buildSection(
            context: context,
            title: 'Recomendações Sazonais',
            subtitle: 'Perfeito para a época atual do ano',
            count: 4,
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

        // Card Swiper
        SizedBox(
          height: 200, // Set a fixed height for the swiper
          child: Swiper(
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TouristSpotScreen(
                        name: swiperSampleData['name'],
                        imageUrl: swiperSampleData['imageUrl'],
                        country: swiperSampleData['country'],
                        city: swiperSampleData['city'],
                        category: swiperSampleData['category'],
                        description: swiperSampleData['description'],
                        rating: swiperSampleData['rating'],
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                  child: Image.network(
                    swiperSampleData['imageUrl'],
                    fit: BoxFit.fill,
                  ),
                ),
              );
            },
            itemCount: count, // Use the count parameter
            pagination: SwiperPagination(),
            control: SwiperControl(),
            viewportFraction: 0.6,
            scale: 0.9,
            curve: Curves.easeInOut,
            transformer: ScaleAndFadeTransformer(),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}