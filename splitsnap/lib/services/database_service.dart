import 'package:sqflite/sqflite.dart';
import '../models/split_session.dart';

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
    final path = '$dbPath/splitsnap.db';

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            items TEXT NOT NULL,
            people TEXT NOT NULL,
            taxAmount REAL NOT NULL,
            tipAmount REAL NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertSession(SplitSession session) async {
    final db = await database;
    final map = session.toMap();
    map.remove('id');
    return db.insert('sessions', map);
  }

  Future<List<SplitSession>> getSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'date DESC');
    return maps.map((m) => SplitSession.fromMap(m)).toList();
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
