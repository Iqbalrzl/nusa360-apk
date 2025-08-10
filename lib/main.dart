import 'package:flutter/material.dart';
import 'package:nusa360/pages/languange_select.dart';

void main() {
  runApp(const NusaApp());
}

class NusaApp extends StatelessWidget {
  const NusaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F5EF);
    const primary = Color(0xFFC84E4E);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NUSA 360',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: bg,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Colors.black, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Colors.black, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Colors.black, width: 1.6),
          ),
          hintStyle: const TextStyle(color: Color(0xFF9A9A9A)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            side: const BorderSide(color: Colors.black, width: 1),
            elevation: 1.5,
          ),
        ),
      ),
      home: const LanguagePage(),
    );
  }
}
