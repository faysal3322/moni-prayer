import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import '../utils/quran_prefs.dart';

class SurahDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int sura;
  const SurahDetailScreen({super.key, required this.lang, required this.sura});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _chapter;
  List<Map<String, dynamic>> _ayat = [];
  List<Map<String, dynamic>> _transliteration = [];
  bool _loading = true;
  String _error = '';

  bool _showArabic = true;
  bool _showBangla = false;
  bool _showTransliteration = true;
  double _fontSize = 24.0;

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _ayaKeys = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPrefs();
    }
  }

  Future<void> _loadPrefs() async {
    final arabic = await QuranPrefs.getShowArabic();
    final bangla = await QuranPrefs.getShowBangla();
    final translit = await QuranPrefs.getShowTransliteration();
    final fontSize = await QuranPrefs.getFontSize();
    if (!mounted) return;
    setState(() {
      _showArabic = arabic;
      _showBangla = bangla;
      _showTransliteration = translit;
      _fontSize = fontSize;
    });
  }

  Future<void> _load() async {
    try {
      final chapter = await QuranDatabaseHelper.getChapter(widget.sura);
      final ayat = await QuranDatabaseHelper.getAyatUthmani(widget.sura);
      final translit = await QuranDatabaseHelper.getAyatTransliteration(widget.sura);
      await _loadPrefs();
      if (!mounted) return;
      setState(() {
        _chapter = chapter;
        _ayat = ayat;
        _transliteration = translit;
        _ayaKeys.clear();
        _ayaKeys.addAll(List.generate(ayat.length, (_) => GlobalKey()));
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

  void _jumpToVerse(int ayaIndex) {
    Navigator.of(context).pop(); // close the bottom sheet
    Future.delayed(const Duration(milliseconds: 200), () {
      if (ayaIndex < 0 || ayaIndex >= _ayaKeys.length) return;
      final ctx = _ayaKeys[ayaIndex].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  void _showVerseJumpSheet() {
    final isBn = widget.lang.isBn;
    final nameTranslit = _chapter?['name_transliteration'] as String? ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
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
                    nameTranslit,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _ayat.length,
                    itemBuilder: (context, index) {
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
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    final nameTranslit = _chapter?['name_transliteration'] as String? ?? '';
    // সূরা ৯ (আত-তাওবা) ছাড়া প্রতি সূরার শুরুতে বিসমিল্লাহ দেখানো হয় (সূরা ১-এ প্রথম আয়াতই বিসমিল্লাহ, তাই আলাদা দেখানো হচ্ছে না)
    final showBismillah = widget.sura != 1 && widget.sura != 9 && _showArabic;
    final noLanguageOn = !_showArabic && !_showBangla && !_showTransliteration;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _ayat.isNotEmpty ? _showVerseJumpSheet : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  nameTranslit.isNotEmpty ? nameTranslit : (isBn ? 'কোরআন' : 'Quran'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_ayat.isNotEmpty) const Icon(Icons.arrow_drop_down, size: 22),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isBn ? 'আয়াত লোড করা যায়নি।\n$_error' : 'Could not load verses.\n$_error',
                      style: const TextStyle(color: AppTheme.missed, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : noLanguageOn
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          isBn
                              ? 'কোনো ভাষা চালু নেই। কোরআন সেটিংস থেকে অন্তত একটি ভাষা চালু করুন।'
                              : 'No language is enabled. Turn on at least one in Quran Settings.',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(14),
                      children: [
                        if (showBismillah)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                              style: TextStyle(
                                fontSize: _fontSize + 2,
                                color: AppTheme.gold,
                                fontFamily: 'ScheherazadeNew',
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        for (int i = 0; i < _ayat.length; i++)
                          _AyaCard(
                            key: _ayaKeys[i],
                            ayaNumber: _ayat[i]['aya'] as int,
                            arabicText: _ayat[i]['text'] as String? ?? '',
                            transliterationText: i < _transliteration.length
                                ? (_transliteration[i]['text'] as String? ?? '')
                                : '',
                            lang: widget.lang,
                            showArabic: _showArabic,
                            showBangla: _showBangla,
                            showTransliteration: _showTransliteration,
                            fontSize: _fontSize,
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
    );
  }
}

class _AyaCard extends StatelessWidget {
  final int ayaNumber;
  final String arabicText;
  final String transliterationText;
  final AppLanguage lang;
  final bool showArabic;
  final bool showBangla;
  final bool showTransliteration;
  final double fontSize;

  const _AyaCard({
    super.key,
    required this.ayaNumber,
    required this.arabicText,
    required this.transliterationText,
    required this.lang,
    required this.showArabic,
    required this.showBangla,
    required this.showTransliteration,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold.withOpacity(0.6)),
                ),
                child: Text(
                  lang.toLocalNum(ayaNumber),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (showArabic) ...[
            const SizedBox(height: 10),
            Text(
              arabicText,
              style: TextStyle(
                fontSize: fontSize,
                color: AppTheme.textPrimary,
                fontFamily: 'ScheherazadeNew',
                height: 2.0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
          if (showBangla) ...[
            const Divider(color: Colors.white12, height: 20),
            Text(
              isBn ? 'বাংলা অনুবাদ শীঘ্রই যুক্ত হবে' : 'Bangla translation coming soon',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (showTransliteration && transliterationText.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 20),
            Text(
              transliterationText,
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
}
