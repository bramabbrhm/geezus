import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/gym_store.dart';

class BossBattleScreen extends StatefulWidget {
  const BossBattleScreen({super.key});

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends State<BossBattleScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  // System Progression Boss
  int _bossLevel = 1;

  // Daftar Boss Bertingkat (Nama, HP Base, Ikon, & Warna)
  final List<Map<String, dynamic>> _bossDatabase = [
    {
      'name': 'Iron Titan Kronos',
      'hp': 35000,
      'icon': Icons.fitness_center_rounded,
      'color': Colors.redAccent,
    },
    {
      'name': 'Shadow Hydra Nix',
      'hp': 60000,
      'icon': Icons.coronavirus_rounded,
      'color': Colors.purpleAccent,
    },
    {
      'name': 'Mecha Behemoth V2',
      'hp': 95000,
      'icon': Icons.precision_manufacturing_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Void Overlord Ignis',
      'hp': 140000,
      'icon': Icons.whatshot_rounded,
      'color': Colors.deepOrangeAccent,
    },
    {
      'name': 'Celestial God Dragon',
      'hp': 200000,
      'icon': Icons.shield_moon_rounded,
      'color': Colors.amberAccent,
    },
  ];

  // Helper Getters untuk Boss Saat Ini
  String get _currentBossName {
    if (_bossLevel <= _bossDatabase.length) {
      return _bossDatabase[_bossLevel - 1]['name'];
    }
    return 'Dungeon Emperor Lvl $_bossLevel';
  }

  int get _currentBossMaxHp {
    if (_bossLevel <= _bossDatabase.length) {
      return _bossDatabase[_bossLevel - 1]['hp'];
    }
    // Formula eksponensial untuk level di atas database dasar
    return (200000 * pow(1.3, _bossLevel - _bossDatabase.length)).round();
  }

  IconData get _currentBossIcon {
    if (_bossLevel <= _bossDatabase.length) {
      return _bossDatabase[_bossLevel - 1]['icon'];
    }
    return Icons.workspace_premium_rounded;
  }

  Color get _currentBossColor {
    if (_bossLevel <= _bossDatabase.length) {
      return _bossDatabase[_bossLevel - 1]['color'];
    }
    return Colors.redAccent;
  }

  // State Game & HP
  late int _bossMaxHp;
  late int _bossCurrentHp;

  int _playerMaxHp = 1000;
  int _playerCurrentHp = 1000;

  bool _isAttacking = false;
  bool _isGameOver = false;
  final List<String> _battleLog = [];

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _bossMaxHp = _currentBossMaxHp;
    _bossCurrentHp = _bossMaxHp;

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

  void _attackBoss(int totalBaseDmg, int gymDmg, int runDmg) {
    if (_isAttacking || _isGameOver) return;

    setState(() {
      _isAttacking = true;
    });

    _animController.forward(from: 0.0).then((_) => _animController.reverse());

    final random = Random();
    final bool isCritical = random.nextDouble() < 0.25;
    final double multiplier = isCritical ? 1.75 : (0.85 + random.nextDouble() * 0.3);
    final int damageDealt = (totalBaseDmg * multiplier).round();

    setState(() {
      _bossCurrentHp = max(0, _bossCurrentHp - damageDealt);
      final String critText = isCritical ? '💥 CRITICAL OVERLOAD! ' : '';
      _battleLog.insert(
        0,
        '⚔️ ${critText}Gym Power ($gymDmg) + Run Speed ($runDmg) memberikan $damageDealt DMG!',
      );
    });

    if (_bossCurrentHp <= 0) {
      _endGame(victory: true);
      return;
    }

    Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _isGameOver) return;

      final int bossDamage = (150 + random.nextInt(120) + (_bossLevel * 20));
      setState(() {
        _playerCurrentHp = max(0, _playerCurrentHp - bossDamage);
        _battleLog.insert(
          0,
          '🔥 $_currentBossName membalas serangan sebesar $bossDamage DMG!',
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
          victory ? '🏆 BOSS VICTORY!' : '💀 GYM FATIGUE!',
          style: TextStyle(
            color: victory ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          victory
              ? 'Selamat! Kamu berhasil menumbangkan $_currentBossName (Lvl $_bossLevel)!\n\nApakah kamu siap menantang Boss berikutnya yang lebih kuat?'
              : 'Staminamu habis melawan $_currentBossName! Tambah volume gym di Chatbot AI untuk memperkuat damagemu.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () {
              Navigator.pop(context);
              if (victory) {
                _nextBossLevel();
              } else {
                _resetCurrentBoss();
              }
            },
            child: Text(
              victory ? 'Lanjut Boss Lvl ${_bossLevel + 1} ➔' : 'Coba Lagi',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Pindah ke Boss Level Selanjutnya
  void _nextBossLevel() {
    setState(() {
      _bossLevel++;
      _bossMaxHp = _currentBossMaxHp;
      _bossCurrentHp = _bossMaxHp;
      _playerCurrentHp = _playerMaxHp;
      _isGameOver = false;
      _battleLog.clear();
      _battleLog.insert(
        0,
        '⚡ BOSS BARU MUNCUL: $_currentBossName (Lvl $_bossLevel) dengan HP ${_bossMaxHp}!',
      );
    });
  }

  // Reset Boss Level yang Sama Jika Kalah
  void _resetCurrentBoss() {
    setState(() {
      _bossCurrentHp = _bossMaxHp;
      _playerCurrentHp = _playerMaxHp;
      _isGameOver = false;
      _battleLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GymStore.instance,
      builder: (context, _) {
        final store = GymStore.instance;
        final gymDmg = store.gymDamage;
        final runDmg = store.runDamage;
        final totalBaseDmg = store.totalBaseDamage;

        return Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            title: const Text(
              'Gym Dungeon & Boss Raid',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: _cardColor,
            elevation: 0,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor),
                ),
                child: Center(
                  child: Text(
                    'DUNGEON LVL $_bossLevel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel Source Damage
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
                            '🏋️ GYM VOLUME',
                            '${store.totalVolumeKg.toInt()} kg',
                            '+$gymDmg DMG',
                            _primaryColor,
                          ),
                        ),
                        Container(height: 36, width: 1, color: Colors.white24),
                        Expanded(
                          child: _buildSourceDamageCard(
                            '🏃 LARI (BONUS)',
                            '${store.weeklyRunKm.toStringAsFixed(1)} km',
                            '+$runDmg DMG',
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dynamic Boss Card
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
                        border: Border.all(
                          color: _currentBossColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(_currentBossIcon, size: 55, color: _currentBossColor),
                          const SizedBox(height: 6),
                          Text(
                            _currentBossName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'BOSS LEVEL $_bossLevel',
                            style: TextStyle(
                              color: _currentBossColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildHpBar(
                            _bossCurrentHp,
                            _bossMaxHp,
                            _currentBossColor,
                            'BOSS HP',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Player Hero Status
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
                            const Text(
                              '🛡️ HERO POWER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'BASE DMG: $totalBaseDmg',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildHpBar(
                          _playerCurrentHp,
                          _playerMaxHp,
                          Colors.greenAccent,
                          'HERO HP',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tombol Serang
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAttacking ? Colors.grey : _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: _isAttacking || _isGameOver
                          ? null
                          : () => _attackBoss(totalBaseDmg, gymDmg, runDmg),
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      label: Text(
                        _isAttacking ? 'ATTACKING...' : 'SERANG BOSS ($totalBaseDmg DMG)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Rekor Angkatan Bulanan
                  const Text(
                    '🏋️ Detail Angkatan & Rekor Bulan Ini',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (store.monthlyMaxes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Belum ada data latihan. Input angkatan di Chatbot AI!',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: store.monthlyMaxes.length,
                      itemBuilder: (context, index) {
                        final name = store.monthlyMaxes.keys.elementAt(index);
                        final maxWeight = store.monthlyMaxes[name]!;
                        final totalVol = store.monthlyVolumes[name]!;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Akumulasi: ${totalVol.toInt()} kg',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _primaryColor),
                                ),
                                child: Text(
                                  'MAX: ${maxWeight.toInt()} kg',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Battle History Log
                  const Text(
                    '📜 Battle History Log',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
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
                              'Riwayat serangan akan muncul di sini.',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _battleLog.length,
                            itemBuilder: (context, index) => Text(
                              _battleLog[index],
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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