import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Read-only helper for the bundled Quran database (assets/database/quran.sqlite).
/// This is completely separate from DatabaseHelper (moni_prayer.db) which stores
/// the user's prayer/roza records — no shared tables, no risk to existing data.
class QuranDatabaseHelper {
  static Database? _db;

  // Bump this whenever assets/database/quran.sqlite is replaced with new content
  // (e.g. new translation tables) so existing installs re-copy the updated file
  // instead of keeping a stale cached copy in writable storage.
  static const int _assetDbVersion = 2;

  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'quran.sqlite');
    final versionMarkerPath = join(dbDir, 'quran_db_version.txt');

    bool needsCopy = !(await databaseExists(path));

    if (!needsCopy) {
      // Check the version marker to see if the bundled asset has been updated.
      try {
        final marker = File(versionMarkerPath);
        if (await marker.exists()) {
          final storedVersion = int.tryParse(await marker.readAsString()) ?? 0;
          if (storedVersion < _assetDbVersion) {
            needsCopy = true;
          }
        } else {
          // No marker means this copy predates versioning — refresh it once.
          needsCopy = true;
        }
      } catch (_) {
        needsCopy = true;
      }
    }

    if (needsCopy) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      final data = await rootBundle.load('assets/database/quran.sqlite');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      try {
        await File(versionMarkerPath).writeAsString(_assetDbVersion.toString());
      } catch (_) {}
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

  /// English transliteration for a given sura.
  static Future<List<Map<String, dynamic>>> getAyatTransliteration(int sura) async {
    final db = await database;
    return db.query('quran_en_transliteration', where: 'sura = ?', whereArgs: [sura], orderBy: 'aya ASC');
  }

  /// Bengali translation (Muhiuddin Khan) for a given sura, ordered by aya number.
  static Future<List<Map<String, dynamic>>> getAyatBangla(int sura) async {
    final db = await database;
    return db.query('quran_bn_muhiuddinkhan', where: 'sura = ?', whereArgs: [sura], orderBy: 'aya ASC');
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
