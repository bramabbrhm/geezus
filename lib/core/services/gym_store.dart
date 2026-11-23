import 'package:flutter/material.dart';
import '../storage/sqlite_helper.dart';

class GymLog {
  final int? id;
  final String name;
  final double weight;
  final int sets;
  final int reps;
  final DateTime date;

  GymLog({
    this.id,
    required this.name,
    required this.weight,
    required this.sets,
    required this.reps,
    required this.date,
  });

  double get volume => weight * sets * reps;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exercise_name': name,
        'weight_kg': weight,
        'sets': sets,
        'reps': reps,
        'volume_kg': volume,
        'date': date.toIso8601String(),
      };

  factory GymLog.fromMap(Map<String, dynamic> map) => GymLog(
        id: map['id'] as int?,
        name: map['exercise_name']?.toString() ?? '',
        weight: (map['weight_kg'] as num?)?.toDouble() ?? 0,
        sets: (map['sets'] as num?)?.toInt() ?? 0,
        reps: (map['reps'] as num?)?.toInt() ?? 0,
        date: map['date'] != null
            ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Central store for all gym activity and run data.
/// Data is persisted to SQLite and survives app restarts.
/// No dummy data — all values come from real user activity.
class GymStore extends ChangeNotifier {
  static final GymStore instance = GymStore._internal();
  GymStore._internal();

  final List<GymLog> _logs = [];
  double _weeklyRunKm = 0.0;
  bool _loaded = false;

  List<GymLog> get logs => List.unmodifiable(_logs);
  double get weeklyRunKm => _weeklyRunKm;
  bool get isLoaded => _loaded;

  // ── Computed stats ──────────────────────────────────────────────────────

  double get totalVolumeKg =>
      _logs.fold(0.0, (sum, item) => sum + item.volume);

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

  Map<String, double> get monthlyVolumes {
    final Map<String, double> volumes = {};
    for (var log in _logs) {
      final key = log.name.toUpperCase();
      volumes[key] = (volumes[key] ?? 0) + log.volume;
    }
    return volumes;
  }

  int get gymDamage => (totalVolumeKg * 0.08).round();
  int get runDamage => (_weeklyRunKm * 25).round();
  int get totalBaseDamage => gymDamage + runDamage;

  // ── Persistence ──────────────────────────────────────────────────────────

  /// Load all stored gym logs and run total from SQLite.
  /// Call once at app startup (or when the Boss Battle screen is opened).
  Future<void> loadFromDatabase() async {
    if (_loaded) return;
    try {
      final rows = await SqliteHelper.instance.getGymLogs();
      _logs.clear();
      _logs.addAll(rows.map((r) => GymLog.fromMap(r)));

      _weeklyRunKm = await SqliteHelper.instance.getTotalRunKm();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('GymStore.loadFromDatabase error: $e');
    }
  }

  /// Add a gym log entry and persist it to SQLite immediately.
  Future<void> addLog(String name, double weight, int sets, int reps) async {
    final log = GymLog(
      name: name,
      weight: weight,
      sets: sets,
      reps: reps,
      date: DateTime.now(),
    );
    _logs.add(log);
    notifyListeners();

    try {
      await SqliteHelper.instance.insertGymLog(log.toMap());
    } catch (e) {
      debugPrint('GymStore.addLog persist error: $e');
    }
  }

  /// Record a run distance (from LiveRunScreen). Updates in-memory and
  /// notifies listeners immediately; the run is also saved to SQLite
  /// via [insertRunRecord] below.
  void addRunDistance(double distanceKm) {
    if (distanceKm <= 0) return;
    _weeklyRunKm += distanceKm;
    notifyListeners();
  }

  /// Persist a completed run session to SQLite.
  Future<void> insertRunRecord({
    required double distanceKm,
    required int durationSeconds,
    required int estimatedCalories,
    required int bossDamage,
  }) async {
    try {
      await SqliteHelper.instance.insertRun({
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
        'estimated_calories': estimatedCalories,
        'boss_damage': bossDamage,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('GymStore.insertRunRecord error: $e');
    }
  }

  /// Force a full reload from SQLite (e.g., after clearing data).
  Future<void> reload() async {
    _loaded = false;
    await loadFromDatabase();
  }

  /// Reset only in-memory state without touching SQLite.
  /// For use in unit tests where Flutter bindings are not available.
  void resetForTesting() {
    _logs.clear();
    _weeklyRunKm = 0.0;
    _loaded = true; // Prevent loadFromDatabase from being called
  }
}
