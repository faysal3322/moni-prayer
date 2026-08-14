import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import '../utils/quran_prefs.dart';

/// "বাংলা কোরআন" — কোরআন সেকশনের ৪র্থ ট্যাব।
/// এই ট্যাবের একমাত্র উদ্দেশ্য: ব্যবহারকারী যেন শুধুমাত্র বাংলা অনুবাদ
/// নির্বিঘ্নে পড়তে পারে — এখানে আরবি টেক্সট, উচ্চারণ (transliteration),
/// অডিও প্লেয়ার, বা অন্য কোনো নিয়ন্ত্রণ নেই, যাতে পড়ার অভিজ্ঞতা একদম
/// পরিষ্কার ও বিভ্রান্তিহীন থাকে।
///
/// এই ফাইলটা সম্পূর্ণ স্বয়ংসম্পূর্ণ এবং read-only — এটা কোনো বিদ্যমান
/// prefs (QuranPrefs), কালেকশন, বুকমার্ক, বা অডিও স্টেট স্পর্শ করে না,
/// এবং কোনো ডাটাবেস স্কিমা পরিবর্তন করে না। বাংলা অনুবাদের ডেটা
/// QuranDatabaseHelper.getAyatBangla() থেকে আসে, যা ইতিমধ্যেই বান্ডিল করা
/// quran.sqlite-এর quran_bn_muhiuddinkhan টেবিল থেকে পড়ে (অ্যাপে আগে
/// থেকেই বিদ্যমান, সম্পূর্ণ ৬২৩৬ আয়াতের বাংলা অনুবাদ)।

// ═══════════════════════════════════════════
// বাংলা কোরআন ট্যাব — ১১৪টা সূরার তালিকা (সূরা ট্যাবের মতোই, কিন্তু
// ট্যাপ করলে বাংলা-শুধু ডিটেইল স্ক্রিনে যায়)
// ═══════════════════════════════════════════
class BanglaQuranTab extends StatefulWidget {
  final AppLanguage lang;
  const BanglaQuranTab({super.key, required this.lang});

  @override
  State<BanglaQuranTab> createState() => _BanglaQuranTabState();
}

class _BanglaQuranTabState extends State<BanglaQuranTab> {
  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();
  // "সূরা" ট্যাব ও "বাংলা কোরআন" ট্যাব এখন সম্পূর্ণ আলাদা last-read key
  // ব্যবহার করে (QuranPrefs.getBanglaLastRead()) — একজন আরবি তেলাওয়াত
  // এক জায়গা পর্যন্ত পড়তে পারেন, বাংলা অনুবাদ অন্য জায়গা পর্যন্ত; দুটো
  // একে অপরকে ওভাররাইট করবে না।
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _loadLastRead();
  }

  /// এই ট্যাব আবার visible/rebuild হলে (যেমন আয়াত পড়ে ফিরে এলে) সর্বশেষ
  /// পঠিত অবস্থান নতুন করে লোড করা হয়, যাতে কার্ডটা আপ-টু-ডেট থাকে।
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final lastRead = await QuranPrefs.getBanglaLastRead();
    if (lastRead == null || !mounted) {
      if (mounted) setState(() => _lastRead = null);
      return;
    }
    final chapter = await QuranDatabaseHelper.getChapter(lastRead['sura']!);
    if (!mounted) return;
    setState(() {
      _lastRead = {
        'sura': lastRead['sura'],
        'aya': lastRead['aya'],
        'name': chapter?['name_transliteration'] ?? '',
        'nameArabic': chapter?['name_arabic'] ?? '',
      };
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await QuranDatabaseHelper.getChapters();
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _filtered = chapters;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filtered = _chapters;
      } else {
        final q = query.trim().toLowerCase();
        _filtered = _chapters.where((c) {
          final translit = (c['name_transliteration'] as String? ?? '').toLowerCase();
          final suraNum = (c['sura'] ?? '').toString();
          return translit.contains(q) || suraNum == q;
        }).toList();
      }
    });
  }

  String _typeLabel(String? type, bool isBn) {
    if (type == 'Meccan') return isBn ? 'মক্কী' : 'Meccan';
    if (type == 'Medinan') return isBn ? 'মাদানী' : 'Medinan';
    return type ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: isBn ? 'সূরা খুঁজুন...' : 'Search Surah...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accent),
              ),
            ),
          ),
        ),
        // "সর্বশেষ পঠিত অবস্থান" কার্ড — সার্চ চলাকালীন (যখন তালিকা
        // ফিল্টার করা থাকে) দেখানো হয় না, শুধু পুরো সূরা তালিকা দেখা
        // অবস্থায় সবার উপরে দেখানো হয়। সূরা ট্যাবের কার্ডের মতোই দেখতে।
        if (_lastRead != null && _searchController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BanglaSurahDetailScreen(
                    lang: widget.lang,
                    sura: _lastRead!['sura'] as int,
                    suraNameTranslit: _lastRead!['name'] as String? ?? '',
                    suraNameArabic: _lastRead!['nameArabic'] as String? ?? '',
                    jumpToAyaNumber: _lastRead!['aya'] as int,
                  ),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark, color: AppTheme.gold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'সর্বশেষ পঠিত অবস্থান' : 'Last read position',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_lastRead!['name']} (${widget.lang.toLocalNum(_lastRead!['aya'] as int)})',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _lastRead!['nameArabic'] as String? ?? '',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 20,
                        fontFamily: 'ScheherazadeNew',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
              : _error.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          isBn
                              ? 'কোরআন ডাটাবেজ লোড করা যায়নি।\n$_error'
                              : 'Could not load Quran database.\n$_error',
                          style: const TextStyle(color: AppTheme.missed, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            isBn ? 'কোনো সূরা পাওয়া যায়নি' : 'No surah found',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final c = _filtered[index];
                            final suraNum = c['sura'] as int;
                            final nameArabic = c['name_arabic'] as String? ?? '';
                            final nameTranslit = c['name_transliteration'] as String? ?? '';
                            final ayasCount = c['ayas_count'] as int? ?? 0;
                            final type = c['type'] as String?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.gold.withOpacity(0.6)),
                                  ),
                                  child: Text(
                                    widget.lang.toLocalNum(suraNum),
                                    style: const TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  nameTranslit,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_typeLabel(type, isBn)} • ${widget.lang.toLocalNum(ayasCount)} ${isBn ? "আয়াত" : "verses"}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                trailing: Text(
                                  nameArabic,
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 22,
                                    fontFamily: 'ScheherazadeNew',
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => BanglaSurahDetailScreen(
                                      lang: widget.lang,
                                      sura: suraNum,
                                      suraNameTranslit: nameTranslit,
                                      suraNameArabic: nameArabic,
                                    ),
                                  ));
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// বাংলা সূরা ডিটেইল স্ক্রিন — শুধুমাত্র বাংলা অনুবাদ, আয়াত নম্বরসহ।
// এখানে ইচ্ছাকৃতভাবে আরবি, উচ্চারণ, অডিও, বা কোনো টগল/সেটিংস নেই —
// শুধু পরিষ্কার পড়ার অভিজ্ঞতা।
// ═══════════════════════════════════════════
class BanglaSurahDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int sura;
  final String suraNameTranslit;
  final String suraNameArabic;
  /// দেওয়া থাকলে, এই সূরার পেজ খোলার পর সরাসরি এই আয়াতে স্ক্রল করে দেখায় —
  /// "সর্বশেষ পঠিত অবস্থান" কার্ডে চাপলে ব্যবহৃত হয়।
  final int? jumpToAyaNumber;
  const BanglaSurahDetailScreen({
    super.key,
    required this.lang,
    required this.sura,
    required this.suraNameTranslit,
    required this.suraNameArabic,
    this.jumpToAyaNumber,
  });

  @override
  State<BanglaSurahDetailScreen> createState() => _BanglaSurahDetailScreenState();
}

class _BanglaSurahDetailScreenState extends State<BanglaSurahDetailScreen> {
  List<Map<String, dynamic>> _ayat = [];
  bool _loading = true;
  String _error = '';
  double _fontSize = 17.0;

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _ayaKeys = [];
  // ফিক্স: আগে dispose()-এর সময় সরাসরি _ayaKeys[i].currentContext পড়ে
  // "এখন কোন আয়াত দেখা যাচ্ছে" বের করা হতো। কিন্তু dispose() কল হওয়ার
  // মুহূর্তে widget tree ইতিমধ্যে unmount হতে শুরু করে দেয়, ফলে প্রায়
  // সবসময়ই প্রতিটা GlobalKey-র currentContext আগেভাগেই null হয়ে
  // যাচ্ছিল — লুপ কোনো ম্যাচ না পেয়ে bestIndex ??= 0 এ পড়ে যেত, এবং
  // সবসময় ১ নম্বর আয়াতই "সর্বশেষ পঠিত" হিসেবে সেভ হতো, আসলে যতদূর পড়া
  // হয়েছিল তা নির্বিশেষে। এখন স্ক্রল থামার সময়েই (যখন widget tree পুরো
  // জীবিত ও দৃশ্যমান) বর্তমান ইনডেক্স এই ভ্যারিয়েবলে ক্যাশ করে রাখা হয়,
  // আর dispose()-এ GlobalKey আবার না পড়ে সরাসরি এই ক্যাশ করা মান
  // ব্যবহার করা হয় — dispose-টাইমিং সমস্যা সম্পূর্ণ এড়িয়ে যায়।
  int? _lastKnownVisibleIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // স্ক্রিন থেকে বের হওয়ার সময়ও একবার সর্বশেষ পঠিত অবস্থান সেভ করা
    // হচ্ছে (ইনস্ট্যান্ট, বিলম্ব ছাড়া) — কিন্তু GlobalKey recompute না
    // করে, বরং সর্বশেষ scroll-idle এ যা ক্যাশ হয়েছিল সেটাই ব্যবহার
    // করে (দেখুন _lastKnownVisibleIndex-এর কমেন্ট)। "সূরা" ট্যাব ও
    // "বাংলা কোরআন" ট্যাব এখন সম্পূর্ণ আলাদা last-read key ব্যবহার করে,
    // তাই একটায় পড়া অন্যটার সর্বশেষ অবস্থান পাল্টায় না।
    _saveCurrentPositionAsLastRead();
    _scrollController.dispose();
    super.dispose();
  }

  /// বর্তমানে স্ক্রিনের উপরের দিকে দৃশ্যমান প্রথম আয়াতের ইনডেক্স খুঁজে
  /// _lastKnownVisibleIndex-এ ক্যাশ করে রাখে। স্ক্রল থামলে (idle) কল করা
  /// হয়, যখন widget tree এখনো পুরোপুরি জীবিত — তাই এখানে GlobalKey পড়া
  /// নির্ভরযোগ্য।
  void _updateLastKnownVisibleIndex() {
    if (_ayat.isEmpty) return;
    int? bestIndex;
    double bestDy = double.infinity;
    for (var i = 0; i < _ayaKeys.length; i++) {
      final ctx = _ayaKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy >= -50 && dy < bestDy) {
        bestDy = dy;
        bestIndex = i;
      }
    }
    if (bestIndex != null) {
      _lastKnownVisibleIndex = bestIndex;
    }
  }

  /// ক্যাশ করা ইনডেক্স (_lastKnownVisibleIndex) অনুযায়ী "সর্বশেষ পঠিত
  /// অবস্থান" QuranPrefs-এ সেভ করে। কোনো ক্যাশ এখনো তৈরি না হয়ে থাকলে
  /// (যেমন ব্যবহারকারী একদম না স্ক্রল করেই সাথে সাথে বের হয়ে গেলে)
  /// প্রথম আয়াতটাকেই "সর্বশেষ পঠিত" হিসেবে ধরা হয়, যাতে অন্তত এই
  /// সূরার শুরুটা সংরক্ষিত থাকে।
  void _saveCurrentPositionAsLastRead() {
    if (_ayat.isEmpty) return;
    final index = (_lastKnownVisibleIndex ?? 0).clamp(0, _ayat.length - 1);
    final ayaNumber = _ayat[index]['aya'] as int?;
    if (ayaNumber != null) {
      QuranPrefs.setBanglaLastRead(widget.sura, ayaNumber);
    }
  }

  Future<void> _load() async {
    try {
      final ayat = await QuranDatabaseHelper.getAyatBangla(widget.sura);
      // ফিক্স: আগে ফন্ট সাইজ শুধু এই widget-এর in-memory state-এ থাকত
      // (সবসময় 17.0 দিয়ে শুরু হতো), QuranPrefs-এ সেভ/লোড হতো না — ফলে
      // ব্যবহারকারী নিজের পছন্দমতো ফন্ট সাইজ সেট করলেও পরের বার এই
      // স্ক্রিনে ঢুকলে বা অ্যাপ পুনরায় চালু করলে সেটা মনে থাকত না। এখন
      // QuranPrefs.getBanglaQuranFontSize() থেকে সর্বশেষ সংরক্ষিত মান
      // লোড করা হচ্ছে।
      final savedFontSize = await QuranPrefs.getBanglaQuranFontSize();
      if (!mounted) return;
      setState(() {
        _ayat = ayat;
        _ayaKeys.clear();
        _ayaKeys.addAll(List.generate(ayat.length, (_) => GlobalKey()));
        _fontSize = savedFontSize;
        _loading = false;
      });
      if (widget.jumpToAyaNumber != null) {
        final targetIndex = _ayat.indexWhere((a) => a['aya'] == widget.jumpToAyaNumber);
        if (targetIndex >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              _scrollToVerse(targetIndex, attemptsLeft: 8);
            });
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// [ayaIndex] নম্বর আয়াতের কার্ডে স্ক্রল করে নিয়ে যায় — কার্ডটা এখনো
  /// লে-আউট হয়ে না থাকলে (GlobalKey-র context null) কয়েকবার রিট্রাই করে।
  void _scrollToVerse(int ayaIndex, {int attemptsLeft = 5}) {
    if (!mounted) return;
    if (ayaIndex < 0 || ayaIndex >= _ayaKeys.length) return;
    final ctx = _ayaKeys[ayaIndex].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: 0.25,
      );
      return;
    }
    if (attemptsLeft <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _scrollToVerse(ayaIndex, attemptsLeft: attemptsLeft - 1);
      });
    });
  }

  void _jumpToVerse(int ayaIndex) {
    Navigator.of(context).pop(); // জাম্প শিট বন্ধ করা হচ্ছে
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _scrollToVerse(ayaIndex, attemptsLeft: 15);
    });
  }

  /// আয়াত নম্বর লিখে সরাসরি সেই আয়াতে যাওয়ার bottom sheet — সূরা ডিটেইল
  /// স্ক্রিনের "জাম্প" শিটের মতোই আচরণ করে।
  void _showVerseJumpSheet() {
    final isBn = widget.lang.isBn;
    final searchController = TextEditingController();
    final ValueNotifier<String> searchQuery = ValueNotifier('');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.suraNameTranslit,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: isBn ? 'আয়াত নম্বর লিখুন...' : 'Enter verse number...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.accent),
                      ),
                    ),
                    onChanged: (value) => searchQuery.value = value.trim(),
                    onSubmitted: (value) {
                      final num = int.tryParse(value.trim());
                      if (num != null) {
                        final index = _ayat.indexWhere((a) => (a['aya'] as int) == num);
                        if (index != -1) {
                          _jumpToVerse(index);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: searchQuery,
                    builder: (context, query, _) {
                      final filteredIndices = <int>[];
                      if (query.isEmpty) {
                        filteredIndices.addAll(List.generate(_ayat.length, (i) => i));
                      } else {
                        final q = int.tryParse(query);
                        for (int i = 0; i < _ayat.length; i++) {
                          final ayaNum = _ayat[i]['aya'] as int;
                          if (q != null && ayaNum.toString().startsWith(query)) {
                            filteredIndices.add(i);
                          }
                        }
                      }

                      if (filteredIndices.isEmpty) {
                        return Center(
                          child: Text(
                            isBn ? 'কোনো আয়াত পাওয়া যায়নি' : 'No verse found',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: filteredIndices.length,
                        itemBuilder: (context, listIndex) {
                          final index = filteredIndices[listIndex];
                          final ayaNum = _ayat[index]['aya'] as int;
                          return ListTile(
                            dense: true,
                            title: Text(
                              isBn ? 'আয়াত $ayaNum' : 'Verse $ayaNum',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            ),
                            onTap: () => _jumpToVerse(index),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      searchController.dispose();
      searchQuery.dispose();
    });
  }

  void _changeFontSize(double delta) {
    final newSize = (_fontSize + delta).clamp(13.0, 28.0);
    if (newSize == _fontSize) return;
    setState(() => _fontSize = newSize);
    // ফিক্স: এখন পরিবর্তিত ফন্ট সাইজ সাথে সাথে QuranPrefs-এ সেভ হয়, যাতে
    // ব্যবহারকারী যেভাবে সেট করে রাখবে অ্যাপ পরের বার সেভাবেই মনে রাখে।
    QuranPrefs.setBanglaQuranFontSize(newSize);
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    // সূরা ফাতিহা ও সূরা তওবা ছাড়া প্রতিটা সূরার শুরুতে বিসমিল্লাহ দেখানো
    // হয় — কোরআনের প্রচলিত রীতি অনুসরণ করে (সূরা ফাতিহাতেই বিসমিল্লাহ
    // প্রথম আয়াত হিসেবে আসবে, তাই আলাদা করে দেখানোর দরকার নেই; সূরা
    // তওবায় বিসমিল্লাহ থাকে না)।
    final showBismillah = widget.sura != 1 && widget.sura != 9;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.lang.toLocalNum(widget.sura)}) ${widget.suraNameTranslit}'),
            Text(
              widget.suraNameArabic,
              style: const TextStyle(fontFamily: 'ScheherazadeNew', fontSize: 14, color: AppTheme.gold),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: isBn ? 'আয়াতে যান' : 'Jump to verse',
            onPressed: _loading ? null : _showVerseJumpSheet,
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: isBn ? 'ফন্ট ছোট করুন' : 'Decrease font size',
            onPressed: () => _changeFontSize(-1),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: isBn ? 'ফন্ট বড় করুন' : 'Increase font size',
            onPressed: () => _changeFontSize(1),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isBn
                          ? 'আয়াত লোড করা যায়নি।\n$_error'
                          : 'Could not load verses.\n$_error',
                      style: const TextStyle(color: AppTheme.missed, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : NotificationListener<UserScrollNotification>(
                  // ফিক্স: শুধু স্ক্রিন থেকে বের হওয়ার সময় (dispose) না,
                  // বরং স্ক্রল থামার সাথে সাথেই "সর্বশেষ পঠিত অবস্থান"
                  // আপডেট করা হচ্ছে — সূরা ডিটেইল স্ক্রিনের একই আচরণ,
                  // যাতে ব্যবহারকারী অ্যাপ থেকে হুট করে (back বাটন, হোম
                  // বাটন, বা অন্য অ্যাপে চলে গিয়ে) বের হয়ে গেলেও সর্বশেষ
                  // অবস্থান দ্রুত সংরক্ষিত থাকে। এখানে widget tree এখনো
                  // জীবিত, তাই আগে ক্যাশ রিফ্রেশ করে তারপর সেভ করা হয়।
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.idle) {
                      _updateLastKnownVisibleIndex();
                      _saveCurrentPositionAsLastRead();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                    itemCount: _ayat.length + (showBismillah ? 1 : 0),
                    itemBuilder: (context, listIndex) {
                      if (showBismillah && listIndex == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            isBn
                                ? 'শুরু করছি আল্লাহর নামে যিনি পরম করুণাময়, অতি দয়ালু।'
                                : 'In the name of Allah, the Most Gracious, the Most Merciful.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      final index = showBismillah ? listIndex - 1 : listIndex;
                      final row = _ayat[index];
                      return Container(
                        key: _ayaKeys[index],
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '(${widget.lang.toLocalNum(row['aya'] as int)}) ',
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: row['text'] as String? ?? '',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: _fontSize,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
