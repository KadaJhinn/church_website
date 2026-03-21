import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: const Color(0xFF385B4F),
        scaffoldBackgroundColor: Colors.grey[100],

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF385B4F),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF385B4F),
            foregroundColor: Colors.white,
          ),
        ),
      ),

      home: const LoginPage(),
    );
  }
}
