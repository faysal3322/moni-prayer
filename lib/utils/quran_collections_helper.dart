import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Stores user-created Quran verse collections ("আমার কোরআন").
/// Completely separate database file (quran_collections.db) — no shared
/// tables with moni_prayer.db (prayer/roza data) or the read-only bundled
/// quran.sqlite (Arabic text/translations). Purely additive; nothing here
/// can affect existing app data.
class QuranCollectionsHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'quran_collections.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE collection_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collection_id INTEGER NOT NULL,
            sura INTEGER NOT NULL,
            aya INTEGER NOT NULL,
            sort_order INTEGER NOT NULL,
            FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getCollections() async {
    final db = await database;
    return db.query('collections', orderBy: 'created_at DESC');
  }

  static Future<int> createCollection(String name) async {
    final db = await database;
    return db.insert('collections', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> renameCollection(int id, String newName) async {
    final db = await database;
    await db.update('collections', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteCollection(int id) async {
    final db = await database;
    await db.delete('collection_items', where: 'collection_id = ?', whereArgs: [id]);
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getCollectionItems(int collectionId) async {
    final db = await database;
    return db.query(
      'collection_items',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'sort_order ASC',
    );
  }

  static Future<void> addItem(int collectionId, int sura, int aya) async {
    final db = await database;
    final existing = await db.query(
      'collection_items',
      where: 'collection_id = ? AND sura = ? AND aya = ?',
      whereArgs: [collectionId, sura, aya],
    );
    if (existing.isNotEmpty) return; // avoid duplicates

    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(sort_order) as maxOrder FROM collection_items WHERE collection_id = ?',
      [collectionId],
    );
    final maxOrder = (maxOrderResult.first['maxOrder'] as int?) ?? -1;

    await db.insert('collection_items', {
      'collection_id': collectionId,
      'sura': sura,
      'aya': aya,
      'sort_order': maxOrder + 1,
    });
  }

  /// একটা সম্পূর্ণ সূরার [ayasCount] সংখ্যক আয়াত (১ থেকে [ayasCount]
  /// পর্যন্ত) একসাথে একটা কালেকশনে যোগ করে — একটা করে addItem কল করার
  /// বদলে একটাই batch transaction ব্যবহার করা হয়, যাতে বড় সূরাতেও
  /// (যেমন সূরা বাকারা, ২৮৬ আয়াত) দ্রুত ও নির্ভরযোগ্যভাবে যোগ হয়।
  /// আগে থেকে যোগ করা আয়াত থাকলে সেগুলো ডুপ্লিকেট না করে বাদ দেওয়া হয়।
  static Future<void> addFullSurah(int collectionId, int sura, int ayasCount) async {
    final db = await database;
    final existingRows = await db.query(
      'collection_items',
      columns: ['aya'],
      where: 'collection_id = ? AND sura = ?',
      whereArgs: [collectionId, sura],
    );
    final existingAyas = existingRows.map((r) => r['aya'] as int).toSet();

    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(sort_order) as maxOrder FROM collection_items WHERE collection_id = ?',
      [collectionId],
    );
    var nextOrder = ((maxOrderResult.first['maxOrder'] as int?) ?? -1) + 1;

    final batch = db.batch();
    for (var aya = 1; aya <= ayasCount; aya++) {
      if (existingAyas.contains(aya)) continue; // ডুপ্লিকেট এড়ানো
      batch.insert('collection_items', {
        'collection_id': collectionId,
        'sura': sura,
        'aya': aya,
        'sort_order': nextOrder++,
      });
    }
    await batch.commit(noResult: true);
  }

  /// [afterItemId] আইটেমটার ঠিক পরে নতুন আয়াত ([sura]:[aya]) যোগ করে।
  /// [afterItemId] যদি null হয় (বা কালেকশন খালি থাকে), তালিকার একদম
  /// শুরুতে যোগ হয়। বিদ্যমান সব আইটেমের sort_order প্রয়োজনমতো একধাপ
  /// করে সরিয়ে জায়গা করে দেওয়া হয়, যাতে পুরো ক্রম ঠিক থাকে।
  /// একই আয়াত আগে থেকে থাকলে ডুপ্লিকেট করা হয় না।
  static Future<void> insertItemAfter(
    int collectionId,
    int sura,
    int aya, {
    int? afterItemId,
  }) async {
    final db = await database;

    final existing = await db.query(
      'collection_items',
      where: 'collection_id = ? AND sura = ? AND aya = ?',
      whereArgs: [collectionId, sura, aya],
    );
    if (existing.isNotEmpty) return; // ডুপ্লিকেট এড়ানো

    final items = await db.query(
      'collection_items',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'sort_order ASC',
    );

    int insertPosition; // items লিস্টে (০-ইনডেক্স) নতুন আয়াত যে অবস্থানে বসবে
    if (afterItemId == null || items.isEmpty) {
      insertPosition = 0;
    } else {
      final idx = items.indexWhere((it) => it['id'] == afterItemId);
      insertPosition = idx == -1 ? items.length : idx + 1;
    }

    // নতুন আইটেম insert করার পর id সহ ফিরে পাওয়া হচ্ছে
    final newItemId = await db.insert('collection_items', {
      'collection_id': collectionId,
      'sura': sura,
      'aya': aya,
      'sort_order': -1, // সাময়িক মান, নিচে পুরো তালিকা renumber হবে
    });

    // পুরনো তালিকায় সঠিক অবস্থানে নতুন আইটেমের id বসিয়ে পুরো ক্রম
    // ০,১,২... হিসেবে আবার লেখা হচ্ছে — এতে sort_order-এ কোনো ফাঁক বা
    // দ্বন্দ্ব থাকে না।
    final orderedIds = items.map((it) => it['id'] as int).toList();
    orderedIds.insert(insertPosition, newItemId);

    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'collection_items',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// [afterItemId] এর পরে একটা সম্পূর্ণ সূরা (আয়াত ১ থেকে [ayasCount])
  /// একসাথে ঢোকায়, সূরার নিজস্ব ক্রম ঠিক রেখে। [afterItemId] null হলে
  /// তালিকার শুরুতে ঢোকে। insertItemAfter-কে বারবার কল করলে যেমন প্রতিবার
  /// পুরো তালিকা আবার পড়তে হতো, তার বদলে এখানে একবারই তালিকা পড়ে পুরো
  /// batch একসাথে কমিট করা হয় — বড় সূরাতেও (২৮৬ আয়াত পর্যন্ত) দ্রুত কাজ করে।
  static Future<void> insertFullSurahAfter(
    int collectionId,
    int sura,
    int ayasCount, {
    int? afterItemId,
  }) async {
    final db = await database;

    final existingRows = await db.query(
      'collection_items',
      columns: ['aya'],
      where: 'collection_id = ? AND sura = ?',
      whereArgs: [collectionId, sura],
    );
    final existingAyas = existingRows.map((r) => r['aya'] as int).toSet();

    final items = await db.query(
      'collection_items',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'sort_order ASC',
    );

    int insertPosition;
    if (afterItemId == null || items.isEmpty) {
      insertPosition = 0;
    } else {
      final idx = items.indexWhere((it) => it['id'] == afterItemId);
      insertPosition = idx == -1 ? items.length : idx + 1;
    }

    final batch = db.batch();
    final newIds = <int>[]; // insert ফলাফল পরে সংগ্রহ করা হবে, তাই আপাতত -1
    for (var aya = 1; aya <= ayasCount; aya++) {
      if (existingAyas.contains(aya)) continue; // ডুপ্লিকেট এড়ানো
      batch.insert('collection_items', {
        'collection_id': collectionId,
        'sura': sura,
        'aya': aya,
        'sort_order': -1,
      });
    }
    final results = await batch.commit();
    for (final r in results) {
      if (r is int) newIds.add(r);
    }

    final orderedIds = items.map((it) => it['id'] as int).toList();
    orderedIds.insertAll(insertPosition, newIds);

    final renumberBatch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      renumberBatch.update(
        'collection_items',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await renumberBatch.commit(noResult: true);
  }

  static Future<void> removeItem(int itemId) async {
    final db = await database;
    await db.delete('collection_items', where: 'id = ?', whereArgs: [itemId]);
  }

  /// Persist a new item order after drag-and-drop reordering.
  /// `orderedItemIds` must contain every item id of the collection, in the new order.
  static Future<void> reorderItems(List<int> orderedItemIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedItemIds.length; i++) {
      batch.update(
        'collection_items',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedItemIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }
}
