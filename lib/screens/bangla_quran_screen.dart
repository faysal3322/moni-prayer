import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadChapters();
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
  const BanglaSurahDetailScreen({
    super.key,
    required this.lang,
    required this.sura,
    required this.suraNameTranslit,
    required this.suraNameArabic,
  });

  @override
  State<BanglaSurahDetailScreen> createState() => _BanglaSurahDetailScreenState();
}

class _BanglaSurahDetailScreenState extends State<BanglaSurahDetailScreen> {
  List<Map<String, dynamic>> _ayat = [];
  bool _loading = true;
  String _error = '';
  double _fontSize = 17.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ayat = await QuranDatabaseHelper.getAyatBangla(widget.sura);
      if (!mounted) return;
      setState(() {
        _ayat = ayat;
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

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(13.0, 28.0);
    });
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                  children: [
                    if (showBismillah)
                      Padding(
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
                      ),
                    for (final row in _ayat)
                      Container(
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
                      ),
                  ],
                ),
    );
  }
}
