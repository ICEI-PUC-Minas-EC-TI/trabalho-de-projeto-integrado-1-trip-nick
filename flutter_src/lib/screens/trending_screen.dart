import 'package:flutter/material.dart';
import 'spot_screen.dart'; // Import the TouristSpotScreen

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção 1
          const SectionTitle(text: 'Perto de Você'),
          const SizedBox(height: 8),
          PlaceholderGrid(count: 4, columns: 4, context: context),

          const SizedBox(height: 24),
          // Seção 2
          const SectionTitle(text: 'Popular'),
          const SizedBox(height: 8),
          PlaceholderGrid(count: 4, columns: 4, context: context),

          const SizedBox(height: 24),
          // Seção 3
          const SectionTitle(text: 'Recomendações Sazonais'),
          const SizedBox(height: 8),
          PlaceholderGrid(count: 4, columns: 4, context: context),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20, // Aumentando um pouco para ficar mais visível
        fontWeight: FontWeight.bold,
      ),
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

  // Sample data for demonstration
  Map<String, dynamic> getSampleData(int index) {
    // List of sample tourist spots
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
    ];

    // Return data for the given index, cycling through sample spots if needed
    return sampleSpots[index % sampleSpots.length];
  }

  @override
  Widget build(BuildContext context) {
    // Cor da borda = cor do topo (outra opção: Colors.green)
    final borderColor = Theme.of(context).primaryColor;

    return GridView.count(
      crossAxisCount: columns, // Ex.: 2 colunas
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9, // mantém quadrado
      children: List.generate(
        count, // Ex.: 4 itens
            (index) => GestureDetector(
          onTap: () {
            // Get sample data for this index
            final spotData = getSampleData(index);

            // Navigate to TouristSpotScreen with the sample data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TouristSpotScreen(
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
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              color: Colors.white,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getSampleData(index)['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}