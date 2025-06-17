import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/tela_login.dart';
import 'design_system/theme.dart';
import 'firebase_options.dart'; // gerado pelo Firebase CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

