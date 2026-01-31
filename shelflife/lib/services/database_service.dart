import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shelf_item.dart';

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
    final path = join(dbPath, 'shelflife.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            openedDate TEXT NOT NULL,
            shelfLifeDays INTEGER NOT NULL,
            notified INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'active',
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertItem(ShelfItem item) async {
    final db = await database;
    return await db.insert('items', item.toMap()..remove('id'));
  }

  Future<List<ShelfItem>> getActiveItems() async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'status = ?',
      whereArgs: ['active'],
    );
    return maps.map((map) => ShelfItem.fromMap(map)).toList();
  }

  Future<List<ShelfItem>> getHistoryItems() async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'status != ?',
      whereArgs: ['active'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ShelfItem.fromMap(map)).toList();
  }

  Future<List<ShelfItem>> getAllItems() async {
    final db = await database;
    final maps = await db.query('items');
    return maps.map((map) => ShelfItem.fromMap(map)).toList();
  }

  Future<int> updateItemStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'items',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItemNotified(int id, bool notified) async {
    final db = await database;
    return await db.update(
      'items',
      {'notified': notified ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
