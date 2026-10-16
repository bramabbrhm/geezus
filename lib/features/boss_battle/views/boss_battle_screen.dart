import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BossBattleScreen extends StatefulWidget {
  const BossBattleScreen({super.key});

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends State<BossBattleScreen>
    with SingleTickerProviderStateMixin {
  // Palette Warna Resmi Projek Geezus
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  // Stat Player (Karakter Pahlawan)
  // EXP diakumulasikan dari langkah/lari mingguan
  final int _weeklyExp = 12500; 
  int _playerMaxHp = 1000;
  int _playerCurrentHp = 1000;
  int _playerBaseDamage = 200;

  // Stat Boss Mingguan
  final String _bossName = 'Goliath the Km-Eater';
  int _bossMaxHp = 25000;
  int _bossCurrentHp = 25000;

  // Game State
  bool _isAttacking = false;
  bool _isGameOver = false;
  bool _isVictory = false;
  final List<String> _battleLog = [];

  // Visual & Animation Controller
  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _calculatePlayerStats();

    // Inisialisasi animasi guncangan saat Boss menerima damage
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -12.0, end: 12.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Defensive Programming: Hitung damage & HP berdasarkan Weekly EXP
  void _calculatePlayerStats() {
    try {
      _playerBaseDamage = ((_weeklyExp * 0.15) + 150).round();
      _playerMaxHp = (1000 + (_weeklyExp * 0.05)).round();
      _playerCurrentHp = _playerMaxHp;
    } catch (e) {
      debugPrint('Error kalkulasi stat player: $e');
      _playerBaseDamage = 200;
      _playerMaxHp = 1000;
      _playerCurrentHp = 1000;
    }
  }

  // Logika Serangan Player ke Boss
  void _attackBoss() {
    if (_isAttacking || _isGameOver) return;

    setState(() {
      _isAttacking = true;
    });

    // Jalankan animasi getar pada avatar Boss
    _animController.forward(from: 0.0).then((_) => _animController.reverse());

    // Hitung damage variatif (25% Peluang Critical Hit)
    final random = Random();
    final bool isCritical = random.nextDouble() < 0.25;
    final double multiplier = isCritical ? 1.8 : (0.85 + random.nextDouble() * 0.3);
    final int damageDealt = (_playerBaseDamage * multiplier).round();

    setState(() {
      _bossCurrentHp = max(0, _bossCurrentHp - damageDealt);
      final String critText = isCritical ? '💥 CRITICAL HIT! ' : '';
      _battleLog.insert(
        0,
        '⚔️ ${critText}Kamu menyerang $_bossName sebesar $damageDealt damage!',
      );
    });

    // Cek Kemenangan
    if (_bossCurrentHp <= 0) {
      _endGame(victory: true);
      return;
    }

    // Boss menyerang balik setelah penundaan singkat (600ms)
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _isGameOver) return;

      final int bossDamage = 120 + random.nextInt(130);
      setState(() {
        _playerCurrentHp = max(0, _playerCurrentHp - bossDamage);
        _battleLog.insert(
          0,
          '🔥 $_bossName membalas serangan sebesar $bossDamage damage!',
        );
        _isAttacking = false;
      });

      // Cek Kekalahan
      if (_playerCurrentHp <= 0) {
        _endGame(victory: false);
      }
    });
  }

  // Menampilkan Dialog Akhir Pertarungan
  void _endGame({required bool victory}) {
    setState(() {
      _isGameOver = true;
      _isVictory = victory;
      _isAttacking = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          victory ? '🏆 KEMENANGAN!' : '💀 KEKALAHAN!',
          style: TextStyle(
            color: victory ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: Text(
          victory
              ? 'Selamat! Kamu berhasil menumbangkan $_bossName dan berhak mengklaim 500 Gold & Medali Mingguan!'
              : 'Darah pahlawanmu habis! Terus lakukan lari harian untuk meningkatkan Damage dan HP kamu.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _resetBattle();
            },
            child: const Text(
              'Main Lagi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Reset Ulang Pertarungan
  void _resetBattle() {
    setState(() {
      _bossCurrentHp = _bossMaxHp;
      _playerCurrentHp = _playerMaxHp;
      _isGameOver = false;
      _isVictory = false;
      _battleLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Weekly Boss Battle',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Panel Informasi Weekly EXP
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏃 Weekly EXP Lari:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '$_weeklyExp EXP',
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card Boss & Animasi Shake
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.smart_toy_rounded,
                        size: 80,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bossName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Health Bar Boss
                      _buildHpBar(
                        current: _bossCurrentHp,
                        max: _bossMaxHp,
                        fillColor: Colors.redAccent,
                        label: 'BOSS HP',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card Stat Hero (Player)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🛡️ HERO (KAMU)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'DMG: ~$_playerBaseDamage',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildHpBar(
                      current: _playerCurrentHp,
                      max: _playerMaxHp,
                      fillColor: Colors.greenAccent,
                      label: 'HERO HP',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Battle Log Box
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: _battleLog.isEmpty
                      ? const Center(
                          child: Text(
                            'Tekan tombol SERANG BOSS untuk memulai!',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _battleLog.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _battleLog[index],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Serang
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAttacking ? Colors.grey : _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  onPressed: _isAttacking || _isGameOver ? null : _attackBoss,
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: Text(
                    _isAttacking ? 'MENYERANG...' : 'SERANG BOSS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Reusable Health Bar
  Widget _buildHpBar({
    required int current,
    required int max,
    required Color fillColor,
    required String label,
  }) {
    final double percentage = (current / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$current / $max',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(fillColor),
          ),
        ),
      ],
    );
  }
}