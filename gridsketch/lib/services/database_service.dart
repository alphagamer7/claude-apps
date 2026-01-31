import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/artwork.dart';

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
    final path = join(dbPath, 'gridsketch.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE artworks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            gridSize INTEGER NOT NULL,
            paletteIndex INTEGER NOT NULL,
            gridData TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertArtwork(Artwork artwork) async {
    final db = await database;
    return await db.insert('artworks', artwork.toMap());
  }

  Future<int> updateArtwork(Artwork artwork) async {
    final db = await database;
    return await db.update(
      'artworks',
      artwork.toMap(),
      where: 'id = ?',
      whereArgs: [artwork.id],
    );
  }

  Future<int> deleteArtwork(int id) async {
    final db = await database;
    return await db.delete('artworks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Artwork>> getAllArtworks() async {
    final db = await database;
    final maps = await db.query('artworks', orderBy: 'updatedAt DESC');
    return maps.map((map) => Artwork.fromMap(map)).toList();
  }

  Future<Artwork?> getArtwork(int id) async {
    final db = await database;
    final maps = await db.query('artworks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Artwork.fromMap(maps.first);
  }
}
