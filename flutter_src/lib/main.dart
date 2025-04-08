import 'package:flutter/material.dart';
import 'screens/tela_login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Nick',
      theme: ThemeData(
        primaryColor: const Color(0xFFCEDDB6),
        scaffoldBackgroundColor: const Color(0xFFF9F9F4),
      ),
      home: TelaLogin(), // Chama a tela de login aqui
    );
  }
}
