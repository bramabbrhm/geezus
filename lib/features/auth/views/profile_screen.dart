import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geezus/features/auth/views/login_screen.dart';
import 'converters_screen.dart'; 
import 'saran_kesan_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  String _username = 'CyberRunner#77';
  String _email = 'eko@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? savedUsername = await _storage.read(key: 'active_username');
    String? savedEmail = await _storage.read(key: 'active_email');

    setState(() {
      if (savedUsername != null) _username = savedUsername;
      if (savedEmail != null) _email = savedEmail;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    await _storage.delete(key: 'active_email');
    await _storage.delete(key: 'active_username');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil Logout!')),
    );
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('User Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF6C5CE7),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(_username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(_email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF1E1E2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.straighten, color: Color(0xFF6C5CE7)),
                    title: Text('Distance Unit', style: TextStyle(color: Colors.white)),
                    trailing: Text('Miles (mi)', style: TextStyle(color: Colors.grey)),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  const ListTile(
                    leading: Icon(Icons.currency_exchange, color: Color(0xFF6C5CE7)),
                    title: Text('Currency Display', style: TextStyle(color: Colors.white)),
                    trailing: Text('IDR (Rp)', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MENU UTAMA (Tombol navigasi ke Modul Konversi & Zona Waktu)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calculate, color: Color(0xFF6C5CE7)),
                    title: const Text('Modul Konversi & Zona Waktu', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ConvertersScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.comment, color: Color(0xFF6C5CE7)),
                    title: const Text('Saran & Kesan Mata Kuliah PAM', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SaranKesanScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleLogout(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'LOGOUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}