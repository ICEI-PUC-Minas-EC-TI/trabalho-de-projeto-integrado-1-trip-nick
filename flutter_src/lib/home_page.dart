import 'package:flutter/material.dart';
import 'screens/trending_screen.dart';
import 'screens/minhas_viagens_screen.dart';
import 'screens/comunidade_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/post_creation_screen.dart'; // Import our new placeholder screen
import 'widgets/speed_dial_fab.dart'; // Import our new SpeedDialFAB

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const MenuScreen(),
        appBar: AppBar(
          leading: Builder(
            // Builder adicionado aqui
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(''),
          bottom: const TabBar(
            isScrollable: true,
            labelStyle: TextStyle(fontSize: 14),
            labelPadding: EdgeInsets.symmetric(horizontal: 12),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Trending'),
              Tab(text: 'Minhas Viagens'),
              Tab(text: 'Comunidade'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Main tab content
            const TabBarView(
              children: [
                TrendingScreen(),
                MinhasViagensScreen(),
                ComunidadeScreen(),
              ],
            ),

            // Floating SpeedDial FAB positioned in bottom-right
            Positioned(
              bottom: 16,
              right: 16,
              child: SpeedDialFAB(
                onCreatePost: () => _navigateToPostCreation(context),
                onCreateList: () => _navigateToListCreation(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to the post creation screen as a full-screen modal
  void _navigateToPostCreation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PostCreationScreen(),
        fullscreenDialog: true, // This makes it open as a modal from bottom
      ),
    );
  }

  /// Navigates to the list creation screen as a full-screen modal
  void _navigateToListCreation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ListCreationScreen(),
        fullscreenDialog: true, // This makes it open as a modal from bottom
      ),
    );
  }
}
