import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/measurement.dart';

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
    final path = p.join(dbPath, 'snapmeasure.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE measurements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT NOT NULL,
            referenceType TEXT NOT NULL,
            measurements TEXT NOT NULL,
            unit TEXT NOT NULL DEFAULT 'cm',
            createdAt TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertMeasurement(Measurement measurement) async {
    final db = await database;
    final map = measurement.toMap();
    map.remove('id');
    return db.insert('measurements', map);
  }

  Future<List<Measurement>> getAllMeasurements() async {
    final db = await database;
    final maps =
        await db.query('measurements', orderBy: 'createdAt DESC');
    return maps.map((m) => Measurement.fromMap(m)).toList();
  }

  Future<Measurement?> getMeasurement(int id) async {
    final db = await database;
    final maps =
        await db.query('measurements', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Measurement.fromMap(maps.first);
  }

  Future<int> updateMeasurement(Measurement measurement) async {
    final db = await database;
    return db.update(
      'measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<int> deleteMeasurement(int id) async {
    final db = await database;
    return db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }
}
