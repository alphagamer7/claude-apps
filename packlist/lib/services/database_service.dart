import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pack_item.dart';
import '../models/template.dart';
import '../models/trip.dart';
import 'default_templates.dart';

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
    final path = join(dbPath, 'packlist.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL DEFAULT 'luggage',
        created_at TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE template_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        template_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (template_id) REFERENCES templates (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE trip_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> seedDefaultTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final seeded = prefs.getBool('defaults_seeded') ?? false;
    if (seeded) return;

    for (final template in DefaultTemplates.all) {
      await insertTemplate(template);
    }

    await prefs.setBool('defaults_seeded', true);
  }

  // --- Template CRUD ---

  Future<int> insertTemplate(Template template) async {
    final db = await database;
    final templateId = await db.insert('templates', template.toMap());

    for (final item in template.items) {
      final itemMap = item.toMap();
      itemMap['template_id'] = templateId;
      await db.insert('template_items', itemMap);
    }

    return templateId;
  }

  Future<List<Template>> getTemplates() async {
    final db = await database;
    final maps = await db.query('templates', orderBy: 'created_at DESC');

    final templates = <Template>[];
    for (final map in maps) {
      final items = await _getTemplateItems(map['id'] as int);
      templates.add(Template.fromMap(map, items: items));
    }
    return templates;
  }

  Future<Template?> getTemplate(int id) async {
    final db = await database;
    final maps = await db.query('templates', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final items = await _getTemplateItems(id);
    return Template.fromMap(maps.first, items: items);
  }

  Future<List<PackItem>> _getTemplateItems(int templateId) async {
    final db = await database;
    final maps = await db.query(
      'template_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => PackItem.fromMap(m)).toList();
  }

  Future<void> updateTemplate(Template template) async {
    final db = await database;
    await db.update('templates', template.toMap(),
        where: 'id = ?', whereArgs: [template.id]);

    // Replace all items
    await db.delete('template_items',
        where: 'template_id = ?', whereArgs: [template.id]);
    for (final item in template.items) {
      final itemMap = item.toMap();
      itemMap['template_id'] = template.id;
      itemMap.remove('id');
      await db.insert('template_items', itemMap);
    }
  }

  Future<void> deleteTemplate(int id) async {
    final db = await database;
    await db.delete('templates', where: 'id = ?', whereArgs: [id]);
    await db.delete('template_items',
        where: 'template_id = ?', whereArgs: [id]);
  }

  // --- Trip CRUD ---

  Future<int> createTripFromTemplate(String tripName, int templateId) async {
    final template = await getTemplate(templateId);
    if (template == null) throw Exception('Template not found');

    final db = await database;
    final trip = Trip(
      name: tripName,
      templateId: templateId,
    );
    final tripId = await db.insert('trips', trip.toMap());

    for (final item in template.items) {
      final itemMap = item.copyWith(isChecked: false).toMap();
      itemMap['trip_id'] = tripId;
      itemMap.remove('id');
      await db.insert('trip_items', itemMap);
    }

    return tripId;
  }

  Future<List<Trip>> getTrips() async {
    final db = await database;
    final maps = await db.query('trips', orderBy: 'created_at DESC');

    final trips = <Trip>[];
    for (final map in maps) {
      final items = await _getTripItems(map['id'] as int);
      trips.add(Trip.fromMap(map, items: items));
    }
    return trips;
  }

  Future<Trip?> getTrip(int id) async {
    final db = await database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final items = await _getTripItems(id);
    return Trip.fromMap(maps.first, items: items);
  }

  Future<List<PackItem>> _getTripItems(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'trip_items',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => PackItem.fromMap(m)).toList();
  }

  Future<void> toggleTripItem(int itemId, bool isChecked) async {
    final db = await database;
    await db.update(
      'trip_items',
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> resetTripItems(int tripId) async {
    final db = await database;
    await db.update(
      'trip_items',
      {'is_checked': 0},
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  Future<void> addTripItem(int tripId, PackItem item) async {
    final db = await database;
    final itemMap = item.toMap();
    itemMap['trip_id'] = tripId;
    itemMap.remove('id');
    await db.insert('trip_items', itemMap);
  }

  Future<void> deleteTripItem(int itemId) async {
    final db = await database;
    await db.delete('trip_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<void> updateTripItemOrder(int itemId, int sortOrder) async {
    final db = await database;
    await db.update(
      'trip_items',
      {'sort_order': sortOrder},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteTrip(int id) async {
    final db = await database;
    await db.delete('trip_items', where: 'trip_id = ?', whereArgs: [id]);
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }
}
