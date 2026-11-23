import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/utils/notification_service.dart';
import 'shared/root_navigation.dart';
import 'features/auth/views/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env — try real .env first, then .env.example as fallback
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (e) {
      debugPrint('⚠️ Could not load any .env file: $e');
    }
  }

  // Initialize Supabase (URL/key from .env if available, else hardcoded fallback)
  final supabaseUrl = dotenv.env['SUPABASE_URL']?.isNotEmpty == true
      ? dotenv.env['SUPABASE_URL']!
      : 'https://ubzviqaxylkmabsscite.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true
      ? dotenv.env['SUPABASE_ANON_KEY']!
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVienZpcWF4eWxrbWFic3NjaXRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyMzY2MDgsImV4cCI6MjEwNzgxMjYwOH0.Nr47rr0qtYtrNUnGGfGiIcHJZ_MfxntnZHvI93vu5mI';

  // ignore: deprecated_member_use
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Initialize notification service (skips on Web automatically)
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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C5CE7),
          secondary: Color(0xFF9C88FF),
          surface: Color(0xFF1E1E2C),
        ),
      ),
      home: const _StartupRouter(),
    );
  }
}

/// Routes to Login or Home based on existing session
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    bool loggedIn = false;

    // 1. Check Supabase session first
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        loggedIn = true;
      }
    } catch (_) {}

    // 2. Fall back to local session in secure storage
    if (!loggedIn) {
      try {
        const storage = FlutterSecureStorage();
        final activeEmail = await storage.read(key: 'active_email');
        if (activeEmail != null && activeEmail.isNotEmpty) {
          loggedIn = true;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on, size: 70, color: Color(0xFF6C5CE7)),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              SizedBox(height: 16),
              Text(
                'GEEZUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? const RootNavigation() : const LoginScreen();
  }
}
