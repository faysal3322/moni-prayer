import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moni_prayer.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        prayer TEXT NOT NULL,
        status TEXT NOT NULL,
        UNIQUE(date, prayer)
      )
    ''');
    await db.execute('''
      CREATE TABLE roza_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL
      )
    ''');
  }

  static Future<void> setPrayerStatus(String date, String prayer, String status) async {
    final db = await database;
    await db.insert('prayer_records',
      {'date': date, 'prayer': prayer, 'status': status},
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, String>> getDayPrayerStatuses(String date) async {
    final db = await database;
    final result = await db.query('prayer_records', where: 'date = ?', whereArgs: [date]);
    final map = <String, String>{};
    for (final row in result) {
      map[row['prayer'] as String] = row['status'] as String;
    }
    return map;
  }

  static Future<Map<String, int>> getPrayerPendingCount() async {
    final db = await database;
    final missed = await db.rawQuery(
      "SELECT COUNT(*) as count FROM prayer_records WHERE status = 'missed'");
    final prayed = await db.rawQuery(
      "SELECT COUNT(*) as count FROM prayer_records WHERE status = 'prayed'");
    final m = Sqflite.firstIntValue(missed) ?? 0;
    final p = Sqflite.firstIntValue(prayed) ?? 0;
    final pending = m - p;
    return {'missed': m, 'prayed': p, 'pending': pending < 0 ? 0 : pending};
  }

  static Future<List<Map<String, dynamic>>> getMissedPrayerDates() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT date, GROUP_CONCAT(prayer, ',') as prayers
      FROM prayer_records WHERE status = 'missed'
      GROUP BY date ORDER BY date DESC
    ''');
  }

  static Future<Map<String, int>> getPrayerStatsByPeriod(String period) async {
    final db = await database;
    String w = '';
    final now = DateTime.now();
    if (period == 'year') w = "AND date LIKE '${now.year}%'";
    else if (period == 'month') {
      final m = now.month.toString().padLeft(2, '0');
      w = "AND date LIKE '${now.year}-$m%'";
    }
    final missed = await db.rawQuery(
      "SELECT COUNT(*) as count FROM prayer_records WHERE status = 'missed' $w");
    final prayed = await db.rawQuery(
      "SELECT COUNT(*) as count FROM prayer_records WHERE status = 'prayed' $w");
    final m = Sqflite.firstIntValue(missed) ?? 0;
    final p = Sqflite.firstIntValue(prayed) ?? 0;
    final pending = m - p;
    return {'missed': m, 'prayed': p, 'pending': pending < 0 ? 0 : pending};
  }

  static Future<void> setRozaStatus(String date, String status) async {
    final db = await database;
    await db.insert('roza_records',
      {'date': date, 'status': status},
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getRozaStatus(String date) async {
    final db = await database;
    final result = await db.query('roza_records', where: 'date = ?', whereArgs: [date]);
    if (result.isEmpty) return null;
    return result.first['status'] as String;
  }

  static Future<Map<String, int>> getRozaPendingCount() async {
    final db = await database;
    final missedResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM roza_records WHERE status = 'missed'");
    final prayedResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM roza_records WHERE status = 'prayed'");
    final totalMissed = Sqflite.firstIntValue(missedResult) ?? 0;
    final totalPrayed = Sqflite.firstIntValue(prayedResult) ?? 0;
    final pendingResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM roza_records WHERE status = 'missed'");
    final pending = Sqflite.firstIntValue(pendingResult) ?? 0;
    return {'missed': totalMissed, 'prayed': totalPrayed, 'pending': pending};
  }

  static Future<List<String>> getMissedRozaDates() async {
    final db = await database;
    final result = await db.query('roza_records',
      where: "status = 'missed'", orderBy: 'date DESC');
    return result.map((r) => r['date'] as String).toList();
  }

  static Future<Map<String, int>> getRozaStatsByPeriod(String period) async {
    final db = await database;
    String w = '';
    final now = DateTime.now();
    if (period == 'year') w = "AND date LIKE '${now.year}%'";
    else if (period == 'month') {
      final m = now.month.toString().padLeft(2, '0');
      w = "AND date LIKE '${now.year}-$m%'";
    }
    final missed = await db.rawQuery(
      "SELECT COUNT(*) as count FROM roza_records WHERE status = 'missed' $w");
    final prayed = await db.rawQuery(
      "SELECT COUNT(*) as count FROM roza_records WHERE status = 'prayed' $w");
    final m = Sqflite.firstIntValue(missed) ?? 0;
    final p = Sqflite.firstIntValue(prayed) ?? 0;
    return {'missed': m, 'prayed': p, 'pending': m};
  }

  static Future<String> getDayStatus(String date) async {
    final db = await database;
    final prayers = await db.query('prayer_records', where: 'date = ?', whereArgs: [date]);
    final roza = await db.query('roza_records', where: 'date = ?', whereArgs: [date]);
    bool hasMissed = prayers.any((p) => p['status'] == 'missed') ||
        roza.any((r) => r['status'] == 'missed');
    bool hasAll = prayers.length == 5 && roza.isNotEmpty;
    bool allCompleted = prayers.every((p) => p['status'] == 'prayed') &&
        roza.every((r) => r['status'] == 'prayed');
    if (hasMissed) return 'missed';
    if (hasAll && allCompleted) return 'completed';
    if (prayers.isNotEmpty || roza.isNotEmpty) return 'pending';
    return 'none';
  }

  static Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final prayers = await db.query('prayer_records');
    final rozas = await db.query('roza_records');
    return {
      'version': 1,
      'export_date': DateTime.now().toIso8601String(),
      'prayer_records': prayers,
      'roza_records': rozas,
    };
  }

  static Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.delete('prayer_records');
    await db.delete('roza_records');
    for (final p in data['prayer_records'] as List) {
      await db.insert('prayer_records', Map<String, dynamic>.from(p));
    }
    for (final r in data['roza_records'] as List) {
      await db.insert('roza_records', Map<String, dynamic>.from(r));
    }
  }

  // সারসংক্ষেপের জন্য সব stats একসাথে
  static Future<Map<String, dynamic>> getSummaryStats({String filter = 'all'}) async {
    final db = await database;
    final now = DateTime.now();

    List<Map> prayerRows;
    List<Map> rozaRows;

    if (filter == 'year') {
      prayerRows = await db.rawQuery(
          "SELECT status FROM prayer_records WHERE date LIKE '${now.year}%'");
      rozaRows = await db.rawQuery(
          "SELECT status FROM roza_records WHERE date LIKE '${now.year}%'");
    } else if (filter == 'month') {
      final month = now.month.toString().padLeft(2, '0');
      prayerRows = await db.rawQuery(
          "SELECT status FROM prayer_records WHERE date LIKE '${now.year}-$month%'");
      rozaRows = await db.rawQuery(
          "SELECT status FROM roza_records WHERE date LIKE '${now.year}-$month%'");
    } else {
      prayerRows = await db.rawQuery("SELECT status FROM prayer_records");
      rozaRows = await db.rawQuery("SELECT status FROM roza_records");
    }

    int pMissed = 0, pPrayed = 0, pPending = 0;
    for (final row in prayerRows) {
      final s = row['status'] as String? ?? '';
      if (s == 'missed') pMissed++;
      else if (s == 'prayed') pPrayed++;
      else pPending++;
    }

    int rMissed = 0, rPrayed = 0, rPending = 0;
    for (final row in rozaRows) {
      final s = row['status'] as String? ?? '';
      if (s == 'missed') rMissed++;
      else if (s == 'prayed') rPrayed++;
      else rPending++;
    }

    return {
      'prayer_missed': pMissed,
      'prayer_prayed': pPrayed,
      'prayer_pending': pPending,
      'roza_missed': rMissed,
      'roza_prayed': rPrayed,
      'roza_pending': rPending,
    };
  }
}
