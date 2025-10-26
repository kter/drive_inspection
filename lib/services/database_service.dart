import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/driving_session.dart';

/// Service for managing database operations
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'driving_sessions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        totalReadings INTEGER NOT NULL,
        totalMagnitude REAL NOT NULL,
        events TEXT NOT NULL,
        score INTEGER NOT NULL
      )
    ''');
  }

  /// Save a driving session
  Future<int> saveSession(DrivingSession session) async {
    final db = await database;
    return await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all sessions ordered by start time (most recent first)
  Future<List<DrivingSession>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'startTime DESC',
    );

    return List.generate(maps.length, (i) {
      return DrivingSession.fromMap(maps[i]);
    });
  }

  /// Get a session by ID
  Future<DrivingSession?> getSession(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return DrivingSession.fromMap(maps.first);
  }

  /// Delete a session by ID
  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get session count
  Future<int> getSessionCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sessions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
