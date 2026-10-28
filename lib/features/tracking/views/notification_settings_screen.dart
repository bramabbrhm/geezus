import 'package:flutter/material.dart';
import '../../../core/utils/notification_service.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Pengingat & Notifikasi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildNotificationTile(
              title: 'Pengingat Minum Air 💧',
              subtitle: 'Kirim notifikasi tes hidrasi tubuh',
              icon: Icons.water_drop,
              iconColor: Colors.lightBlueAccent,
              onPressed: () => NotificationService.showHydrationReminder(),
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              title: 'Pengingat Jadwal Lari 🏃‍♂️',
              subtitle: 'Kirim notifikasi tes lari harian',
              icon: Icons.directions_run,
              iconColor: Colors.orangeAccent,
              onPressed: () => NotificationService.showRunReminder(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
          onPressed: onPressed,
          child: const Text('Tes', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}