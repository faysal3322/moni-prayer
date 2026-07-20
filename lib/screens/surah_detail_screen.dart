import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import '../utils/quran_prefs.dart';
import '../utils/quran_audio_helper.dart';
import '../utils/quran_bookmarks_helper.dart';
import 'quran_settings_screen.dart';

class SurahDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int sura;
  const SurahDetailScreen({super.key, required this.lang, required this.sura});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> with WidgetsBindingObserver {
  static const int _totalSurahs = 114;
  late PageController _pageController;
  late int _currentSura;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentSura = widget.sura;
    _pageController = PageController(initialPage: _currentSura - 1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuranSettingsScreen(lang: widget.lang),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lang.isBn ? 'কোরআন' : 'Quran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: widget.lang.isBn ? 'কোরআন সেটিংস' : 'Quran Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _totalSurahs,
        onPageChanged: (index) {
          setState(() => _currentSura = index + 1);
        },
        itemBuilder: (context, index) {
          final suraNumber = index + 1;
          return _SurahPage(lang: widget.lang, sura: suraNumber);
        },
      ),
    );
  }
}

/// একটা নির্দিষ্ট সূরার আয়াতসমূহ দেখানোর জন্য পৃথক widget।
/// PageView-এর প্রতিটি পেজ এই widget-এর একটি instance, যা lazy-load হয়।
class _SurahPage extends StatefulWidget {
  final AppLanguage lang;
  final int sura;
  const _SurahPage({required this.lang, required this.sura});

  @override
  State<_SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<_SurahPage> with WidgetsBindingObserver {
  Map<String, dynamic>? _chapter;
  List<Map<String, dynamic>> _ayat = [];
  List<Map<String, dynamic>> _transliteration = [];
  List<Map<String, dynamic>> _bangla = [];
  bool _loading = true;
  String _error = '';

  bool _showArabic = true;
  bool _showBangla = false;
  bool _showTransliteration = true;
  double _fontSize = 24.0;
  String _viewMode = 'list';

  bool _fullSurahLoading = false;
  bool _fullSurahPlaying = false;
  int? _fullSurahAyaIndex;

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
    if (_fullSurahPlaying) QuranAudioHelper.stop();
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
    final viewMode = await QuranPrefs.getViewMode();
    if (!mounted) return;
    setState(() {
      _showArabic = arabic;
      _showBangla = bangla;
      _showTransliteration = translit;
      _fontSize = fontSize;
      _viewMode = viewMode;
    });
  }

  Future<void> _setViewMode(String mode) async {
    setState(() => _viewMode = mode);
    await QuranPrefs.setViewMode(mode);
  }

  static const double _minFontSize = 18.0;
  static const double _maxFontSize = 40.0;

  Future<void> _changeFontSize(double delta) async {
    final newSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize);
    if (newSize == _fontSize) return;
    setState(() => _fontSize = newSize);
    await QuranPrefs.setFontSize(newSize);
  }

  Future<void> _load() async {
    try {
      final chapter = await QuranDatabaseHelper.getChapter(widget.sura);
      final ayat = await QuranDatabaseHelper.getAyatUthmani(widget.sura);
      final translit = await QuranDatabaseHelper.getAyatTransliteration(widget.sura);
      final bangla = await QuranDatabaseHelper.getAyatBangla(widget.sura);
      await _loadPrefs();
      if (!mounted) return;
      setState(() {
        _chapter = chapter;
        _ayat = ayat;
        _transliteration = translit;
        _bangla = bangla;
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

  /// Repeatedly tries Scrollable.ensureVisible on the target aya's GlobalKey,
  /// retrying for up to ~3s. This is more reliable than a single fixed delay
  /// because it keeps checking until the widget's context is actually laid out
  /// (list/page rebuilds after closing the bottom sheet can take a variable
  /// number of frames, especially for long surahs).
  ///
  /// In list mode, a non-lazy ListView builds every _AyaCard up front, but for
  /// long surahs that first layout pass can take longer than the old fixed
  /// retry budget, so the GlobalKey's context was still null when we gave up
  /// and the jump silently did nothing. As a fallback, once we run out of
  /// attempts we jump to an estimated scroll offset based on the item's index.
  void _scrollToVerse(int ayaIndex, {int attemptsLeft = 30}) {
    if (!mounted) return;
    if (ayaIndex < 0 || ayaIndex >= _ayaKeys.length) return;
    final ctx = _ayaKeys[ayaIndex].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
      return;
    }
    if (attemptsLeft <= 0) {
      _scrollToVerseFallback(ayaIndex);
      return;
    }
    // Context not ready yet (widget not laid out on screen) — retry next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToVerse(ayaIndex, attemptsLeft: attemptsLeft - 1);
      });
    });
  }

  /// Best-effort scroll when the target GlobalKey never got a context
  /// (e.g. very long surah still building off-screen items). Estimates an
  /// offset from the item's position among all verses so the jump still
  /// moves the user close to the right verse instead of doing nothing.
  void _scrollToVerseFallback(int ayaIndex) {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (_ayat.isEmpty || maxExtent <= 0) return;
    final estimated = (ayaIndex / _ayat.length) * maxExtent;
    _scrollController.animateTo(
      estimated.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    // After the estimated jump, the target card is likely close to visible,
    // so its context should now exist — try one more precise pass.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        final ctx = _ayaKeys[ayaIndex].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.05,
          );
        }
      });
    });
  }

  Future<void> _toggleFullSurahPlay() async {
    if (_fullSurahPlaying) {
      await QuranAudioHelper.stop();
      if (mounted) {
        setState(() {
          _fullSurahPlaying = false;
          _fullSurahAyaIndex = null;
        });
      }
      return;
    }

    if (_fullSurahLoading || _ayat.isEmpty) return;
    setState(() => _fullSurahLoading = true);
    try {
      final surahAudio = await QuranDatabaseHelper.getSurahAudio(widget.sura);
      final segments = await QuranDatabaseHelper.getAllSegmentsForSura(widget.sura);
      if (surahAudio == null || segments.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.lang.isBn ? 'অডিও পাওয়া যায়নি' : 'Audio not available')),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() => _fullSurahPlaying = true);
      await QuranAudioHelper.playFullSurah(
        sura: widget.sura,
        surahAudioUrl: surahAudio['audio_url'] as String,
        segments: segments,
        onAyaStart: (ayaIndex, ayaNumber) {
          if (!mounted) return;
          setState(() => _fullSurahAyaIndex = ayaIndex);
          _scrollToVerse(ayaIndex);
        },
        onSequenceComplete: () {
          if (!mounted) return;
          setState(() {
            _fullSurahPlaying = false;
            _fullSurahAyaIndex = null;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lang.isBn ? 'ডাউনলোড ব্যর্থ হয়েছে' : 'Download failed')),
        );
        setState(() => _fullSurahPlaying = false);
      }
    } finally {
      if (mounted) setState(() => _fullSurahLoading = false);
    }
  }

  void _jumpToVerse(int ayaIndex) {
    Navigator.of(context).pop(); // close the bottom sheet
    // Wait for the bottom sheet's close animation to finish, then retry-scroll
    // until the target verse's context becomes available.
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollToVerse(ayaIndex);
    });
  }

  void _showVerseJumpSheet() {
    final isBn = widget.lang.isBn;
    final nameTranslit = _chapter?['name_transliteration'] as String? ?? '';
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
                    nameTranslit,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // আয়াত নম্বর সার্চ বক্স — নম্বর টাইপ করলে সরাসরি সেই আয়াতে যাওয়া যাবে
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: searchController,
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
                          } else if (q == null) {
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

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    final nameTranslit = _chapter?['name_transliteration'] as String? ?? '';
    // সূরা ৯ (আত-তাওবা) ছাড়া প্রতি সূরার শুরুতে বিসমিল্লাহ দেখানো হয় (সূরা ১-এ প্রথম আয়াতই বিসমিল্লাহ, তাই আলাদা দেখানো হচ্ছে না)
    final showBismillah = widget.sura != 1 && widget.sura != 9 && _showArabic;
    final noLanguageOn = !_showArabic && !_showBangla && !_showTransliteration;

    return Column(
      children: [
        // সূরার নাম + আয়াত জাম্প বাটন + সম্পূর্ণ সূরা প্লে/স্টপ, প্রতিটি পেজের ওপরে
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: AppTheme.cardBg,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InkWell(
                onTap: _ayat.isNotEmpty ? _showVerseJumpSheet : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nameTranslit.isNotEmpty ? nameTranslit : (isBn ? 'কোরআন' : 'Quran'),
                        style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_ayat.isNotEmpty) const Icon(Icons.arrow_drop_down, size: 20, color: AppTheme.gold),
                    ],
                  ),
                ),
              ),
              if (_ayat.isNotEmpty)
                Positioned(
                  right: 4,
                  child: IconButton(
                    icon: _fullSurahLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                          )
                        : Icon(
                            _fullSurahPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                            color: AppTheme.gold,
                            size: 26,
                          ),
                    tooltip: _fullSurahPlaying
                        ? (isBn ? 'থামান' : 'Stop')
                        : (isBn ? 'সম্পূর্ণ সূরা শুনুন' : 'Play full surah'),
                    onPressed: _toggleFullSurahPlay,
                  ),
                ),
            ],
          ),
        ),
        // Page / List ভিউ টগল + ফন্ট সাইজ +/- বাটন
        if (_ayat.isNotEmpty)
          Container(
            width: double.infinity,
            color: AppTheme.cardBg,
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewModeButton(
                        icon: Icons.description_outlined,
                        label: isBn ? 'পেজ' : 'Page',
                        selected: _viewMode == 'page',
                        onTap: () => _setViewMode('page'),
                      ),
                      _ViewModeButton(
                        icon: Icons.view_list_outlined,
                        label: isBn ? 'লিস্ট' : 'List',
                        selected: _viewMode == 'list',
                        onTap: () => _setViewMode('list'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _FontSizeControls(
                  onDecrease: () => _changeFontSize(-2),
                  onIncrease: () => _changeFontSize(2),
                  canDecrease: _fontSize > _minFontSize,
                  canIncrease: _fontSize < _maxFontSize,
                ),
              ],
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
                      : _viewMode == 'page'
                          ? _MushafPageView(
                              scrollController: _scrollController,
                              nameArabic: _chapter?['name_arabic'] as String? ?? '',
                              ayat: _ayat,
                              ayaKeys: _ayaKeys,
                              showBismillah: showBismillah,
                              fontSize: _fontSize,
                              lang: widget.lang,
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
                                sura: widget.sura,
                                ayaNumber: _ayat[i]['aya'] as int,
                                arabicText: _ayat[i]['text'] as String? ?? '',
                                transliterationText: i < _transliteration.length
                                    ? (_transliteration[i]['text'] as String? ?? '')
                                    : '',
                                banglaText: i < _bangla.length
                                    ? (_bangla[i]['text'] as String? ?? '')
                                    : '',
                                lang: widget.lang,
                                showArabic: _showArabic,
                                showBangla: _showBangla,
                                showTransliteration: _showTransliteration,
                                fontSize: _fontSize,
                                onWillPlay: _fullSurahPlaying
                                    ? () => setState(() {
                                          _fullSurahPlaying = false;
                                          _fullSurahAyaIndex = null;
                                        })
                                    : null,
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
        ),
      ],
    );
  }
}

/// রিডিং পেজেই সরাসরি ফন্ট সাইজ বাড়ানো/কমানোর জন্য +/- বাটন —
/// সেটিংসে না গিয়ে তাৎক্ষণিক পরিবর্তনের জন্য।
class _FontSizeControls extends StatelessWidget {
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool canDecrease;
  final bool canIncrease;

  const _FontSizeControls({
    required this.onDecrease,
    required this.onIncrease,
    required this.canDecrease,
    required this.canIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            color: canDecrease ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.4),
            onPressed: canDecrease ? onDecrease : null,
            tooltip: 'A-',
            splashRadius: 18,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
          const Text(
            'A',
            style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            color: canIncrease ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.4),
            onPressed: canIncrease ? onIncrease : null,
            tooltip: 'A+',
            splashRadius: 18,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppTheme.gold : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.gold : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// মুসহাফ-স্টাইল পৃষ্ঠা ভিউ — একটানা প্রবাহিত আরবি টেক্সট, প্রতিটি আয়াতের শেষে
/// ছোট গোল নাম্বার মার্কার। শুধু আরবি দেখায় (বাংলা/উচ্চারণ এই মোডে থাকে না)।
class _MushafPageView extends StatelessWidget {
  final ScrollController scrollController;
  final String nameArabic;
  final List<Map<String, dynamic>> ayat;
  final List<GlobalKey> ayaKeys;
  final bool showBismillah;
  final double fontSize;
  final AppLanguage lang;

  const _MushafPageView({
    required this.scrollController,
    required this.nameArabic,
    required this.ayat,
    required this.ayaKeys,
    required this.showBismillah,
    required this.fontSize,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.gold.withOpacity(0.35), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // সূরার নাম ফ্রেমে
            if (nameArabic.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  nameArabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 22,
                    color: AppTheme.gold,
                    fontFamily: 'ScheherazadeNew',
                  ),
                ),
              ),
            if (showBismillah)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: AppTheme.gold,
                    fontFamily: 'ScheherazadeNew',
                    height: 1.8,
                  ),
                ),
              ),
            // একটানা প্রবাহিত আয়াত টেক্সট, প্রতিটির শেষে ইনলাইন নাম্বার মার্কার
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text.rich(
                TextSpan(
                  children: [
                    for (int i = 0; i < ayat.length; i++) ...[
                      TextSpan(
                        text: '${ayat[i]['text'] as String? ?? ''} ',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: AppTheme.textPrimary,
                          fontFamily: 'ScheherazadeNew',
                          height: 2.2,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            key: ayaKeys.length > i ? ayaKeys[i] : null,
                            width: fontSize * 1.1,
                            height: fontSize * 1.1,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.gold.withOpacity(0.7), width: 1.2),
                            ),
                            child: Text(
                              lang.toLocalNum(ayat[i]['aya'] as int),
                              style: TextStyle(
                                color: AppTheme.gold,
                                fontSize: fontSize * 0.48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' '),
                    ],
                  ],
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyaCard extends StatefulWidget {
  final int sura;
  final int ayaNumber;
  final String arabicText;
  final String transliterationText;
  final String banglaText;
  final AppLanguage lang;
  final bool showArabic;
  final bool showBangla;
  final bool showTransliteration;
  final double fontSize;
  /// Called right before this card starts playing its own audio, so the
  /// parent screen can stop a full-surah playback session if one is running
  /// (avoids two audio sessions fighting over the same player).
  final VoidCallback? onWillPlay;

  const _AyaCard({
    super.key,
    required this.sura,
    required this.ayaNumber,
    required this.arabicText,
    required this.transliterationText,
    required this.banglaText,
    required this.lang,
    required this.showArabic,
    required this.showBangla,
    required this.showTransliteration,
    required this.fontSize,
    this.onWillPlay,
  });

  @override
  State<_AyaCard> createState() => _AyaCardState();
}

class _AyaCardState extends State<_AyaCard> {
  bool _expanded = false;
  bool _loadingAudio = false;
  bool _playing = false;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final marked = await QuranBookmarksHelper.isBookmarked(widget.sura, widget.ayaNumber);
    if (mounted) setState(() => _bookmarked = marked);
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarked) {
      await QuranBookmarksHelper.removeBookmark(widget.sura, widget.ayaNumber);
    } else {
      await QuranBookmarksHelper.addBookmark(widget.sura, widget.ayaNumber);
    }
    if (mounted) setState(() => _bookmarked = !_bookmarked);
  }

  Future<void> _playAudio() async {
    if (_loadingAudio) return;
    widget.onWillPlay?.call();
    setState(() {
      _loadingAudio = true;
      _playing = false;
    });
    try {
      final surahAudio = await QuranDatabaseHelper.getSurahAudio(widget.sura);
      final segment = await QuranDatabaseHelper.getAyaSegment(widget.sura, widget.ayaNumber);
      if (surahAudio == null || segment == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.lang.isBn ? 'অডিও পাওয়া যায়নি' : 'Audio not available')),
          );
        }
        return;
      }
      setState(() => _playing = true);
      await QuranAudioHelper.playAya(
        sura: widget.sura,
        surahAudioUrl: surahAudio['audio_url'] as String,
        startMs: segment['timestamp_from_ms'] as int,
        endMs: segment['timestamp_to_ms'] as int,
        onComplete: () {
          if (mounted) setState(() => _playing = false);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lang.isBn ? 'ডাউনলোড ব্যর্থ হয়েছে' : 'Download failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  Future<void> _stopAudio() async {
    await QuranAudioHelper.stop();
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded ? AppTheme.gold.withOpacity(0.6) : AppTheme.primary.withOpacity(0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_expanded)
                  Row(
                    children: [
                      IconButton(
                        icon: _loadingAudio
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                              )
                            : Icon(
                                _playing ? Icons.stop_circle : Icons.play_circle_fill,
                                color: AppTheme.gold,
                                size: 28,
                              ),
                        onPressed: _playing ? _stopAudio : _playAudio,
                        tooltip: isBn ? 'আয়াত শুনুন' : 'Play verse',
                      ),
                      IconButton(
                        icon: Icon(
                          _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _bookmarked ? AppTheme.gold : AppTheme.textSecondary,
                        ),
                        onPressed: _toggleBookmark,
                        tooltip: isBn ? 'বুকমার্ক করুন' : 'Bookmark',
                      ),
                    ],
                  )
                else
                  const SizedBox(),
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
                widget.banglaText.isNotEmpty
                    ? widget.banglaText
                    : (isBn ? 'এই আয়াতের অনুবাদ পাওয়া যায়নি' : 'Translation not available for this verse'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
            if (widget.showTransliteration && widget.transliterationText.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 20),
              Text(
                widget.transliterationText,
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
      ),
    );
  }
}
