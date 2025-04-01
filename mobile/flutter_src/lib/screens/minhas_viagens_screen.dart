import 'package:flutter/material.dart';

class MinhasViagensScreen extends StatelessWidget {
  const MinhasViagensScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Decoração dos quadrados
    final boxDecoration = BoxDecoration(
      border: Border.all(
        color: Theme.of(context).primaryColor, // Borda verde
        width: 2,
      ),
      color: Colors.white, // Fundo branco
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) Primeiro bloco
          const Text(
            'Placeholder Title',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 0),
          // 3 quadrados em uma só linha
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  decoration: boxDecoration,
                ),
              ),
              const SizedBox(width: 0),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: boxDecoration,
                ),
              ),
              const SizedBox(width: 0),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: boxDecoration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Texto
          const Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
            'sed do eiusmod tempor incididunt ut labore et dolore magna '
            'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
            'ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            style: TextStyle(fontSize: 10),
          ),

          const SizedBox(height: 24),
          // 2) Segundo bloco
          const Text(
            'Placeholder Title',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 0),
          // 2 quadrados em uma só linha
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  decoration: boxDecoration,
                ),
              ),
              const SizedBox(width: 0),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: boxDecoration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Texto que estava faltando
          const Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
            'sed do eiusmod tempor incididunt ut labore et dolore magna '
            'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
            'ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            style: TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

