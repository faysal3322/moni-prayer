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

/// এই স্ক্রিনে নেভিগেট করার সময় MaterialPageRoute-এর settings.name হিসেবে
/// ব্যবহার করার জন্য একটা কনস্ট্যান্ট — main.dart-এর route observer এটা
/// দেখে বুঝতে পারে কুরআন সূরা-বিস্তারিত স্ক্রিন এখন টপ-এ আছে কিনা, যাতে
/// persistent "এখন তেলাওয়াত হচ্ছে" ব্যানার তখন লুকিয়ে রাখা যায় (নাহলে
/// এই স্ক্রিনের নিজস্ব প্লে-বার ব্যানারে ঢাকা পড়ে যেত)।
const String kSurahDetailRouteName = '/quran/surah-detail';

class SurahDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int sura;
  /// দেওয়া থাকলে, এই সূরার পেজ খোলার পর সরাসরি এই আয়াতে স্ক্রল করে দেখায়।
  final int? jumpToAyaNumber;
  const SurahDetailScreen({
    super.key,
    required this.lang,
    required this.sura,
    this.jumpToAyaNumber,
  });

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

  // সেটিংস থেকে ফিরে আসার পর PageView-এর সব পেজ জোর করে নতুন করে তৈরি
  // (rebuild with fresh state) করাতে এই কাউন্টার ব্যবহার হয় — নিচে
  // itemBuilder-এর key-তে এটা যুক্ত করা আছে, তাই মান বদলালে প্রতিটা
  // _SurahPage-এর নতুন state instance তৈরি হয়, যেটা initState-এ
  // নিজে থেকেই সর্বশেষ QuranPrefs মান লোড করে নেয়।
  int _prefsRefreshTick = 0;

  void _openSettings() async {
    // ফিক্স: আগে Navigator.push এর ফলাফল await/handle করা হতো না, তাই
    // কোরআন সেটিংস স্ক্রিনে গিয়ে ভাষা টগল বা ফন্ট সাইজ পরিবর্তন করে
    // "Back" চাপলে সেই পরিবর্তন QuranPrefs (SharedPreferences)-এ সেভ
    // হতো ঠিকই, কিন্তু সূরা পড়ার পেজের (_SurahPage) ইন-মেমরি state
    // (_showArabic, _showBangla, _showTransliteration, _fontSize)
    // রিফ্রেশ হতো না — ফলে সেটিংস বদলানোর কোনো প্রভাব সাথে সাথে দেখা
    // যেত না। _loadPrefs() সরাসরি এখান থেকে কল করা যায় না কারণ সেটা
    // ভিন্ন (child) widget-এর state-এ থাকে। তাই এখন সেটিংস স্ক্রিন
    // থেকে ফিরে এলে _prefsRefreshTick বাড়িয়ে PageView-এর key বদলে
    // দেওয়া হচ্ছে, যা প্রতিটা সূরা-পেজকে ফ্রেশ state দিয়ে আবার তৈরি
    // করে — এবং সেই নতুন state তার initState-এই সর্বশেষ সংরক্ষিত
    // QuranPrefs মান লোড করে নেয়।
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuranSettingsScreen(lang: widget.lang),
    ));
    if (mounted) setState(() => _prefsRefreshTick++);
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
            // _prefsRefreshTick যোগ করা হয়েছে যাতে কোরআন সেটিংস বদলে ফেরার
            // পর প্রতিটা পেজ ফ্রেশ state নিয়ে আবার তৈরি হয় (দেখুন
            // _openSettings-এর কমেন্ট)।
            key: ValueKey('surah_page_${suraNumber}_$_prefsRefreshTick'),
            lang: widget.lang,
            sura: suraNumber,
            autoPlayOnStart: shouldAutoPlay,
            onRequestNextSurah: () => _goToNextSurahAndAutoPlay(suraNumber + 1),
            jumpToAyaNumber: suraNumber == widget.sura ? widget.jumpToAyaNumber : null,
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
  /// দেওয়া থাকলে, পেজ লোড হওয়ার পরপরই এই আয়াত নম্বরে স্ক্রল করে দেখায় —
  /// persistent "এখন তেলাওয়াত হচ্ছে" ব্যানারে চাপলে সরাসরি চলমান আয়াতে
  /// ফিরে যাওয়ার জন্য ব্যবহৃত হয়।
  final int? jumpToAyaNumber;

  const _SurahPage({
    super.key,
    required this.lang,
    required this.sura,
    this.autoPlayOnStart = false,
    this.onRequestNextSurah,
    this.jumpToAyaNumber,
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
  bool _showTransliteration = false;
  double _fontSize = 24.0;
  String _viewMode = 'list';
  double _playbackSpeed = 1.0;

  bool _fullSurahLoading = false;
  bool _fullSurahPlaying = false;
  bool _fullSurahPaused = false;
  int? _fullSurahAyaIndex;
  // যেই আয়াতে সর্বশেষ ম্যানুয়ালি জাম্প করা হয়েছে (verse-jump শিট থেকে) —
  // এরপর নিচের Play বাটন চাপলে ১ নম্বর থেকে না গিয়ে এখান থেকেই শুরু হবে।
  int _resumeFromIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _ayaKeys = [];
  // ফিক্স: আগে dispose()-এর সময় সরাসরি _ayaKeys[i].currentContext পড়ে
  // "এখন কোন আয়াত দেখা যাচ্ছে" বের করা হতো। কিন্তু dispose() কল হওয়ার
  // মুহূর্তে widget tree ইতিমধ্যে unmount হতে শুরু করে দেয়, ফলে প্রায়
  // সবসময়ই GlobalKey-দের currentContext আগেভাগেই null হয়ে যাচ্ছিল —
  // ফলে dispose-এ last-read সেভই হতো না, বা (বড় সূরায় "page" মোডে)
  // ভুল/পুরনো আয়াত সেভ হতো। এখন স্ক্রল থামার সময়েই (যখন widget tree
  // পুরো জীবিত) বর্তমান ইনডেক্স এখানে ক্যাশ করে রাখা হয়, আর dispose()-এ
  // GlobalKey আবার না পড়ে সরাসরি এই ক্যাশ করা মান ব্যবহার করা হয়।
  int? _lastKnownVisibleIndex;
  Timer? _saveDebounceTimer;

  // নিচের বার (সূরার নাম/জাম্প + প্লে বাটন + Page/List টগল) স্ক্রল করলে
  // লুকিয়ে/দেখা যাওয়ার জন্য — উপরের দিকে স্ক্রল করলে (নিচে পড়তে থাকলে)
  // লুকিয়ে যায়, নিচের দিকে স্ক্রল করলে (উপরে ফিরলে) আবার দেখা যায়।
  bool _bottomBarVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    QuranAudioHelper.activeSession.addListener(_onActiveSessionChanged);
    _load();
  }

  /// [QuranAudioHelper.activeSession] বদলালেই কল হয় — অন্য কোনো স্ক্রিন
  /// (বা এই স্ক্রিন নিজেই) playFullSurah/seekToIndex চালালে হ্যান্ডলার
  /// এই ভ্যালু আপডেট করে, আর এই স্ক্রিন সেটা শুনে নিজের স্ক্রল/হাইলাইট
  /// মিলিয়ে নেয় — পড়তে পড়তে যত দূরেই আয়াত এগিয়ে যাক না কেন।
  void _onActiveSessionChanged() {
    _syncWithActiveSession(QuranAudioHelper.activeSession.value);
  }

  void _syncWithActiveSession(QuranActiveSession? session) {
    if (!mounted) return;
    if (session == null || session.sura != widget.sura) {
      // এই সূরার জন্য কোনো সক্রিয় সেশন নেই (অন্য সূরা চলছে, বা কিছুই
      // চলছে না) — লোকাল প্লেয়িং স্টেট থাকলে সেটা মুছে ফেলা হচ্ছে, তবে
      // হাইলাইট (_fullSurahAyaIndex) রেখে দেওয়া হচ্ছে যাতে স্ক্রিন হঠাৎ
      // "কিছুই হাইলাইট নেই" অবস্থায় ঝাঁকি না খায়।
      if (_fullSurahPlaying) {
        setState(() {
          _fullSurahPlaying = false;
          _fullSurahPaused = false;
        });
      }
      return;
    }
    setState(() {
      _fullSurahPlaying = true;
      _fullSurahPaused = session.isPaused;
      _fullSurahAyaIndex = session.ayaIndex;
    });
    if (session.ayaIndex >= 0) {
      _resumeFromIndex = session.ayaIndex;
      // অডিও প্লেব্যাক নিজে থেকে আয়াত এগিয়ে নিয়ে গেলে ব্যবহারকারী হয়তো
      // কোনো ম্যানুয়াল স্ক্রল করবেনই না (idle notification আসবে না) —
      // তাই এখানেও সরাসরি ক্যাশ আপডেট করা হচ্ছে, যাতে শোনা অবস্থায়
      // হঠাৎ বের হয়ে গেলেও সঠিক আয়াত last-read হিসেবে সেভ হয়।
      _lastKnownVisibleIndex = session.ayaIndex;
      _scrollToVerse(session.ayaIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    QuranAudioHelper.activeSession.removeListener(_onActiveSessionChanged);
    // স্ক্রিন থেকে বের হওয়ার সময়ও একবার সর্বশেষ পঠিত অবস্থান সেভ করা
    // হচ্ছে — এতে ব্যবহারকারী স্ক্রল না করে (শুধু প্রথম আয়াত দেখে) স্ক্রিন
    // থেকে বের হয়ে গেলেও অন্তত এই সূরার শুরুটা "সর্বশেষ পড়া" হিসেবে
    // সংরক্ষিত থাকে।
    _saveCurrentPositionAsLastRead();
    _saveDebounceTimer?.cancel();
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
    // "সর্বশেষ পঠিত অবস্থান" সেভ — স্ক্রল থামলেই (ScrollEndNotification নয়,
    // UserScrollNotification.idle) বর্তমানে দৃশ্যমান প্রথম আয়াতটা বের করে
    // সংরক্ষণ করা হয়। প্রতিটা স্ক্রল ফ্রেমে না করে শুধু থামার সময় করা
    // হচ্ছে যাতে অহেতুক বারবার SharedPreferences write না হয়। widget tree
    // এখনো জীবিত থাকা অবস্থাতেই এটা ঘটে, তাই আগে ক্যাশ রিফ্রেশ করে তারপর
    // সেভ করা হয় (dispose()-এ শুধু এই ক্যাশ থেকে সেভ হয়, নতুন করে
    // GlobalKey পড়া হয় না)।
    if (notification.direction == ScrollDirection.idle) {
      _updateLastKnownVisibleIndex();
      _saveCurrentPositionAsLastRead();
    }
    return false;
  }

  /// বর্তমানে স্ক্রিনের উপরের দিকে দৃশ্যমান প্রথম আয়াতের ইনডেক্স খুঁজে
  /// _lastKnownVisibleIndex-এ ক্যাশ করে রাখে। স্ক্রল থামলে (idle) কল করা
  /// হয়, যখন widget tree এখনো পুরোপুরি জীবিত — তাই এখানে GlobalKey পড়া
  /// নির্ভরযোগ্য। _ayaKeys-এর প্রতিটা GlobalKey-এর RenderBox থেকে
  /// স্ক্রিনের উপরের কিনারার সাপেক্ষে অবস্থান (dy) দেখে সবচেয়ে কাছেরটা
  /// (কিন্তু উপরের কিনারার নিচে/সমান) বেছে নেওয়া হয়।
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
      // স্ক্রিনের উপরের অংশের (AppBar-এর নিচ থেকে) কাছাকাছি বা তার একটু
      // নিচে থাকা প্রথম আয়াতটাই "এখন যা পড়া হচ্ছে" হিসেবে ধরা হচ্ছে।
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
  /// অবস্থান" QuranPrefs-এ সেভ করে (GlobalKey আবার recompute করে না,
  /// দেখুন _lastKnownVisibleIndex-এর কমেন্ট)। কোনো ক্যাশ এখনো তৈরি না
  /// হয়ে থাকলে (যেমন ব্যবহারকারী একদম না স্ক্রল করেই সাথে সাথে বের হয়ে
  /// গেলে) প্রথম আয়াতটাকেই "সর্বশেষ পঠিত" হিসেবে ধরা হয়।
  void _saveCurrentPositionAsLastRead() {
    if (_ayat.isEmpty) return;
    final index = (_lastKnownVisibleIndex ?? 0).clamp(0, _ayat.length - 1);
    final ayaNumber = _ayat[index]['aya'] as int?;
    if (ayaNumber != null) {
      QuranPrefs.setLastRead(widget.sura, ayaNumber);
    }
  }

  Future<void> _loadPrefs() async {
    final arabic = await QuranPrefs.getShowArabic();
    final bangla = await QuranPrefs.getShowBangla();
    final translit = await QuranPrefs.getShowTransliteration();
    final fontSize = await QuranPrefs.getFontSize();
    final viewMode = await QuranPrefs.getViewMode();
    final speed = await QuranPrefs.getPlaybackSpeed();
    if (!mounted) return;
    setState(() {
      _showArabic = arabic;
      _showBangla = bangla;
      _showTransliteration = translit;
      _fontSize = fontSize;
      _viewMode = viewMode;
      _playbackSpeed = speed;
    });
  }

  /// স্পিড মানকে পরিষ্কারভাবে দেখায় — অহেতুক ট্রেইলিং শূন্য ছাড়া
  /// (যেমন 1.0 → "1", 0.85 → "0.85", 1.20 → "1.2")।
  String _formatSpeed(double speed) {
    String s = speed.toStringAsFixed(2);
    if (s.endsWith('0')) s = s.substring(0, s.length - 1);
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return s;
  }

  /// স্পিড বদলানোর ডায়ালগ খোলে — এখানে ব্যবহারকারী নিজে ইচ্ছেমতো যেকোনো
  /// সংখ্যা (যেমন 0.7, 1.15, 1.5, 2.0) লিখে বসাতে পারে, কোনো লিমিটেড
  /// তালিকা থেকে বেছে নেওয়ার বাধ্যবাধকতা নেই। +/- বাটন দুটো শুধু
  /// সুবিধার জন্য (০.০৫ করে বাড়ায়/কমায়), না চাইলে সরাসরি টাইপও করা যায়।
  Future<void> _showSpeedPicker() async {
    final isBn = widget.lang.isBn;
    final controller = TextEditingController(
      text: _playbackSpeed.toStringAsFixed(2),
    );
    String? errorText;

    final selected = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void adjust(double delta) {
              final current = double.tryParse(controller.text) ?? _playbackSpeed;
              final next = (current + delta).clamp(0.25, 3.0);
              controller.text = next.toStringAsFixed(2);
              setDialogState(() => errorText = null);
            }

            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              title: Text(
                isBn ? 'তেলাওয়াতের গতি' : 'Recitation speed',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBn
                        ? 'যেকোনো মান লিখুন (যেমন 0.75, 1.2, 1.5)। ১ = স্বাভাবিক গতি।'
                        : 'Type any value (e.g. 0.75, 1.2, 1.5). 1 = normal speed.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.gold),
                        onPressed: () => adjust(-0.05),
                        tooltip: isBn ? 'কমাও' : 'Decrease',
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          decoration: InputDecoration(
                            suffixText: 'x',
                            suffixStyle: const TextStyle(color: AppTheme.gold),
                            errorText: errorText,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.gold),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.gold, width: 2),
                            ),
                          ),
                          onChanged: (_) => setDialogState(() => errorText = null),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.gold),
                        onPressed: () => adjust(0.05),
                        tooltip: isBn ? 'বাড়াও' : 'Increase',
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    final value = double.tryParse(controller.text.trim());
                    if (value == null || value < 0.25 || value > 3.0) {
                      setDialogState(() {
                        errorText = isBn
                            ? '0.25 থেকে 3.0-এর মধ্যে একটা সংখ্যা লিখুন'
                            : 'Enter a value between 0.25 and 3.0';
                      });
                      return;
                    }
                    Navigator.pop(ctx, value);
                  },
                  child: Text(isBn ? 'ঠিক আছে' : 'OK', style: const TextStyle(color: AppTheme.gold)),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected == null || selected == _playbackSpeed) return;
    setState(() => _playbackSpeed = selected);
    await QuranAudioHelper.setSpeed(selected);
    // ফিক্স: আগে speed শুধু বর্তমান প্লেয়ার সেশনে প্রয়োগ হতো, prefs-এ
    // সেভ হতো না। ফলে স্ক্রিন থেকে বের হয়ে আবার ঢুকলে বা অ্যাপ পুনরায়
    // চালু করলে স্পিড 1.0x-এ রিসেট হয়ে যেত। এখন QuranPrefs-এও সেভ হয়,
    // তাই কালেকশন স্ক্রিন সহ (collection_detail_screen.dart) পুরো
    // অ্যাপ জুড়ে স্পিড ধারাবাহিকভাবে বজায় থাকে।
    await QuranPrefs.setPlaybackSpeed(selected);
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
      // বাগ ফিক্স: আগে widget.autoPlayOnStart true হলে এখানে
      // _toggleFullSurahPlay() কল করে একটা নতুন playFullSurah সেশন শুরু
      // করা হতো। কিন্তু এখন QuranAudioHelper নিজেই (হ্যান্ডলার-স্তরে)
      // আগের সূরা শেষ হলে পরের সূরা লোড করে অটো-প্লে চালিয়ে দেয় — তাই
      // এখানে আবার নতুন করে প্লে শুরু করলে একই সূরা দুইবার/দুই সেশনে
      // বাজতে শুরু করত (এবং প্রথম আয়াত থেকে আবার শুরু হয়ে হ্যান্ডলারের
      // প্রকৃত chain-করা অবস্থানের সাথে সাংঘর্ষিক হতো)। তাই এখন সবসময়
      // else ব্রাঞ্চ ব্যবহার হয় — যেটা activeSession থেকে হ্যান্ডলারের
      // প্রকৃত/সবশেষ অবস্থান পড়ে local UI state মিলিয়ে নেয় (স্ক্রল সহ)।
      {
        // এই সূরার জন্য যদি ইতিমধ্যেই একটা প্লেব্যাক সেশন চলমান/পজড
        // থাকে (persistent ব্যানারে চেপে এই স্ক্রিন খোলা হয়েছে, বা
        // আগের সূরা শেষ হয়ে এখানে chain হয়ে এসেছে), local
        // state (_fullSurahPlaying/_fullSurahPaused/_resumeFromIndex)
        // এখন সেই সেশনের সাথে মিলিয়ে নেওয়া হচ্ছে এবং একই আয়াতে স্ক্রল
        // করা হচ্ছে — activeSession ব্যবহার করা হচ্ছে (widget.jumpToAyaNumber
        // এর বদলে) কারণ এটা সবসময় হ্যান্ডলারের প্রকৃত/সবশেষ অবস্থান
        // দেখায়, ব্যানারে চাপার সময়কার একটা পুরনো স্ন্যাপশট না — নাহলে
        // এই নতুন স্ক্রিন playback শুরুই হয়নি ভেবে Play বাটনে চাপলে
        // ১ নং আয়াত থেকে নতুন সেশন শুরু করে দিত, এবং কোরআন পড়তে পড়তে
        // যত দূরেই এগিয়ে যাক, স্ক্রিন প্রথম জাম্প-করা আয়াতেই আটকে থাকত।
        //
        // প্রথম ফ্রেম আঁকা শেষ হওয়ার পরই স্ক্রল করা দরকার, তা না হলে
        // GlobalKey-গুলো এখনো কোনো RenderBox-এর সাথে যুক্ত হয়নি। এটা
        // একটা নতুন push-করা স্ক্রিন হওয়ায় (persistent ব্যানার থেকে
        // এসে) সামান্য বাড়তি বিলম্বও দেওয়া হচ্ছে, যাতে পেজ/লিস্ট পুরো
        // লেআউট করার সময় পায় — নাহলে প্রথম স্ক্রল-চেষ্টা ব্যর্থ হয়ে
        // "ব্যানারে চাপলে সঠিক আয়াতে যায় না" মনে হতে পারে।
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 150));
          if (!mounted) return;
          final session = QuranAudioHelper.activeSession.value;
          if (session != null && session.sura == widget.sura) {
            _syncWithActiveSession(session);
          } else if (widget.jumpToAyaNumber != null) {
            // কোনো সক্রিয় সেশন খুঁজে পাওয়া গেল না (হয়তো এর মধ্যেই থেমে
            // গেছে) — তবু ব্যানারে যে আয়াত নম্বর দেখানো হয়েছিল, ফলব্যাক
            // হিসেবে সেখানেই স্ক্রল করে দেখানো হচ্ছে।
            final targetIndex = _ayat.indexWhere((a) => a['aya'] == widget.jumpToAyaNumber);
            if (targetIndex >= 0) _scrollToVerse(targetIndex, attemptsLeft: 8);
          }
        });
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
      // ফিক্স: সূরা বাকারার মতো বড় সূরায়, page (মুশাফ) ভিউতে সবগুলো
      // আয়াত (২৮৬টা) একসাথে একটামাত্র বিশাল Text.rich-এ (আরবি গ্লিফ
      // শেপিং সহ) রেন্ডার হয়। এই GlobalKey-র context ওয়াইজেট মাউন্ট
      // হওয়া মাত্রই তৈরি হয়ে যায় (তাই ctx != null চেক পাস করে যায়),
      // কিন্তু তার মানে এই না যে পুরো বিশাল layout তখনই স্থির (settled)
      // হয়ে গেছে — ধীরগতির ডিভাইসে এই বিরাট প্যারাগ্রাফের প্রকৃত
      // পজিশন/উচ্চতা হিসাব সম্পূর্ণ হতে ১-২ সেকেন্ড বা তার বেশিও লাগতে
      // পারে। আগে মাত্র কয়েকটা fixed-delay (৩২০/৭০০/১২০০ms) সংশোধনী কল
      // ছিল — ধীর ডিভাইসে এই সময়ের মধ্যেও layout স্থির না হলে শেষ
      // সংশোধনী কলটাও ভুল/আংশিক geometry দিয়ে হিসাব করে ফেলত এবং
      // ব্যবহারকারী টার্গেট আয়াতের (যেমন ২৪৫) অনেক আগেই (যেমন ১৪৬-এ)
      // আটকে থাকতেন। এখন অনেক বেশি ঘন ঘন, প্রায় ৪ সেকেন্ড ধরে বারবার
      // সংশোধনী কল করা হচ্ছে — Scrollable.ensureVisible প্রতিবার
      // এখনকার (সেই মুহূর্তের সর্বশেষ) geometry দিয়ে নতুন করে হিসাব করে,
      // তাই layout যতক্ষণ না পুরোপুরি স্থির হয় ততক্ষণ প্রতিটা কল আগেরটার
      // চেয়ে একটু বেশি নির্ভুল জায়গায় নিয়ে যাবে, আর একবার স্থির হয়ে
      // গেলে পরের কলগুলো কার্যত কিছুই বদলাবে না (already at correct
      // alignment) — তাই এত বেশি কল করাও নিরাপদ।
      for (final delayMs in [200, 350, 550, 800, 1100, 1500, 2000, 2600, 3300, 4000]) {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (!mounted) return;
          final ctx2 = _ayaKeys[ayaIndex].currentContext;
          if (ctx2 != null) {
            Scrollable.ensureVisible(
              ctx2,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              alignment: 0.3,
            );
          }
        });
      }
      return;
    }
    if (attemptsLeft <= 0) {
      _scrollToVerseFallback(ayaIndex);
      return;
    }
    // Context not ready yet (widget not laid out on screen) — retry next frame.
    // বড় সূরায় (যেমন সূরা বাকারা) বিশাল Text.rich layout সম্পূর্ণ হতে বেশি
    // সময় লাগতে পারে বলে ব্যবধানও একটু বাড়ানো হয়েছে (১০০ms → ১৫০ms)।
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
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
  ///
  /// [explicitStartIndex] দেওয়া থাকলে (কোনো নির্দিষ্ট আয়াত কার্ডের প্লে
  /// বাটন থেকে চাপা হলে), সেই আয়াত থেকেই ধারাবাহিক প্লেব্যাক শুরু হয় —
  /// pause/resume অবস্থা উপেক্ষা করে সবসময় নতুন করে শুরু হয়, যাতে "যেকোনো
  /// আয়াতে চাপলে সেখান থেকেই চলতে থাকুক" আচরণ পাওয়া যায়।
  Future<void> _toggleFullSurahPlay({int? explicitStartIndex}) async {
    if (explicitStartIndex == null) {
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
    }

    if (_fullSurahLoading || _ayat.isEmpty) return;
    if (explicitStartIndex != null) {
      _resumeFromIndex = explicitStartIndex;
    }
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
        suraName: _chapter?['name_transliteration'] as String? ?? 'Surah ${widget.sura}',
        surahAudioUrl: surahAudio['audio_url'] as String,
        segments: segments,
        startIndex: _resumeFromIndex,
        onAyaStart: (ayaIndex, ayaNumber) {
          // স্ক্রল/হাইলাইট/_resumeFromIndex আপডেট (_syncWithActiveSession
          // দিয়ে, activeSession শুনে) এবং persistent ব্যানারের nowPlaying
          // আপডেট — দুটোই এখন QuranAudioHelper.playFullSurah নিজে করে,
          // এই widget বেঁচে আছে কিনা তার উপর নির্ভর না করেই। তাই এখানে
          // সত্যিকারের কিছু করার দরকার নেই।
        },
        onSequenceComplete: () {
          // বাগ ফিক্স: প্রকৃত অডিও chain (পরের সূরা লোড করে অটো-প্লে করা)
          // এখন QuranAudioHelper.playFullSurah নিজেই হ্যান্ডলার-স্তরে করে
          // (দেখুন quran_audio_helper.dart-এর _playNextSurahInChain) —
          // কারণ স্ক্রিন ব্যাকগ্রাউন্ডে dispose হয়ে গেলে (mounted false)
          // আগে এই কলব্যাকই chain শুরু করত এবং সেটা কখনো ট্রিগার হতো না।
          // তাই এখানে UI-এর কাজ শুধু: স্ক্রিন এখনও খোলা থাকলে PageView-কে
          // পরের সূরার পেজে সরিয়ে দেখানো (audio আবার নতুন করে চালু করা
          // নয়, তাহলে দুইবার প্লে শুরু হয়ে যেত)।
          if (mounted) {
            setState(() {
              _fullSurahPlaying = false;
              _fullSurahPaused = false;
              _fullSurahAyaIndex = null;
            });
            _resumeFromIndex = 0;
            if (widget.sura < 114) {
              widget.onRequestNextSurah?.call();
            }
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
    //
    // বাগ ফিক্স: আগে ডিফল্ট attemptsLeft (৫ বার, প্রতিটার মাঝে ১০০ms, মোট
    // মাত্র ৫০০ms) ব্যবহার হতো। এটা ছোট সূরায় ঠিক থাকলেও সূরা বাকারার
    // (২৮৬ আয়াত) মতো বড় সূরায়, বিশেষত শেষের দিকের আয়াতে (যেমন ২৮০, ২৮৬),
    // "page" (মুশাফ) ভিউ মোডে পুরো সূরাটা একটাই বিশাল Text.rich হিসেবে
    // রেন্ডার হয় — এত বড় প্যারাগ্রাফের layout সম্পূর্ণ হতে ৫০০ms-এর
    // বেশি সময় লাগতে পারে, ফলে GlobalKey-এর context কখনো রেডি না হয়েই
    // রিট্রাই ফুরিয়ে যেত এবং কম-নির্ভরযোগ্য আনুমানিক fallback scroll-এ
    // চলে যেত। এখন বেশি রিট্রাই ও কিছুটা বেশি বিলম্ব দেওয়া হচ্ছে, যাতে
    // বড় সূরাতেও আসল (আনুমানিক নয়) scroll-টাই কাজ করার সুযোগ পায়।
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _scrollToVerse(ayaIndex, attemptsLeft: 20);
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

    return NotificationListener<ScrollNotification>(
      // ফিক্স: আগে শুধু UserScrollNotification.idle (আঙুল তোলার পর
      // momentum থেমে যাওয়ার ইভেন্ট)-এ cache আপডেট হতো — ইউজার স্ক্রল
      // করেই সাথে সাথে back বাটনে চাপলে idle ইভেন্টটা dispose()-এর আগে
      // আসার সুযোগই পেত না, ফলে ভুল/পুরনো আয়াত last-read হিসেবে সেভ
      // হয়ে যেত। এখন প্রতিটা ScrollUpdateNotification-এই (আঙুল টানার
      // সময়ও) cache রিফ্রেশ হয়, তাই dispose()-এর সময় cache প্রায়
      // সবসময়ই সবশেষ অবস্থান ধরে রাখে। সেভ করাটা হালকা debounce করা,
      // তবে cache আপডেট নিজে সস্তা অপারেশন বলে debounce ছাড়াই হয়। এই
      // listener bottom-bar hide/show লজিক (নিচে UserScrollNotification
      // listener) স্পর্শ করে না, শুধু cache+save করে।
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification || notification is ScrollEndNotification) {
          _updateLastKnownVisibleIndex();
          _saveDebounceTimer?.cancel();
          _saveDebounceTimer = Timer(const Duration(milliseconds: 150), () {
            _saveCurrentPositionAsLastRead();
          });
        }
        return false;
      },
      child: NotificationListener<UserScrollNotification>(
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
                              onAyaTap: (i) => _toggleFullSurahPlay(explicitStartIndex: i),
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
                                onPlayFromHere: () => _toggleFullSurahPlay(explicitStartIndex: i),
                                isThisCardPlaying: _fullSurahPlaying && _fullSurahAyaIndex == i,
                                isThisCardLoading: _fullSurahLoading && _resumeFromIndex == i,
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
                            // তেলাওয়াতের স্পিড বদলানোর বাটন — চাপলে
                            // বটমশিটে 1.0x/0.90x/0.85x/0.80x অপশন দেখায়।
                            InkWell(
                              onTap: _showSpeedPicker,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 1),
                                ),
                                child: Text(
                                  '${_formatSpeed(_playbackSpeed)}x',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
  /// আয়াত নাম্বার-মার্কারে ট্যাপ করলে কল হয় — সেই আয়াত থেকে তেলাওয়াত
  /// শুরু করার জন্য। index হলো [ayat] লিস্টে ওই আয়াতের ইনডেক্স।
  final void Function(int index)? onAyaTap;

  const _MushafPageView({
    required this.scrollController,
    required this.nameArabic,
    required this.ayat,
    required this.ayaKeys,
    required this.showBismillah,
    required this.fontSize,
    required this.lang,
    this.currentAyaIndex,
    this.onAyaTap,
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
            // ফিচার আবিষ্কারযোগ্যতা: page ভিউতে যেকোনো আয়াতের নাম্বার-
            // সার্কেলে ট্যাপ করলে ঠিক ওই আয়াত থেকে তেলাওয়াত শুরু হয় —
            // আগে এই কাজ করা গেলেও কোনো ইঙ্গিত না থাকায় ব্যবহারকারীরা
            // বুঝতে পারতেন না। এখন উপরে একটা ছোট হিন্ট দেখানো হচ্ছে।
            if (onAyaTap != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline, color: AppTheme.gold, size: fontSize * 0.55),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lang.isBn
                              ? 'যেকোনো আয়াতের নাম্বারে চাপুন — সেখান থেকে তেলাওয়াত শুরু হবে'
                              : 'Tap any verse number to start recitation from there',
                          style: TextStyle(color: AppTheme.gold.withOpacity(0.9), fontSize: fontSize * 0.36),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          child: GestureDetector(
                            // ফিক্স: আগে page (মুশাফ) ভিউতে আয়াত নাম্বার
                            // মার্কারে ট্যাপ করার কোনো ব্যবস্থাই ছিল না,
                            // তাই কোনো নির্দিষ্ট আয়াত থেকে প্লে শুরু করার
                            // উপায় ছিল না — এখন ট্যাপ করলে ঠিক এই আয়াত
                            // থেকেই তেলাওয়াত শুরু হবে (list ভিউয়ের প্রতিটা
                            // আয়াতের পাশে থাকা প্লে বাটনের মতোই কাজ করে)।
                            // আগে থেকে কোড থাকলেও একটা প্লে-আইকন (▶) যোগ
                            // করা হচ্ছে যাতে এই নাম্বার-সার্কেলে ট্যাপ করলে
                            // যে প্লে হবে সেটা স্পষ্টভাবে বোঝা যায়।
                            onTap: onAyaTap == null ? null : () => onAyaTap!(i),
                            child: Container(
                              key: ayaKeys.length > i ? ayaKeys[i] : null,
                              width: fontSize * 1.3,
                              height: fontSize * 1.3,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentAyaIndex == i
                                    ? AppTheme.gold.withOpacity(0.85)
                                    : AppTheme.gold.withOpacity(0.08),
                                border: Border.all(color: AppTheme.gold.withOpacity(0.7), width: 1.2),
                              ),
                              child: currentAyaIndex == i
                                  ? Icon(
                                      Icons.graphic_eq_rounded,
                                      color: AppTheme.cardBg,
                                      size: fontSize * 0.55,
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          lang.toLocalNum(ayat[i]['aya'] as int),
                                          style: TextStyle(
                                            color: AppTheme.gold,
                                            fontSize: fontSize * 0.42,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
  /// এই আয়াতের প্লে বাটনে চাপলে কল হয় — parent screen-এ এই আয়াত থেকে
  /// শুরু করে ধারাবাহিক (continuous) প্লেব্যাক চালু করে, শুধু এই একটা
  /// আয়াত বাজিয়ে থেমে যায় না। সূরা শেষ হলে পরের সূরাতেও chain হবে,
  /// ঠিক উপরের Play বাটনের মতোই — পার্থক্য শুধু শুরুর আয়াত কোনটা তাতে।
  final VoidCallback? onPlayFromHere;
  /// True when this specific card is the one currently being read aloud.
  final bool isThisCardPlaying;
  /// True while this card's play request is being set up (loading audio),
  /// so its button can show a small spinner instead of the play icon.
  final bool isThisCardLoading;

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
    this.onPlayFromHere,
    this.isThisCardPlaying = false,
    this.isThisCardLoading = false,
  });

  @override
  State<_AyaCard> createState() => _AyaCardState();
}

class _AyaCardState extends State<_AyaCard> {
  bool _expanded = false;
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
          color: widget.isThisCardPlaying
              ? AppTheme.primary.withOpacity(0.28)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isThisCardPlaying
                ? AppTheme.gold
                : (_expanded ? AppTheme.gold.withOpacity(0.6) : AppTheme.primary.withOpacity(0.25)),
            width: widget.isThisCardPlaying ? 1.6 : 1.0,
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
                        icon: widget.isThisCardLoading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                              )
                            : Icon(
                                widget.isThisCardPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                color: AppTheme.gold,
                                size: 28,
                              ),
                        // এই আয়াত থেকে ধারাবাহিক তেলাওয়াত শুরু হয় — শুধু এই
                        // আয়াতটাই বাজিয়ে থেমে যায় না, পুরো সূরা জুড়ে চলতে
                        // থাকে এবং সূরা শেষ হলে পরের সূরাতেও chain হয়।
                        onPressed: widget.onPlayFromHere,
                        tooltip: isBn ? 'এখান থেকে শুনুন' : 'Play from here',
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
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  // ফিক্স: আগে এখানে fontSize hardcoded 15 ছিল, তাই কোরআন
                  // সেটিংসের ফন্ট সাইজ স্লাইডার শুধু আরবি টেক্সটে প্রভাব
                  // ফেলত, বাংলা অনুবাদে না। এখন widget.fontSize (স্লাইডার
                  // থেকে আসা মান) এর সাথে আনুপাতিকভাবে স্কেল করা হচ্ছে —
                  // আরবি ফন্টের চেয়ে কিছুটা ছোট রাখা হয়েছে (0.625×) যাতে
                  // ভিজুয়াল hierarchy (আরবি সবচেয়ে বড়, অনুবাদ তার চেয়ে
                  // ছোট) বজায় থাকে, কিন্তু স্লাইডার বাড়ালে/কমালে এটাও
                  // proportionally বদলায়।
                  fontSize: widget.fontSize * 0.625,
                  height: 1.6,
                ),
              ),
            ],
            if (widget.showTransliteration && widget.transliterationText.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 20),
              Text(
                widget.transliterationText,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  // ফিক্স: একই কারণে transliteration টেক্সটেও এখন
                  // widget.fontSize এর সাথে আনুপাতিক স্কেলিং (0.54×,
                  // সবচেয়ে ছোট — এটা সহায়ক/ঐচ্ছিক তথ্য)।
                  fontSize: widget.fontSize * 0.54,
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
