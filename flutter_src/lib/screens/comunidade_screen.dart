import 'package:flutter/material.dart';
import 'post_screen.dart'; // Import to use the PostScreen

class ComunidadeScreen extends StatelessWidget {
  const ComunidadeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample post data
    final List<Map<String, dynamic>> posts = [
      {
        'title': 'Minha viagem à Serra do Cipó',
        'username': 'aventureiro123',
        'imageUrl': '', // Empty for placeholder
        'description': 'Compartilhando minha experiência incrível na Serra do Cipó. Trilhas maravilhosas, cachoeiras deslumbrantes e muita natureza preservada. Recomendo para quem busca aventura e tranquilidade ao mesmo tempo.',
        'datePosted': DateTime(2025, 5, 1),
      },
      {
        'title': 'Fernando de Noronha - Paraíso Brasileiro',
        'username': 'mariasantos',
        'imageUrl': '', // Empty for placeholder
        'description': 'Um dos lugares mais incríveis que já visitei! Águas cristalinas, praias desertas e uma experiência de mergulho indescritível. Vale cada centavo investido na viagem.',
        'datePosted': DateTime(2025, 4, 28),
      },
      {
        'title': 'Fim de semana em Bonito-MS',
        'username': 'joaoviajante',
        'imageUrl': '', // Empty for placeholder
        'description': 'Passei um final de semana em Bonito e fiquei impressionado com a transparência das águas dos rios. Flutuação, mergulho e caminhadas em meio à natureza fizeram desta uma viagem memorável.',
        'datePosted': DateTime(2025, 4, 15),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comunidade',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

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
                  // Navegar para a tela de detalhes do post
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
    final boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do post com nome de usuário
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(datePosted),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Título do post
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Imagem do post
            Container(
              width: double.infinity,
              height: 200,
              decoration: boxDecoration,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
              )
                  : Center(
                child: Icon(
                  Icons.photo,
                  size: 64,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                ),
              ),
            ),

            // Descrição do post (prévia)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                description.length > 120
                    ? '${description.substring(0, 120)}...'
                    : description,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // Botão para ler mais
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('Ler mais'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format the date
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];

    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}