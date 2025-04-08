import 'package:flutter/material.dart';

class ComunidadeScreen extends StatelessWidget {
  const ComunidadeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
      color: Colors.white,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Placeholder Title',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                // Centraliza o quadrado
                child: Container(
                  width:
                      350, // Largura fixa de 200px (ajuste conforme necessário)
                  height: 200,
                  decoration: boxDecoration,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
              'sed do eiusmod tempor incididunt ut labore et dolore magna '
              'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
              'ullamco laboris nisi ut aliquip ex ea commodo consequat.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
