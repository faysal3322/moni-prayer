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
  static const int _assetDbVersion = 3;

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

  /// All 30 juz (para) start points: {id, sura, aya}, ordered 1..30.
  static Future<List<Map<String, dynamic>>> getJuzList() async {
    final db = await database;
    return db.query('juz', orderBy: 'id ASC');
  }

  /// All ayat belonging to a given juz number (1..30), possibly spanning
  /// multiple surahs, in Uthmani script with sura/aya info.
  /// Uses the start point of this juz and the start point of the next juz
  /// (or end of Quran for juz 30) to bound the range.
  static Future<List<Map<String, dynamic>>> getAyatForJuz(int juzNumber) async {
    final db = await database;
    final juzRows = await db.query('juz', where: 'id = ?', whereArgs: [juzNumber]);
    if (juzRows.isEmpty) return [];
    final startSura = juzRows.first['sura'] as int;
    final startAya = juzRows.first['aya'] as int;

    final nextJuzRows = await db.query('juz', where: 'id = ?', whereArgs: [juzNumber + 1]);

    if (nextJuzRows.isEmpty) {
      // Last juz — everything from the start point to the end of the Quran.
      return db.rawQuery('''
        SELECT * FROM quran_uthmani
        WHERE (sura > ?) OR (sura = ? AND aya >= ?)
        ORDER BY sura ASC, aya ASC
      ''', [startSura, startSura, startAya]);
    }

    final endSura = nextJuzRows.first['sura'] as int;
    final endAya = nextJuzRows.first['aya'] as int;

    return db.rawQuery('''
      SELECT * FROM quran_uthmani
      WHERE (sura > ? OR (sura = ? AND aya >= ?))
        AND (sura < ? OR (sura = ? AND aya < ?))
      ORDER BY sura ASC, aya ASC
    ''', [startSura, startSura, startAya, endSura, endSura, endAya]);
  }

  /// Fetch a single ayah's Uthmani text by sura+aya (used by "আমার কোরআন" collections).
  static Future<Map<String, dynamic>?> getSingleAya(int sura, int aya) async {
    final db = await database;
    final rows = await db.query(
      'quran_uthmani',
      where: 'sura = ? AND aya = ?',
      whereArgs: [sura, aya],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Fetch a single ayah's Bengali translation by sura+aya.
  static Future<Map<String, dynamic>?> getSingleAyaBangla(int sura, int aya) async {
    final db = await database;
    final rows = await db.query(
      'quran_bn_muhiuddinkhan',
      where: 'sura = ? AND aya = ?',
      whereArgs: [sura, aya],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Fetch a single ayah's English transliteration by sura+aya.
  static Future<Map<String, dynamic>?> getSingleAyaTransliteration(int sura, int aya) async {
    final db = await database;
    final rows = await db.query(
      'quran_en_transliteration',
      where: 'sura = ? AND aya = ?',
      whereArgs: [sura, aya],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Fetch the Saad al-Ghamdi audio URL for the whole surah (gapless, one file).
  static Future<Map<String, dynamic>?> getSurahAudio(int sura) async {
    final db = await database;
    final rows = await db.query('quran_audio_surah', where: 'sura = ?', whereArgs: [sura]);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Fetch the start/end timestamp (in ms, within the surah's mp3 file) for
  /// a single ayah — used to seek/clip playback of one verse from the
  /// gapless surah audio.
  ///
  /// Note: returns the raw database timestamp (no Basmalah adjustment).
  /// Audio playback must always seek to the true recorded start, otherwise
  /// the Bismillah recitation at the start of ayah 1 (for every surah
  /// except Al-Fatiha) gets skipped. Highlight-timing adjustments for the
  /// Bismillah gap are applied separately in QuranPlaybackHandler.
  static Future<Map<String, dynamic>?> getAyaSegment(int sura, int aya) async {
    final db = await database;
    final rows = await db.query(
      'quran_audio_segments',
      where: 'sura = ? AND aya = ?',
      whereArgs: [sura, aya],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Fetch all ayah timing segments for a surah, ordered by aya number
  /// (used for sequential/auto-continue playback across the whole surah).
  static Future<List<Map<String, dynamic>>> getAllSegmentsForSura(int sura) async {
    final db = await database;
    return db.query('quran_audio_segments', where: 'sura = ?', whereArgs: [sura], orderBy: 'aya ASC');
  }
}
