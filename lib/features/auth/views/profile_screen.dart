import 'package:flutter/material.dart';
<<<<<<< HEAD
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
    // Hapus sesi aktif
    await _storage.delete(key: 'active_email');
    await _storage.delete(key: 'active_username');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil Logout!')),
    );
    
    // KELUAR KE HALAMAN LOGIN
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Menghapus riwayat halaman sebelumnya agar tidak bisa tombol 'Back'
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
=======
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile'), backgroundColor: Colors.transparent),
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
<<<<<<< HEAD
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF6C5CE7),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _username,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Container Pengaturan
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
=======
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF6C5CE7),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text('CyberRunner#77', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('runner@geezus.io', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF1E1E2C),
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.straighten, color: Color(0xFF6C5CE7)),
<<<<<<< HEAD
                    title: const Text('Distance Unit', style: TextStyle(color: Colors.white)),
                    trailing: const Text('Miles (mi)', style: TextStyle(color: Colors.grey)),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange, color: Color(0xFF6C5CE7)),
                    title: const Text('Currency Display', style: TextStyle(color: Colors.white)),
                    trailing: const Text('IDR (Rp)', style: TextStyle(color: Colors.grey)),
                    onTap: () {},
=======
                    title: const Text('Distance Unit'),
                    trailing: DropdownButton<String>(
                      value: 'Kilometers (km)',
                      dropdownColor: const Color(0xFF1E1E2C),
                      items: ['Kilometers (km)', 'Miles (mi)'].map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                      onChanged: (val) {},
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange, color: Color(0xFF6C5CE7)),
                    title: const Text('Currency Display'),
                    trailing: DropdownButton<String>(
                      value: 'IDR (Rp)',
                      dropdownColor: const Color(0xFF1E1E2C),
                      items: ['IDR (Rp)', 'USD (\$)'].map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                      onChanged: (val) {},
                    ),
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
                  ),
                ],
              ),
            ),
<<<<<<< HEAD
            const SizedBox(height: 20),

            // Container Menu Tambahan
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
=======
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('LOGOUT', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
              ),
            ),
          ],
        ),
      ),
    );
  }
}