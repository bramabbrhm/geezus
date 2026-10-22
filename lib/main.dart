import 'package:flutter/material.dart';
import 'package:geezus/features/auth/views/login_screen.dart';
import 'core/utils/notification_service.dart';
import 'shared/root_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initNotification();
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
      home: const LoginScreen(),
    );
  }
}
