import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pzawnkdtawyqclpzqzue.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6YXdua2R0YXd5cWNscHpxenVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxNjI0NDcsImV4cCI6MjA4OTczODQ0N30.RA-uSclUnQNjewoN6ixWybqYbk8YdvK3qEMTetx9HuE',
  );

  ui.platformViewRegistry.registerViewFactory(
    'webcam-view',
    (int viewId) {
      final video = html.VideoElement()
        ..id = 'attendanceVideo'
        ..autoplay = true
        ..style.width = '100%'
        ..style.height = '100%';
      return video;
    },
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

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
