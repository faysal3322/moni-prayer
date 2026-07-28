import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  // যখন একটা সূরার সম্পূর্ণ-সূরা প্লেব্যাক শেষ হয়ে পরের সূরায় chain করা
  // দরকার হয়, সেই টার্গেট সূরা নম্বর এখানে রাখা হয় যাতে PageView-এর
  // itemBuilder সেই নির্দিষ্ট পেজেই autoPlayOnStart: true পাঠাতে পারে।
  int? _autoPlayTargetSura;

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

  /// একটা সূরার সম্পূর্ণ-প্লেব্যাক শেষ হলে পরের সূরার পেজে সরানো হয় এবং
  /// সেই পেজ অটো-প্লে দিয়ে খোলার জন্য চিহ্নিত করা হয়।
  void _goToNextSurahAndAutoPlay(int nextSura) {
    if (!mounted || nextSura > _totalSurahs) return;
    setState(() => _autoPlayTargetSura = nextSura);
    _pageController.animateToPage(
      nextSura - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
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
          final shouldAutoPlay = _autoPlayTargetSura == suraNumber;
          if (shouldAutoPlay) {
            // একবার ব্যবহার হয়ে গেলে সাথে সাথে reset করা হচ্ছে, যাতে এই
            // সূরার পেজ ভবিষ্যতে আবার তৈরি হলে (যেমন ব্যবহারকারী পরে সোয়াইপ
            // করে ফিরে এলে) অনিচ্ছাকৃতভাবে আবার অটো-প্লে শুরু না হয়।
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _autoPlayTargetSura == suraNumber) {
                setState(() => _autoPlayTargetSura = null);
              }
            });
          }
          return _SurahPage(
            // suraNumber পাল্টালে GlobalKey না থাকলেও পুরনো _SurahPageState
            // পুনর্ব্যবহার হওয়ার ঝুঁকি এড়াতে key ব্যবহার করা হচ্ছে — এটা
            // নিশ্চিত করে অটো-প্লে টার্গেট পেজ সবসময় ফ্রেশ state দিয়ে খোলে।
            key: ValueKey('surah_page_$suraNumber'),
            lang: widget.lang,
            sura: suraNumber,
            autoPlayOnStart: shouldAutoPlay,
            onRequestNextSurah: () => _goToNextSurahAndAutoPlay(suraNumber + 1),
          );
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
  /// true হলে এই পেজ খোলার সাথে সাথেই সম্পূর্ণ সূরা অটো-প্লে শুরু হবে —
  /// আগের সূরা শেষ হয়ে এখানে chain হয়ে এলে ব্যবহৃত হয়।
  final bool autoPlayOnStart;
  /// এই সূরার প্লেব্যাক শেষ হলে parent (PageView holder)-কে জানায় যাতে
  /// পরের সূরার পেজে move করে সেখানে অটো-প্লে চালু করা যায়।
  final VoidCallback? onRequestNextSurah;

  const _SurahPage({
    super.key,
    required this.lang,
    required this.sura,
    this.autoPlayOnStart = false,
    this.onRequestNextSurah,
  });

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
  bool _fullSurahPaused = false;
  int? _fullSurahAyaIndex;
  // যেই আয়াতে সর্বশেষ ম্যানুয়ালি জাম্প করা হয়েছে (verse-jump শিট থেকে) —
  // এরপর নিচের Play বাটন চাপলে ১ নম্বর থেকে না গিয়ে এখান থেকেই শুরু হবে।
  int _resumeFromIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _ayaKeys = [];

  // নিচের বার (সূরার নাম/জাম্প + প্লে বাটন + Page/List টগল) স্ক্রল করলে
  // লুকিয়ে/দেখা যাওয়ার জন্য — উপরের দিকে স্ক্রল করলে (নিচে পড়তে থাকলে)
  // লুকিয়ে যায়, নিচের দিকে স্ক্রল করলে (উপরে ফিরলে) আবার দেখা যায়।
  bool _bottomBarVisible = true;

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
    // স্ক্রিন থেকে বের হলেও সূরা প্লে ব্যাকগ্রাউন্ডে চলতে থাকবে (lock screen
    // এও যেমন চলে) — তাই এখানে ইচ্ছাকৃতভাবে audio বন্ধ করা হয় না।
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPrefs();
    }
  }

  /// স্ক্রল করার ডিরেকশন অনুযায়ী নিচের বার লুকায়/দেখায়।
  /// নিচের দিকে (reverse, অর্থাৎ পড়তে পড়তে এগিয়ে যাওয়া) স্ক্রল করলে বার
  /// লুকিয়ে যায়, উপরের দিকে (forward, অর্থাৎ পিছনে ফেরা) স্ক্রল করলে
  /// আবার দেখা যায় — অনেক কোরআন অ্যাপে দেখা পরিচিত আচরণ।
  bool _handleScrollNotification(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse && _bottomBarVisible) {
      setState(() => _bottomBarVisible = false);
    } else if (notification.direction == ScrollDirection.forward && !_bottomBarVisible) {
      setState(() => _bottomBarVisible = true);
    }
    return false;
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
      if (widget.autoPlayOnStart && _ayat.isNotEmpty) {
        _toggleFullSurahPlay();
      }
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
  void _scrollToVerse(int ayaIndex, {int attemptsLeft = 5}) {
    if (!mounted) return;
    if (ayaIndex < 0 || ayaIndex >= _ayaKeys.length) return;
    final ctx = _ayaKeys[ayaIndex].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 150),
        curve: Curves.linear,
        alignment: 0.35,
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
            duration: const Duration(milliseconds: 150),
            curve: Curves.linear,
            alignment: 0.35,
          );
        }
      });
    });
  }

  /// Play/Pause বাটনের মূল লজিক। চলমান অবস্থায় চাপলে stop না করে pause করে
  /// (যাতে "রিজিউম" সম্ভব হয়) — pause অবস্থায় চাপলে ঠিক সেখান থেকেই আবার চালু হয়।
  Future<void> _toggleFullSurahPlay() async {
    if (_fullSurahPlaying && !_fullSurahPaused) {
      // চলমান থেকে পজ করা
      await QuranAudioHelper.pause();
      if (mounted) setState(() => _fullSurahPaused = true);
      return;
    }

    if (_fullSurahPaused) {
      // পজ থেকে আবার চালু করা — নতুন সিকোয়েন্স শুরু না করে সরাসরি resume
      await QuranAudioHelper.resume();
      if (mounted) setState(() => _fullSurahPaused = false);
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
      setState(() {
        _fullSurahPlaying = true;
        _fullSurahPaused = false;
      });
      await QuranAudioHelper.playFullSurah(
        sura: widget.sura,
        surahAudioUrl: surahAudio['audio_url'] as String,
        segments: segments,
        startIndex: _resumeFromIndex,
        onAyaStart: (ayaIndex, ayaNumber) {
          if (!mounted) return;
          setState(() => _fullSurahAyaIndex = ayaIndex);
          // ayaIndex == -1 মানে এখন বিসমিল্লাহ পড়া হচ্ছে (এখনো প্রকৃত
          // কোনো আয়াত শুরু হয়নি) — এই অবস্থায় _resumeFromIndex আপডেট
          // করা হয় না, কারণ এটা একটা বৈধ আয়াত-ইনডেক্স হিসেবেই থাকা
          // দরকার (পরে Play চাপলে আবার সঠিক জায়গা থেকে শুরু হওয়ার জন্য)।
          if (ayaIndex >= 0) {
            _resumeFromIndex = ayaIndex; // পরের বার Play চাপলে এখান থেকেই শুরু হবে
            _scrollToVerse(ayaIndex);
          }
        },
        onSequenceComplete: () {
          if (!mounted) return;
          setState(() {
            _fullSurahPlaying = false;
            _fullSurahPaused = false;
            _fullSurahAyaIndex = null;
          });
          // সূরা শেষ হয়ে গেলে পরের বার প্লে করলে আবার প্রথম থেকে শুরু হবে।
          _resumeFromIndex = 0;
          // সূরা ১১৪ (আন-নাস)-এর পরে আর কোনো সূরা নেই, তাই chain করা হবে না।
          if (widget.sura < 114) {
            widget.onRequestNextSurah?.call();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lang.isBn ? 'ব্যর্থ হয়েছে: $e' : 'Failed: $e')),
        );
        setState(() => _fullSurahPlaying = false);
      }
    } finally {
      if (mounted) setState(() => _fullSurahLoading = false);
    }
  }

  /// সম্পূর্ণ থামানোর জন্য (stop বাটন প্রয়োজন হলে ভবিষ্যতে ব্যবহারের জন্য রাখা) —
  /// বর্তমানে UI-তে ব্যবহার না হলেও pause-vs-stop এর পার্থক্য স্পষ্ট রাখতে রাখা।
  Future<void> _stopFullSurah() async {
    await QuranAudioHelper.stop();
    if (mounted) {
      setState(() {
        _fullSurahPlaying = false;
        _fullSurahPaused = false;
        _fullSurahAyaIndex = null;
      });
    }
    _resumeFromIndex = 0;
  }

  /// আগের আয়াত থেকে আবার চালানো (◀◀ বাটন)।
  /// আগের আয়াত থেকে আবার চালানো (◀◀ বাটন) — দ্রুত সিক, রিলোড ছাড়াই।
  Future<void> _playPreviousAya() async {
    if (_ayat.isEmpty || (!_fullSurahPlaying && !_fullSurahPaused)) return;
    final highlighted = _fullSurahAyaIndex;
    final current = (highlighted != null && highlighted >= 0) ? highlighted : _resumeFromIndex;
    final target = (current - 1).clamp(0, _ayat.length - 1);
    _resumeFromIndex = target;
    await QuranAudioHelper.seekToIndex(target);
    if (mounted) {
      setState(() {
        _fullSurahPlaying = true;
        _fullSurahPaused = false;
      });
    }
  }

  /// পরের আয়াত থেকে চালানো (▶▶ বাটন) — দ্রুত সিক, রিলোড ছাড়াই।
  Future<void> _playNextAya() async {
    if (_ayat.isEmpty || (!_fullSurahPlaying && !_fullSurahPaused)) return;
    final highlighted = _fullSurahAyaIndex;
    final current = (highlighted != null && highlighted >= 0) ? highlighted : _resumeFromIndex;
    final target = (current + 1).clamp(0, _ayat.length - 1);
    _resumeFromIndex = target;
    await QuranAudioHelper.seekToIndex(target);
    if (mounted) {
      setState(() {
        _fullSurahPlaying = true;
        _fullSurahPaused = false;
      });
    }
  }

  void _jumpToVerse(int ayaIndex) {
    _resumeFromIndex = ayaIndex;
    Navigator.of(context).pop(); // close the bottom sheet
    // Wait for the bottom sheet's close animation to finish (Material's
    // default modal transition is ~300ms; giving it a bit more margin makes
    // this reliable on slower devices), then retry-scroll until the target
    // verse's context becomes available.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
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

    return NotificationListener<UserScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Column(
      children: [
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
                              currentAyaIndex: _fullSurahAyaIndex,
                            )
                          : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(14),
                          children: [
                            if (showBismillah)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  // বিসমিল্লাহ তেলাওয়াত চলাকালীন (_fullSurahAyaIndex == -1)
                                  // এই লাইনটাও ঠিক আয়াতের মতোই হাইলাইট হয় — সূরা
                                  // আল-ফাতিহায় যেমন ১ নং আয়াত হিসেবে বিসমিল্লাহ
                                  // হাইলাইট হয়, বাকি সূরাতেও একই অনুভূতি দিতে।
                                  color: _fullSurahAyaIndex == -1
                                      ? AppTheme.primary.withOpacity(0.28)
                                      : AppTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _fullSurahAyaIndex == -1
                                      ? Border.all(color: AppTheme.gold, width: 1.6)
                                      : null,
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
                                          _fullSurahPaused = false;
                                          _fullSurahAyaIndex = null;
                                        })
                                    : null,
                                isCurrentlyPlaying: _fullSurahAyaIndex == i,
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
        ),
        // নিচের কম্প্যাক্ট বার — দুই সারিতে ভাগ করা যাতে ছোট স্ক্রিনেও কোনো
        // বাটন/টেক্সট একে অপরের উপর না ওঠে:
        // ১ম সারি: সূরার নাম + বর্তমান আয়াত — মার্কি (স্ক্রলিং) টেক্সট
        // ২য় সারি: Page/List টগল + ফন্ট সাইজ + প্লে-কন্ট্রোল
        // AnimatedSize দিয়ে স্ক্রল ডিরেকশনে hide/show হয়, SafeArea দিয়ে
        // gesture navigation bar-এর নিচে চাপা পড়া এড়ানো হয়।
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: !_bottomBarVisible
              ? const SizedBox(width: double.infinity, height: 0)
              : SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ১ম সারি: সূরার নাম (+ চলমান আয়াত নম্বর) — মার্কি স্ক্রল,
                        // ট্যাপ করলে verse-jump শিট খোলে
                        if (_ayat.isNotEmpty)
                          InkWell(
                            onTap: _showVerseJumpSheet,
                            child: SizedBox(
                              height: 22,
                              width: double.infinity,
                              child: _MarqueeText(
                                text: (_fullSurahPlaying &&
                                        _fullSurahAyaIndex != null &&
                                        _fullSurahAyaIndex! >= 0 &&
                                        _fullSurahAyaIndex! < _ayat.length)
                                    ? '$nameTranslit  -  ${isBn ? 'আয়াত' : 'Aya'} ${_ayat[_fullSurahAyaIndex!]['aya']}'
                                    : (nameTranslit.isNotEmpty ? nameTranslit : (isBn ? 'কোরআন' : 'Quran')),
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        // ২য় সারি: Page/List টগল + ফন্ট সাইজ + প্লে-কন্ট্রোল
                        Row(
                          children: [
                            // Page/List একক টগল বাটন — বাম দিকে, চাপ দিলেই
                            // বর্তমান মোড অনুযায়ী পরের মোডে (List ⇄ Page) পাল্টে যায়।
                            // অন্য কোরআন অ্যাপের নিচের-বাম কর্নারের বাটনের রেফারেন্স অনুযায়ী।
                            if (_ayat.isNotEmpty)
                              _ViewModeToggleButton(
                                viewMode: _viewMode,
                                isBn: isBn,
                                onTap: () => _setViewMode(_viewMode == 'page' ? 'list' : 'page'),
                              ),
                            const Spacer(),
                            // ফন্ট সাইজ কন্ট্রোল
                            _FontSizeControls(
                              onDecrease: () => _changeFontSize(-2),
                              onIncrease: () => _changeFontSize(2),
                              canDecrease: _fontSize > _minFontSize,
                              canIncrease: _fontSize < _maxFontSize,
                              compact: true,
                            ),
                            const SizedBox(width: 6),
                            // চলমান/পজড অবস্থায়: ◀◀ (আগের আয়াত) ⏸/▶ (প্লে-পজ) ▶▶ (পরের আয়াত) — ৩টা বাটন
                            // বন্ধ অবস্থায়: শুধু একটা গোল ▶ প্লে বাটন — অন্য কোরআন অ্যাপের রেফারেন্স অনুযায়ী
                            if (_ayat.isNotEmpty)
                              if (_fullSurahPlaying || _fullSurahPaused) ...[
                                IconButton(
                                  icon: const Icon(Icons.fast_rewind, size: 20),
                                  color: AppTheme.gold,
                                  tooltip: isBn ? 'আগের আয়াত' : 'Previous verse',
                                  onPressed: _playPreviousAya,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 1),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _fullSurahLoading ? null : _toggleFullSurahPlay,
                                      child: Center(
                                        child: _fullSurahLoading
                                            ? const SizedBox(
                                                width: 16, height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                                              )
                                            : Icon(
                                                (_fullSurahPlaying && !_fullSurahPaused) ? Icons.pause : Icons.play_arrow,
                                                color: AppTheme.gold,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.fast_forward, size: 20),
                                  color: AppTheme.gold,
                                  tooltip: isBn ? 'পরের আয়াত' : 'Next verse',
                                  onPressed: _playNextAya,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ] else
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 1),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _fullSurahLoading ? null : _toggleFullSurahPlay,
                                      child: Center(
                                        child: _fullSurahLoading
                                            ? const SizedBox(
                                                width: 16, height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                                              )
                                            : const Icon(
                                                Icons.play_arrow,
                                                color: AppTheme.gold,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
      ),
    );
  }
}

/// ডান থেকে বামে ক্রমাগত স্ক্রল হতে থাকা টেক্সট — টেক্সট বক্সের প্রস্থের
/// চেয়ে বড় হলেই স্ক্রল শুরু হয়, ছোট হলে সাধারণভাবে মাঝে বসে থাকে।
/// অন্য কোরআন অ্যাপের রেফারেন্স অনুযায়ী প্লে-বার এর উপরের সূরা/আয়াত
/// নাম দেখানোর জন্য ব্যবহৃত।
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late final ScrollController _controller;
  bool _scheduling = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_controller.hasClients) _controller.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
    }
  }

  void _maybeStart() {
    if (!mounted || _scheduling) return;
    if (!_controller.hasClients) return;
    final maxExtent = _controller.position.maxScrollExtent;
    if (maxExtent <= 0) return; // টেক্সট বক্সে ধরে যাচ্ছে, স্ক্রল দরকার নেই
    _scheduling = true;
    _runLoop(maxExtent);
  }

  Future<void> _runLoop(double maxExtent) async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_controller.hasClients) return;
      final extent = _controller.position.maxScrollExtent;
      if (extent <= 0) return;
      await _controller.animateTo(
        extent,
        duration: Duration(milliseconds: (extent * 30).clamp(2000, 9000).toInt()),
        curve: Curves.linear,
      );
      if (!mounted || !_controller.hasClients) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_controller.hasClients) return;
      _controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(widget.text, style: widget.style, maxLines: 1),
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
  final bool compact;

  const _FontSizeControls({
    required this.onDecrease,
    required this.onIncrease,
    required this.canDecrease,
    required this.canIncrease,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 15.0 : 18.0;
    final btnPadding = compact ? const EdgeInsets.all(3.0) : const EdgeInsets.all(6.0);
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
            icon: Icon(Icons.remove, size: iconSize),
            color: canDecrease ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.4),
            onPressed: canDecrease ? onDecrease : null,
            tooltip: 'A-',
            splashRadius: compact ? 14 : 18,
            padding: btnPadding,
            constraints: const BoxConstraints(),
          ),
          if (!compact)
            const Text(
              'A',
              style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          IconButton(
            icon: Icon(Icons.add, size: iconSize),
            color: canIncrease ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.4),
            onPressed: canIncrease ? onIncrease : null,
            tooltip: 'A+',
            splashRadius: compact ? 14 : 18,
            padding: btnPadding,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// একক Page/List টগল বাটন — বর্তমানে যে মোড সক্রিয় সেটাই দেখায়
/// (আইকন + লেবেল), ট্যাপ করলে অন্য মোডে পাল্টে যায়। যেমন: এখন
/// 'page' মোডে থাকলে বাটনে "Page" দেখাবে, ট্যাপ করলে 'list' মোডে
/// চলে যাবে এবং বাটনে "List" দেখাবে — এবং এভাবেই চলতে থাকবে।
class _ViewModeToggleButton extends StatelessWidget {
  final String viewMode; // 'page' অথবা 'list'
  final bool isBn;
  final VoidCallback onTap;

  const _ViewModeToggleButton({
    required this.viewMode,
    required this.isBn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPage = viewMode == 'page';
    final icon = isPage ? Icons.description_outlined : Icons.view_list_outlined;
    final label = isPage
        ? (isBn ? 'পেজ' : 'Page')
        : (isBn ? 'লিস্ট' : 'List');

    return Material(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.gold),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
  /// Index (into [ayat]) of the ayah currently being read aloud during
  /// full-surah playback, or null if nothing is playing. Used to highlight
  /// that ayah's text in the flowing mushaf-style layout.
  final int? currentAyaIndex;

  const _MushafPageView({
    required this.scrollController,
    required this.nameArabic,
    required this.ayat,
    required this.ayaKeys,
    required this.showBismillah,
    required this.fontSize,
    required this.lang,
    this.currentAyaIndex,
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
                    // বিসমিল্লাহ তেলাওয়াত চলাকালীন (currentAyaIndex == -1)
                    // এখানেও ঠিক আয়াতের মতোই ব্যাকগ্রাউন্ড হাইলাইট হয়।
                    backgroundColor: currentAyaIndex == -1
                        ? AppTheme.primary.withOpacity(0.35)
                        : null,
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
                          // audio প্লে চলাকালীন যেই আয়াতটা এখন পড়া হচ্ছে
                          // সেটার পিছনে হালকা সবুজ ব্যাকগ্রাউন্ড হাইলাইট
                          backgroundColor: currentAyaIndex == i
                              ? AppTheme.primary.withOpacity(0.35)
                              : null,
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
                              color: currentAyaIndex == i
                                  ? AppTheme.gold.withOpacity(0.85)
                                  : null,
                              border: Border.all(color: AppTheme.gold.withOpacity(0.7), width: 1.2),
                            ),
                            child: Text(
                              lang.toLocalNum(ayat[i]['aya'] as int),
                              style: TextStyle(
                                color: currentAyaIndex == i ? AppTheme.cardBg : AppTheme.gold,
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
  /// True when this ayah is the one currently being read aloud during a
  /// full-surah playback session (independent of this card's own single-ayah
  /// play button) — used to highlight the card.
  final bool isCurrentlyPlaying;

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
    this.isCurrentlyPlaying = false,
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
          SnackBar(content: Text(widget.lang.isBn ? 'ব্যর্থ হয়েছে: $e' : 'Failed: $e')),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // পুরো সূরা প্লে চলাকালীন যেই আয়াতটা এখন পড়া হচ্ছে সেটার
          // ব্যাকগ্রাউন্ড হালকা সবুজ হাইলাইট হয়, স্ক্রিনশটে দেখানো
          // অন্য অ্যাপের মতো।
          color: widget.isCurrentlyPlaying
              ? AppTheme.primary.withOpacity(0.28)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isCurrentlyPlaying
                ? AppTheme.gold
                : (_expanded ? AppTheme.gold.withOpacity(0.6) : AppTheme.primary.withOpacity(0.25)),
            width: widget.isCurrentlyPlaying ? 1.6 : 1.0,
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
