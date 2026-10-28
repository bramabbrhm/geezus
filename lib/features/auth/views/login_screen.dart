import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geezus/shared/root_navigation.dart';
import 'package:local_auth/local_auth.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // Email atau Username
  final _passwordController = TextEditingController();
  
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;

  // Fungsi Login dengan Validasi Email/Username via AuthController (Supabase & Fallback Lokal)
  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email/Username dan Password wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await AuthController.instance.signIn(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await _storage.write(key: 'biometric_enabled', value: 'true');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Berhasil! Selamat datang.')),
      );

      // Masuk ke Halaman Utama
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RootNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthController.instance.errorMessage ?? 'Login Gagal: Akun tidak cocok!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi Login Biometrik (Sidik Jari)
  Future<void> _handleBiometricLogin() async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perangkat tidak Mendukung Biometrik!')),
        );
        return;
      }

      bool authenticated = await _auth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke Geezus',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        String? activeEmail = await _storage.read(key: 'active_email');
        if (!mounted) return;
        if (activeEmail != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autentikasi Biometrik Berhasil!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RootNavigation()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan Login manual terlebih dahulu untuk mengaktifkan biometrik pertama kali.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal Biometrik: $e')),
      );
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.flash_on, size: 70, color: Color(0xFF6C5CE7)),
              const SizedBox(height: 16),
              const Text(
                'GEEZUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'Gamified Fitness & Web3 Experience',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 48),

              // Input Username / Email
              TextField(
                controller: _identifierController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username / Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF6C5CE7)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Input Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF6C5CE7)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Login Manual
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'LOGIN',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Login Biometrik
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleBiometricLogin,
                  icon: const Icon(Icons.fingerprint, color: Color(0xFF6C5CE7)),
                  label: const Text(
                    'Login dengan Biometrik',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Pindah ke Halaman Registrasi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? ', style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Daftar Sekarang',
                      style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
