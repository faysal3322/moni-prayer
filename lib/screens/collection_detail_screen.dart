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
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.gold.withOpacity(0.15),
                            child: Text(
                              lang.toLocalNum(sura),
                              style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(color: AppTheme.textPrimary)),
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
  bool _audioBusy = false; // ডাউনলোড/লোড হওয়ার সময় ডাবল-ট্যাপ ঠেকাতে
  double _playbackSpeed = 1.0;
  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _title = widget.collectionName;
    _load();
  }

  @override
  void dispose() {
    // স্ক্রিন থেকে বেরিয়ে গেলে কালেকশনের অডিও থামিয়ে দেওয়া হচ্ছে — সূরা
    // পড়ার স্ক্রিনের ব্যাকগ্রাউন্ড-প্লেব্যাকের বিপরীতে, কালেকশনের প্লেব্যাক
    // এখানেই সীমাবদ্ধ, তাই persistent ব্যানার এই স্বল্প ক্লিপগুলোর জন্য
    // অপ্রয়োজনীয়ভাবে থেকে যাওয়ার দরকার নেই।
    if (_playingItemId != null) {
      QuranAudioHelper.stop();
    }
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
  }

  Future<void> _changeFontSize(double delta) async {
    final newSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize);
    if (newSize == _fontSize) return;
    setState(() => _fontSize = newSize);
    await QuranPrefs.setFontSize(newSize);
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
    Map<String, dynamic>? selectedChapter;
    final ayaController = TextEditingController();
    String? errorText;
    bool submitting = false;

    // পজিশন নির্বাচন — শুধু কোনো নির্দিষ্ট আয়াতের কার্ড থেকে না এসে
    // FAB থেকে খোলা হলে এবং কালেকশনে অন্তত একটা আয়াত থাকলেই দেখানো হয়।
    final bool showPositionPicker = afterItemId == null && _items.isNotEmpty;
    // insertAfterId == null মানে "তালিকার শেষে" যোগ হবে।
    int? insertAfterId = afterItemId;

    String positionLabel(int? itemId) {
      if (itemId == null) {
        return isBn ? 'তালিকার শেষে' : 'At the end';
      }
      final cached = _ayaCache[itemId];
      final item = _items.firstWhere((it) => it['id'] == itemId, orElse: () => {});
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
                  // মোড নির্বাচন — নির্দিষ্ট আয়াত বনাম সম্পূর্ণ সূরা
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
                              errorText = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: !fullSurahMode ? AppTheme.gold : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isBn ? 'নির্দিষ্ট আয়াত' : 'Single Verse',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !fullSurahMode ? Colors.black : AppTheme.textSecondary,
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
                              errorText = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: fullSurahMode ? AppTheme.gold : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isBn ? 'সম্পূর্ণ সূরা' : 'Full Surah',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: fullSurahMode ? Colors.black : AppTheme.textSecondary,
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
                                  );
                                } else {
                                  await QuranCollectionsHelper.addFullSurah(widget.collectionId, sura, maxAya);
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
                                );
                              } else if (ayaNums.length == 1) {
                                await QuranCollectionsHelper.addItem(widget.collectionId, sura, ayaNums.first);
                              } else {
                                await QuranCollectionsHelper.insertMultipleAyasAfter(
                                  widget.collectionId,
                                  sura,
                                  ayaNums,
                                  afterItemId: null,
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
                              fullSurahMode
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

  Future<void> _removeItem(int itemId) async {
    if (_playingItemId == itemId) {
      await QuranAudioHelper.stop();
      setState(() {
        _playingItemId = null;
        _sequencePlaying = false;
      });
    }
    await QuranCollectionsHelper.removeItem(itemId);
    _load();
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
        });
      }
      return;
    }
    await _playItem(item, chainNext: false);
  }

  Future<void> _playItem(Map<String, dynamic> item, {required bool chainNext}) async {
    if (_audioBusy) return;
    final sura = item['sura'] as int;
    final aya = item['aya'] as int;
    final itemId = item['id'] as int;

    setState(() {
      _audioBusy = true;
      _playingItemId = itemId;
    });

    try {
      final surahAudio = await QuranDatabaseHelper.getSurahAudio(sura);
      final segment = await QuranDatabaseHelper.getAyaSegment(sura, aya);
      if (surahAudio == null || segment == null) {
        if (mounted) {
          setState(() {
            _audioBusy = false;
            _playingItemId = null;
          });
          // ফিক্স: ডাটাবেসে অডিও তথ্য না পাওয়া গেলেও আগে চুপচাপ থেমে
          // যেত। "সব শোনো" চলাকালীন এখন এই আয়াতটা স্কিপ করে পরেরটায়
          // যাওয়া হয়, যাতে একটা আয়াতের সমস্যায় পুরো সিকোয়েন্স না আটকায়।
          if (chainNext && _sequencePlaying) {
            _playNextInSequence(itemId);
          } else {
            setState(() => _sequencePlaying = false);
          }
        }
        return;
      }
      await QuranAudioHelper.playAya(
        sura: sura,
        surahAudioUrl: surahAudio['audio_url'] as String,
        startMs: segment['timestamp_from_ms'] as int,
        endMs: segment['timestamp_to_ms'] as int,
        onComplete: () {
          if (!mounted) return;
          if (chainNext && _sequencePlaying) {
            _playNextInSequence(itemId);
          } else {
            setState(() {
              _playingItemId = null;
              _sequencePlaying = false;
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
      if (mounted) {
        if (chainNext && _sequencePlaying) {
          _playNextInSequence(itemId);
        } else {
          setState(() {
            _playingItemId = null;
            _sequencePlaying = false;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _audioBusy = false);
    }
  }

  void _playNextInSequence(int justFinishedItemId) {
    final currentIndex = _items.indexWhere((it) => it['id'] == justFinishedItemId);
    if (currentIndex < 0 || currentIndex + 1 >= _items.length) {
      // কালেকশনের শেষ আইটেম শেষ হয়ে গেছে।
      setState(() {
        _playingItemId = null;
        _sequencePlaying = false;
      });
      return;
    }
    _playItem(_items[currentIndex + 1], chainNext: true);
  }

  /// AppBar-এর "সব শোনো" বাটন — কালেকশনের প্রথম আইটেম থেকে শুরু করে
  /// একটার পর একটা ক্রমান্বয়ে (sort_order অনুযায়ী) বাজায়।
  Future<void> _playAll() async {
    if (_items.isEmpty) return;
    if (_sequencePlaying) {
      await QuranAudioHelper.stop();
      setState(() {
        _playingItemId = null;
        _sequencePlaying = false;
      });
      return;
    }
    setState(() => _sequencePlaying = true);
    await _playItem(_items.first, chainNext: true);
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
              icon: Icon(_sequencePlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline),
              tooltip: isBn ? 'সব শোনো' : 'Play All',
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
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final itemId = item['id'] as int;
                    final sura = item['sura'] as int;
                    final aya = item['aya'] as int;
                    final cached = _ayaCache[itemId] ?? {};
                    final isPlayingThis = _playingItemId == itemId;

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
                                child: Text(
                                  '${cached['suraName'] ?? ''} • ${isBn ? "আয়াত" : "Verse"} ${widget.lang.toLocalNum(aya)}',
                                  style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600),
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
                  },
                ),
    );
  }
}
