import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/tela_login.dart';
import 'package:provider/provider.dart';
import 'design_system/theme.dart';
import 'firebase_options.dart'; // gerado pelo Firebase CLI
import 'providers/spots_provider.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService().initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add providers here - they'll be available throughout the app
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        // Future providers will go here:
        // ChangeNotifierProvider(create: (_) => PostsProvider()),
        // ChangeNotifierProvider(create: (_) => ListsProvider()),
      ],
      child: MaterialApp(
        title: 'Trip Nick',
        theme: AppTheme.lightTheme,
        home: TelaLogin(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
