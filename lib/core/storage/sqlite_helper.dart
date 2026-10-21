import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        distance REAL,
        durationSeconds INTEGER,
        calories INTEGER,
        date TEXT
      )
    ''');
  }

  Future<int> insertWorkout(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('workouts', row);
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await instance.database;
    return await db.query('workouts', orderBy: 'id DESC');
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) db.close();
  }
}