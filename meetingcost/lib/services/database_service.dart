import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meeting.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'meetingcost.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE meetings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendeeCount INTEGER NOT NULL,
            hourlyRate REAL NOT NULL,
            durationSeconds INTEGER NOT NULL,
            totalCost REAL NOT NULL,
            isPaused INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            note TEXT DEFAULT ''
          )
        ''');
      },
    );
  }

  Future<int> insertMeeting(Meeting meeting) async {
    final db = await database;
    return await db.insert('meetings', meeting.toMap()..remove('id'));
  }

  Future<List<Meeting>> getAllMeetings() async {
    final db = await database;
    final maps = await db.query('meetings', orderBy: 'createdAt DESC');
    return maps.map((map) => Meeting.fromMap(map)).toList();
  }

  Future<List<Meeting>> getMeetingsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'meetings',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Meeting.fromMap(map)).toList();
  }

  Future<int> deleteMeeting(int id) async {
    final db = await database;
    return await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(totalCost), 0) as totalCost,
        COALESCE(AVG(totalCost), 0) as avgCost,
        COUNT(*) as count
      FROM meetings
    ''');
    final row = result.first;
    return {
      'totalCost': (row['totalCost'] as num).toDouble(),
      'avgCost': (row['avgCost'] as num).toDouble(),
      'count': (row['count'] as num).toDouble(),
    };
  }
}
