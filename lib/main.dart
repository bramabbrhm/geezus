import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/notification_service.dart';
import 'shared/root_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initNotification();
  await Supabase.initialize(
    url: 'https://ubzviqaxylkmabsscite.supabase.co', // Ganti dengan Project URL kamu
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVienZpcWF4eWxrbWFic3NjaXRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyMzY2MDgsImV4cCI6MjEwNzgxMjYwOH0.Nr47rr0qtYtrNUnGGfGiIcHJZ_MfxntnZHvI93vu5mI',            // Anon Key
  );
try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e. Using environment fallbacks.');
  }// Masukkan sebelum runApp
  runApp(const GeezusApp());
}

class GeezusApp extends StatelessWidget {
  const GeezusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geezus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6C5CE7),
      ),
      home: const RootNavigation(),
    );
  }
}
