import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Simple ayah bookmarks — a single flat list of "saved verses", separate
/// from the named "আমার কোরআন" collections. Uses its own database file;
/// no shared tables with any other part of the app.
class QuranBookmarksHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'quran_bookmarks.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sura INTEGER NOT NULL,
            aya INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            UNIQUE(sura, aya)
          )
        ''');
      },
    );
  }

  static Future<bool> isBookmarked(int sura, int aya) async {
    final db = await database;
    final rows = await db.query('bookmarks', where: 'sura = ? AND aya = ?', whereArgs: [sura, aya]);
    return rows.isNotEmpty;
  }

  static Future<void> addBookmark(int sura, int aya) async {
    final db = await database;
    await db.insert(
      'bookmarks',
      {'sura': sura, 'aya': aya, 'created_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> removeBookmark(int sura, int aya) async {
    final db = await database;
    await db.delete('bookmarks', where: 'sura = ? AND aya = ?', whereArgs: [sura, aya]);
  }

  static Future<List<Map<String, dynamic>>> getAllBookmarks() async {
    final db = await database;
    return db.query('bookmarks', orderBy: 'created_at DESC');
  }
}
