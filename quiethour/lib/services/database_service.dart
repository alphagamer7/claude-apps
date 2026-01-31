import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import '../models/quiet_profile.dart';

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
    final path = join(dbPath, 'quiethour.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            iconCodePoint INTEGER NOT NULL,
            iconFontFamily TEXT NOT NULL,
            startHour INTEGER NOT NULL,
            startMinute INTEGER NOT NULL,
            endHour INTEGER NOT NULL,
            endMinute INTEGER NOT NULL,
            activeDays TEXT NOT NULL,
            isEnabled INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
  }

  Future<int> insertProfile(QuietProfile profile) async {
    final db = await database;
    return await db.insert('profiles', profile.toMap());
  }

  Future<List<QuietProfile>> getAllProfiles() async {
    final db = await database;
    final maps = await db.query('profiles', orderBy: 'id ASC');
    return maps.map((map) => QuietProfile.fromMap(map)).toList();
  }

  Future<QuietProfile?> getProfile(int id) async {
    final db = await database;
    final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return QuietProfile.fromMap(maps.first);
  }

  Future<int> updateProfile(QuietProfile profile) async {
    final db = await database;
    return await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> toggleProfile(int id, bool isEnabled) async {
    final db = await database;
    return await db.update(
      'profiles',
      {'isEnabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProfile(int id) async {
    final db = await database;
    return await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }
}
