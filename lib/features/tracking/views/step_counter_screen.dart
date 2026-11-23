import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/storage/sqlite_helper.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  // Sensor subscriptions
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Step counter state
  int _stepCount = 0;
  final int _dailyGoal = 10000;
  bool _canCountStep = true;
  bool _sensorAvailable = true;

  // Gyroscope data
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  // Persistence
  bool _isLoading = true;
  String _todayKey = '';
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _todayKey = DateTime.now().toIso8601String().substring(0, 10);
    _loadTodaySteps();
    _initSensors();
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _saveDebounce?.cancel();
    // Persist final count before leaving screen
    _persistSteps();
    super.dispose();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> _loadTodaySteps() async {
    try {
      final row = await SqliteHelper.instance.getTodayStepCount();
      if (row != null && row['date'] == _todayKey) {
        final savedSteps = (row['step_count'] as num?)?.toInt() ?? 0;
        if (mounted) {
          setState(() {
            _stepCount = savedSteps;
          });
        }
      }
    } catch (e) {
      debugPrint('StepCounter: loadTodaySteps error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 3), _persistSteps);
  }

  Future<void> _persistSteps() async {
    try {
      final km = _stepCount * 0.00075;
      final cal = (_stepCount * 0.04).round();
      await SqliteHelper.instance.saveStepCount(
        steps: _stepCount,
        estimatedKm: km,
        estimatedCalories: cal,
      );
    } catch (e) {
      debugPrint('StepCounter: persistSteps error: $e');
    }
  }

  // ── Sensors ───────────────────────────────────────────────────────────────

  void _initSensors() {
    try {
      _accelSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          if (!mounted) return;

          final double magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          // Threshold ~11.5 m/s² detects a step (walking/running)
          if (magnitude > 11.5 && _canCountStep) {
            setState(() {
              _stepCount++;
              _canCountStep = false;
            });

            // 350ms cooldown prevents double-counting one step
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) setState(() => _canCountStep = true);
            });

            // Debounced save every 3s
            _scheduleSave();
          }
        },
        onError: (error) {
          debugPrint('Accelerometer error: $error');
          if (mounted) setState(() => _sensorAvailable = false);
        },
      );

      _gyroSubscription = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          if (!mounted) return;
          setState(() {
            _gyroX = event.x;
            _gyroY = event.y;
            _gyroZ = event.z;
          });
        },
        onError: (error) {
          debugPrint('Gyroscope error: $error');
        },
      );
    } catch (e) {
      debugPrint('Sensor init failed: $e');
      if (mounted) setState(() => _sensorAvailable = false);
    }
  }

  Future<void> _resetSteps() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Reset Hitungan?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Hitungan langkah hari ini akan di-reset ke 0.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _stepCount = 0);
      await _persistSteps();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
      );
    }

    final double progress = (_stepCount / _dailyGoal).clamp(0.0, 1.0);
    final double estimatedKm = _stepCount * 0.00075;
    final int estimatedCalories = (_stepCount * 0.04).round();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Sensor & Step Counter',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Sensor unavailable warning
              if (!_sensorAvailable)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sensors_off, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sensor akselerometer tidak tersedia di perangkat ini. Hitungan langkah tidak dapat bekerja.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Step counter panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Langkah Hari Ini',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_stepCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Target: $_dailyGoal langkah',
                      style: const TextStyle(
                        color: _primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            _primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% dari target harian',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 20),

                    // Est. distance & calories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSubStat(
                            'JARAK', '${estimatedKm.toStringAsFixed(2)} km'),
                        Container(
                            height: 24, width: 1, color: Colors.white24),
                        _buildSubStat(
                            'KALORI*', '$estimatedCalories kcal'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '* Estimasi kasar — bukan pengukuran medis',
                      style: TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Gyroscope panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.screen_rotation,
                            color: _primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Gyroscope (Kemiringan HP)',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Visual tilt indicator
                    Center(
                      child: Container(
                        width: 160,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 100),
                              left: (70 + (_gyroY * 20)).clamp(10.0, 130.0),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('X: ${_gyroX.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text('Y: ${_gyroY.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text('Z: ${_gyroZ.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reset button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _resetSteps,
                  icon: const Icon(Icons.refresh, color: Colors.redAccent),
                  label: const Text(
                    'RESET HITUNGAN HARI INI',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
