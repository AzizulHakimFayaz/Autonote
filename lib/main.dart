import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const AutoNoteApp());
}

class AutoNoteApp extends StatelessWidget {
  const AutoNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoNote AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF13151A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E2025),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Or standard font
        cardTheme: CardThemeData(
          color: const Color(0xFF1E2025),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFF2A2D35),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
      ),
      home: const HomePage(),
    );
  }
}
