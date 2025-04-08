import 'package:flutter/material.dart';

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
          const PlaceholderGrid(count: 4, columns: 4),

          const SizedBox(height: 24),
          // Seção 2
          const SectionTitle(text: 'Popular'),
          const SizedBox(height: 8),
          const PlaceholderGrid(count: 4, columns: 4),

          const SizedBox(height: 24),
          // Seção 3
          const SectionTitle(text: 'Recomendações Sazonais'),
          const SizedBox(height: 8),
          const PlaceholderGrid(count: 4, columns: 4),
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

  const PlaceholderGrid({Key? key, required this.count, required this.columns})
    : super(key: key);

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
        (index) => Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
