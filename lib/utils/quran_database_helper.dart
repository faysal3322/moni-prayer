import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Read-only helper for the bundled Quran database (assets/database/quran.sqlite).
/// This is completely separate from DatabaseHelper (moni_prayer.db) which stores
/// the user's prayer/roza records — no shared tables, no risk to existing data.
class QuranDatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'quran.sqlite');

    // Copy the bundled asset database to writable storage only once.
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      final data = await rootBundle.load('assets/database/quran.sqlite');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  /// All 114 chapters (surahs) with metadata, ordered by sura number.
  static Future<List<Map<String, dynamic>>> getChapters() async {
    final db = await database;
    return db.query('chapters', orderBy: 'sura ASC');
  }

  /// Single chapter's metadata.
  static Future<Map<String, dynamic>?> getChapter(int sura) async {
    final db = await database;
    final rows = await db.query('chapters', where: 'sura = ?', whereArgs: [sura]);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// All ayat (verses) of a given sura in Uthmani script, ordered by aya number.
  static Future<List<Map<String, dynamic>>> getAyatUthmani(int sura) async {
    final db = await database;
    return db.query('quran_uthmani', where: 'sura = ?', whereArgs: [sura], orderBy: 'aya ASC');
  }

  /// English transliteration for a given sura (until Bengali translation is added).
  static Future<List<Map<String, dynamic>>> getAyatTransliteration(int sura) async {
    final db = await database;
    return db.query('quran_en_transliteration', where: 'sura = ?', whereArgs: [sura], orderBy: 'aya ASC');
  }

  /// Search chapters by name (Arabic or transliteration), case-insensitive.
  static Future<List<Map<String, dynamic>>> searchChapters(String query) async {
    final db = await database;
    final q = '%$query%';
    return db.query(
      'chapters',
      where: 'name_arabic LIKE ? OR name_transliteration LIKE ?',
      whereArgs: [q, q],
      orderBy: 'sura ASC',
    );
  }
}
