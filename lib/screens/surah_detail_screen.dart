import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';

class SurahDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int sura;
  const SurahDetailScreen({super.key, required this.lang, required this.sura});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  Map<String, dynamic>? _chapter;
  List<Map<String, dynamic>> _ayat = [];
  List<Map<String, dynamic>> _transliteration = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final chapter = await QuranDatabaseHelper.getChapter(widget.sura);
      final ayat = await QuranDatabaseHelper.getAyatUthmani(widget.sura);
      final translit = await QuranDatabaseHelper.getAyatTransliteration(widget.sura);
      if (!mounted) return;
      setState(() {
        _chapter = chapter;
        _ayat = ayat;
        _transliteration = translit;
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
    final nameTranslit = _chapter?['name_transliteration'] as String? ?? '';
    // সূরা ৯ (আত-তাওবা) ছাড়া প্রতি সূরার শুরুতে বিসমিল্লাহ দেখানো হয় (সূরা ১-এ প্রথম আয়াতই বিসমিল্লাহ, তাই আলাদা দেখানো হচ্ছে না)
    final showBismillah = widget.sura != 1 && widget.sura != 9;

    return Scaffold(
      appBar: AppBar(
        title: Text(nameTranslit.isNotEmpty ? nameTranslit : (isBn ? 'কোরআন' : 'Quran')),
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
              : ListView(
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
                        child: const Text(
                          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          style: TextStyle(
                            fontSize: 26,
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
                        ayaNumber: _ayat[i]['aya'] as int,
                        arabicText: _ayat[i]['text'] as String? ?? '',
                        transliterationText: i < _transliteration.length
                            ? (_transliteration[i]['text'] as String? ?? '')
                            : '',
                        lang: widget.lang,
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

  const _AyaCard({
    required this.ayaNumber,
    required this.arabicText,
    required this.transliterationText,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 10),
          Text(
            arabicText,
            style: const TextStyle(
              fontSize: 24,
              color: AppTheme.textPrimary,
              fontFamily: 'ScheherazadeNew',
              height: 2.0,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (transliterationText.isNotEmpty) ...[
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
