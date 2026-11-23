import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../controllers/auth_controller.dart';
import 'package:geezus/features/auth/views/login_screen.dart';
import 'converters_screen.dart';
import 'saran_kesan_screen.dart';
import '../../tracking/views/notification_settings_screen.dart';
import '../../tracking/views/step_counter_screen.dart';
import '../../tracking/views/search_routes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  final _storage = const FlutterSecureStorage();
  String _username = '';
  String _email = '';
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? savedUsername;
    String? savedEmail;

    // Try Supabase user first
    try {
      final supabaseUser = AuthController.instance.currentUser;
      if (supabaseUser != null) {
        savedEmail = supabaseUser.email;
        savedUsername = supabaseUser.email?.split('@').first;
      }
    } catch (_) {}

    // Fall back to local secure storage
    try {
      savedUsername ??= await _storage.read(key: 'active_username');
      savedEmail ??= await _storage.read(key: 'active_email');
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _username = savedUsername ?? 'Guest';
      _email = savedEmail ?? 'Belum login';
      _isLoadingData = false;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Konfirmasi Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Geezus?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthController.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: _primaryColor,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (_isLoadingData)
              const CircularProgressIndicator(color: _primaryColor)
            else ...[
              Text(
                _username.isEmpty ? 'Guest' : _username,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                _email.isEmpty ? '-' : _email,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),

            // Preferensi
            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.straighten, color: _primaryColor),
                    title: Text('Satuan Jarak', style: TextStyle(color: Colors.white)),
                    trailing: Text('km', style: TextStyle(color: Colors.grey)),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  const ListTile(
                    leading: Icon(Icons.currency_exchange, color: _primaryColor),
                    title: Text('Mata Uang', style: TextStyle(color: Colors.white)),
                    trailing: Text('IDR (Rp)', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu Navigasi — Fitur Tracking
            _buildMenuSection(
              title: 'Fitur Tracking',
              items: [
                _buildMenuTile(
                  icon: Icons.notifications_active,
                  iconColor: Colors.orangeAccent,
                  title: 'Pengaturan Notifikasi',
                  subtitle: 'Jadwalkan pengingat lari & hidrasi',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  ),
                ),
                _buildMenuTile(
                  icon: Icons.directions_walk,
                  iconColor: Colors.greenAccent,
                  title: 'Sensor & Step Counter',
                  subtitle: 'Hitung langkah harian dengan sensor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StepCounterScreen()),
                  ),
                ),
                _buildMenuTile(
                  icon: Icons.map_outlined,
                  iconColor: Colors.blueAccent,
                  title: 'Cari Rute Lari',
                  subtitle: 'Temukan rute lari di sekitar Anda',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchRoutesScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Menu Navigasi — Lainnya
            _buildMenuSection(
              title: 'Lainnya',
              items: [
                _buildMenuTile(
                  icon: Icons.calculate,
                  iconColor: _primaryColor,
                  title: 'Modul Konversi & Zona Waktu',
                  subtitle: 'Konversi mata uang & zona waktu dunia',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConvertersScreen()),
                  ),
                ),
                _buildMenuTile(
                  icon: Icons.comment,
                  iconColor: Colors.amberAccent,
                  title: 'Saran & Kesan Mata Kuliah PAM',
                  subtitle: 'Berikan feedback untuk mata kuliah',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SaranKesanScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
          onTap: onTap,
        ),
        const Divider(height: 1, color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
