import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/tela_login.dart';
import 'design_system/theme.dart';
import 'firebase_options.dart'; // gerado pelo Firebase CLI
import 'services/api_service.dart';
import 'providers/spots_provider.dart';
import 'providers/posts_provider.dart'; // NEW: Import PostsProvider
import 'providers/reviews_provider.dart';

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
        ChangeNotifierProvider(create: (_) => SpotsProvider()),

        ChangeNotifierProvider(create: (_) => PostsProvider()),

        ChangeNotifierProvider(create: (context) => ReviewsProvider()),
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
