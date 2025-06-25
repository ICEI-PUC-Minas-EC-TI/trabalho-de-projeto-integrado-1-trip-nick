import 'package:flutter/material.dart';
import 'screens/trending_screen.dart';
import 'screens/minhas_viagens_screen.dart';
import 'screens/comunidade_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/post_creation_screen.dart';
import 'widgets/speed_dial_fab.dart';

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
            // Note: The new SpeedDialFAB handles its own navigation
            const Positioned(bottom: 16, right: 16, child: SpeedDialFAB()),
          ],
        ),
      ),
    );
  }
}
