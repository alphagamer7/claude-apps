import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/saved_color.dart';
import '../models/palette.dart';

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
    final path = p.join(dbPath, 'huematch.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE colors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hex TEXT NOT NULL,
            red INTEGER NOT NULL,
            green INTEGER NOT NULL,
            blue INTEGER NOT NULL,
            hue REAL NOT NULL,
            saturation REAL NOT NULL,
            lightness REAL NOT NULL,
            nearestName TEXT NOT NULL,
            paletteName TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE palettes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            colorIds TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL
          )
        ''');

        // Create the default Favorites palette
        await db.insert('palettes', {
          'name': 'Favorites',
          'colorIds': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  // --- Colors ---

  Future<int> insertColor(SavedColor color) async {
    final db = await database;
    return db.insert('colors', color.toMap());
  }

  Future<List<SavedColor>> getColors() async {
    final db = await database;
    final maps = await db.query('colors', orderBy: 'createdAt DESC');
    return maps.map((m) => SavedColor.fromMap(m)).toList();
  }

  Future<List<SavedColor>> getColorsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    final maps = await db.query(
      'colors',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    // Maintain order from ids list
    final mapById = {for (var m in maps) m['id'] as int: m};
    return ids
        .where((id) => mapById.containsKey(id))
        .map((id) => SavedColor.fromMap(mapById[id]!))
        .toList();
  }

  Future<SavedColor?> getColorById(int id) async {
    final db = await database;
    final maps = await db.query('colors', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SavedColor.fromMap(maps.first);
  }

  Future<int> deleteColor(int id) async {
    final db = await database;
    return db.delete('colors', where: 'id = ?', whereArgs: [id]);
  }

  // --- Palettes ---

  Future<int> insertPalette(Palette palette) async {
    final db = await database;
    return db.insert('palettes', palette.toMap());
  }

  Future<List<Palette>> getPalettes() async {
    final db = await database;
    final maps = await db.query('palettes', orderBy: 'createdAt ASC');
    return maps.map((m) => Palette.fromMap(m)).toList();
  }

  Future<Palette?> getPaletteById(int id) async {
    final db = await database;
    final maps = await db.query('palettes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Palette.fromMap(maps.first);
  }

  Future<int> updatePalette(Palette palette) async {
    final db = await database;
    return db.update(
      'palettes',
      palette.toMap(),
      where: 'id = ?',
      whereArgs: [palette.id],
    );
  }

  Future<int> deletePalette(int id) async {
    final db = await database;
    return db.delete('palettes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addColorToPalette(int paletteId, int colorId) async {
    final palette = await getPaletteById(paletteId);
    if (palette == null) return;

    final updatedIds = List<int>.from(palette.colorIds);
    if (!updatedIds.contains(colorId)) {
      updatedIds.add(colorId);
      await updatePalette(palette.copyWith(colorIds: updatedIds));
    }
  }

  Future<void> removeColorFromPalette(int paletteId, int colorId) async {
    final palette = await getPaletteById(paletteId);
    if (palette == null) return;

    final updatedIds = List<int>.from(palette.colorIds);
    updatedIds.remove(colorId);
    await updatePalette(palette.copyWith(colorIds: updatedIds));
  }
}
