<<<<<<< HEAD
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geezus/shared/root_navigation.dart';
import 'package:local_auth/local_auth.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // Bisa Email atau Username
  final _passwordController = TextEditingController();
  
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;

  // Fungsi Login Manual dengan Validasi Email/Username & SHA-256 yang Akurat
  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email/Username dan Password wajib diisi!')),
      );
      return;
    }

    // --- VALIDASI PENCEGAHAN TIMPA AKUN ---
    // Cek apakah sudah ada sesi akun lain yang sedang aktif di perangkat ini
    String? currentActiveEmail = await _storage.read(key: 'active_email');
    
    // Tentukan target email dari input identifier (bisa email langsung atau dari username)
    String? targetEmail;
    String? directPasswordHash = await _storage.read(key: 'reg_password_$identifier');
    if (directPasswordHash != null) {
      targetEmail = identifier;
    } else {
      targetEmail = await _storage.read(key: 'username_to_email_$identifier');
    }

    // Jika ada akun lain yang aktif DAN akun tersebut bukan akun yang sedang mencoba login
    if (currentActiveEmail != null && currentActiveEmail != targetEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun $currentActiveEmail masih aktif! Harap Logout terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Batalkan proses login agar sesi lama tidak tertimpa
    }
    // -------------------------------------

    setState(() => _isLoading = true);

    String? matchedEmail;
    
    // 1. Cek langsung jika input adalah Email yang terdaftar
    String? storedDirectHash = await _storage.read(key: 'reg_password_$identifier');
    if (storedDirectHash != null) {
      matchedEmail = identifier;
    } else {
      // 2. Jika bukan email, cek apakah input adalah Username menggunakan pemetaan kunci penghubung
      String? mappedEmailFromUsername = await _storage.read(key: 'username_to_email_$identifier');
      if (mappedEmailFromUsername != null) {
        matchedEmail = mappedEmailFromUsername;
      }
    }

    if (matchedEmail == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Gagal: Akun tidak ditemukan! Silakan Register.')),
      );
      return;
    }

    String? storedPasswordHash = await _storage.read(key: 'reg_password_$matchedEmail');

    // Enkripsi input password dengan SHA-256 untuk dicocokkan
    var bytes = utf8.encode(password);
    var inputPasswordHash = sha256.convert(bytes).toString();

    if (inputPasswordHash == storedPasswordHash) {
      // Simpan sesi aktif
      await _storage.write(key: 'active_email', value: matchedEmail);
      String? username = await _storage.read(key: 'reg_username_$matchedEmail');
      if (username != null) {
        await _storage.write(key: 'active_username', value: username);
      }
      
      // Tandai biometrik aktif untuk perangkat ini
      await _storage.write(key: 'biometric_enabled', value: 'true');

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Berhasil! Selamat datang.')),
      );

      // LANGSUNG MASUK KE HALAMAN UTAMA 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RootNavigation()), 
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Gagal: Password salah!')),
      );
    }
  }

  // Fungsi Login Biometrik (Sidik Jari) yang Langsung Masuk
  Future<void> _handleBiometricLogin() async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
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
        // Cek apakah ada sesi akun yang pernah aktif sebelumnya di perangkat ini
        String? activeEmail = await _storage.read(key: 'active_email');
        if (activeEmail != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autentikasi Biometrik Berhasil!')),
          );

          // LANGSUNG MASUK KE HALAMAN UTAMA OTOMATIS
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

              // Tombol Login dengan Biometrik (Sidik Jari)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleBiometricLogin,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fingerprint, color: Color(0xFF6C5CE7)),
                      SizedBox(width: 8),
                      Text(
                        'Login with Biometrics',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tautan ke Halaman Register
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Belum punya akun? Register di sini',
                  style: TextStyle(color: Color(0xFF6C5CE7)),
=======
import 'package:flutter/material.dart';
import '../../../shared/root_navigation.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.bolt, size: 80, color: Color(0xFF6C5CE7)),
              const SizedBox(height: 16),
              const Text(
                'GEEZUS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const Text(
                'Gamified Fitness & Web3 Experience',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username / Email',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const RootNavigation()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Biometric Auth Action Placeholder
                },
                icon: const Icon(Icons.fingerprint, color: Color(0xFF6C5CE7)),
                label: const Text('Login with Biometrics'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}