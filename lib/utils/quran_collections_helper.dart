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
      version: 3,
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
            sura INTEGER,
            aya INTEGER,
            sort_order INTEGER NOT NULL,
            group_key TEXT,
            repeat_count INTEGER NOT NULL DEFAULT 1,
            item_type TEXT NOT NULL DEFAULT 'aya',
            custom_title TEXT,
            custom_file_path TEXT,
            FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE
          )
        ''');
      },
      // ফিচার সংযোজন: "সম্পূর্ণ সূরা N বার পড়ুন" গ্রুপিং সাপোর্ট করতে
      // group_key ও repeat_count কলাম যোগ করা হচ্ছে। আগে থেকে ইনস্টল করা
      // অ্যাপে থাকা বিদ্যমান কালেকশন/আইটেম কোনোভাবে মোছা বা পরিবর্তিত হয়
      // না — শুধু নতুন কলাম দুটো ডিফল্ট মান (NULL, 1) নিয়ে যোগ হয়, যা
      // "আলাদা আলাদা আয়াত" হিসেবেই আগের মতো দেখাতে থাকে যতক্ষণ না
      // ব্যবহারকারী নতুন করে "সম্পূর্ণ সূরা" ফিচার ব্যবহার করেন।
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE collection_items ADD COLUMN group_key TEXT');
          await db.execute(
              'ALTER TABLE collection_items ADD COLUMN repeat_count INTEGER NOT NULL DEFAULT 1');
        }
        // ফিচার সংযোজন: "নিজের দোয়া/অডিও" — কোরআনের বাইরের যেকোনো mp3
        // (custom_file_path) কালেকশনে সূরা/আয়াতের মতোই একটা আইটেম
        // হিসেবে যোগ করা যায়। sura/aya এখন থেকে nullable (custom
        // আইটেমে এগুলো লাগে না), কিন্তু SQLite-এ কলামকে "nullable" করতে
        // ALTER TABLE লাগে না — আগের NOT NULL constraint নতুন সংস্করণে
        // শুধু নতুন insert-এ প্রযোজ্য না হওয়ার জন্য পুরো টেবিল আগের
        // ডেটাসহ নতুন স্কিমায় copy করা হচ্ছে, যাতে পুরনো সূরা/আয়াত
        // আইটেমগুলো (item_type='aya') কোনোভাবে ক্ষতিগ্রস্ত না হয়।
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE collection_items RENAME TO collection_items_old');
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER NOT NULL,
              sura INTEGER,
              aya INTEGER,
              sort_order INTEGER NOT NULL,
              group_key TEXT,
              repeat_count INTEGER NOT NULL DEFAULT 1,
              item_type TEXT NOT NULL DEFAULT 'aya',
              custom_title TEXT,
              custom_file_path TEXT,
              FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            INSERT INTO collection_items
              (id, collection_id, sura, aya, sort_order, group_key, repeat_count, item_type)
            SELECT id, collection_id, sura, aya, sort_order, group_key, repeat_count, 'aya'
            FROM collection_items_old
          ''');
          await db.execute('DROP TABLE collection_items_old');
        }
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
    await insertItemAfter(collectionId, sura, aya, afterItemId: null);
  }

  /// [afterItemId] এর পরে একই সূরার [ayas] আয়াতগুলো একটা "গ্রুপ" হিসেবে
  /// একসাথে যোগ করে, প্রতিটা row-কে একই [group_key] ও [repeatCount]
  /// দিয়ে ট্যাগ করে। কালেকশন ডিটেইল স্ক্রিন এই group_key দেখে বুঝতে
  /// পারে কোন আয়াতগুলো একসাথে যোগ হয়েছিল, তাই সেগুলোকে একটা কার্ডে
  /// দেখানো যায় (যেমন "সূরা ফাতিহা — ৭ বার")। [ayas] দৈর্ঘ্য ১ হলেও
  /// (একটামাত্র আয়াত, যেমন আয়াতুল কুরসি ১০ বার) একই লজিক কাজ করে।
  ///
  /// [afterItemId] null হলে তালিকার শেষে যোগ হয়। আগে থেকে থাকা আয়াত
  /// ডুপ্লিকেট করা হয় না (গ্রুপ থেকে বাদ পড়ে যায়, কিন্তু বাকিগুলো ঠিকই
  /// যোগ হয় — যেমন সূরা ফাতিহা একবার আগে থেকে যোগ থাকলে, আবার "সম্পূর্ণ
  /// সূরা" দিলে শুধু নতুন repeat-block হিসেবে বাকি অংশ যোগ হবে না, বরং
  /// পুরো ব্যাপারটা এড়িয়ে যাওয়া হয় — ব্যবহারকারীকে আলাদা নামে/নতুন
  /// কালেকশনে যোগ করতে বলা ভালো, কিন্তু সেই UI সিদ্ধান্ত collection_detail
  /// screen-এর দায়িত্ব)।
  static Future<void> insertGroupAfter(
    int collectionId,
    int sura,
    List<int> ayas, {
    int? afterItemId,
    int repeatCount = 1,
  }) async {
    if (ayas.isEmpty) return;
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
    if (items.isEmpty) {
      insertPosition = 0;
    } else if (afterItemId == null) {
      insertPosition = items.length;
    } else {
      final idx = items.indexWhere((it) => it['id'] == afterItemId);
      insertPosition = idx == -1 ? items.length : idx + 1;
    }

    final sortedAyas = List<int>.from(ayas.toSet())..sort();
    // একই গ্রুপের সব আয়াত একই group_key শেয়ার করে — timestamp + sura
    // দিয়ে বানানো, যাতে একই সূরা বারবার আলাদা আলাদা গ্রুপ হিসেবে যোগ
    // করলেও (যেমন একবার ফাতিহা ৭ বার, পরে আবার ফাতিহা ৩ বার আলাদা
    // জায়গায়) key দুটো আলাদা থাকে, একসাথে মিশে না যায়।
    final groupKey = 'g_${DateTime.now().microsecondsSinceEpoch}_$sura';

    final batch = db.batch();
    final newIds = <int>[];
    for (final aya in sortedAyas) {
      if (existingAyas.contains(aya)) continue; // ডুপ্লিকেট এড়ানো
      batch.insert('collection_items', {
        'collection_id': collectionId,
        'sura': sura,
        'aya': aya,
        'sort_order': -1,
        'group_key': groupKey,
        'repeat_count': repeatCount,
      });
    }
    final results = await batch.commit();
    for (final r in results) {
      if (r is int) newIds.add(r);
    }
    if (newIds.isEmpty) return; // সবই আগে থেকে ছিল, কিছু নতুন যোগ হয়নি

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

  /// একটা সম্পূর্ণ সূরার [ayasCount] সংখ্যক আয়াত (১ থেকে [ayasCount]
  /// পর্যন্ত) কালেকশনের শেষে একসাথে যোগ করে, [repeatCount] বার পড়ার
  /// জন্য গ্রুপ করে। insertGroupAfter-এর thin wrapper — পুরনো কলার
  /// (backup import ইত্যাদি) এর জন্য backward-compatible রাখা হয়েছে।
  static Future<void> addFullSurah(
    int collectionId,
    int sura,
    int ayasCount, {
    int repeatCount = 1,
  }) async {
    await insertGroupAfter(
      collectionId,
      sura,
      List<int>.generate(ayasCount, (i) => i + 1),
      afterItemId: null,
      repeatCount: repeatCount,
    );
  }

  /// [afterItemId] আইটেমটার ঠিক পরে নতুন আয়াত ([sura]:[aya]) যোগ করে,
  /// [repeatCount] বার পড়ার জন্য (ডিফল্ট ১, অর্থাৎ স্বাভাবিক একবার)।
  /// [afterItemId] null হলে তালিকার শেষে যোগ হয়।
  static Future<void> insertItemAfter(
    int collectionId,
    int sura,
    int aya, {
    int? afterItemId,
    int repeatCount = 1,
  }) async {
    await insertGroupAfter(
      collectionId,
      sura,
      [aya],
      afterItemId: afterItemId,
      repeatCount: repeatCount,
    );
  }

  /// [afterItemId] এর পরে একটা সম্পূর্ণ সূরা (আয়াত ১ থেকে [ayasCount])
  /// একসাথে ঢোকায়, [repeatCount] বার পড়ার জন্য গ্রুপ করে। [afterItemId]
  /// null হলে তালিকার শেষে ঢোকে।
  static Future<void> insertFullSurahAfter(
    int collectionId,
    int sura,
    int ayasCount, {
    int? afterItemId,
    int repeatCount = 1,
  }) async {
    await insertGroupAfter(
      collectionId,
      sura,
      List<int>.generate(ayasCount, (i) => i + 1),
      afterItemId: afterItemId,
      repeatCount: repeatCount,
    );
  }

  /// [afterItemId] এর পরে একই সূরার একাধিক নির্দিষ্ট আয়াত ([ayas]) একসাথে
  /// ঢোকায় (যেমন "1-5,9,21-29"), [repeatCount] বার পড়ার জন্য গ্রুপ করে।
  /// [afterItemId] null হলে তালিকার শেষে ঢোকে।
  static Future<void> insertMultipleAyasAfter(
    int collectionId,
    int sura,
    List<int> ayas, {
    int? afterItemId,
    int repeatCount = 1,
  }) async {
    await insertGroupAfter(
      collectionId,
      sura,
      ayas,
      afterItemId: afterItemId,
      repeatCount: repeatCount,
    );
  }

  /// [afterItemId] এর পরে "নিজের দোয়া/অডিও" আইটেম (কোরআনের বাইরের, নিজের
  /// রাখা mp3) যোগ করে — sura/aya এখানে null থাকে, বদলে item_type='custom'
  /// আর custom_title/custom_file_path সেট হয়। [afterItemId] null হলে
  /// তালিকার শেষে যোগ হয়। এই আইটেম insertGroupAfter-এর গ্রুপিং লজিকের
  /// বাইরে — প্রতিটা কাস্টম অডিও নিজেই একটা স্বতন্ত্র আইটেম (রিপিট/গ্রুপ
  /// কার্ড হিসেবে দেখানোর দরকার নেই, কারণ এটা একটামাত্র সম্পূর্ণ ফাইল)।
  static Future<void> insertCustomAudioAfter(
    int collectionId,
    String title,
    String filePath, {
    int? afterItemId,
    int repeatCount = 1,
  }) async {
    final db = await database;

    final items = await db.query(
      'collection_items',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'sort_order ASC',
    );

    int insertPosition;
    if (items.isEmpty) {
      insertPosition = 0;
    } else if (afterItemId == null) {
      insertPosition = items.length;
    } else {
      final idx = items.indexWhere((it) => it['id'] == afterItemId);
      insertPosition = idx == -1 ? items.length : idx + 1;
    }

    final newId = await db.insert('collection_items', {
      'collection_id': collectionId,
      'sura': null,
      'aya': null,
      'sort_order': -1,
      'group_key': null,
      'repeat_count': repeatCount,
      'item_type': 'custom',
      'custom_title': title,
      'custom_file_path': filePath,
    });

    final orderedIds = items.map((it) => it['id'] as int).toList();
    orderedIds.insert(insertPosition, newId);

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

  /// ব্যাকআপের জন্য সব কালেকশন ও তাদের আইটেম একসাথে বের করে আনে।
  /// প্রতিটা কালেকশনের ভেতরে তার নিজস্ব আইটেমগুলো (sura, aya, sort_order)
  /// নেস্টেড আকারে থাকে, যাতে রিস্টোরের সময় collection_id নতুন করে বসাতে
  /// সুবিধা হয় (পুরনো ডিভাইসের auto-increment id নতুন ডিভাইসে মিলবে না)।
  static Future<List<Map<String, dynamic>>> exportAllCollections() async {
    final db = await database;
    final collections = await db.query('collections', orderBy: 'created_at DESC');
    final result = <Map<String, dynamic>>[];
    for (final c in collections) {
      final items = await db.query(
        'collection_items',
        where: 'collection_id = ?',
        whereArgs: [c['id']],
        orderBy: 'sort_order ASC',
      );
      result.add({
        'name': c['name'],
        'created_at': c['created_at'],
        'items': items
            .map((it) => {
                  'sura': it['sura'],
                  'aya': it['aya'],
                  'sort_order': it['sort_order'],
                  'group_key': it['group_key'],
                  'repeat_count': it['repeat_count'],
                  'item_type': it['item_type'],
                  'custom_title': it['custom_title'],
                  'custom_file_path': it['custom_file_path'],
                })
            .toList(),
      });
    }
    return result;
  }

  /// ব্যাকআপ থেকে কালেকশন পুনরুদ্ধার করে। আগে থেকে থাকা সব কালেকশন ও
  /// আইটেম মুছে ফেলে ব্যাকআপের ডেটা দিয়ে প্রতিস্থাপন করা হয় (পুরনো id
  /// নির্ভরতা এড়াতে প্রতিটা কালেকশন নতুন করে insert করে তার নতুন id
  /// দিয়ে আইটেম যুক্ত করা হয়)।
  static Future<void> importAllCollections(List<dynamic> data) async {
    final db = await database;
    await db.delete('collection_items');
    await db.delete('collections');
    for (final c in data) {
      final map = Map<String, dynamic>.from(c as Map);
      final newId = await db.insert('collections', {
        'name': map['name'],
        'created_at': map['created_at'],
      });
      final items = (map['items'] as List?) ?? [];
      final batch = db.batch();
      for (final it in items) {
        final itemMap = Map<String, dynamic>.from(it as Map);
        batch.insert('collection_items', {
          'collection_id': newId,
          'sura': itemMap['sura'],
          'aya': itemMap['aya'],
          'sort_order': itemMap['sort_order'],
          // পুরনো ব্যাকআপ ফাইলে (নতুন ফিচার যোগ হওয়ার আগের) এই key গুলো
          // না-ও থাকতে পারে — তখন null/1/'aya' ডিফল্ট ব্যবহার হয়, যা
          // "আলাদা আলাদা আয়াত, একবার করে" হিসেবে স্বাভাবিকভাবেই দেখাবে।
          'group_key': itemMap['group_key'],
          'repeat_count': itemMap['repeat_count'] ?? 1,
          'item_type': itemMap['item_type'] ?? 'aya',
          'custom_title': itemMap['custom_title'],
          'custom_file_path': itemMap['custom_file_path'],
        });
      }
      await batch.commit(noResult: true);
    }
  }

  static Future<void> removeItem(int itemId) async {
    final db = await database;
    await db.delete('collection_items', where: 'id = ?', whereArgs: [itemId]);
  }

  /// সূচিপত্র তৈরির জন্য — কালেকশনের সব আইটেম সূরা অনুযায়ী গ্রুপ করে,
  /// প্রতিটা সূরার আয়াত নম্বরগুলোকে কম্প্যাক্ট রেঞ্জ-স্ট্রিং বানিয়ে দেয়
  /// (যেমন সূরা বাকারার [1,2,3,4,5,163,255,256,257,284,285,286] থেকে
  /// "১-৫, ১৬৩, ২৫৫-২৫৭, ২৮৪-২৮৬")। রিটার্ন করা লিস্ট কালেকশনে সূরাগুলো
  /// প্রথম যে ক্রমে এসেছে (sort_order অনুযায়ী) সেই ক্রমেই থাকে, প্রতিটা
  /// এন্ট্রিতে থাকে {sura, suraName, ayaCount, rangeText}। UI নিজের
  /// ভাষা/সংখ্যা-ফরম্যাট অনুযায়ী rangeText থেকে বাংলা/ইংরেজি সংখ্যায়
  /// বদলে নিতে পারে (এখানে ইংরেজি সংখ্যাতেই রাখা হয়েছে, যাতে ভাষা-নিরপেক্ষ
  /// থাকে — collection_detail_screen.dart প্রয়োজনে বাংলায় রূপান্তর করবে)।
  static Future<List<Map<String, dynamic>>> getTableOfContents(int collectionId) async {
    final items = await getCollectionItems(collectionId);
    if (items.isEmpty) return [];

    final suraOrder = <int>[]; // সূরা প্রথম যে ক্রমে দেখা গেছে
    final suraAyas = <int, List<int>>{};
    for (final item in items) {
      // "নিজের দোয়া/অডিও" আইটেমে sura/aya null থাকে — এগুলো
      // সূচিপত্রে কোরআনের সূরা হিসেবে গণনা হয় না, তাই স্কিপ করা হচ্ছে।
      if (item['item_type'] == 'custom') continue;
      final sura = item['sura'] as int;
      final aya = item['aya'] as int;
      if (!suraAyas.containsKey(sura)) {
        suraAyas[sura] = [];
        suraOrder.add(sura);
      }
      suraAyas[sura]!.add(aya);
    }

    final result = <Map<String, dynamic>>[];
    for (final sura in suraOrder) {
      final ayas = List<int>.from(suraAyas[sura]!.toSet())..sort();
      result.add({
        'sura': sura,
        'ayaCount': ayas.length,
        'rangeText': _formatAyaRanges(ayas),
      });
    }
    return result;
  }

  /// [1,2,3,4,5,163,255,256,257] → "1-5, 163, 255-257" — ধারাবাহিক
  /// আয়াত নম্বরগুলোকে একটা রেঞ্জে একত্র করে, বিচ্ছিন্ন নম্বর আলাদা থাকে।
  static String _formatAyaRanges(List<int> sortedAyas) {
    if (sortedAyas.isEmpty) return '';
    final parts = <String>[];
    var rangeStart = sortedAyas.first;
    var rangeEnd = sortedAyas.first;

    void flush() {
      parts.add(rangeStart == rangeEnd ? '$rangeStart' : '$rangeStart-$rangeEnd');
    }

    for (var i = 1; i < sortedAyas.length; i++) {
      final n = sortedAyas[i];
      if (n == rangeEnd + 1) {
        rangeEnd = n;
      } else {
        flush();
        rangeStart = n;
        rangeEnd = n;
      }
    }
    flush();
    return parts.join(', ');
  }

  /// [1,5,7]-এর মতো itemId তালিকা থেকে একটা "গ্রুপ" (একই group_key শেয়ার
  /// করা সব আইটেম) মুছে ফেলে — কালেকশন ডিটেইল স্ক্রিনে "সূরা ফাতিহা (৭
  /// বার)" কার্ডের ✕ বাটনে চাপলে পুরো গ্রুপ একসাথে সরাতে ব্যবহৃত হয়।
  static Future<void> removeGroup(String groupKey) async {
    final db = await database;
    await db.delete('collection_items', where: 'group_key = ?', whereArgs: [groupKey]);
  }

  /// একটা গ্রুপের repeat_count আপডেট করে (যেমন ব্যবহারকারী "সূরা ফাতিহা
  /// ৭ বার" থেকে বদলে "৩ বার" করতে চাইলে) — গ্রুপের সব row-এ একই মান বসে।
  static Future<void> updateGroupRepeatCount(String groupKey, int repeatCount) async {
    final db = await database;
    await db.update(
      'collection_items',
      {'repeat_count': repeatCount},
      where: 'group_key = ?',
      whereArgs: [groupKey],
    );
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
