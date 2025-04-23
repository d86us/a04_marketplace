import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/login_page.dart';
import 'pages/market_page.dart';
import 'pages/favorites_page.dart';
import 'pages/settings_page.dart';
import 'pages/selling_page.dart';
import 'themes/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goat Marketplace',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routes: {
        '/login': (context) => const LoginPage(),
        '/market': (context) => const MarketPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/selling': (context) => const SellingPage(),
        '/settings': (context) => const SettingsPage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MarketPage(); // ⬅️ Go straight to MarketPage
          }
          return const LoginPage();
        },
      ),
    );
  }
}
