import 'package:sqflite/sqflite.dart';
import '../models/focus_session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/focusfence.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE focus_sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            appName TEXT NOT NULL,
            durationMinutes INTEGER NOT NULL,
            startTime TEXT NOT NULL,
            endTime TEXT,
            completed INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertSession(FocusSession session) async {
    final db = await database;
    return await db.insert('focus_sessions', session.toMap());
  }

  Future<int> updateSession(FocusSession session) async {
    final db = await database;
    return await db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<FocusSession>> getAllSessions() async {
    final db = await database;
    final maps = await db.query(
      'focus_sessions',
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => FocusSession.fromMap(map)).toList();
  }

  Future<List<FocusSession>> getCompletedSessions() async {
    final db = await database;
    final maps = await db.query(
      'focus_sessions',
      where: 'completed = ?',
      whereArgs: [1],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => FocusSession.fromMap(map)).toList();
  }

  Future<List<FocusSession>> getAbandonedSessions() async {
    final db = await database;
    final maps = await db.query(
      'focus_sessions',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => FocusSession.fromMap(map)).toList();
  }

  Future<List<FocusSession>> getSessionsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'focus_sessions',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => FocusSession.fromMap(map)).toList();
  }

  Future<int> getTotalFocusMinutes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(durationMinutes) as total FROM focus_sessions WHERE completed = 1',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTodaySessionCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_sessions WHERE completed = 1 AND startTime >= ?',
      [startOfDay.toIso8601String()],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
