import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import '../utils/quran_prefs.dart';

class JuzDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int juzNumber;
  const JuzDetailScreen({super.key, required this.lang, required this.juzNumber});

  @override
  State<JuzDetailScreen> createState() => _JuzDetailScreenState();
}

class _JuzDetailScreenState extends State<JuzDetailScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _ayat = [];
  Map<int, String> _suraNames = {};
  bool _loading = true;
  String _error = '';

  bool _showArabic = true;
  bool _showBangla = false;
  bool _showTransliteration = true;
  double _fontSize = 24.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      final ayat = await QuranDatabaseHelper.getAyatForJuz(widget.juzNumber);
      final chapters = await QuranDatabaseHelper.getChapters();
      await _loadPrefs();
      if (!mounted) return;
      setState(() {
        _ayat = ayat;
        _suraNames = {
          for (final c in chapters) (c['sura'] as int): (c['name_transliteration'] as String? ?? ''),
        };
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

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    final noLanguageOn = !_showArabic && !_showBangla && !_showTransliteration;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'পারা ${widget.juzNumber}' : 'Juz ${widget.juzNumber}'),
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _ayat.length,
                      itemBuilder: (context, index) {
                        final row = _ayat[index];
                        final sura = row['sura'] as int;
                        final aya = row['aya'] as int;
                        final isNewSura = index == 0 || (_ayat[index - 1]['sura'] as int) != sura;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isNewSura)
                              Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _suraNames[sura] ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ),
                            _JuzAyaCard(
                              ayaNumber: aya,
                              arabicText: row['text'] as String? ?? '',
                              lang: widget.lang,
                              showArabic: _showArabic,
                              showBangla: _showBangla,
                              showTransliteration: _showTransliteration,
                              fontSize: _fontSize,
                              sura: sura,
                            ),
                          ],
                        );
                      },
                    ),
    );
  }
}

/// একটা আয়াত কার্ড, juz ভিউয়ের জন্য — বাংলা/উচ্চারণ সরাসরি ডাটাবেজ থেকে on-demand আনা হয়
/// (surah_detail_screen-এর মতো পুরো সূরার লিস্ট প্রি-লোড করার বদলে, কারণ juz একাধিক সূরা জুড়ে)
class _JuzAyaCard extends StatefulWidget {
  final int ayaNumber;
  final String arabicText;
  final AppLanguage lang;
  final bool showArabic;
  final bool showBangla;
  final bool showTransliteration;
  final double fontSize;
  final int sura;

  const _JuzAyaCard({
    required this.ayaNumber,
    required this.arabicText,
    required this.lang,
    required this.showArabic,
    required this.showBangla,
    required this.showTransliteration,
    required this.fontSize,
    required this.sura,
  });

  @override
  State<_JuzAyaCard> createState() => _JuzAyaCardState();
}

class _JuzAyaCardState extends State<_JuzAyaCard> {
  String? _bangla;
  String? _translit;
  bool _fetched = false;

  @override
  void didUpdateWidget(covariant _JuzAyaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBangla != widget.showBangla || oldWidget.showTransliteration != widget.showTransliteration) {
      _fetched = false;
      _maybeFetch();
    }
  }

  @override
  void initState() {
    super.initState();
    _maybeFetch();
  }

  Future<void> _maybeFetch() async {
    if (_fetched) return;
    if (widget.showBangla) {
      final row = await QuranDatabaseHelper.getSingleAyaBangla(widget.sura, widget.ayaNumber);
      if (mounted) setState(() => _bangla = row?['text'] as String?);
    }
    if (widget.showTransliteration) {
      final row = await QuranDatabaseHelper.getSingleAyaTransliteration(widget.sura, widget.ayaNumber);
      if (mounted) setState(() => _translit = row?['text'] as String?);
    }
    _fetched = true;
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold.withOpacity(0.6)),
                ),
                child: Text(
                  widget.lang.toLocalNum(widget.ayaNumber),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (widget.showArabic) ...[
            const SizedBox(height: 10),
            Text(
              widget.arabicText,
              style: TextStyle(
                fontSize: widget.fontSize,
                color: AppTheme.textPrimary,
                fontFamily: 'ScheherazadeNew',
                height: 2.0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
          if (widget.showBangla) ...[
            const Divider(color: Colors.white12, height: 20),
            Text(
              _bangla?.isNotEmpty == true
                  ? _bangla!
                  : (isBn ? 'এই আয়াতের অনুবাদ পাওয়া যায়নি' : 'Translation not available for this verse'),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.6),
            ),
          ],
          if (widget.showTransliteration && _translit?.isNotEmpty == true) ...[
            const Divider(color: Colors.white12, height: 20),
            Text(
              _translit!,
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
