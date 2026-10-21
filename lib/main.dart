import 'package:flutter/material.dart';
import 'features/auth/views/login_screen.dart';

void main() {
  runApp(const GeezusApp());
}

class GeezusApp extends StatelessWidget {
  const GeezusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geezus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const LoginScreen(),
    );
  }
}