import 'package:flutter/material.dart';
import 'post_screen.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';

class ComunidadeScreen extends StatelessWidget {
  const ComunidadeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample post data
    final List<Map<String, dynamic>> posts = [
      {
        'title': 'Minha viagem à Serra do Cipó',
        'username': 'aventureiro123',
        'imageUrl': '',
        'description': 'Compartilhando minha experiência incrível na Serra do Cipó. Trilhas maravilhosas, cachoeiras deslumbrantes e muita natureza preservada. Recomendo para quem busca aventura e tranquilidade ao mesmo tempo.',
        'datePosted': DateTime(2025, 5, 1),
      },
      {
        'title': 'Fernando de Noronha - Paraíso Brasileiro',
        'username': 'mariasantos',
        'imageUrl': '',
        'description': 'Um dos lugares mais incríveis que já visitei! Águas cristalinas, praias desertas e uma experiência de mergulho indescritível. Vale cada centavo investido na viagem.',
        'datePosted': DateTime(2025, 4, 28),
      },
      {
        'title': 'Fim de semana em Bonito-MS',
        'username': 'joaoviajante',
        'imageUrl': '',
        'description': 'Passei um final de semana em Bonito e fiquei impressionado com a transparência das águas dos rios. Flutuação, mergulho e caminhadas em meio à natureza fizeram desta uma viagem memorável.',
        'datePosted': DateTime(2025, 4, 15),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen title using theme
          Text(
            'Comunidade',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 24),

          // Lista de posts da comunidade
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                title: post['title'],
                username: post['username'],
                imageUrl: post['imageUrl'],
                description: post['description'],
                datePosted: post['datePosted'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostScreen(
                        title: post['title'],
                        username: post['username'],
                        imageUrl: post['imageUrl'],
                        description: post['description'],
                        datePosted: post['datePosted'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String title;
  final String username;
  final String imageUrl;
  final String description;
  final DateTime datePosted;
  final VoidCallback onTap;

  const PostCard({
    Key? key,
    required this.title,
    required this.username,
    required this.imageUrl,
    required this.description,
    required this.datePosted,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with user info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ColorAliases.primaryDefault,
                    child: Text(
                      username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: UIColors.textOnAction,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(datePosted),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Post title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Post image
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: UIColors.borderPrimary),
                borderRadius: BorderRadius.circular(4),
                color: ColorAliases.neutral100,
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: UIColors.iconPrimary,
                      ),
                    );
                  },
                ),
              )
                  : const Center(
                child: Icon(
                  Icons.image,
                  size: 40,
                  color: UIColors.iconPrimary,
                ),
              ),
            ),

            // Post description preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description.length > 120
                        ? '${description.substring(0, 120)}...'
                        : description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  // Read more button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: const Text('Ler mais'),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];

    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}