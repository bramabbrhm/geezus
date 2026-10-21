import 'package:flutter/material.dart';

class GymLog {
  final String name;
  final double weight;
  final int sets;
  final int reps;
  final DateTime date;

  GymLog({
    required this.name,
    required this.weight,
    required this.sets,
    required this.reps,
    required this.date,
  });

  double get volume => weight * sets * reps;
}

class GymStore extends ChangeNotifier {
  static final GymStore instance = GymStore._internal();
  GymStore._internal();

  // Data awal dummy agar layar tidak kosong
  final List<GymLog> _logs = [
    GymLog(name: 'Bench Press', weight: 40, sets: 3, reps: 10, date: DateTime.now()),
    GymLog(name: 'Squat', weight: 50, sets: 4, reps: 8, date: DateTime.now()),
  ];

  double weeklyRunKm = 5.0; // Bonus Speed Damage dari lari

// Tambahkan method ini di dalam class GymStore (misal tepat di bawah 'weeklyRunKm'):
void addRunDistance(double distanceKm) {
  if (distanceKm <= 0) return;
  weeklyRunKm += distanceKm;
  notifyListeners(); // Memberi tahu Laman Dungeon agar Damage Lari langsung naik!
}
  List<GymLog> get logs => List.unmodifiable(_logs);

  // Tambah log angkatan baru dari AI Chatbot
  void addLog(String name, double weight, int sets, int reps) {
    _logs.add(GymLog(
      name: name,
      weight: weight,
      sets: sets,
      reps: reps,
      date: DateTime.now(),
    ));
    notifyListeners(); // Notifikasi agar Laman Dungeon & Boss otomatis terbarui!
  }

  // Total Volume Angkatan (kg)
  double get totalVolumeKg => _logs.fold(0.0, (sum, item) => sum + item.volume);

  // Hitung Beban Maksimal (PR / Max Lift) per Gerakan Bulan Ini
  Map<String, double> get monthlyMaxes {
    final Map<String, double> maxes = {};
    for (var log in _logs) {
      final key = log.name.toUpperCase();
      if (!maxes.containsKey(key) || log.weight > maxes[key]!) {
        maxes[key] = log.weight;
      }
    }
    return maxes;
  }

  // Hitung Total Volume per Gerakan Bulan Ini
  Map<String, double> get monthlyVolumes {
    final Map<String, double> volumes = {};
    for (var log in _logs) {
      final key = log.name.toUpperCase();
      volumes[key] = (volumes[key] ?? 0) + log.volume;
    }
    return volumes;
  }

  // Perhitungan Damage Dinamis
  int get gymDamage => (totalVolumeKg * 0.08).round();
  int get runDamage => (weeklyRunKm * 25).round();
  int get totalBaseDamage => gymDamage + runDamage;
}