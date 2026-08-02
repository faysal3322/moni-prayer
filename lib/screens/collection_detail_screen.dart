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
  double _fontSize = 24.0;

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
      _items = items;
      _chapters = chapters;
      _ayaCache = cache;
      _showArabic = showArabic;
      _showBangla = showBangla;
      _showTransliteration = showTranslit;
      _fontSize = fontSize;
      _loading = false;
    });
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

  /// ফিক্স: আগে + বাটনে শুধু একটা নির্দিষ্ট আয়াত যোগ করা যেত, সম্পূর্ণ
  /// সূরা যোগ করার কোনো উপায় ছিল না। এখন শিটের উপরে দুটো মোড আছে —
  /// "নির্দিষ্ট আয়াত" ও "সম্পূর্ণ সূরা", ব্যবহারকারী যেকোনো একটা বেছে
  /// নিয়ে ব্যবহার করতে পারবে।
  void _showAddVerseSheet() {
    final isBn = widget.lang.isBn;
    bool fullSurahMode = false;
    Map<String, dynamic>? selectedChapter;
    final ayaController = TextEditingController();
    String? errorText;
    bool submitting = false;

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

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
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
                    TextField(
                      controller: ayaController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: isBn ? 'আয়াত নম্বর' : 'Verse Number',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
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

                              if (fullSurahMode) {
                                setSheetState(() => submitting = true);
                                await QuranCollectionsHelper.addFullSurah(widget.collectionId, sura, maxAya);
                                if (context.mounted) Navigator.pop(sheetContext);
                                _load();
                                return;
                              }

                              final ayaNum = int.tryParse(ayaController.text.trim());
                              if (ayaNum == null || ayaNum < 1) {
                                setSheetState(() => errorText = isBn ? 'সঠিক আয়াত নম্বর দিন' : 'Enter a valid verse number');
                                return;
                              }
                              if (ayaNum > maxAya) {
                                setSheetState(() => errorText = isBn
                                    ? 'এই সূরায় সর্বোচ্চ ${widget.lang.toLocalNum(maxAya)} আয়াত আছে'
                                    : 'This surah has only $maxAya verses');
                                return;
                              }
                              await QuranCollectionsHelper.addItem(widget.collectionId, sura, ayaNum);
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

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
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
        onPressed: _showAddVerseSheet,
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
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  itemCount: _items.length,
                  onReorder: _onReorder,
                  // ডিফল্ট হ্যান্ডেল বন্ধ — এটা চালু থাকলে পুরো কার্ডের (আরবি টেক্সট
                  // সহ) যেকোনো জায়গা থেকে ড্র্যাগ শুরু হতে পারত, যেটা টেক্সট
                  // সিলেকশন/স্ক্রল জেসচারের সাথে সংঘর্ষ করে ড্র্যাগ মাঝপথে বাতিল
                  // করে দিত এবং আইটেম আগের জায়গায় ফিরে যেত। এখন শুধু নিচের
                  // drag_handle আইকন থেকেই ড্র্যাগ শুরু করা যাবে।
                  buildDefaultDragHandles: false,
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
                              IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                                onPressed: () => _removeItem(itemId),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.drag_handle, color: AppTheme.textSecondary, size: 20),
                                ),
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
