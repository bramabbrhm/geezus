import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Central SQLite helper for Geezus app.
/// Tables:
///   - run_history   : records of each run session
///   - gym_logs      : gym workout log entries
///   - step_counter  : daily step count persistence
class SqliteHelper {
  static final SqliteHelper instance = SqliteHelper._init();
  static Database? _database;

  SqliteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('geezus_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Run history table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS run_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        distance_km REAL NOT NULL DEFAULT 0,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        estimated_calories INTEGER NOT NULL DEFAULT 0,
        boss_damage INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');

    // Gym logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gym_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_name TEXT NOT NULL,
        weight_kg REAL NOT NULL DEFAULT 0,
        sets INTEGER NOT NULL DEFAULT 0,
        reps INTEGER NOT NULL DEFAULT 0,
        volume_kg REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');

    // Step counter daily persistence
    await db.execute('''
      CREATE TABLE IF NOT EXISTS step_counter (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        step_count INTEGER NOT NULL DEFAULT 0,
        estimated_km REAL NOT NULL DEFAULT 0,
        estimated_calories INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Legacy workouts table for backward compatibility
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        distance REAL,
        durationSeconds INTEGER,
        calories INTEGER,
        date TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gym_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_name TEXT NOT NULL,
          weight_kg REAL NOT NULL DEFAULT 0,
          sets INTEGER NOT NULL DEFAULT 0,
          reps INTEGER NOT NULL DEFAULT 0,
          volume_kg REAL NOT NULL DEFAULT 0,
          date TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS step_counter (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          step_count INTEGER NOT NULL DEFAULT 0,
          estimated_km REAL NOT NULL DEFAULT 0,
          estimated_calories INTEGER NOT NULL DEFAULT 0
        )
      ''');
      // Rename old workouts table to run_history if columns match
      await db.execute('''
        CREATE TABLE IF NOT EXISTS run_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          distance_km REAL NOT NULL DEFAULT 0,
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          estimated_calories INTEGER NOT NULL DEFAULT 0,
          boss_damage INTEGER NOT NULL DEFAULT 0,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Ensure run_history exists for upgrades from v1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS run_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          distance_km REAL NOT NULL DEFAULT 0,
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          estimated_calories INTEGER NOT NULL DEFAULT 0,
          boss_damage INTEGER NOT NULL DEFAULT 0,
          date TEXT NOT NULL
        )
      ''');
    }
  }

  // ── Run History ──────────────────────────────────────────────────────────

  Future<int> insertRun(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('run_history', row);
  }

  Future<List<Map<String, dynamic>>> getRuns() async {
    final db = await database;
    return await db.query('run_history', orderBy: 'id DESC');
  }

  Future<double> getTotalRunKm() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(distance_km), 0) as total FROM run_history');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Gym Logs ─────────────────────────────────────────────────────────────

  Future<int> insertGymLog(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('gym_logs', row);
  }

  Future<List<Map<String, dynamic>>> getGymLogs() async {
    final db = await database;
    return await db.query('gym_logs', orderBy: 'id DESC');
  }

  Future<double> getTotalGymVolume() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(volume_kg), 0) as total FROM gym_logs');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Step Counter ──────────────────────────────────────────────────────────

  String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> saveStepCount({
    required int steps,
    required double estimatedKm,
    required int estimatedCalories,
  }) async {
    final db = await database;
    final date = _todayKey();
    await db.insert(
      'step_counter',
      {
        'date': date,
        'step_count': steps,
        'estimated_km': estimatedKm,
        'estimated_calories': estimatedCalories,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getTodayStepCount() async {
    final db = await database;
    final date = _todayKey();
    final rows = await db.query('step_counter',
        where: 'date = ?', whereArgs: [date], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  // ── Legacy workouts (kept for backward compatibility) ─────────────────────

  Future<int> insertWorkout(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('workouts', row);
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await database;
    return await db.query('workouts', orderBy: 'id DESC');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
