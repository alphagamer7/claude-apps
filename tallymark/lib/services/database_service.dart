import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/counter.dart';
import '../models/counter_history.dart';

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
    final path = join(dbPath, 'tallymark.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE counters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        currentValue INTEGER NOT NULL DEFAULT 0,
        dailyReset INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE counter_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        counterId INTEGER NOT NULL,
        date TEXT NOT NULL,
        value INTEGER NOT NULL,
        FOREIGN KEY (counterId) REFERENCES counters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_history_counter_date
      ON counter_history(counterId, date)
    ''');
  }

  // --- Counter CRUD ---

  Future<int> insertCounter(Counter counter) async {
    final db = await database;
    return await db.insert('counters', counter.toMap());
  }

  Future<List<Counter>> getCounters() async {
    final db = await database;
    final maps = await db.query('counters', orderBy: 'sortOrder ASC, id ASC');
    return maps.map((map) => Counter.fromMap(map)).toList();
  }

  Future<Counter?> getCounter(int id) async {
    final db = await database;
    final maps = await db.query('counters', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Counter.fromMap(maps.first);
  }

  Future<int> updateCounter(Counter counter) async {
    final db = await database;
    return await db.update(
      'counters',
      counter.toMap(),
      where: 'id = ?',
      whereArgs: [counter.id],
    );
  }

  Future<int> deleteCounter(int id) async {
    final db = await database;
    await db.delete('counter_history', where: 'counterId = ?', whereArgs: [id]);
    return await db.delete('counters', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCounterValue(int id, int value) async {
    final db = await database;
    await db.update(
      'counters',
      {'currentValue': value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderCounters(List<Counter> counters) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < counters.length; i++) {
      batch.update(
        'counters',
        {'sortOrder': i},
        where: 'id = ?',
        whereArgs: [counters[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- History ---

  Future<void> saveHistory(int counterId, String date, int value) async {
    final db = await database;
    await db.insert(
      'counter_history',
      {'counterId': counterId, 'date': date, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CounterHistory>> getHistoryForCounter(int counterId) async {
    final db = await database;
    final maps = await db.query(
      'counter_history',
      where: 'counterId = ?',
      whereArgs: [counterId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => CounterHistory.fromMap(map)).toList();
  }

  Future<List<CounterHistory>> getAllHistory() async {
    final db = await database;
    final maps = await db.query('counter_history', orderBy: 'date DESC');
    return maps.map((map) => CounterHistory.fromMap(map)).toList();
  }

  /// Snapshot today's values for all counters, and reset daily-reset counters.
  Future<void> performDailySnapshot() async {
    final today = _dateString(DateTime.now());
    final counters = await getCounters();

    for (final counter in counters) {
      if (counter.id == null) continue;
      await saveHistory(counter.id!, today, counter.currentValue);

      if (counter.dailyReset) {
        await updateCounterValue(counter.id!, 0);
      }
    }
  }

  String _dateString(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
