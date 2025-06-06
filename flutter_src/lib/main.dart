import 'package:flutter/material.dart';
import 'screens/tela_login.dart';
import 'design_system/theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Nick',
      theme: AppTheme.lightTheme,
      home: TelaLogin(),
      debugShowCheckedModeBanner: false,
    );
  }
}