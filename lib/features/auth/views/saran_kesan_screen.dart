import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SaranKesanScreen extends StatelessWidget {
  const SaranKesanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saran & Kesan PAM', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.surface),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mata Kuliah: Pemrograman Aplikasi Mobile', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Kesan:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Kuliah PAM sangat menantang dan membuka wawasan luas mengenai pengembangan aplikasi cross-platform modern menggunakan Flutter, mulai dari integrasi sensor hingga arsitektur yang bersih.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 20),
            Text('Saran:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Semoga ke depannya semakin banyak sesi studi kasus penerapan arsitektur modular yang kompleks seperti Web3 dan AI di dalam Flutter.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}