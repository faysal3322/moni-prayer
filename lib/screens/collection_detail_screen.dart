import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import '../utils/quran_collections_helper.dart';
import '../utils/quran_prefs.dart';
import '../utils/quran_audio_helper.dart';

/// একটা সূরা তালিকা থেকে খুঁজে বেছে নেওয়ার জন্য reusable bottom sheet।
/// ফিক্স: আগে সূরা নির্বাচনের জন্য একটা সাধারণ DropdownButtonFormField
/// ব্যবহার হতো, যেখানে ১১৪টা সূরার পুরো তালিকা স্ক্রল করে খুঁজতে হতো —
/// কোনো সার্চ বক্স ছিল না। এখন এই ফাংশনটা একটা সার্চযোগ্য bottom sheet
/// দেখায় (উপরে একটা TextField, টাইপ করলেই তালিকা ফিল্টার হয়), এবং
/// নির্বাচিত সূরার সম্পূর্ণ chapter map রিটার্ন করে।
Future<Map<String, dynamic>?> showSearchableSurahPicker({
  required BuildContext context,
  required AppLanguage lang,
  required List<Map<String, dynamic>> chapters,
}) {
  final isBn = lang.isBn;
  final searchController = TextEditingController();
  final ValueNotifier<String> query = ValueNotifier('');

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: AppTheme.cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (v) => query.value = v.trim().toLowerCase(),
                  decoration: InputDecoration(
                    hintText: isBn ? 'সূরা খুঁজুন (নাম বা নম্বর)...' : 'Search surah (name or number)...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: query,
                  builder: (context, q, _) {
                    final filtered = q.isEmpty
                        ? chapters
                        : chapters.where((c) {
                            final sura = c['sura'] as int;
                            final nameEn = (c['name_transliteration'] as String? ?? '').toLowerCase();
                            final nameAr = (c['name_arabic'] as String? ?? '');
                            return nameEn.contains(q) ||
                                nameAr.contains(q) ||
                                sura.toString() == q ||
                                lang.toLocalNum(sura) == q;
                          }).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          isBn ? 'কোনো সূরা পাওয়া যায়নি' : 'No surah found',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        final sura = c['sura'] as int;
                        final name = c['name_transliteration'] as String? ?? '';
                        final nameAr = c['name_arabic'] as String? ?? '';
                        final ayasCount = c['ayas_count'] as int?;
                        // যোগ করা হয়েছে: প্রতিটা সূরার নামের পাশে মোট আয়াত
                        // সংখ্যা দেখানো হচ্ছে (chapters টেবিলের ayas_count
                        // কলাম থেকে), যাতে "নির্দিষ্ট আয়াত" যোগ করার সময়
                        // ব্যবহারকারী আলাদাভাবে না খুঁজে এখান থেকেই বুঝতে
                        // পারেন সূরাটায় সর্বোচ্চ কত নম্বর আয়াত পর্যন্ত আছে।
                        final ayahCountLabel = ayasCount != null
                            ? (isBn
                                ? '${lang.toLocalNum(ayasCount)} আয়াত'
                                : '$ayasCount ayahs')
                            : null;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.gold.withOpacity(0.15),
                            child: Text(
                              lang.toLocalNum(sura),
                              style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(color: AppTheme.textPrimary)),
                          subtitle: ayahCountLabel != null
                              ? Text(
                                  ayahCountLabel,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                )
                              : null,
                          trailing: Text(
                            nameAr,
                            style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'ScheherazadeNew', fontSize: 18),
                          ),
                          onTap: () => Navigator.pop(sheetContext, c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      );
    },
  );
}

class CollectionDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int collectionId;
  final String collectionName;
  const CollectionDetailScreen({
    super.key,
    required this.lang,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  List<Map<String, dynamic>> _items = []; // collection_items rows (id, sura, aya, sort_order)
  Map<int, Map<String, dynamic>> _ayaCache = {}; // item id -> {arabic, bangla, translit, suraName}
  List<Map<String, dynamic>> _chapters = [];
  bool _loading = true;
  late String _title;

  bool _showArabic = true;
  bool _showBangla = false;
  bool _showTransliteration = true;
  double _fontSize = 28.0;
  static const double _minFontSize = 18.0;
  static const double _maxFontSize = 40.0;

  // ══ অডিও প্লেয়ার স্টেট ══
  // ফিক্স: আগে কালেকশনের কোনো আয়াতই শোনার কোনো উপায় ছিল না। এখন প্রতিটা
  // আইটেম কার্ডে একটা প্লে বাটন আছে (একটা নির্দিষ্ট আয়াত শোনার জন্য),
  // এবং AppBar-এ একটা "সব শোনো" বাটন আছে (পুরো কালেকশন ক্রমান্বয়ে শোনার
  // জন্য)। _playingItemId বর্তমানে কোন item চলছে তা ট্র্যাক করে;
  // _sequencePlaying = true মানে "সব শোনো" মোডে আছি (একটা আয়াত শেষ হলে
  // পরেরটায় নিজে থেকে যাবে)।
  int? _playingItemId;
  bool _sequencePlaying = false;
  // "সব শোনো" চলমান অবস্থায় pause করা হয়েছে কিনা — stop থেকে আলাদা,
  // কারণ pause হলে audio position ধরে রাখা হয় এবং resume করলে সেখান
  // থেকেই আবার শুরু হয়, শুরু থেকে না।
  bool _sequencePaused = false;
  bool _audioBusy = false; // ডাউনলোড/লোড হওয়ার সময় ডাবল-ট্যাপ ঠেকাতে
  double _playbackSpeed = 1.0;
  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  // বর্তমানে চলা আইটেমটা কতবার (ইতিমধ্যে) পুনরাবৃত্তি হয়েছে — যেমন
  // repeat_count=7 হলে এই মান 0..6 পর্যন্ত যাবে, তারপর পরের আইটেমে যাবে।
  int _currentRepeatIndex = 0;

  // ফিক্স: "সব শোনো" চলাকালীন লিস্ট নিজে থেকে স্ক্রল হতো না — কোন
  // আয়াত এখন বাজছে সেটা বোঝাই যেত না যদি না ব্যবহারকারী নিজে স্ক্রল
  // করে খুঁজে বের করেন। প্রতিটা কার্ডের নিজস্ব GlobalKey রাখা হচ্ছে
  // (item id দিয়ে), যাতে _playingItemId বদলালে Scrollable.ensureVisible
  // দিয়ে সেই কার্ডে স্বয়ংক্রিয়ভাবে স্ক্রল করা যায়।
  final Map<int, GlobalKey> _itemKeys = {};
  GlobalKey _keyFor(int itemId) => _itemKeys.putIfAbsent(itemId, () => GlobalKey());
  // গ্রুপ কার্ডের (যেমন পুরো সূরা) বাইরের wrapper-এর জন্য আলাদা key
  // namespace — কারণ গ্রুপের প্রথম আয়াতের id দিয়েই যদি এই key বানানো হতো,
  // তাহলে সেই একই id-এর ভেতরের আয়াত (_buildInnerAyaText) তার নিজের key
  // এর সাথে সংঘর্ষ (duplicate GlobalKey) বাধিয়ে ফেলত।
  final Map<String, GlobalKey> _groupKeys = {};
  GlobalKey _groupKeyFor(String groupKey) => _groupKeys.putIfAbsent(groupKey, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    _title = widget.collectionName;
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    final items = await QuranCollectionsHelper.getCollectionItems(widget.collectionId);
    final chapters = await QuranDatabaseHelper.getChapters();
    final showArabic = await QuranPrefs.getShowArabic();
    final showBangla = await QuranPrefs.getShowBangla();
    final showTranslit = await QuranPrefs.getShowTransliteration();
    final fontSize = await QuranPrefs.getFontSize();
    final playbackSpeed = await QuranPrefs.getPlaybackSpeed();

    final cache = <int, Map<String, dynamic>>{};
    final suraNameMap = {
      for (final c in chapters) (c['sura'] as int): (c['name_transliteration'] as String? ?? ''),
    };

    for (final item in items) {
      final itemId = item['id'] as int;
      // "নিজের দোয়া/অডিও" আইটেমে sura/aya null থাকে — কোরআনের টেক্সট
      // ক্যাশে এদের জন্য কিছু লুকআপ করার দরকার নেই, স্কিপ করা হচ্ছে
      // (নাহলে নিচের `as int` cast null-এ ব্যর্থ হয়ে ক্র্যাশ করত)।
      if ((item['item_type'] as String? ?? 'aya') == 'custom') continue;
      final sura = item['sura'] as int;
      final aya = item['aya'] as int;
      final arabicRow = await QuranDatabaseHelper.getSingleAya(sura, aya);
      final banglaRow = await QuranDatabaseHelper.getSingleAyaBangla(sura, aya);
      final translitRow = await QuranDatabaseHelper.getSingleAyaTransliteration(sura, aya);
      cache[itemId] = {
        'arabic': arabicRow?['text'] as String? ?? '',
        'bangla': banglaRow?['text'] as String? ?? '',
        'translit': translitRow?['text'] as String? ?? '',
        'suraName': suraNameMap[sura] ?? '',
      };
    }

    if (!mounted) return;
    setState(() {
      // ফিক্স: sqflite-এর db.query() থেকে আসা List প্রায়ই ফিক্সড-লেংথ/
      // আনমডিফায়েবল হয় — সরাসরি সেটা _items-এ বসালে removeAt()/insert()
      // (যা _moveUp/_moveDown ব্যবহার করে) UnsupportedError ছোড়ে। যেহেতু
      // এই এরর একটা async setState callback-এর ভেতরে ঘটছিল, এটা কোনো
      // visible crash/error ছাড়াই silently swallow হয়ে যাচ্ছিল — তাই
      // SnackBar-এ "চাপা হয়েছে" দেখা যাচ্ছিল, কিন্তু তালিকা reorder
      // হচ্ছিল না। এখন List.of(...) দিয়ে একটা নতুন, নিশ্চিতভাবে growable
      // List তৈরি করা হচ্ছে।
      _items = List.of(items);
      _chapters = chapters;
      _ayaCache = cache;
      _showArabic = showArabic;
      _showBangla = showBangla;
      _showTransliteration = showTranslit;
      _fontSize = fontSize;
      _playbackSpeed = playbackSpeed;
      _loading = false;
    });
    // ব্যাকগ্রাউন্ডে অডিও আগে থেকেই চলমান থাকলে (ব্যবহারকারী স্ক্রিন
    // থেকে বেরিয়ে আবার ঢুকলে) UI-কে সেই সাথে মিলিয়ে নেওয়া হচ্ছে —
    // নাহলে অডিও আসলে চলছে থাকলেও স্ক্রিন থেমে-আছে এমন দেখাত।
    final np = QuranAudioHelper.nowPlaying.value;
    if (np != null) {
      final match = _items.firstWhere(
        (it) =>
            (it['item_type'] as String? ?? 'aya') == 'aya' &&
            it['sura'] == np.sura &&
            it['aya'] == np.ayaNumber,
        orElse: () => {},
      );
      if (match.isNotEmpty && mounted) {
        setState(() {
          _playingItemId = match['id'] as int;
          _sequencePlaying = true;
          _sequencePaused = np.isPaused;
        });
        _scrollToPlayingItem(match['id'] as int);
      }
    }
  }

  Future<void> _changeFontSize(double delta) async {
    final newSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize);
    if (newSize == _fontSize) return;
    setState(() => _fontSize = newSize);
    await QuranPrefs.setFontSize(newSize);
  }

  /// _items (flat, sort_order অনুযায়ী) থেকে প্রদর্শনযোগ্য গ্রুপ বানায়।
  /// একই group_key-এর consecutive আইটেমগুলো (যেমন একটা "সম্পূর্ণ সূরা"
  /// যোগ করার ফলাফল) একটা "group" এন্ট্রিতে মিশে যায়, যাতে UI-তে
  /// "সূরা ফাতিহা — ৭ বার" এর মতো একটাই কার্ড দেখানো যায়। একক আয়াত
  /// (group_key null, অথবা কোনো group-এ মাত্র ১টা আইটেম থাকলে — যেমন
  /// পুরনো ডাটা যেখানে গ্রুপিং ছিলই না) আলাদা "single" এন্ট্রি থাকে,
  /// আগের UI-এর মতোই। প্রতিটা এন্ট্রিতে থাকে:
  /// {type: 'group'|'single', items: [...], groupKey, repeatCount, sura}
  List<Map<String, dynamic>> _buildDisplayGroups() {
    final result = <Map<String, dynamic>>[];
    var i = 0;
    while (i < _items.length) {
      final item = _items[i];
      final groupKey = item['group_key'] as String?;
      if (groupKey == null) {
        result.add({'type': 'single', 'items': [item]});
        i++;
        continue;
      }
      // একই group_key-এর ধারাবাহিক (consecutive) আইটেমগুলো জড়ো করা —
      // reorder (moveUp/moveDown) করলে একটা গ্রুপ ভেঙে দুই টুকরো হয়ে
      // যেতে পারে, সেক্ষেত্রে প্রতিটা টুকরো নিজের মতো আলাদা গ্রুপ কার্ড
      // হিসেবে দেখানো হবে — এটা একটা যুক্তিসঙ্গত সীমাবদ্ধতা এবং কোনো
      // ডাটা হারায় না।
      final groupItems = <Map<String, dynamic>>[item];
      var j = i + 1;
      while (j < _items.length && _items[j]['group_key'] == groupKey) {
        groupItems.add(_items[j]);
        j++;
      }
      if (groupItems.length == 1) {
        result.add({'type': 'single', 'items': groupItems});
      } else {
        result.add({
          'type': 'group',
          'items': groupItems,
          'groupKey': groupKey,
          'repeatCount': (groupItems.first['repeat_count'] as int?) ?? 1,
          'sura': groupItems.first['sura'] as int,
        });
      }
      i = j;
    }
    return result;
  }

  /// একটা গ্রুপ পুরো সূরা কিনা যাচাই করে — গ্রুপের আয়াতগুলো ১ থেকে সূরার
  /// মোট আয়াত সংখ্যা পর্যন্ত ধারাবাহিকভাবে সবগুলো কভার করলে সেটা "সম্পূর্ণ
  /// সূরা"; নাহলে এটা একাধিক নির্দিষ্ট আয়াতের গ্রুপ (যেমন "1-5,9,21-29")।
  bool _isFullSurahGroup(Map<String, dynamic> group) {
    final sura = group['sura'] as int;
    final items = group['items'] as List<Map<String, dynamic>>;
    final chapter = _chapters.firstWhere((c) => c['sura'] == sura, orElse: () => {});
    final totalAyas = chapter['ayas_count'] as int?;
    if (totalAyas == null) return false;
    if (items.length != totalAyas) return false;
    final ayaSet = items.map((it) => it['aya'] as int).toSet();
    for (var a = 1; a <= totalAyas; a++) {
      if (!ayaSet.contains(a)) return false;
    }
    return true;
  }

  Future<void> _setSpeed(double value) async {
    setState(() => _playbackSpeed = value);
    await QuranPrefs.setPlaybackSpeed(value);
    // চলমান প্লেব্যাকেও সাথে সাথে নতুন স্পিড প্রয়োগ হয়, পরের আয়াতের
    // জন্য অপেক্ষা করতে হয় না।
    await QuranAudioHelper.setSpeed(value);
  }

  Future<void> _renameCollection() async {
    final isBn = widget.lang.isBn;
    final controller = TextEditingController(text: _title);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(isBn ? 'নাম পরিবর্তন' : 'Rename', style: const TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(isBn ? 'সেভ' : 'Save', style: const TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await QuranCollectionsHelper.renameCollection(widget.collectionId, newName);
      setState(() => _title = newName);
    }
  }

  /// "1-5,9,21-29,78" ফরম্যাটের স্ট্রিং পার্স করে একটা sorted, ডুপ্লিকেট-মুক্ত
  /// আয়াত-নম্বর তালিকায় রূপান্তর করে। কমা দিয়ে আলাদা আলাদা অংশ, প্রতিটা অংশ
  /// হয় একক নম্বর ("9") নয়তো রেঞ্জ ("21-29") হতে পারে। খালি অংশ (যেমন পরপর
  /// দুটো কমা) উপেক্ষা করা হয়। রেঞ্জের শুরু > শেষ হলে (যেমন "29-21") সেটাও
  /// স্বাভাবিকভাবে উল্টে নেওয়া হয়। কোনো অংশ পার্স করা না গেলে বা কোনো নম্বর
  /// ১ এর কম বা [maxAya] এর বেশি হলে একটা বর্ণনামূলক এরর ছুড়ে দেয়, যাতে
  /// ব্যবহারকারীকে ঠিক কোন অংশে সমস্যা তা জানানো যায়।
  List<int> _parseAyaRanges(String input, int maxAya) {
    final result = <int>{};
    final parts = input.split(',');
    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      if (part.contains('-')) {
        final bounds = part.split('-');
        if (bounds.length != 2) {
          throw FormatException(part);
        }
        final start = int.tryParse(bounds[0].trim());
        final end = int.tryParse(bounds[1].trim());
        if (start == null || end == null) {
          throw FormatException(part);
        }
        final lo = start <= end ? start : end;
        final hi = start <= end ? end : start;
        if (lo < 1 || hi > maxAya) {
          throw RangeError.range(hi, 1, maxAya, part);
        }
        for (var a = lo; a <= hi; a++) {
          result.add(a);
        }
      } else {
        final n = int.tryParse(part);
        if (n == null) {
          throw FormatException(part);
        }
        if (n < 1 || n > maxAya) {
          throw RangeError.range(n, 1, maxAya, part);
        }
        result.add(n);
      }
    }
    if (result.isEmpty) {
      throw const FormatException('empty');
    }
    return result.toList()..sort();
  }

  /// ফিক্স: আগে + বাটনে শুধু একটা নির্দিষ্ট আয়াত যোগ করা যেত, সম্পূর্ণ
  /// সূরা যোগ করার কোনো উপায় ছিল না। এখন শিটের উপরে দুটো মোড আছে —
  /// "নির্দিষ্ট আয়াত" ও "সম্পূর্ণ সূরা", ব্যবহারকারী যেকোনো একটা বেছে
  /// নিয়ে ব্যবহার করতে পারবে।
  /// [afterItemId] দেওয়া থাকলে (যেমন কোনো আয়াত কার্ডের ছোট + বাটন থেকে
  /// আসা কল), শিট সরাসরি সেই আয়াতের পরে যোগ করার জন্য প্রি-সিলেক্ট হয়ে
  /// খোলে এবং পজিশন ড্রপডাউন লুকানো থাকে (যেহেতু অবস্থান আগেই জানা)।
  /// FAB থেকে খোলা হলে (afterItemId == null) ব্যবহারকারী নিজে বেছে
  /// নিতে পারে — "তালিকার শেষে" নাকি "নির্দিষ্ট আয়াতের পরে"।
  void _showAddVerseSheet({int? afterItemId}) {
    final isBn = widget.lang.isBn;
    bool fullSurahMode = false;
    // "নিজের দোয়া/অডিও" — তৃতীয় মোড, কোরআনের সূরা/আয়াতের বাইরে গিয়ে
    // ব্যবহারকারীর নিজের রাখা mp3-কে কালেকশনে একটা আইটেম হিসেবে যোগ
    // করে। fullSurahMode এর পাশাপাশি আলাদা বুলিয়ান হিসেবে রাখা হলো
    // (তিনটা true/false এর জটিল কম্বিনেশন এড়াতে বাকি দুইটা মোডের
    // বিদ্যমান কোড অপরিবর্তিত রাখা সহজ হয়)।
    bool customAudioMode = false;
    String? pickedCustomAudioPath;
    String? pickedCustomAudioName;
    final customTitleController = TextEditingController();
    bool pickingFile = false;
    Map<String, dynamic>? selectedChapter;
    final ayaController = TextEditingController();
    String? errorText;
    bool submitting = false;
    int repeatCount = 1;

    // পজিশন নির্বাচন — শুধু কোনো নির্দিষ্ট আয়াতের কার্ড থেকে না এসে
    // FAB থেকে খোলা হলে এবং কালেকশনে অন্তত একটা আয়াত থাকলেই দেখানো হয়।
    final bool showPositionPicker = afterItemId == null && _items.isNotEmpty;
    // insertAfterId == null মানে "তালিকার শেষে" যোগ হবে।
    int? insertAfterId = afterItemId;

    String positionLabel(int? itemId) {
      if (itemId == null) {
        return isBn ? 'তালিকার শেষে' : 'At the end';
      }
      final item = _items.firstWhere((it) => it['id'] == itemId, orElse: () => {});
      if ((item['item_type'] as String? ?? 'aya') == 'custom') {
        final title = item['custom_title'] as String? ?? (isBn ? 'কাস্টম অডিও' : 'Custom audio');
        return isBn ? '$title এর পরে' : 'After $title';
      }
      final cached = _ayaCache[itemId];
      final aya = item['aya'];
      final suraName = cached?['suraName'] ?? '';
      return isBn
          ? '$suraName • আয়াত ${widget.lang.toLocalNum(aya as int? ?? 0)} এর পরে'
          : '$suraName • after verse $aya';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickSurah() async {
              final chosen = await showSearchableSurahPicker(
                context: context,
                lang: widget.lang,
                chapters: _chapters,
              );
              if (chosen != null) {
                setSheetState(() {
                  selectedChapter = chosen;
                  errorText = null;
                });
              }
            }

            // "নিজের দোয়া/অডিও" মোডে — file picker দিয়ে ডিভাইসের যেকোনো
            // mp3 বেছে নিয়ে Music/Recitations/custom-duas/ ফোল্ডারে
            // কপি করে (QuranAudioHelper.pickAndCopyCustomAudio)। কপি হয়ে
            // যাওয়ার পর সেই পাথটাই সংরক্ষণ হয়, তাই পরে মূল ফাইলটা
            // (Downloads/WhatsApp ইত্যাদি থেকে) মুছে গেলেও কালেকশনে
            // প্লে করা বন্ধ হয়ে যাবে না।
            Future<void> pickCustomAudio() async {
              setSheetState(() => pickingFile = true);
              try {
                final copiedPath = await QuranAudioHelper.pickAndCopyCustomAudio();
                if (copiedPath == null) {
                  setSheetState(() {
                    pickingFile = false;
                    errorText = isBn ? 'শুধু mp3 ফাইল নির্বাচন করুন' : 'Please select an mp3 file';
                  });
                  return;
                }
                setSheetState(() {
                  pickingFile = false;
                  pickedCustomAudioPath = copiedPath;
                  pickedCustomAudioName = copiedPath.split('/').last;
                  errorText = null;
                  // ব্যবহারকারী শিরোনাম আগে থেকে না লিখলে ফাইলের নাম
                  // (টাইমস্ট্যাম্প prefix বাদ দিয়ে) ডিফল্ট শিরোনাম
                  // হিসেবে বসিয়ে দেওয়া হচ্ছে, যাতে খালি রেখে জমা দিলেও
                  // একটা অর্থবহ নাম দেখা যায়।
                  if (customTitleController.text.trim().isEmpty) {
                    final name = pickedCustomAudioName!;
                    final underscoreIdx = name.indexOf('_');
                    final withoutTimestamp = (underscoreIdx > 0 && underscoreIdx < 20)
                        ? name.substring(underscoreIdx + 1)
                        : name;
                    customTitleController.text =
                        withoutTimestamp.replaceAll('.mp3', '').replaceAll('_', ' ');
                  }
                });
              } catch (e) {
                setSheetState(() {
                  pickingFile = false;
                  errorText = isBn ? 'ফাইল যোগ করতে সমস্যা হয়েছে' : 'Failed to add file';
                });
              }
            }

            final bottomSafeArea = MediaQuery.of(context).padding.bottom;
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                // ফিক্স: আগে শুধু viewInsets.bottom (কীবোর্ড ইনসেট) যোগ করা
                // হতো, কিন্তু ফোনের নিচের সিস্টেম নেভিগেশন বার/জেসচার-বার
                // এর padding (MediaQuery.padding.bottom) হিসাবে ধরা হতো না।
                // ফলে "যোগ করুন" বাটন নেভিগেশন বার দিয়ে আংশিক ঢাকা পড়ে
                // যেত (কীবোর্ড বন্ধ থাকা অবস্থাতেও)। এখন দুটোই যোগ করা
                // হচ্ছে, যেটাই বড় হোক না কেন।
                bottom: (keyboardInset > bottomSafeArea ? keyboardInset : bottomSafeArea) + 16,
              ),
              // ফিক্স: আগে এখানে সরাসরি Column বসানো ছিল, স্ক্রল-করার কোনো
              // ব্যবস্থা ছাড়া। ছোট স্ক্রিনে বা কীবোর্ড খোলা অবস্থায় শিটের
              // ভেতরের কনটেন্ট (মোড টগল + সূরা নির্বাচন + আয়াত নম্বর ফিল্ড
              // + বাটন) স্ক্রিনের উপলব্ধ জায়গার চেয়ে বেশি হয়ে গেলে নিচের
              // "যোগ করুন" বাটন কেটে/ঢাকা পড়ে যেত। এখন SingleChildScrollView
              // দিয়ে wrap করা হলো, যাতে প্রয়োজনে পুরো শিট স্ক্রল করে নিচের
              // বাটন পর্যন্ত সবসময় পৌঁছানো যায়।
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'কালেকশনে যোগ করুন' : 'Add to Collection',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  // মোড নির্বাচন — নির্দিষ্ট আয়াত / সম্পূর্ণ সূরা / নিজের দোয়া
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              fullSurahMode = false;
                              customAudioMode = false;
                              errorText = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: (!fullSurahMode && !customAudioMode) ? AppTheme.gold : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isBn ? 'নির্দিষ্ট আয়াত' : 'Single Verse',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: (!fullSurahMode && !customAudioMode) ? Colors.black : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              fullSurahMode = true;
                              customAudioMode = false;
                              errorText = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: (fullSurahMode && !customAudioMode) ? AppTheme.gold : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isBn ? 'সম্পূর্ণ সূরা' : 'Full Surah',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: (fullSurahMode && !customAudioMode) ? Colors.black : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              customAudioMode = true;
                              errorText = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: customAudioMode ? AppTheme.gold : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isBn ? 'নিজের দোয়া' : 'My Audio',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: customAudioMode ? Colors.black : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showPositionPicker) ...[
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final chosen = await showModalBottomSheet<int?>(
                          context: context,
                          backgroundColor: AppTheme.cardBg,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          builder: (posContext) {
                            return SafeArea(
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                children: [
                                  ListTile(
                                    title: Text(
                                      isBn ? 'তালিকার শেষে' : 'At the end',
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                    ),
                                    trailing: insertAfterId == null
                                        ? const Icon(Icons.check, color: AppTheme.gold)
                                        : null,
                                    onTap: () => Navigator.pop(posContext, null),
                                  ),
                                  const Divider(color: Colors.white12, height: 1),
                                  for (final it in _items)
                                    ListTile(
                                      title: Text(
                                        positionLabel(it['id'] as int),
                                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                      ),
                                      trailing: insertAfterId == it['id']
                                          ? const Icon(Icons.check, color: AppTheme.gold)
                                          : null,
                                      onTap: () => Navigator.pop(posContext, it['id'] as int),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                        // চাপার পর কিছুই বাছা না হলে (ব্যাক বাটনে বন্ধ করলে)
                        // আগের নির্বাচন অপরিবর্তিত থাকবে — তাই আলাদা ফ্ল্যাগ
                        // ব্যবহার করে "শেষে" স্পষ্টভাবে বেছে নেওয়া বনাম শিট
                        // বন্ধ করার মধ্যে পার্থক্য করা হচ্ছে না, কারণ চাপার
                        // ফলাফল সবসময়ই একটা বৈধ নির্বাচন (Navigator.pop এর
                        // মাধ্যমে explicit মান দিয়ে করা হয়)।
                        if (context.mounted) {
                          setSheetState(() => insertAfterId = chosen);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: isBn ? 'কোথায় যোগ হবে' : 'Insert position',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          suffixIcon: const Icon(Icons.expand_more, color: AppTheme.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.accent),
                          ),
                        ),
                        child: Text(
                          positionLabel(insertAfterId),
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (!customAudioMode) ...[
                  // সূরা নির্বাচন — এখন সার্চযোগ্য bottom sheet খোলে (আগে
                  // ছিল plain dropdown, স্ক্রল করে ১১৪টা সূরা খুঁজতে হতো)
                  InkWell(
                    onTap: pickSurah,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isBn ? 'সূরা নির্বাচন করুন' : 'Select Surah',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        suffixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.accent),
                        ),
                      ),
                      child: Text(
                        selectedChapter == null
                            ? (isBn ? 'চাপুন এবং খুঁজুন...' : 'Tap to search...')
                            : '${widget.lang.toLocalNum(selectedChapter!['sura'] as int)}. ${selectedChapter!['name_transliteration']}',
                        style: TextStyle(
                          color: selectedChapter == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (!fullSurahMode) ...[
                    const SizedBox(height: 12),
                    // ফিক্স: আগে এই ফিল্ডে শুধু একটা একক আয়াত নম্বর দেওয়া
                    // যেত, ফলে একসাথে অনেক আয়াত যোগ করতে হলে বারবার শিট
                    // খুলে একটা একটা করে যোগ করতে হতো। এখন কমা ও ড্যাশ
                    // দিয়ে একসাথে একাধিক আয়াত/রেঞ্জ লেখা যায় — যেমন
                    // "1-5,9,21-29" লিখলে ১-৫, ৯, এবং ২১-২৯ নম্বর আয়াত
                    // একসাথে, ক্রমান্বয়ে যোগ হবে। _parseAyaRanges এই
                    // ফরম্যাট পার্স করে।
                    TextField(
                      controller: ayaController,
                      keyboardType: const TextInputType.numberWithOptions(),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: isBn ? 'আয়াত নম্বর' : 'Verse Number(s)',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: isBn ? 'যেমন: 1-5,9,21-29' : 'e.g. 1-5,9,21-29',
                        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                        helperText: isBn
                            ? 'একাধিক আয়াত/রেঞ্জ কমা দিয়ে আলাদা করে লিখুন'
                            : 'Separate multiple verses/ranges with commas',
                        helperStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                        helperMaxLines: 2,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.accent),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    if (selectedChapter != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          isBn
                              ? 'মোট ${widget.lang.toLocalNum(selectedChapter!['ayas_count'] as int? ?? 0)} আয়াত যোগ হবে'
                              : 'All ${selectedChapter!['ayas_count'] ?? 0} verses will be added',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                  ],
                  ] else ...[
                    // "নিজের দোয়া/অডিও" মোড — mp3 বেছে নেওয়া + শিরোনাম
                    InkWell(
                      onTap: pickingFile ? null : pickCustomAudio,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: isBn ? 'mp3 ফাইল নির্বাচন করুন' : 'Select mp3 file',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          suffixIcon: pickingFile
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    height: 16, width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                                  ),
                                )
                              : const Icon(Icons.audio_file_outlined, color: AppTheme.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.accent),
                          ),
                        ),
                        child: Text(
                          pickedCustomAudioName ?? (isBn ? 'চাপুন এবং ফাইল বেছে নিন...' : 'Tap to pick a file...'),
                          style: TextStyle(
                            color: pickedCustomAudioName == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customTitleController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: isBn ? 'দোয়ার নাম' : 'Title',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: isBn ? 'যেমন: দরুদ শরীফ' : 'e.g. Durood Shorif',
                        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.accent),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // "কতবার পড়া হবে" — যেকোনো মোডেই (নির্দিষ্ট আয়াত বা
                  // সম্পূর্ণ সূরা) প্রযোজ্য। ডিফল্ট ১ (স্বাভাবিক একবার),
                  // বাড়ালে সেই আয়াত/সূরাটা প্লে করার সময় পরপর ততবার
                  // চলবে — যেমন আয়াতুল কুরসি মুখস্থ করার জন্য ১০ বার,
                  // বা সূরা ফাতিহা তাহাজ্জুদে ৭ বার।
                  Text(
                    isBn ? 'কতবার পড়া হবে' : 'Repeat count',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _RepeatStepperButton(
                        icon: Icons.remove,
                        enabled: repeatCount > 1,
                        onTap: () => setSheetState(() => repeatCount = (repeatCount - 1).clamp(1, 99)),
                      ),
                      Container(
                        width: 56,
                        alignment: Alignment.center,
                        child: Text(
                          widget.lang.toLocalNum(repeatCount),
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _RepeatStepperButton(
                        icon: Icons.add,
                        enabled: repeatCount < 99,
                        onTap: () => setSheetState(() => repeatCount = (repeatCount + 1).clamp(1, 99)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isBn ? '(ডিফল্ট ১ বার)' : '(default: once)',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              if (customAudioMode) {
                                if (pickedCustomAudioPath == null) {
                                  setSheetState(() => errorText =
                                      isBn ? 'একটি mp3 ফাইল নির্বাচন করুন' : 'Select an mp3 file');
                                  return;
                                }
                                final title = customTitleController.text.trim().isEmpty
                                    ? (isBn ? 'কাস্টম অডিও' : 'Custom audio')
                                    : customTitleController.text.trim();
                                setSheetState(() => submitting = true);
                                await QuranCollectionsHelper.insertCustomAudioAfter(
                                  widget.collectionId,
                                  title,
                                  pickedCustomAudioPath!,
                                  afterItemId: insertAfterId,
                                );
                                if (context.mounted) Navigator.pop(sheetContext);
                                _load();
                                return;
                              }

                              if (selectedChapter == null) {
                                setSheetState(() => errorText = isBn ? 'সূরা নির্বাচন করুন' : 'Select a surah');
                                return;
                              }
                              final sura = selectedChapter!['sura'] as int;
                              final maxAya = selectedChapter!['ayas_count'] as int? ?? 0;

                              // "শেষে" মোডে থাকলে (insertAfterId == null এবং
                              // showPositionPicker ব্যবহারই হয়নি) পুরোনো
                              // দ্রুত addFullSurah/addItem পথ ব্যবহার হয়।
                              // নির্দিষ্ট আয়াতের পরে যোগ করতে হলে
                              // insertItemAfter ব্যবহার হয়।
                              final bool insertAtPosition = insertAfterId != null;

                              if (fullSurahMode) {
                                setSheetState(() => submitting = true);
                                if (insertAtPosition) {
                                  await QuranCollectionsHelper.insertFullSurahAfter(
                                    widget.collectionId,
                                    sura,
                                    maxAya,
                                    afterItemId: insertAfterId,
                                    repeatCount: repeatCount,
                                  );
                                } else {
                                  await QuranCollectionsHelper.addFullSurah(
                                    widget.collectionId,
                                    sura,
                                    maxAya,
                                    repeatCount: repeatCount,
                                  );
                                }
                                if (context.mounted) Navigator.pop(sheetContext);
                                _load();
                                return;
                              }

                              // ফিক্স: এখন একটা একক নম্বরের বদলে
                              // "1-5,9,21-29" ফরম্যাটে একাধিক আয়াত/রেঞ্জ
                              // পার্স করা হয় (_parseAyaRanges)। ভুল ফরম্যাট
                              // বা রেঞ্জের বাইরের নম্বর দিলে নির্দিষ্ট এরর
                              // দেখানো হয়, নাহলে সবগুলো আয়াত একসাথে
                              // (insertMultipleAyasAfter) batch insert হয়।
                              List<int> ayaNums;
                              try {
                                ayaNums = _parseAyaRanges(ayaController.text.trim(), maxAya);
                              } on RangeError {
                                setSheetState(() => errorText = isBn
                                    ? 'এই সূরায় সর্বোচ্চ ${widget.lang.toLocalNum(maxAya)} আয়াত আছে'
                                    : 'This surah has only $maxAya verses');
                                return;
                              } catch (_) {
                                setSheetState(() => errorText = isBn
                                    ? 'সঠিক আয়াত নম্বর দিন (যেমন: 1-5,9,21-29)'
                                    : 'Enter valid verse number(s), e.g. 1-5,9,21-29');
                                return;
                              }
                              setSheetState(() => submitting = true);
                              if (insertAtPosition) {
                                await QuranCollectionsHelper.insertMultipleAyasAfter(
                                  widget.collectionId,
                                  sura,
                                  ayaNums,
                                  afterItemId: insertAfterId,
                                  repeatCount: repeatCount,
                                );
                              } else if (ayaNums.length == 1 && repeatCount == 1) {
                                await QuranCollectionsHelper.addItem(widget.collectionId, sura, ayaNums.first);
                              } else {
                                await QuranCollectionsHelper.insertMultipleAyasAfter(
                                  widget.collectionId,
                                  sura,
                                  ayaNums,
                                  afterItemId: null,
                                  repeatCount: repeatCount,
                                );
                              }
                              if (context.mounted) Navigator.pop(sheetContext);
                              _load();
                            },
                      child: submitting
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              customAudioMode
                                  ? (isBn ? 'দোয়া যোগ করুন' : 'Add Audio')
                                  : fullSurahMode
                                      ? (isBn ? 'সম্পূর্ণ সূরা যোগ করুন' : 'Add Full Surah')
                                      : (isBn ? 'যোগ করুন' : 'Add'),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  /// [1,2,3,163,255,256,257] → "1-3, 163, 255-257" — গ্রুপ কার্ডের
  /// টাইটেলে সংক্ষিপ্ত রেঞ্জ দেখানোর জন্য (সূচিপত্রের মতোই লজিক, কিন্তু
  /// এখানে সরাসরি UI-লেয়ারে ছোট তালিকার জন্য synchronous গণনা)।
  String _formatAyaRangesLocal(List<int> sortedAyas) {
    if (sortedAyas.isEmpty) return '';
    final parts = <String>[];
    var rangeStart = sortedAyas.first;
    var rangeEnd = sortedAyas.first;
    void flush() => parts.add(rangeStart == rangeEnd ? '$rangeStart' : '$rangeStart-$rangeEnd');
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

  /// একটা গ্রুপকে (একাধিক consecutive আইটেম) এক ধাপ উপরে সরায় — অর্থাৎ
  /// গ্রুপের ঠিক আগের আইটেমটার সাথে গ্রুপের অবস্থান অদল-বদল করে। যদি
  /// আগের আইটেমও একটা গ্রুপের অংশ হয়, পুরো সেই গ্রুপটাই একসাথে সরে যায়
  /// (যাতে দুটো গ্রুপ কখনো একে অপরের মধ্যে মিশে না যায়)।
  Future<void> _moveGroupUp(int firstIndex, int groupLength) async {
    if (firstIndex <= 0) return;
    final prevGroupKey = _items[firstIndex - 1]['group_key'] as String?;
    var prevBlockStart = firstIndex - 1;
    if (prevGroupKey != null) {
      while (prevBlockStart > 0 && _items[prevBlockStart - 1]['group_key'] == prevGroupKey) {
        prevBlockStart--;
      }
    }
    final prevBlockLength = firstIndex - prevBlockStart;
    setState(() {
      final movingBlock = _items.sublist(firstIndex, firstIndex + groupLength);
      _items.removeRange(firstIndex, firstIndex + groupLength);
      _items.insertAll(prevBlockStart, movingBlock);
    });
    final orderedIds = _items.map((e) => e['id'] as int).toList();
    await QuranCollectionsHelper.reorderItems(orderedIds);
  }

  /// _moveGroupUp-এর বিপরীত — গ্রুপকে এক ধাপ নিচে সরায়।
  Future<void> _moveGroupDown(int firstIndex, int groupLength) async {
    final lastIndex = firstIndex + groupLength - 1;
    if (lastIndex >= _items.length - 1) return;
    final nextGroupKey = _items[lastIndex + 1]['group_key'] as String?;
    var nextBlockEnd = lastIndex + 1;
    if (nextGroupKey != null) {
      while (nextBlockEnd + 1 < _items.length && _items[nextBlockEnd + 1]['group_key'] == nextGroupKey) {
        nextBlockEnd++;
      }
    }
    final nextBlockLength = nextBlockEnd - lastIndex;
    setState(() {
      final movingBlock = _items.sublist(firstIndex, firstIndex + groupLength);
      _items.removeRange(firstIndex, firstIndex + groupLength);
      _items.insertAll(firstIndex + nextBlockLength, movingBlock);
    });
    final orderedIds = _items.map((e) => e['id'] as int).toList();
    await QuranCollectionsHelper.reorderItems(orderedIds);
  }

  Future<void> _removeItem(int itemId) async {
    if (_playingItemId == itemId) {
      await QuranAudioHelper.stop();
      setState(() {
        _playingItemId = null;
        _sequencePlaying = false;
        _sequencePaused = false;
      });
    }
    await QuranCollectionsHelper.removeItem(itemId);
    _load();
  }

  /// একটা গ্রুপ কার্ডের ✕ বাটনে চাপলে পুরো গ্রুপের সব আয়াত একসাথে মুছে
  /// ফেলে (যেমন "সূরা ফাতিহা — ৭ বার" কার্ড মুছলে ফাতিহার সব কটা আয়াতই
  /// একসাথে চলে যায়, একটা একটা করে মুছতে হয় না)।
  Future<void> _removeGroup(String groupKey, List<Map<String, dynamic>> items) async {
    if (_playingItemId != null && items.any((it) => it['id'] == _playingItemId)) {
      await QuranAudioHelper.stop();
      setState(() {
        _playingItemId = null;
        _sequencePlaying = false;
        _sequencePaused = false;
        _currentRepeatIndex = 0;
      });
    }
    await QuranCollectionsHelper.removeGroup(groupKey);
    _load();
  }

  /// একটা গ্রুপের repeat count পাল্টানোর ছোট ডায়ালগ — তালিকায় প্রতিটা
  /// গ্রুপ কার্ডের পাশে একটা "✎ N বার" বাটন থেকে খোলে।
  Future<void> _showEditRepeatDialog(Map<String, dynamic> group) async {
    final isBn = widget.lang.isBn;
    int value = group['repeatCount'] as int;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            isBn ? 'কতবার পড়া হবে' : 'Repeat count',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RepeatStepperButton(
                icon: Icons.remove,
                enabled: value > 1,
                onTap: () => setDialogState(() => value = (value - 1).clamp(1, 99)),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  widget.lang.toLocalNum(value),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              _RepeatStepperButton(
                icon: Icons.add,
                enabled: value < 99,
                onTap: () => setDialogState(() => value = (value + 1).clamp(1, 99)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Text(isBn ? 'সংরক্ষণ' : 'Save', style: const TextStyle(color: AppTheme.gold)),
            ),
          ],
        ),
      ),
    );
    if (result != null && result != group['repeatCount']) {
      final groupKey = group['groupKey'] as String?;
      if (groupKey != null) {
        // group_key null মানে এই একক আইটেম (যেমন কাস্টম অডিও) কখনো কোনো
        // গ্রুপের অংশ ছিল না — এখানে পৌঁছানোর কথাই না (UI বাটনটাই
        // repeatCount > 1 না হলে দেখায় না), তবু নিরাপত্তার জন্য গার্ড।
        await QuranCollectionsHelper.updateGroupRepeatCount(groupKey, result);
        _load();
      }
    }
  }

  /// [index] নম্বর আইটেমটাকে এক ধাপ উপরে সরায়। প্রথম আইটেম হলে কিছু করে না।
  /// UI-তে সাথে সাথে আপডেট দেখানোর জন্য আগে লোকাল লিস্ট বদলানো হয় (setState),
  /// তারপর ডাটাবেসে নতুন sort_order সংরক্ষণ করা হয়।
  Future<void> _moveUp(int index) async {
    if (index <= 0 || index >= _items.length) return;
    setState(() {
      final item = _items.removeAt(index);
      _items.insert(index - 1, item);
    });
    final orderedIds = _items.map((e) => e['id'] as int).toList();
    await QuranCollectionsHelper.reorderItems(orderedIds);
  }

  /// [index] নম্বর আইটেমটাকে এক ধাপ নিচে সরায়। শেষ আইটেম হলে কিছু করে না।
  Future<void> _moveDown(int index) async {
    if (index < 0 || index >= _items.length - 1) return;
    setState(() {
      final item = _items.removeAt(index);
      _items.insert(index + 1, item);
    });
    final orderedIds = _items.map((e) => e['id'] as int).toList();
    await QuranCollectionsHelper.reorderItems(orderedIds);
  }

  // ══ একটা নির্দিষ্ট আইটেম (আয়াত) চালানো/থামানো ══
  Future<void> _togglePlayItem(Map<String, dynamic> item) async {
    final itemId = item['id'] as int;
    if (_playingItemId == itemId) {
      await QuranAudioHelper.stop();
      if (mounted) {
        setState(() {
          _playingItemId = null;
          _sequencePlaying = false;
          _sequencePaused = false;
          _currentRepeatIndex = 0;
        });
      }
      return;
    }
    // একক আয়াতে চাপলেও এখন থেকে এই আয়াত শেষ হওয়ার পর কালেকশনের পরের
    // আইটেমে চলে যাবে (আগে থেমে যেত) — chainNext:true এবং
    // _sequencePlaying:true সেট করে "সব শোনো"-র মতোই চেইন চলবে।
    final groupKey = item['group_key'] as String?;
    final groupFirstId = groupKey != null
        ? (_items.firstWhere((it) => it['group_key'] == groupKey, orElse: () => item)['id'] as int)
        : null;
    setState(() {
      _currentRepeatIndex = 0;
      _sequencePlaying = true;
      _sequencePaused = false;
    });
    await _playItem(
      item,
      chainNext: true,
      groupPassStart: groupFirstId,
    );
  }

  /// একটা group-এর (সম্পূর্ণ সূরা বা একাধিক-আয়াত ব্লক) প্লে বাটনে চাপলে —
  /// গ্রুপের প্রথম আয়াত থেকে শুরু করে, সবগুলো আয়াত ক্রমান্বয়ে একবার শেষ
  /// করে, তারপর গ্রুপের repeat_count অনুযায়ী পুরো গ্রুপটাই আবার শুরু
  /// থেকে বাজে — যেমন "সূরা ফাতিহা ৭ বার" মানে ফাতিহার ৭টা আয়াত
  /// ক্রমান্বয়ে বাজিয়ে, শেষ হলে আবার ১ নম্বর থেকে শুরু, মোট ৭ বার পুরো
  /// সূরা।
  Future<void> _togglePlayGroup(Map<String, dynamic> group) async {
    final items = group['items'] as List<Map<String, dynamic>>;
    if (items.isEmpty) return;
    final firstItemId = items.first['id'] as int;
    if (_sequencePlaying && _playingItemId != null &&
        items.any((it) => it['id'] == _playingItemId)) {
      await QuranAudioHelper.stop();
      if (mounted) {
        setState(() {
          _playingItemId = null;
          _sequencePlaying = false;
          _sequencePaused = false;
          _currentRepeatIndex = 0;
        });
      }
      return;
    }
    setState(() {
      _sequencePlaying = true;
      _currentRepeatIndex = 0;
    });
    await _playItem(items.first, chainNext: true, groupPassStart: firstItemId);
  }

  /// বর্তমানে যেই আইটেম বাজছে সেই কার্ডে স্মুথলি স্ক্রল করে নিয়ে যায়।
  /// গ্রুপের ভেতরের আয়াত হলে (যেমন পুরো সূরা চলছে), গ্রুপ কার্ড আগেই
  /// initiallyExpanded দিয়ে খুলে যায় (দেখুন _buildGroupCard), তাই এখানে
  /// দুই ফ্রেম অপেক্ষা করা হচ্ছে — একটা গ্রুপ খোলার অ্যানিমেশন শুরু
  /// হওয়ার জন্য, তারপর নির্দিষ্ট আয়াতের key attach হওয়ার জন্য।
  /// নির্দিষ্ট আয়াতের key এখনও না পাওয়া গেলে (এখনো খুলছে) গ্রুপ কার্ডেই
  /// স্ক্রল হয়, যা তখনও অনেকটা কাছাকাছি নিয়ে যায়।
  void _scrollToPlayingItem(int itemId) {
    void attempt() {
      if (!mounted) return;
      var ctx = _itemKeys[itemId]?.currentContext;
      if (ctx == null) {
        final groupKey = _items.firstWhere(
          (it) => it['id'] == itemId,
          orElse: () => {},
        )['group_key'] as String?;
        if (groupKey != null) {
          ctx = _groupKeys[groupKey]?.currentContext;
        }
      }
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.3, // স্ক্রিনের মাঝামাঝির একটু উপরে রাখা হচ্ছে, একদম উপরের কিনারায় না
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // গ্রুপ কার্ড এই ফ্রেমেই সবেমাত্র খোলা শুরু হয়েছে হতে পারে —
      // ভেতরের আয়াতের key attach হতে একটা ফ্রেম দেরি দেওয়া হচ্ছে।
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    });
  }

  /// [groupPassStart] দেওয়া থাকলে (group-play মোডে), এই itemId-টা যেই
  /// গ্রুপের প্রথম আয়াত সেই গ্রুপের "এক পাস" শুরুর id হিসেবে মনে রাখা
  /// হয় — যাতে গ্রুপের শেষ আয়াত শেষ হওয়ার পর দরকার হলে আবার এখান
  /// থেকেই শুরু করা যায় (গ্রুপ-লেভেল repeat)।
  Future<void> _playItem(
    Map<String, dynamic> item, {
    required bool chainNext,
    int? groupPassStart,
  }) async {
    if (_audioBusy) return;
    final itemId = item['id'] as int;
    final itemType = item['item_type'] as String? ?? 'aya';

    // "নিজের দোয়া/অডিও" আইটেম — কোনো সূরা/আয়াত/সেগমেন্ট লুকআপ লাগে না,
    // সরাসরি সংরক্ষিত mp3 ফাইলটাই শুরু থেকে শেষ পর্যন্ত বাজে। বাকি
    // চেইন-লজিক (পরের আইটেমে যাওয়া, repeat) সাধারণ আয়াতের মতোই কাজ
    // করে যাতে একই কালেকশনে সূরা ও কাস্টম দোয়া মিশিয়ে রাখলেও
    // "সব শোনো" নিরবচ্ছিন্নভাবে চলতে থাকে।
    if (itemType == 'custom') {
      final filePath = item['custom_file_path'] as String?;
      if (mounted) {
        setState(() {
          _audioBusy = true;
          _playingItemId = itemId;
        });
      }
      _scrollToPlayingItem(itemId);
      if (filePath == null || !await File(filePath).exists()) {
        // ফিক্স: আগে এখানে "if (mounted)" গার্ড থাকায় ব্যবহারকারী স্ক্রিন
        // থেকে বেরিয়ে গেলে (back চাপলে) চেইন এখানেই থেমে যেত — পরের
        // আইটেমে আর যাওয়া হতো না, কারণ পুরো ব্লকটাই mounted না হলে স্কিপ
        // হয়ে যেত। এখন UI আপডেট (setState) শুধু mounted থাকলে হয়, কিন্তু
        // পরের আইটেমে যাওয়ার সিদ্ধান্তটা mounted অবস্থা নির্বিশেষে নেওয়া
        // হচ্ছে, যাতে ব্যাকগ্রাউন্ডেও প্লেব্যাক চলতে থাকে।
        if (mounted) {
          setState(() {
            _audioBusy = false;
            _playingItemId = null;
          });
        }
        if (chainNext && _sequencePlaying) {
          _playNextInSequence(item, groupPassStart: groupPassStart);
        } else if (mounted) {
          setState(() { _sequencePlaying = false; _sequencePaused = false; });
        }
        return;
      }
      try {
        await QuranAudioHelper.playCustomAudio(
          filePath: filePath,
          onComplete: () {
            // ফিক্স: mounted না হলেও (স্ক্রিন থেকে বের হয়ে গেলেও) চেইন
            // চালিয়ে যাওয়া হচ্ছে — নিচের মন্তব্য দ্রষ্টব্য।
            if (chainNext && _sequencePlaying) {
              _playNextInSequence(item, groupPassStart: groupPassStart);
            } else if (mounted) {
              setState(() {
                _playingItemId = null;
                _sequencePlaying = false;
                _sequencePaused = false;
                _currentRepeatIndex = 0;
              });
            }
          },
        );
      } catch (e) {
        debugPrint('COLLECTION CUSTOM AUDIO PLAY ERROR ($filePath): $e');
        if (chainNext && _sequencePlaying) {
          _playNextInSequence(item, groupPassStart: groupPassStart);
        } else if (mounted) {
          setState(() {
            _playingItemId = null;
            _sequencePlaying = false;
            _sequencePaused = false;
            _currentRepeatIndex = 0;
          });
        }
      } finally {
        if (mounted) setState(() => _audioBusy = false);
      }
      return;
    }

    final sura = item['sura'] as int;
    final aya = item['aya'] as int;

    if (mounted) {
      setState(() {
        _audioBusy = true;
        _playingItemId = itemId;
      });
    }
    _scrollToPlayingItem(itemId);

    try {
      final surahAudio = await QuranDatabaseHelper.getSurahAudio(sura);
      final segment = await QuranDatabaseHelper.getAyaSegment(sura, aya);
      if (surahAudio == null || segment == null) {
        if (mounted) {
          setState(() {
            _audioBusy = false;
            _playingItemId = null;
          });
        }
        // ফিক্স: ডাটাবেসে অডিও তথ্য না পাওয়া গেলেও আগে চুপচাপ থেমে
        // যেত। "সব শোনো" চলাকালীন এখন এই আয়াতটা স্কিপ করে পরেরটায়
        // যাওয়া হয়, যাতে একটা আয়াতের সমস্যায় পুরো সিকোয়েন্স না আটকায়।
        // mounted না হলেও (স্ক্রিন থেকে বের হয়ে গেলেও) এই সিদ্ধান্ত
        // নেওয়া হচ্ছে, যাতে ব্যাকগ্রাউন্ডে চেইন থেমে না যায়।
        if (chainNext && _sequencePlaying) {
          _playNextInSequence(item, groupPassStart: groupPassStart);
        } else if (mounted) {
          setState(() { _sequencePlaying = false; _sequencePaused = false; });
        }
        return;
      }
      await QuranAudioHelper.playAya(
        sura: sura,
        surahAudioUrl: surahAudio['audio_url'] as String,
        startMs: segment['timestamp_from_ms'] as int,
        endMs: segment['timestamp_to_ms'] as int,
        suraName: (_ayaCache[itemId]?['suraName'] as String?) ?? _suraNameFor(sura),
        ayaNumber: aya,
        onComplete: () {
          // ফিক্স: এটাই মূল বাগ ছিল — আগে এখানে "if (!mounted) return;"
          // থাকায় ব্যবহারকারী স্ক্রিন থেকে বেরিয়ে গেলে (back বাটনে চাপলে)
          // চলমান আয়াত শেষ হওয়ার পর আর কোনো পরের আয়াত/সূরা চলত না —
          // চেইন এখানেই নিঃশব্দে থেমে যেত, যদিও নোটিফিকেশন/মিনি-প্লেয়ার
          // তখনও চলমান দেখাত (বা কিছুই দেখাত না)। এখন mounted অবস্থা
          // নির্বিশেষে পরের আইটেমে যাওয়ার সিদ্ধান্ত নেওয়া হচ্ছে — শুধু
          // UI আপডেট (setState) mounted থাকলেই হয়।
          if (chainNext && _sequencePlaying) {
            _playNextInSequence(item, groupPassStart: groupPassStart);
          } else if (mounted) {
            setState(() {
              _playingItemId = null;
              _sequencePlaying = false;
              _sequencePaused = false;
              _currentRepeatIndex = 0;
            });
          }
        },
      );
    } catch (e) {
      // ফিক্স: এটাই মূল বাগ ছিল — নতুন সূরার অডিও ফাইল ডাউনলোড করতে
      // (network timeout, অসম্পূর্ণ ডাউনলোড ইত্যাদি) ব্যর্থ হলে এখান
      // থেকে exception ছুঁড়ত, কিন্তু আগে কোনো catch ব্লক ছিল না — শুধু
      // finally। ফলে exception silently গিলে ফেলা হতো (mounted অ্যাপে
      // অ্যাসিঙ্ক এরর ধরা না পড়লে ডিফল্টভাবে uncaught থেকে যায়), onComplete
      // কখনো কল হতো না, আর _sequencePlaying=true অবস্থাতেই প্লেব্যাক
      // থেমে যেত — এটাই "সূরা ফাতিহার পরে থেমে যাওয়া" সমস্যার কারণ,
      // কারণ Al-Baqara-র অডিও ফাইল তখনো ডাউনলোড করা ছিল না। এখন এই
      // exception ধরে "সব শোনো" মোডে থাকলে পরের আয়াতে move করা হয়,
      // যাতে একটা আয়াতের নেটওয়ার্ক সমস্যায় পুরো সিকোয়েন্স না থামে।
      debugPrint('COLLECTION PLAY ERROR (sura $sura, aya $aya): $e');
      if (chainNext && _sequencePlaying) {
        _playNextInSequence(item, groupPassStart: groupPassStart);
      } else if (mounted) {
        setState(() {
          _playingItemId = null;
          _sequencePlaying = false;
          _sequencePaused = false;
          _currentRepeatIndex = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _audioBusy = false);
    }
  }

  /// [justFinishedItem] শেষ হওয়ার পর পরবর্তী ধাপ ঠিক করে — তিনটা সম্ভাবনা:
  /// (১) এই আইটেমের নিজস্ব repeat_count এখনো বাকি থাকলে, একই আইটেম আবার
  ///     বাজে (_currentRepeatIndex বাড়িয়ে) — একক-আয়াত repeat (যেমন
  ///     আয়াতুল কুরসি ১০ বার) এভাবেই কাজ করে।
  /// (২) এই আইটেম কোনো গ্রুপের অংশ হলে ([groupPassStart] দেওয়া) এবং
  ///     গ্রুপের শেষ আয়াত না হলে, গ্রুপের পরের আয়াতে যায়।
  /// (৩) গ্রুপের শেষ আয়াত শেষ হলে, গ্রুপের repeat_count অনুযায়ী পুরো
  ///     গ্রুপটাই আবার শুরু থেকে বাজতে পারে (group-level repeat, যেমন
  ///     "সূরা ফাতিহা ৭ বার" মানে পুরো সূরা ৭ বার, প্রতিটা আয়াত একবার
  ///     করেই প্রতি পাসে)। সব রিপিট শেষ হলে বা এটা কোনো গ্রুপের অংশ না
  ///     হলে, কালেকশনের পরবর্তী আইটেমে (_items-এর ক্রম অনুযায়ী) যায়।
  /// mounted থাকলেই setState কল করে — ব্যাকগ্রাউন্ডে চেইন চলতে থাকা অবস্থায়
  /// (ব্যবহারকারী স্ক্রিন থেকে বেরিয়ে গেলে) UI স্টেট আপডেট করার দরকার নেই,
  /// কিন্তু unmounted অবস্থায় সরাসরি setState() কল করলে Flutter exception
  /// ছোঁড়ে — এই wrapper সেটা নিরাপদে এড়ায় প্লেব্যাক চেইন থামিয়ে না দিয়েই।
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _playNextInSequence(Map<String, dynamic> justFinishedItem, {int? groupPassStart}) {
    final justFinishedItemId = justFinishedItem['id'] as int;
    final repeatCount = (justFinishedItem['repeat_count'] as int?) ?? 1;

    if (groupPassStart == null && _currentRepeatIndex + 1 < repeatCount) {
      // একক আয়াতের নিজস্ব repeat বাকি আছে — একই আয়াত আবার।
      _currentRepeatIndex++;
      _safeSetState(() {});
      _playItem(justFinishedItem, chainNext: true);
      return;
    }

    if (groupPassStart != null) {
      final groupKey = justFinishedItem['group_key'] as String?;
      final currentIndex = _items.indexWhere((it) => it['id'] == justFinishedItemId);
      final hasNextInGroup = currentIndex >= 0 &&
          currentIndex + 1 < _items.length &&
          _items[currentIndex + 1]['group_key'] == groupKey;

      if (hasNextInGroup) {
        _playItem(_items[currentIndex + 1], chainNext: true, groupPassStart: groupPassStart);
        return;
      }

      // গ্রুপের শেষ আয়াত শেষ হলো — পুরো গ্রুপ আবার শুরু করতে হবে কিনা
      // দেখা হচ্ছে (group-level repeat)।
      if (_currentRepeatIndex + 1 < repeatCount) {
        _currentRepeatIndex++;
        _safeSetState(() {});
        final firstItem = _items.firstWhere((it) => it['id'] == groupPassStart, orElse: () => justFinishedItem);
        _playItem(firstItem, chainNext: true, groupPassStart: groupPassStart);
        return;
      }
    }

    // এই আইটেম/গ্রুপের সব রিপিট শেষ — কালেকশনের সরাসরি পরের আইটেমে যাওয়া।
    _currentRepeatIndex = 0;
    _safeSetState(() {});
    final currentIndex = _items.indexWhere((it) => it['id'] == justFinishedItemId);
    if (currentIndex < 0 || currentIndex + 1 >= _items.length) {
      // কালেকশনের শেষ আইটেম শেষ হয়ে গেছে।
      _playingItemId = null;
      _sequencePlaying = false;
      _sequencePaused = false;
      _safeSetState(() {});
      return;
    }
    final nextItem = _items[currentIndex + 1];
    final nextGroupKey = nextItem['group_key'] as String?;
    // পরের আইটেম যদি নতুন কোনো গ্রুপের প্রথম সদস্য হয়, সেটাকেও group-play
    // মোডে চালানো হচ্ছে, যাতে সেই গ্রুপের নিজস্ব repeat/pass ঠিকমতো কাজ করে।
    final nextIsGroupStart = nextGroupKey != null &&
        (currentIndex + 1 == 0 || _items[currentIndex]['group_key'] != nextGroupKey);
    _playItem(
      nextItem,
      chainNext: true,
      groupPassStart: nextGroupKey != null && nextIsGroupStart ? (nextItem['id'] as int) : null,
    );
  }

  /// AppBar-এর "সব শোনো" বাটন — কালেকশনের প্রথম আইটেম থেকে শুরু করে
  /// একটার পর একটা ক্রমান্বয়ে (sort_order অনুযায়ী) বাজায়। কোনো আইটেম
  /// কোনো গ্রুপের অংশ হলে সেই গ্রুপের repeat_count-ও প্রযোজ্য হয়।
  Future<void> _playAll() async {
    if (_items.isEmpty) return;
    // ফিক্স: আগে এই বাটনে চাপলে সবসময় QuranAudioHelper.stop() কল হতো,
    // যা প্লেয়ারকে সম্পূর্ণ থামিয়ে position মুছে দিত। ফলে অর্ধেক পর্যন্ত
    // শোনার পর এই বাটনে ভুলবশত চাপ পড়লে (বা ইচ্ছাকৃত থামালে) আবার চাপলে
    // একদম শুরু থেকে বাজত, মাঝখান থেকে resume হতো না। এখন যদি আগে থেকেই
    // চলমান থাকে (এই বাটন দিয়েই শুরু করা হয়েছিল, _sequencePlaying true),
    // তাহলে stop() না করে pause()/resume() ব্যবহার হচ্ছে — যা player-এর
    // বর্তমান অবস্থান অক্ষুণ্ণ রাখে, তাই আবার চাপলে ঠিক যেখানে ছিল
    // সেখান থেকেই চলতে থাকে।
    if (_sequencePlaying) {
      if (_sequencePaused) {
        setState(() => _sequencePaused = false);
        await QuranAudioHelper.resume();
      } else {
        setState(() => _sequencePaused = true);
        await QuranAudioHelper.pause();
      }
      return;
    }
    setState(() {
      _sequencePlaying = true;
      _sequencePaused = false;
      _currentRepeatIndex = 0;
    });
    final first = _items.first;
    final firstGroupKey = first['group_key'] as String?;
    await _playItem(
      first,
      chainNext: true,
      groupPassStart: firstGroupKey != null ? (first['id'] as int) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          // ফিক্স: কালেকশন/ফোল্ডার ভিউতে ফন্ট সাইজ ছোট-বড় করার কোনো
          // উপায় ছিল না (অন্য সূরা-পড়ার স্ক্রিনগুলোয় A-/A+ বাটন আছে,
          // কিন্তু এখানে ছিল না)। এখন সেই একই কন্ট্রোল এখানেও যোগ করা
          // হয়েছে, একই QuranPrefs.fontSize ব্যবহার করে — তাই এখানে
          // পাল্টালে অন্য কোরআন স্ক্রিনেও তা প্রতিফলিত হয় (এবং উল্টোটাও)।
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'A-',
            color: _fontSize > _minFontSize ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.4),
            onPressed: _fontSize > _minFontSize ? () => _changeFontSize(-2) : null,
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'A+',
            color: _fontSize < _maxFontSize ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.4),
            onPressed: _fontSize < _maxFontSize ? () => _changeFontSize(2) : null,
          ),
          // ফিক্স: কালেকশন/ফোল্ডার ভিউতে অডিও প্লেব্যাক স্পিড পাল্টানোর
          // কোনো উপায় ছিল না। এখানে যোগ করা QuranPrefs.playbackSpeed-ই
          // ব্যবহার করে, তাই "সব শোনো"/একক-আয়াত প্লে — দুই ক্ষেত্রেই এবং
          // অন্য কোরআন স্ক্রিনেও একই স্পিড প্রযোজ্য হয়।
          PopupMenuButton<double>(
            tooltip: isBn ? 'প্লেব্যাক স্পিড' : 'Playback speed',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: AppTheme.gold, size: 22),
                const SizedBox(width: 2),
                Text(
                  '${_playbackSpeed}x'.replaceAll('.0x', 'x'),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            color: AppTheme.cardBg,
            onSelected: _setSpeed,
            itemBuilder: (context) => _speedOptions.map((s) {
              final label = '${s}x'.replaceAll('.0x', 'x');
              return PopupMenuItem<double>(
                value: s,
                child: Text(
                  label,
                  style: TextStyle(
                    color: s == _playbackSpeed ? AppTheme.gold : AppTheme.textPrimary,
                    fontWeight: s == _playbackSpeed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_items.isNotEmpty)
            IconButton(
              icon: Icon(
                !_sequencePlaying
                    ? Icons.play_circle_outline
                    : (_sequencePaused ? Icons.play_circle_outline : Icons.pause_circle_outline),
              ),
              tooltip: !_sequencePlaying
                  ? (isBn ? 'সব শোনো' : 'Play All')
                  : (_sequencePaused ? (isBn ? 'আবার চালু করুন' : 'Resume') : (isBn ? 'পজ করুন' : 'Pause')),
              onPressed: _playAll,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isBn ? 'নাম পরিবর্তন' : 'Rename',
            onPressed: _renameCollection,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVerseSheet(),
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isBn
                          ? 'এখনো কোনো আয়াত যোগ করা হয়নি।\n+ বাটনে চেপে আয়াত বা সম্পূর্ণ সূরা যোগ করুন।'
                          : 'No verses added yet.\nTap + to add a verse or a full surah.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Builder(builder: (context) {
                  final groups = _buildDisplayGroups();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                    // +১ — সবার উপরে সূচিপত্র (TOC) কার্ডের জন্য একটা অতিরিক্ত স্লট।
                    itemCount: groups.length + 1,
                    itemBuilder: (context, listIndex) {
                      if (listIndex == 0) {
                        return _buildTocCard(isBn);
                      }
                      final entry = groups[listIndex - 1];
                      final entryItems = entry['items'] as List<Map<String, dynamic>>;
                      if (entry['type'] == 'group') {
                        final groupKey = entry['groupKey'] as String;
                        return KeyedSubtree(key: _groupKeyFor(groupKey), child: _buildGroupCard(entry, isBn));
                      }
                      final item = entryItems.first;
                      final index = _items.indexWhere((it) => it['id'] == item['id']);
                      return KeyedSubtree(key: _keyFor(item['id'] as int), child: _buildSingleItemCard(item, index, isBn));
                    },
                  );
                }),
    );
  }

  /// "সূচিপত্র" কার্ড — কালেকশনের একদম উপরে, ভাঁজ-করা (collapsed) অবস্থায়
  /// শুরু হয়, চাপলে খুলে সূরা-ভিত্তিক সংক্ষিপ্ত তালিকা দেখায় (যেমন "সূরা
  /// বাকারা: ১-৫, ১৬৩, ২৫৫-২৫৭, ২৮৪-২৮৬")। এটা ডাটাবেসে কিছু সংরক্ষণ করে
  /// না — প্রতিবার _items থেকে তাৎক্ষণিকভাবে হিসাব হয়, তাই সবসময় হালনাগাদ।
  Widget _buildTocCard(bool isBn) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: QuranCollectionsHelper.getTableOfContents(widget.collectionId),
      builder: (context, snapshot) {
        final toc = snapshot.data ?? [];
        if (toc.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              iconColor: AppTheme.gold,
              collapsedIconColor: AppTheme.gold,
              title: Row(
                children: [
                  const Icon(Icons.list_alt, color: AppTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isBn
                        ? 'সূচিপত্র (${widget.lang.toLocalNum(toc.length)} সূরা)'
                        : 'Table of contents (${toc.length} surahs)',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              children: [
                for (final entry in toc)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            _suraNameFor(entry['sura'] as int),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _localizeRangeText(entry['rangeText'] as String, isBn),
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _suraNameFor(int sura) {
    final chapter = _chapters.firstWhere((c) => c['sura'] == sura, orElse: () => {});
    return chapter['name_transliteration'] as String? ?? 'Surah $sura';
  }

  /// "1-5, 163, 255-257" — বাংলা মোডে থাকলে সংখ্যাগুলো বাংলা অঙ্কে,
  /// ইংরেজি মোডে অপরিবর্তিত রাখে।
  String _localizeRangeText(String rangeText, bool isBn) {
    if (!isBn) return rangeText;
    return rangeText.replaceAllMapped(RegExp(r'\d+'), (m) => widget.lang.toLocalNum(int.parse(m.group(0)!)));
  }

  /// একটা "গ্রুপ" কার্ড — সম্পূর্ণ সূরা বা একাধিক-আয়াত ব্লক একসাথে যোগ
  /// করার ফলাফল। আলাদা আলাদা আয়াত না দেখিয়ে একটাই কার্ডে সূরার নাম +
  /// আয়াত-রেঞ্জ + কতবার পড়া হবে তা সংক্ষেপে দেখায়; ট্যাপ করলে ভেতরের
  /// প্রতিটা আয়াত খুলে দেখা যায় (ExpansionTile)।
  Widget _buildGroupCard(Map<String, dynamic> entry, bool isBn) {
    final items = entry['items'] as List<Map<String, dynamic>>;
    final sura = entry['sura'] as int;
    final groupKey = entry['groupKey'] as String;
    final repeatCount = entry['repeatCount'] as int;
    final isFullSurah = _isFullSurahGroup(entry);
    final ayaNums = items.map((it) => it['aya'] as int).toList()..sort();
    final localRangeText = _localizeRangeText(_formatAyaRangesLocal(ayaNums), isBn);
    final isGroupPlaying = _playingItemId != null && items.any((it) => it['id'] == _playingItemId);
    final firstIndex = _items.indexWhere((it) => it['id'] == items.first['id']);
    final lastIndex = _items.indexWhere((it) => it['id'] == items.last['id']);

    return Container(
      key: ValueKey(groupKey),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isGroupPlaying ? AppTheme.gold.withOpacity(0.08) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGroupPlaying ? AppTheme.gold.withOpacity(0.6) : AppTheme.primary.withOpacity(0.25),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // ফিক্স: "সব শোনো" মোডে গ্রুপ কার্ড (যেমন পুরো সূরা) ডিফল্টভাবে
          // বন্ধ থাকত, তাই বাজতে থাকা আয়াতটা হাইলাইট হলেও তা দেখা যেত না
          // যতক্ষণ না ব্যবহারকারী নিজে ম্যানুয়ালি খুলতেন। এখন গ্রুপের
          // ভেতরের কোনো আয়াত বাজতে শুরু করলে (isGroupPlaying == true)
          // গ্রুপটা নিজে থেকেই খুলে যায়।
          initiallyExpanded: isGroupPlaying,
          key: ValueKey('${groupKey}_$isGroupPlaying'),
          tilePadding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          iconColor: AppTheme.textSecondary,
          collapsedIconColor: AppTheme.textSecondary,
          title: Row(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _togglePlayGroup(entry),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    isGroupPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
                    color: AppTheme.gold,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFullSurah
                          ? '${_suraNameFor(sura)} (${widget.lang.toLocalNum(items.length)})'
                          : '${_suraNameFor(sura)} • $localRangeText',
                      style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isBn ? '${widget.lang.toLocalNum(repeatCount)} বার পড়া হবে' : 'Repeats ${repeatCount}x',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showEditRepeatDialog(entry),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.repeat, color: AppTheme.textSecondary, size: 18),
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showAddVerseSheet(afterItemId: items.last['id'] as int),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 20),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                onPressed: () => _removeGroup(groupKey, items),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: firstIndex <= 0 ? null : () => _moveGroupUp(firstIndex, items.length),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: firstIndex <= 0 ? AppTheme.textSecondary.withOpacity(0.3) : AppTheme.gold,
                        size: 22,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: lastIndex >= _items.length - 1
                        ? null
                        : () => _moveGroupDown(firstIndex, items.length),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: lastIndex >= _items.length - 1
                            ? AppTheme.textSecondary.withOpacity(0.3)
                            : AppTheme.gold,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            for (final item in items) _buildInnerAyaText(item, isBn),
          ],
        ),
      ),
    );
  }

  /// গ্রুপ কার্ড খুললে ভেতরে দেখানো প্রতিটা আয়াতের টেক্সট — একক কার্ডের
  /// মতো প্লে/মুছা বাটন ছাড়া, শুধু পড়ার জন্য (গ্রুপ হিসেবেই manage হয়)।
  Widget _buildInnerAyaText(Map<String, dynamic> item, bool isBn) {
    final itemId = item['id'] as int;
    final aya = item['aya'] as int;
    final cached = _ayaCache[itemId] ?? {};
    final isPlayingThis = _playingItemId == itemId;
    return Container(
      key: _keyFor(itemId),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPlayingThis ? AppTheme.gold.withOpacity(0.06) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _togglePlayItem(item),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_outline,
                    color: AppTheme.gold,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${isBn ? "আয়াত" : "Verse"} ${widget.lang.toLocalNum(aya)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_showArabic) ...[
            const SizedBox(height: 6),
            Text(
              cached['arabic'] as String? ?? '',
              style: TextStyle(
                fontSize: _fontSize * 0.85,
                color: AppTheme.textPrimary,
                fontFamily: 'ScheherazadeNew',
                height: 2.0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
          if (_showBangla && (cached['bangla'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cached['bangla'] as String,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  /// একক আয়াতের কার্ড (আগের মতোই), সাথে repeat_count > 1 হলে একটা
  /// ছোট "N বার" ব্যাজও দেখায় (যেমন আয়াতুল কুরসি ১০ বার সেট করা থাকলে)।
  Widget _buildSingleItemCard(Map<String, dynamic> item, int index, bool isBn) {
    if ((item['item_type'] as String? ?? 'aya') == 'custom') {
      return _buildCustomAudioCard(item, index, isBn);
    }
    final itemId = item['id'] as int;
    final aya = item['aya'] as int;
    final cached = _ayaCache[itemId] ?? {};
    final isPlayingThis = _playingItemId == itemId;
    final repeatCount = (item['repeat_count'] as int?) ?? 1;

    return Container(
      key: ValueKey(itemId),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPlayingThis ? AppTheme.gold.withOpacity(0.08) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlayingThis ? AppTheme.gold.withOpacity(0.6) : AppTheme.primary.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ফিক্স: আগে কালেকশনের কোনো আয়াতই শোনার কোনো
              // উপায় ছিল না — এখানে প্রতিটা আইটেমের সাথে
              // একটা প্লে/পজ বাটন যোগ করা হলো।
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _togglePlayItem(item),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_outline,
                    color: AppTheme.gold,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${cached['suraName'] ?? ''} • ${isBn ? "আয়াত" : "Verse"} ${widget.lang.toLocalNum(aya)}',
                        style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (repeatCount > 1) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showEditRepeatDialog({
                          'groupKey': item['group_key'],
                          'repeatCount': repeatCount,
                          'items': [item],
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isBn ? '${widget.lang.toLocalNum(repeatCount)}× ' : '${repeatCount}x',
                            style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // এই আয়াতের ঠিক পরে নতুন আয়াত যোগ করার শর্টকাট —
              // যেমন ৯ নং আয়াতের কার্ডে চাপলে ১০ নং অবস্থানে
              // (৯ এর পরে, আগের ১০ নং যা ছিল তার আগে) বসবে।
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showAddVerseSheet(afterItemId: itemId),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                onPressed: () => _removeItem(itemId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 14),
              // ফিক্স: আগে ড্র্যাগ-করে সরানোর (ReorderableListView)
              // ব্যবস্থা ছিল, কিন্তু বিভিন্ন ডিভাইসে/জেসচারে এটা
              // অনির্ভরযোগ্য প্রমাণিত হয়েছে — ড্র্যাগ প্রায়ই শুরুই
              // হতো না বা মাঝপথে বাতিল হয়ে যেত। তার বদলে এখন
              // সাধারণ ⬆ ⬇ বাটন।
              // ফিক্স: InkWell-কে সরাসরি Container-এর ভেতরে
              // (কোনো Material widget ছাড়া) বসানো হয়েছিল —
              // InkWell সবসময় Material widget-এর descendant
              // হতে হয়, নাহলে splash/hit-test ঠিকভাবে কাজ
              // করে না। এখানে পুরো কার্ডের জন্যই কোনো Material
              // ছিল না, ফলে বাটনে ট্যাপ করলেও কিছুই ঘটছিল না।
              // এখন GestureDetector + সরাসরি hitTestBehavior
              // ব্যবহার করা হলো, যেটা Material-নির্ভর নয় এবং
              // যেকোনো widget-tree-তে নির্ভরযোগ্যভাবে কাজ করে।
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: index == 0 ? null : () => _moveUp(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: index == 0 ? AppTheme.textSecondary.withOpacity(0.3) : AppTheme.gold,
                        size: 24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: index == _items.length - 1 ? null : () => _moveDown(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: index == _items.length - 1
                            ? AppTheme.textSecondary.withOpacity(0.3)
                            : AppTheme.gold,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_showArabic) ...[
            const SizedBox(height: 10),
            Text(
              cached['arabic'] as String? ?? '',
              style: TextStyle(
                fontSize: _fontSize,
                color: AppTheme.textPrimary,
                fontFamily: 'ScheherazadeNew',
                height: 2.0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
          if (_showBangla && (cached['bangla'] as String? ?? '').isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 20),
            Text(
              cached['bangla'] as String,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.6),
            ),
          ],
          if (_showTransliteration && (cached['translit'] as String? ?? '').isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 20),
            Text(
              cached['translit'] as String,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "নিজের দোয়া/অডিও" আইটেমের কার্ড — আয়াতের মতো আরবি/বাংলা টেক্সট নেই
  /// (শুধু নাম + প্লে), কিন্তু প্লে/মুছা/আগে-পরে সরানো/এখানে নতুন আইটেম
  /// যোগ করার সব বাটন একই আচরণ বজায় রাখে, যাতে ব্যবহারকারীর অভিজ্ঞতা
  /// সূরার আয়াত কার্ডের সাথে সামঞ্জস্যপূর্ণ থাকে।
  Widget _buildCustomAudioCard(Map<String, dynamic> item, int index, bool isBn) {
    final itemId = item['id'] as int;
    final title = item['custom_title'] as String? ?? (isBn ? 'কাস্টম অডিও' : 'Custom audio');
    final isPlayingThis = _playingItemId == itemId;
    final repeatCount = (item['repeat_count'] as int?) ?? 1;

    return Container(
      key: ValueKey(itemId),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPlayingThis ? AppTheme.gold.withOpacity(0.08) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlayingThis ? AppTheme.gold.withOpacity(0.6) : AppTheme.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _togglePlayItem(item),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_outline,
                color: AppTheme.gold,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.mic_none, color: AppTheme.gold, size: 15),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppTheme.gold, fontSize: 12.5, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (repeatCount > 1) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showEditRepeatDialog({
                      'groupKey': item['group_key'],
                      'repeatCount': repeatCount,
                      'items': [item],
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isBn ? '${widget.lang.toLocalNum(repeatCount)}× ' : '${repeatCount}x',
                        style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showAddVerseSheet(afterItemId: itemId),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
            onPressed: () => _removeItem(itemId),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: index == 0 ? null : () => _moveUp(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: index == 0 ? AppTheme.textSecondary.withOpacity(0.3) : AppTheme.gold,
                    size: 24,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: index == _items.length - 1 ? null : () => _moveDown(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: index == _items.length - 1
                        ? AppTheme.textSecondary.withOpacity(0.3)
                        : AppTheme.gold,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "কতবার পড়া হবে" স্টেপারের ছোট গোলাকার +/− বাটন — reusable, disabled
/// অবস্থায় ধূসর দেখায় (repeatCount সীমা 1-99 এ পৌঁছালে)।
class _RepeatStepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _RepeatStepperButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppTheme.gold.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          border: Border.all(color: enabled ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.4)),
      ),
    );
  }
}
