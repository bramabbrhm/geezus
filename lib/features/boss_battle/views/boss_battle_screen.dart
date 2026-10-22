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
  // Palette Warna Geezus
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  // Data Aktivitas Pengguna Minggu Ini
  final double _weeklyVolumeKg = 8500.0; // Primary: Total Volume Angkatan (8.5 Ton)
  final double _weeklyRunKm = 12.5;       // Secondary: Total Jarak Lari (12.5 km)

  // Break Down Damage
  int _gymDamage = 0;
  int _runDamage = 0;
  int _totalBaseDamage = 0;

  int _playerMaxHp = 1000;
  int _playerCurrentHp = 1000;

  // Stat Boss Mingguan
  final String _bossName = 'Iron Titan Kronos';
  final int _bossMaxHp = 35000;
  int _bossCurrentHp = 35000;

  // Game State
  bool _isAttacking = false;
  bool _isGameOver = false;
  final List<String> _battleLog = [];

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _calculateHybridDamage();

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

  // Kalkulasi Damage Kombinasi Gym (Utama) + Lari (Tambahan)
  void _calculateHybridDamage() {
    try {
      // 1. Gym Volume = Main Damage
      _gymDamage = (_weeklyVolumeKg * 0.08).round(); 

      // 2. Running Distance = Bonus Speed Damage
      _runDamage = (_weeklyRunKm * 25).round();

      // Total Base Damage
      _totalBaseDamage = _gymDamage + _runDamage;

      // HP Player disesuaikan dengan stamina lari & volume gym
      _playerMaxHp = (1000 + (_weeklyVolumeKg * 0.02) + (_weeklyRunKm * 20)).round();
      _playerCurrentHp = _playerMaxHp;
    } catch (e) {
      debugPrint('Error kalkulasi hybrid damage: $e');
      _totalBaseDamage = 500;
      _playerMaxHp = 1000;
      _playerCurrentHp = 1000;
    }
  }

  void _attackBoss() {
    if (_isAttacking || _isGameOver) return;

    setState(() {
      _isAttacking = true;
    });

    _animController.forward(from: 0.0).then((_) => _animController.reverse());

    final random = Random();
    final bool isCritical = random.nextDouble() < 0.25; // 25% Crit Chance
    final double multiplier = isCritical ? 1.75 : (0.85 + random.nextDouble() * 0.3);
    final int damageDealt = (_totalBaseDamage * multiplier).round();

    setState(() {
      _bossCurrentHp = max(0, _bossCurrentHp - damageDealt);
      final String critText = isCritical ? '💥 MAXIMUM OVERLOAD! ' : '';
      _battleLog.insert(
        0,
        '⚔️ ${critText}Gym Power ($_gymDamage) + Run Speed ($_runDamage) memberikan total $damageDealt DMG!',
      );
    });

    if (_bossCurrentHp <= 0) {
      _endGame(victory: true);
      return;
    }

    Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _isGameOver) return;

      final int bossDamage = 150 + random.nextInt(120);
      setState(() {
        _playerCurrentHp = max(0, _playerCurrentHp - bossDamage);
        _battleLog.insert(
          0,
          '🔥 $_bossName membalas serangan sebesar $bossDamage DMG!',
        );
        _isAttacking = false;
      });

      if (_playerCurrentHp <= 0) {
        _endGame(victory: false);
      }
    });
  }

  void _endGame({required bool victory}) {
    setState(() {
      _isGameOver = true;
      _isAttacking = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          victory ? '🏆 TITAN DEFEATED!' : '💀 FATIGUE OVERCOMING!',
          style: TextStyle(
            color: victory ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          victory
              ? 'Luar biasa! Angkatan gym ${_weeklyVolumeKg.toInt()} kg & stamina lari ${_weeklyRunKm} km kamu berhasil meruntuhkan $_bossName!'
              : 'Staminamu habis! Tingkatkan volume gym dan sesi larimu untuk menumbangkan Boss.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () {
              Navigator.pop(context);
              _resetBattle();
            },
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetBattle() {
    setState(() {
      _bossCurrentHp = _bossMaxHp;
      _playerCurrentHp = _playerMaxHp;
      _isGameOver = false;
      _battleLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Gym & Cardio Boss Raid',
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
              // Panel Statistik Hybrid (Gym + Lari)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSourceDamageCard(
                        '🏋️ GYM VOLUME (UTAMA)',
                        '${_weeklyVolumeKg.toInt()} kg',
                        '+$_gymDamage DMG',
                        _primaryColor,
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    Expanded(
                      child: _buildSourceDamageCard(
                        '🏃 LARI (BONUS)',
                        '$_weeklyRunKm km',
                        '+$_runDamage DMG',
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Boss View dengan Animasi Shake
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.fitness_center, size: 50, color: Colors.redAccent),
                      const SizedBox(height: 6),
                      Text(
                        _bossName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildHpBar(_bossCurrentHp, _bossMaxHp, Colors.redAccent, 'BOSS HP'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Player View
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🛡️ HERO POWER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('BASE DMG: $_totalBaseDamage', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildHpBar(_playerCurrentHp, _playerMaxHp, Colors.greenAccent, 'HERO HP'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Battle Log Box
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: _battleLog.isEmpty
                      ? const Center(
                          child: Text(
                            'Serang Boss untuk menggabungkan Volume Gym & Jarak Lari menjadi Damage!',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _battleLog.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _battleLog[index],
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Tombol Serang
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAttacking ? Colors.grey : _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _isAttacking || _isGameOver ? null : _attackBoss,
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: Text(
                    _isAttacking ? 'ATTACKING...' : 'SERANG BOSS (HYBRID DMG)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceDamageCard(String title, String val, String dmg, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(dmg, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHpBar(int current, int max, Color color, String label) {
    double pct = (current / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('$current / $max', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}