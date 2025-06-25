import 'package:flutter/material.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import 'user_profile_screen.dart'; 

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ColorAliases.white,
      child: Column(
        children: [
          // Header with user info (agora clicável)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            decoration: const BoxDecoration(
              color: ColorAliases.primaryDefault,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: ColorAliases.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: ColorAliases.primaryDefault,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User name
                  Text(
                    'user_name',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: UIColors.textOnAction,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // User level or description
                  Text(
                    'Explorador Iniciante',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UIColors.textOnAction.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Perfil',
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.map,
                  title: 'Mapa',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.search,
                  title: 'Busca',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.bookmark,
                  title: 'Lista de Desejos',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.book,
                  title: 'Diário de Viagem',
                  onTap: () => Navigator.pop(context),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),

                _buildMenuItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Configurações',
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Ajuda',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Footer with app version
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Trip Nick v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? UIColors.surfaceActionHover : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? ColorAliases.primaryDefault : UIColors.iconPrimary,
          size: 24,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isActive ? ColorAliases.primaryDefault : UIColors.textBody,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
