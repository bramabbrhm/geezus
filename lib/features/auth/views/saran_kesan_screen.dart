import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaranKesanScreen extends StatefulWidget {
  const SaranKesanScreen({super.key});

  @override
  State<SaranKesanScreen> createState() => _SaranKesanScreenState();
}

class _SaranKesanScreenState extends State<SaranKesanScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);
  static const String _storageKey = 'pam_saran_kesan_list';

  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  List<Map<String, String>> _feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbackList();
  }

  Future<void> _loadFeedbackList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedList = prefs.getStringList(_storageKey);

      if (savedList != null && savedList.isNotEmpty) {
        final List<Map<String, String>> loaded = [];
        for (final item in savedList) {
          try {
            final decoded = jsonDecode(item) as Map<String, dynamic>;
            loaded.add({
              'author': decoded['author']?.toString() ?? 'Mahasiswa PAM',
              'kesan': decoded['kesan']?.toString() ?? '',
              'saran': decoded['saran']?.toString() ?? '',
              'date': decoded['date']?.toString() ?? '',
            });
          } catch (_) {}
        }
        if (loaded.isNotEmpty) {
          setState(() {
            _feedbackList = loaded;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading feedback from SharedPreferences: $e');
    }

    // Default initial card jika SharedPreferences kosong
    setState(() {
      _feedbackList = [
        {
          'author': 'Mahasiswa PAM (CyberRunner#77)',
          'kesan':
              'Kuliah PAM sangat menantang dan membuka wawasan luas mengenai pengembangan aplikasi cross-platform modern menggunakan Flutter, mulai dari integrasi sensor hingga arsitektur yang bersih.',
          'saran':
              'Semoga ke depannya semakin banyak sesi studi kasus penerapan arsitektur modular yang kompleks seperti Web3 dan AI di dalam Flutter.',
          'date': '28 Okt 2026',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _saveFeedbackList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encodedList = _feedbackList.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList(_storageKey, encodedList);
    } catch (e) {
      debugPrint('Error saving feedback to SharedPreferences: $e');
    }
  }

  Future<void> _handleSubmit() async {
    final kesan = _kesanController.text.trim();
    final saran = _saranController.text.trim();

    if (kesan.isEmpty || saran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Harap isi kedua kolom Kesan dan Saran terlebih dahulu!'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';

    final newFeedback = {
      'author': 'Anda (Mahasiswa PAM)',
      'kesan': kesan,
      'saran': saran,
      'date': dateStr,
    };

    setState(() {
      _feedbackList.insert(0, newFeedback);
    });

    await _saveFeedbackList();

    _kesanController.clear();
    _saranController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: _primaryColor,
        content: Text('🎉 Saran & Kesan PAM berhasil disimpan secara permanen! Terima kasih.'),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Saran & Kesan PAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Mata Kuliah
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school_rounded, color: _primaryColor, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mata Kuliah PAM',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pemrograman Aplikasi Mobile • Semester Gasal',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Input Kesan & Saran Baru
            const Text(
              'Tulis Feedback Anda',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Input Kesan
            TextField(
              controller: _kesanController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Kesan selama perkuliahan',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'Contoh: Materi praktikum sangat aplikatif...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: _cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Input Saran
            TextField(
              controller: _saranController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Saran untuk perbaikan ke depan',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'Contoh: Tambahkan sesi hands-on deployment...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: _cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Kirim
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleSubmit,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Kirim Saran & Kesan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Riwayat Feedback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Feedback Terkirim',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_feedbackList.length} Entri',
                    style: const TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: _primaryColor))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _feedbackList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _feedbackList[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle, color: _primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  item['author'] ?? 'Anonim',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              item['date'] ?? '',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kesan:',
                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['kesan'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Saran:',
                          style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['saran'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
