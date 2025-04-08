import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Cabeçalho com foto do usuário
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícone do usuário
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Nome do usuário
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'user_name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Itens do menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(Icons.home, 'Home', context),
                _buildMenuItem(Icons.person, 'Perfil', context),
                _buildMenuItem(Icons.map, 'Mapa', context),
                _buildMenuItem(Icons.search, 'Busca', context),
                _buildMenuItem(Icons.list, 'Bucketlist', context),
                _buildMenuItem(Icons.book, 'Travel Journal', context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir os itens do menu
  Widget _buildMenuItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(color: Colors.grey[700], fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context);
        // Adicionar a navegação para cada tela aqui posteriormente
      },
    );
  }
}
