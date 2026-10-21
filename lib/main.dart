import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'features/auth/views/login_screen.dart';

void main() {
=======
import 'core/utils/notification_service.dart';
import 'shared/root_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initNotification();
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
  runApp(const GeezusApp());
}

class GeezusApp extends StatelessWidget {
  const GeezusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geezus',
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD
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
=======
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6C5CE7),
      ),
      home: const RootNavigation(),
    );
  }
}
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
