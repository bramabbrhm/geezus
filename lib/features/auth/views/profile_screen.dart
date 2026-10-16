import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile'), backgroundColor: Colors.transparent),
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
            const Text('CyberRunner#77', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('runner@geezus.io', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF1E1E2C),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.straighten, color: Color(0xFF6C5CE7)),
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
                  ),
                ],
              ),
            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}