import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  // Warna Palette Geezus
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  // Subskripsi Stream Sensor
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Stat Hitung Langkah (Accelerometer)
  int _stepCount = 0;
  final int _dailyGoal = 10000;
  bool _canCountStep = true;

  // Stat Kemiringan (Gyroscope)
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  // Defensive Programming: Inisialisasi listener sensor dengan penanganan error
  void _initSensors() {
    try {
      // 1. Accelerometer: Deteksi guncangan langkah kaki
      _accelSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          if (!mounted) return;

          // Hitung magnitudo akselerasi total (vektor X, Y, Z)
          double magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          // Ambang batas akselerasi langkah lari/jalan (~11.5 m/s²)
          if (magnitude > 11.5 && _canCountStep) {
            setState(() {
              _stepCount++;
              _canCountStep = false;
            });

            // Cooldown 350ms agar tidak double count dalam 1 langkah
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) {
                setState(() {
                  _canCountStep = true;
                });
              }
            });
          }
        },
        onError: (error) {
          debugPrint('Error Accelerometer: $error');
        },
      );

      // 2. Gyroscope: Deteksi posisi kemiringan HP
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
          debugPrint('Error Gyroscope: $error');
        },
      );
    } catch (e) {
      debugPrint('Gagal membaca sensor hardware: $e');
    }
  }

  void _resetSteps() {
    setState(() {
      _stepCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_stepCount / _dailyGoal).clamp(0.0, 1.0);
    double estimatedKm = _stepCount * 0.00075; // Asumsi 1 langkah = 0.75 meter
    int estimatedCalories = (_stepCount * 0.04).round(); // Asumsi 1 langkah = 0.04 kalori

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Sensor & Step Counter',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Panel Status Langkah Kaki
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
                        fontSize: 48,
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

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Est. Jarak & Kalori
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSubStat('JARAK', '${estimatedKm.toStringAsFixed(2)} km'),
                        Container(height: 24, width: 1, color: Colors.white24),
                        _buildSubStat('KALORI', '$estimatedCalories kcal'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Panel Gyroscope (Kemiringan Perangkat)
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
                        Icon(Icons.screen_rotation, color: _primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Gyroscope (Kemiringan HP)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Indicator Visual Kemiringan
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

                    // Nilai Real-time Sumbu Gyroscope
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('X: ${_gyroX.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('Y: ${_gyroY.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('Z: ${_gyroZ.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Reset Langkah
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _resetSteps,
                  child: const Text('RESET HITUNGAN', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}