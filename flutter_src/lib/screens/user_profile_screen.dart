import 'package:flutter/material.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<Map<String, dynamic>> _userData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      final response = await _apiService.get('/user/profile');
      return response;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do usuário: $e')),
      );
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meu Perfil',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: UIColors.textOnAction,
              ),
        ),
        backgroundColor: ColorAliases.primaryDefault,
        iconTheme: const IconThemeData(color: UIColors.textOnAction),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Erro ao carregar dados',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final userData = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 64,
                  backgroundColor: ColorAliases.primaryDefault,
                  child: Icon(
                    Icons.person,
                    size: 72,
                    color: ColorAliases.white,
                  ),
                ),
                const SizedBox(height: 24),

                // User Name
                Text(
                  userData['name'] ?? 'Nome não informado',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: UIColors.textHeadings,
                      ),
                ),
                const SizedBox(height: 8),

                // User Level
                Text(
                  userData['level'] ?? 'Explorador Iniciante',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: UIColors.textBody,
                      ),
                ),
                const SizedBox(height: 16),

                // User Bio - NEW SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    userData['bio'] ?? 'Nenhuma biografia informada',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: UIColors.textBody,
                          fontStyle: userData['bio'] == null ? FontStyle.italic : null,
                        ),
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Info Card
                _buildInfoCard(
                  context,
                  title: 'Informações Pessoais',
                  items: [
                    _buildInfoItem(
                      context,
                      icon: Icons.email,
                      label: 'Email',
                      value: userData['email'] ?? 'Não informado',
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Stats Card
                _buildInfoCard(
                  context,
                  title: 'Estatísticas de Viagem',
                  items: [
                    _buildInfoItem(
                      context,
                      icon: Icons.place,
                      label: 'Locais visitados',
                      value: userData['visitedPlaces']?.toString() ?? '0',
                    ),
                    _buildInfoItem(
                      context,
                      icon: Icons.favorite,
                      label: 'Favoritos',
                      value: userData['favorites']?.toString() ?? '0',
                    ),
                    _buildInfoItem(
                      context,
                      icon: Icons.star,
                      label: 'Avaliações',
                      value: userData['reviews']?.toString() ?? '0',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Edit Profile Button
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement edit profile functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorAliases.primaryDefault,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Editar Perfil',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: UIColors.textOnAction,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ColorAliases.primaryDefault,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: ColorAliases.primaryDefault, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: UIColors.textBody.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: UIColors.textBody,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
