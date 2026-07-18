import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import 'surah_detail_screen.dart';
import 'quran_settings_screen.dart';

class QuranScreen extends StatefulWidget {
  final AppLanguage lang;
  const QuranScreen({super.key, required this.lang});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
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

  // বাংলায় সূরার বাংলা নাম এখনো ডাটাবেজে নেই বলে transliteration নাম দেখানো হচ্ছে।
  // বাংলা অনুবাদ যোগ হলে এখানে বাংলা নাম বসানো হবে।

  String _typeLabel(String? type, bool isBn) {
    if (type == 'Meccan') return isBn ? 'মক্কী' : 'Meccan';
    if (type == 'Medinan') return isBn ? 'মাদানী' : 'Medinan';
    return type ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'কোরআন' : 'Quran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: isBn ? 'কোরআন সেটিংস' : 'Quran Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => QuranSettingsScreen(lang: widget.lang),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // সার্চ বার
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
                                      builder: (_) => SurahDetailScreen(lang: widget.lang, sura: suraNum),
                                    ));
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
