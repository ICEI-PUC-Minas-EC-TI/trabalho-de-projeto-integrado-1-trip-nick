import 'package:flutter/material.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';

class MinhasViagensScreen extends StatelessWidget {
  const MinhasViagensScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen title
          Text(
            'Minhas Viagens',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 24),

          // First section
          _buildTravelSection(
            context: context,
            title: 'Viagens Recentes',
            description: 'Relembre suas últimas aventuras e compartilhe suas experiências mais marcantes com a comunidade.',
            itemCount: 3,
          ),

          const SizedBox(height: 32),

          // Second section
          _buildTravelSection(
            context: context,
            title: 'Favoritos',
            description: 'Os destinos que mais marcaram suas jornadas e que você sempre recomenda para outros viajantes.',
            itemCount: 2,
          ),

          const SizedBox(height: 32),

          // Statistics section
          _buildStatsSection(context),
        ],
      ),
    );
  }

  Widget _buildTravelSection({
    required BuildContext context,
    required String title,
    required String description,
    required int itemCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),

        // Travel items grid
        GridView.count(
          crossAxisCount: itemCount == 3 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
          children: List.generate(
            itemCount,
                (index) => _buildTravelItem(context, index),
          ),
        ),

        const SizedBox(height: 16),

        // Section description
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTravelItem(BuildContext context, int index) {
    final List<Map<String, dynamic>> sampleTrips = [
      {
        'icon': Icons.beach_access,
        'name': 'Praia do Rosa',
        'location': 'SC',
      },
      {
        'icon': Icons.landscape,
        'name': 'Serra do Cipó',
        'location': 'MG',
      },
      {
        'icon': Icons.water,
        'name': 'Bonito',
        'location': 'MS',
      },
      {
        'icon': Icons.water,
        'name': 'Fernando de Noronha',
        'location': 'PE',
      },
      {
        'icon': Icons.park,
        'name': 'Chapada dos Veadeiros',
        'location': 'GO',
      },
    ];

    final trip = sampleTrips[index % sampleTrips.length];

    return Container(
      decoration: BoxDecoration(
        color: ColorAliases.white,
        border: Border.all(
          color: UIColors.borderPrimary,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to trip details
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                trip['icon'],
                size: 32,
                color: ColorAliases.primaryDefault,
              ),
              const SizedBox(height: 8),
              Text(
                trip['name'],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                trip['location'],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        border: Border.all(color: UIColors.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suas Estatísticas',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.place,
                  value: '12',
                  label: 'Destinos\nVisitados',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.route,
                  value: '2.3k',
                  label: 'Km\nPercorridos',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.photo_camera,
                  value: '184',
                  label: 'Fotos\nCompartilhadas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: ColorAliases.primaryDefault,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: ColorAliases.primaryDefault,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}