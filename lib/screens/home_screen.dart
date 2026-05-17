import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/date_helper.dart';
import '../utils/database_helper.dart';
import '../utils/prayer_time_helper.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'missed_list_screen.dart';
import 'names_screen.dart';
import 'nafl_screen.dart';
import 'dua_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  int _currentIndex = 0;
  String _lang = 'bn';
  String _userName = 'FAYSAL';
  int _namazPending = 0;
  int _rozaPending = 0;
  DateTime? _lastBackPress;

  final Map<int, ScrollController> _scrollControllers = {
    0: ScrollController(),
    1: ScrollController(),
    2: ScrollController(),
    3: ScrollController(),
    4: ScrollController(),
    5: ScrollController(),
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadCounts();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('language') ?? 'bn';
      _userName = prefs.getString('user_name') ?? 'FAYSAL';
    });
  }

  Future<void> _loadCounts() async {
    final namazData = await DatabaseHelper.getPrayerPendingCount();
    final rozaData = await DatabaseHelper.getRozaPendingCount();
    if (mounted) {
      setState(() {
        _namazPending = namazData['pending'] ?? 0;
        _rozaPending = rozaData['pending'] ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isScrolledDown() {
    final controller = _scrollControllers[_currentIndex];
    if (controller == null || !controller.hasClients) return false;
    return controller.offset > 50;
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_isScrolledDown()) {
      _scrollControllers[_currentIndex]?.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return false;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          AppLanguage(_lang).isBn
              ? 'আবার চাপুন অ্যাপ বন্ধ করতে'
              : 'Press again to exit',
          style: const TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primary,
      ));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage(_lang);
    final isBn = lang.isBn;
    final screens = [
      _HomeTab(
        lang: lang,
        now: _now,
        userName: _userName,
        namazPending: _namazPending,
        rozaPending: _rozaPending,
        onRefresh: _loadCounts,
        scrollController: _scrollControllers[0]!,
      ),
      CalendarScreen(lang: lang, onDataChanged: _loadCounts),
      NaflScreen(lang: lang),
      DuaScreen(lang: lang),
      NamesScreen(lang: lang),
      SettingsScreen(lang: lang, onChanged: () {
        _loadPrefs();
        _loadCounts();
      }),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppTheme.surface,
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          indicatorColor: AppTheme.primary,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: lang.home),
            NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: lang.calendar),
            NavigationDestination(
                icon: const Icon(Icons.mosque_outlined),
                selectedIcon: const Icon(Icons.mosque),
                label: isBn ? 'নামাজ' : 'Prayer'),
            NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: isBn ? 'দোয়া' : 'Dua'),
            NavigationDestination(
                icon: const Icon(Icons.auto_stories_outlined),
                selectedIcon: const Icon(Icons.auto_stories),
                label: isBn ? '৯৯ নাম' : '99 Names'),
            NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: lang.settings),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _HomeTab extends StatefulWidget {
  final AppLanguage lang;
  final DateTime now;
  final String userName;
  final int namazPending;
  final int rozaPending;
  final VoidCallback onRefresh;
  final ScrollController scrollController;

  const _HomeTab({
    required this.lang,
    required this.now,
    required this.userName,
    required this.namazPending,
    required this.rozaPending,
    required this.onRefresh,
    required this.scrollController,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, String> _todayPrayers = {};
  String? _todayRoza;
  PrayerTimes? _prayerTimes;
  SunnahTimes? _sunnahTimes;
  String _hijriDate = '';
  Timer? _autoQazaTimer;

  @override
  void initState() {
    super.initState();
    _loadToday();
    _loadHijri();
    _autoQazaTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _checkAndAutoMarkQaza();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkAndAutoMarkQaza();
    });
  }

  @override
  void dispose() {
    _autoQazaTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadHijri();
  }

  Future<void> _loadHijri() async {
    final h = await DateHelper.toHijriWithUserAdjust(
        DateTime.now(), bangla: widget.lang.isBn);
    if (mounted) setState(() => _hijriDate = h);
  }

  Future<void> _loadToday() async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    final statuses = await DatabaseHelper.getDayPrayerStatuses(dateKey);
    final roza = await DatabaseHelper.getRozaStatus(dateKey);
    if (mounted) {
      setState(() {
        _todayPrayers = statuses;
        _todayRoza = roza;
      });
    }
    if (_prayerTimes == null) {
      final times = await PrayerTimeHelper.getPrayerTimes();
      final sunnah = SunnahTimes(times);
      if (mounted) {
        setState(() {
          _prayerTimes = times;
          _sunnahTimes = sunnah;
        });
      }
    }
  }

  Future<void> _refreshStatusOnly() async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    final statuses = await DatabaseHelper.getDayPrayerStatuses(dateKey);
    final roza = await DatabaseHelper.getRozaStatus(dateKey);
    if (mounted) {
      setState(() {
        _todayPrayers = statuses;
        _todayRoza = roza;
      });
    }
  }

  Future<void> _checkAndAutoMarkQaza() async {
    final pt = _prayerTimes;
    if (pt == null) return;
    final now = DateTime.now();
    final dateKey = DateHelper.dateKey(now);
    final statuses = await DatabaseHelper.getDayPrayerStatuses(dateKey);
    bool changed = false;

    final entries = <String, Map<String, DateTime>>{
      'fajr': {'start': pt.fajr, 'end': pt.sunrise},
      'dhuhr': {'start': pt.dhuhr, 'end': pt.asr},
      'asr': {'start': pt.asr, 'end': pt.maghrib},
      'maghrib': {'start': pt.maghrib, 'end': pt.isha},
    };

    for (final entry in entries.entries) {
      final prayer = entry.key;
      final start = entry.value['start']!;
      final end = entry.value['end']!;
      final currentStatus = statuses[prayer];
      final startIsToday = DateHelper.dateKey(start) == dateKey;
      if (startIsToday && now.isAfter(start) && now.isAfter(end) && currentStatus == null) {
        await DatabaseHelper.setPrayerStatus(dateKey, prayer, 'missed');
        changed = true;
      }
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = DateHelper.dateKey(yesterday);
    final yesterdayStatuses = await DatabaseHelper.getDayPrayerStatuses(yesterdayKey);
    if (yesterdayStatuses['isha'] == null && now.isAfter(pt.fajr)) {
      await DatabaseHelper.setPrayerStatus(yesterdayKey, 'isha', 'missed');
      changed = true;
    }

    final ishaStatus = statuses['isha'];
    final ishaStart = pt.isha;
    final ishaStartIsToday = DateHelper.dateKey(ishaStart) == dateKey;
    final midNight = DateTime(now.year, now.month, now.day, 23, 59);
    if (ishaStartIsToday && now.isAfter(ishaStart) && now.isAfter(midNight) && ishaStatus == null) {
      await DatabaseHelper.setPrayerStatus(dateKey, 'isha', 'missed');
      changed = true;
    }

    if (changed) {
      await _refreshStatusOnly();
      widget.onRefresh();
    }
  }

  Future<void> _setPrayer(String prayer, String status) async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    setState(() => _todayPrayers = {..._todayPrayers, prayer: status});
    await DatabaseHelper.setPrayerStatus(dateKey, prayer, status);
    widget.onRefresh();
  }

  Future<void> _setRoza(String status) async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    setState(() => _todayRoza = status);
    await DatabaseHelper.setRozaStatus(dateKey, status);
    widget.onRefresh();
  }

  String _fmtTime(DateTime t) => PrayerTimeHelper.formatTime(t);

  String _countdown(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return '';
    final hr = diff.inHours.toString().padLeft(2, '0');
    final mn = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final sc = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hr:$mn:$sc';
  }

  List<Map<String, dynamic>> _getLiveAlerts(AppLanguage lang) {
    final isBn = lang.isBn;
    final now = DateTime.now();
    final pt = _prayerTimes;
    final alerts = <Map<String, dynamic>>[];
    if (pt == null) return alerts;

    final lastThird = _sunnahTimes?.lastThirdOfTheNight;
    final h = _HijriSimple.fromDate(now);
    final hijriMonth = _HijriSimple.getMonth(now);

    final ishraqStart = pt.sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = pt.sunrise.add(const Duration(minutes: 45));
    final chashtStart = pt.sunrise.add(const Duration(minutes: 45));
    final chashtEnd = pt.dhuhr.subtract(const Duration(minutes: 10));
    final sunriseForbiddenEnd = pt.sunrise.add(const Duration(minutes: 15));
    final zawalStart = pt.dhuhr.subtract(const Duration(minutes: 5));
    final zawalEnd = pt.dhuhr;
    final sunsetForbiddenStart = pt.maghrib.subtract(const Duration(minutes: 15));
    final ishaaEnd = lastThird ?? pt.fajr.add(const Duration(days: 1));

    // ══ ফরজ নামাজের ওয়াক্ত countdown ══
    if (now.isAfter(pt.fajr) && now.isBefore(pt.sunrise)) {
      final cd = _countdown(pt.sunrise);
      if (cd.isNotEmpty) alerts.add({'icon': '🕌', 'text': isBn ? 'ফজর নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Fajr ends in $cd', 'color': AppTheme.gold});
    }
    if (now.isAfter(pt.dhuhr) && now.isBefore(pt.asr)) {
      final cd = _countdown(pt.asr);
      if (cd.isNotEmpty) alerts.add({'icon': '🕌', 'text': isBn ? 'যোহর নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Dhuhr ends in $cd', 'color': AppTheme.gold});
    }
    if (now.isAfter(pt.asr) && now.isBefore(pt.maghrib)) {
      final cd = _countdown(pt.maghrib);
      if (cd.isNotEmpty) alerts.add({'icon': '🕌', 'text': isBn ? 'আসর নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Asr ends in $cd', 'color': AppTheme.gold});
    }
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      final cd = _countdown(pt.isha);
      if (cd.isNotEmpty) alerts.add({'icon': '🕌', 'text': isBn ? 'মাগরিব নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Maghrib ends in $cd', 'color': AppTheme.gold});
    }
    if (now.isAfter(pt.isha) && now.isBefore(ishaaEnd)) {
      final cd = _countdown(ishaaEnd);
      if (cd.isNotEmpty) alerts.add({'icon': '🕌', 'text': isBn ? 'এশা নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Isha ends in $cd', 'color': AppTheme.gold});
    }

    // ══ নফল নামাজের ওয়াক্ত ══
    if (now.isAfter(ishraqStart) && now.isBefore(ishraqEnd)) {
      final cd = _countdown(ishraqEnd);
      alerts.add({'icon': '⭐', 'text': isBn ? 'ইশরাকের ওয়াক্ত শেষ হতে বাকি $cd — হজ্জ-উমরার সওয়াব!' : 'Ishraq ends in $cd — Hajj & Umrah reward!', 'color': const Color(0xFFFF8F00)});
    }
    if (now.isAfter(chashtStart) && now.isBefore(chashtEnd)) {
      final cd = _countdown(chashtEnd);
      alerts.add({'icon': '☀️', 'text': isBn ? 'দুহা/চাশতের ওয়াক্ত শেষ হতে বাকি $cd' : 'Duha/Chasht ends in $cd', 'color': const Color(0xFFFDD835)});
    }
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      final cd = _countdown(pt.isha);
      alerts.add({'icon': '⭐', 'text': isBn ? 'আওওয়াবিনের ওয়াক্ত শেষ হতে বাকি $cd (৬-২০ রাকাত)' : 'Awwabin ends in $cd (6-20 rakats)', 'color': const Color(0xFF26A69A)});
    }
    if (lastThird != null) {
      final isNight = now.hour >= 21 || now.hour <= 6;
      if (isNight && now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
        final cd = _countdown(pt.fajr);
        alerts.add({'icon': '🌙', 'text': isBn ? 'তাহাজ্জুদের ওয়াক্ত শেষ হতে বাকি $cd — দোয়া কবুলের সর্বোত্তম সময়!' : 'Tahajjud ends in $cd — Best time for duas!', 'color': const Color(0xFF7C4DFF)});
      } else if (now.isAfter(pt.isha) && now.isBefore(lastThird)) {
        final cd = _countdown(lastThird);
        alerts.add({'icon': '🌙', 'text': isBn ? 'তাহাজ্জুদের সর্বোত্তম সময় শুরু হতে বাকি $cd' : 'Best Tahajjud time starts in $cd', 'color': const Color(0xFF7C4DFF)});
      }
    }

    // ══ সেহরি / ইফতার countdown ══
    if (now.isBefore(pt.fajr) && pt.fajr.difference(now).inMinutes <= 90) {
      final cd = _countdown(pt.fajr);
      alerts.add({'icon': '🍽️', 'text': isBn ? 'সেহরি শেষ হতে বাকি $cd (শেষ সময়: ${_fmtTime(pt.fajr)})' : 'Sehri ends in $cd (${_fmtTime(pt.fajr)})', 'color': const Color(0xFF81C784)});
    }
    if (now.isAfter(pt.fajr) && now.isBefore(pt.maghrib) && pt.maghrib.difference(now).inMinutes <= 120) {
      final cd = _countdown(pt.maghrib);
      alerts.add({'icon': '🌙', 'text': isBn ? 'ইফতার শুরু হতে বাকি $cd (${_fmtTime(pt.maghrib)})' : 'Iftar in $cd (${_fmtTime(pt.maghrib)})', 'color': const Color(0xFF64B5F6)});
    }

    // ══ সূর্যোদয় / সূর্যাস্ত ══
    if (now.isAfter(pt.sunrise.subtract(const Duration(minutes: 5))) && now.isBefore(pt.sunrise.add(const Duration(minutes: 5)))) {
      alerts.add({'icon': '🌅', 'text': isBn ? 'এখন সূর্যোদয় হচ্ছে (${_fmtTime(pt.sunrise)})' : 'Sunrise now (${_fmtTime(pt.sunrise)})', 'color': const Color(0xFFFFB300)});
    }
    if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 5))) && now.isBefore(pt.maghrib.add(const Duration(minutes: 5)))) {
      alerts.add({'icon': '🌇', 'text': isBn ? 'সূর্যাস্ত — ইফতারের সময় শুরু! (${_fmtTime(pt.maghrib)})' : 'Sunset — Iftar time! (${_fmtTime(pt.maghrib)})', 'color': const Color(0xFFFF7043)});
    }

    // ══ নামাজের নিষিদ্ধ সময় ══
    if (now.isAfter(pt.fajr) && now.isBefore(pt.sunrise)) {
      alerts.add({'icon': '⛔', 'text': isBn ? 'নামাজের নিষিদ্ধ সময় — ফজর ব্যতীত (${_fmtTime(pt.fajr)} - ${_fmtTime(pt.sunrise)})' : 'Forbidden — Except Fajr', 'color': AppTheme.missed});
    } else if (now.isAfter(pt.sunrise) && now.isBefore(sunriseForbiddenEnd)) {
      final cd = _countdown(sunriseForbiddenEnd);
      alerts.add({'icon': '⛔', 'text': isBn ? 'নামাজের নিষিদ্ধ সময় — সূর্যোদয়কালীন — শেষ হতে বাকি $cd' : 'Forbidden — Sunrise — ends in $cd', 'color': AppTheme.missed});
    } else if (now.isAfter(zawalStart) && now.isBefore(zawalEnd)) {
      final cd = _countdown(zawalEnd);
      alerts.add({'icon': '⛔', 'text': isBn ? 'নামাজের নিষিদ্ধ সময় — দ্বিপ্রহর — শেষ হতে বাকি $cd' : 'Forbidden — Noon — ends in $cd', 'color': AppTheme.missed});
    } else if (now.isAfter(pt.asr) && now.isBefore(sunsetForbiddenStart)) {
      alerts.add({'icon': '⛔', 'text': isBn ? 'নামাজের নিষিদ্ধ সময় — আসর ব্যতীত (${_fmtTime(pt.asr)} - ${_fmtTime(pt.maghrib)})' : 'Forbidden — Except Asr', 'color': AppTheme.missed});
    } else if (now.isAfter(sunsetForbiddenStart) && now.isBefore(pt.maghrib)) {
      final cd = _countdown(pt.maghrib);
      alerts.add({'icon': '⛔', 'text': isBn ? 'নামাজের নিষিদ্ধ সময় — সূর্যাস্তকালীন — শেষ হতে বাকি $cd' : 'Forbidden — Sunset — ends in $cd', 'color': AppTheme.missed});
    }

    // ══ পরবর্তী নামাজ ১৫ মিনিটের মধ্যে ══
    final next = PrayerTimeHelper.getNextPrayer(pt);
    final remaining = PrayerTimeHelper.getTimeToNextPrayer(pt);
    if (next != null && remaining != null && remaining.inMinutes <= 15) {
      final names = {'fajr': isBn ? 'ফজর' : 'Fajr', 'dhuhr': isBn ? 'যোহর' : 'Dhuhr', 'asr': isBn ? 'আসর' : 'Asr', 'maghrib': isBn ? 'মাগরিব' : 'Maghrib', 'isha': isBn ? 'এশা' : 'Isha'};
      final nextTime = PrayerTimeHelper.getPrayerTimesMap(pt)[next];
      final cd = nextTime != null ? _countdown(nextTime) : '';
      alerts.add({'icon': '🕌', 'text': isBn ? '${names[next]} নামাজের সময় হতে বাকি $cd ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""}' : '${names[next]} in $cd', 'color': AppTheme.accent});
    }

    // ══ জামাতের reminder — প্রতিটি ওয়াক্তের ১৫ মিনিট আগে ══
    if (next != null && remaining != null && remaining.inMinutes <= 15 && remaining.inMinutes > 0) {
      alerts.add({'icon': '🏛️', 'text': isBn ? 'জামাতে নামাজ পড়লে একাকী পড়ার চেয়ে ২৭ গুণ বেশি সওয়াব — মসজিদে যান!' : 'Pray in congregation — 27x more reward! Go to mosque!', 'color': const Color(0xFF26A69A)});
      alerts.add({'icon': '🥇', 'text': isBn ? 'রাসূল ﷺ প্রথম সারির জন্য ৩ বার দোয়া করতেন — প্রথম সারিতে দাঁড়ানোর চেষ্টা করুন!' : 'Prophet ﷺ made dua 3 times for first row — try to stand in first row!', 'color': const Color(0xFFFF8F00)});
    }

    // ══ সকালের বিশেষ reminder (ফজরের পর থেকে সকাল ৯টা) ══
    if (now.isAfter(pt.fajr) && now.hour < 9) {
      alerts.add({'icon': '📖', 'text': isBn ? 'প্রতি রাতে সূরা মুলক পড়ুন — কবরের আযাব থেকে রক্ষা করবে।' : 'Recite Surah Mulk every night — protection from grave punishment.', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ রাতের reminder (এশার পর) ══
    if (now.isAfter(pt.isha) && now.hour < 23) {
      alerts.add({'icon': '📖', 'text': isBn ? 'ঘুমানোর আগে সূরা মুলক পড়তে ভুলবেন না — কবরের আযাব থেকে রক্ষা করবে।' : 'Don\'t forget Surah Mulk before sleep — protection from grave punishment.', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ সন্ধ্যার reminder (মাগরিবের পর) ══
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      alerts.add({'icon': '🏠', 'text': isBn
          ? 'ঘরে ফেরার সুন্নত:\n◆ ডান পা দিয়ে প্রবেশ করুন\n◆ "বিসমিল্লাহি ওয়ালাজনা..." পড়ুন\n◆ পরিবারকে সালাম দিন'
          : 'Sunnah of returning home: Enter with right foot, say Bismillah, give Salam.', 'color': const Color(0xFF26A69A)});
    }

    // ══ আইয়ামে বিজ ══
    if (h >= 13 && h <= 15) {
      alerts.add({'icon': '🌙', 'text': isBn ? 'আজ আইয়ামে বিজের রোজার দিন (হিজরি $h তারিখ)! রোজা রাখুন।' : 'Today is Ayyam al-Beed (Hijri day $h)! Please fast.', 'color': AppTheme.gold});
    } else if (h == 12 && now.isAfter(pt.maghrib)) {
      alerts.add({'icon': '🌙', 'text': isBn ? 'আগামীকাল থেকে আইয়ামে বিজের রোজা (১৩-১৫ তারিখ)! সেহরির প্রস্তুতি নিন।' : 'Ayyam al-Beed starts tomorrow (13th-15th)!', 'color': AppTheme.gold});
    }

    // ══ সোম/বৃহস্পতি রোজা ══
    final isFastDay = now.weekday == DateTime.monday || now.weekday == DateTime.thursday;
    final prevDayIsSunday = now.weekday == DateTime.sunday;
    final prevDayIsWed = now.weekday == DateTime.wednesday;

    if (isFastDay && now.isBefore(pt.fajr)) {
      alerts.add({'icon': '🌿', 'text': isBn ? 'আজ ${now.weekday == DateTime.monday ? "সোমবার" : "বৃহস্পতিবার"} — নফল রোজার দিন! সেহরি খেতে ভুলবেন না।' : 'Today is ${now.weekday == DateTime.monday ? "Monday" : "Thursday"} — Nafl fast day!', 'color': const Color(0xFF7C4DFF)});
    }
    if (prevDayIsSunday && now.isAfter(pt.maghrib)) {
      alerts.add({'icon': '🌿', 'text': isBn ? 'আগামীকাল সোমবার — নফল রোজার দিন! সেহরির প্রস্তুতি নিন।' : 'Tomorrow is Monday — Nafl fast day!', 'color': const Color(0xFF7C4DFF)});
    }
    if (prevDayIsWed && now.isAfter(pt.maghrib)) {
      alerts.add({'icon': '🌿', 'text': isBn ? 'আগামীকাল বৃহস্পতিবার — নফল রোজার দিন! সেহরির প্রস্তুতি নিন।' : 'Tomorrow is Thursday — Nafl fast day!', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ জুমার দিন ══
    if (now.weekday == DateTime.friday) {
      if (now.isBefore(pt.dhuhr.add(const Duration(hours: 1, minutes: 30)))) {
        alerts.add({'icon': '🕌', 'text': isBn ? 'আজ জুমার দিন — জুমার নামাজ আদায় করুন। দরূদ ও দোয়া করুন।' : 'Today is Friday — Pray Jumu\'ah.', 'color': AppTheme.accent});
      } else if (now.isBefore(pt.maghrib)) {
        final cd = _countdown(pt.maghrib);
        alerts.add({'icon': '🕌', 'text': isBn ? 'জুমার দিন — দরূদ ও দোয়া করুন (শেষ হতে বাকি $cd)' : 'Friday — Send Salawat & dua (ends in $cd)', 'color': AppTheme.accent});
      }
      // জুমার দিন সূরা কাহাফ reminder
      if (now.hour < 20) {
        alerts.add({'icon': '📖', 'text': isBn ? 'আজ জুমার দিন — সূরা কাহাফ তেলাওয়াত করুন! কিয়ামতে নূরের আলো হবে।' : 'Friday — Recite Surah Kahaf! Light on Judgment Day.', 'color': const Color(0xFF7C4DFF)});
      }
    }

    // ══ জিলকদ শেষ হচ্ছে (২৫-২৯ জিলকদ) ══
    if (hijriMonth == 11 && h >= 25) {
      alerts.add({'icon': '🕋', 'text': isBn ? 'জিলকদ শেষ হচ্ছে — জিলহজ শুরু হলে কোরবানিদাতারা নখ, চুল ও গোঁফ কাটবেন না!' : 'Dhul Qa\'dah ending — When Dhul Hijjah starts, don\'t cut nails or hair if sacrificing!', 'color': AppTheme.gold});
    }

    // ══ জিলহজ মাসের বিশেষ আমল ══
    if (hijriMonth == 12) {
      // ১-৯ জিলহজ: সার্বক্ষণিক ফজিলতের reminder
      if (h >= 1 && h <= 9) {
        alerts.add({'icon': '🕋', 'text': isBn ? 'আজ $h জিলহজ — বছরের শ্রেষ্ঠ দিন! বেশি বেশি ইবাদত করুন। এই দিনের আমল জিহাদের চেয়েও উত্তম!' : 'Today $h Dhul Hijjah — Best days of the year! Worship is better than Jihad!', 'color': AppTheme.gold});
        // জিকিরের reminder
        alerts.add({'icon': '📿', 'text': isBn ? 'জিলহজের আমল: বেশি বেশি পড়ুন — সুবহানাল্লাহ, আলহামদুলিল্লাহ, আল্লাহু আকবার, লা ইলাহা ইল্লাল্লাহ!' : 'Dhul Hijjah Dhikr: Subhanallah, Alhamdulillah, Allahu Akbar, La ilaha illallah!', 'color': const Color(0xFF7C4DFF)});
      }

      // ১-৮ জিলহজ সেহরির আগে: রোজার reminder
      if (h >= 1 && h <= 8 && now.isBefore(pt.fajr)) {
        alerts.add({'icon': '🌙', 'text': isBn ? '$h জিলহজ — আজ রোজা রাখুন! রাসূল ﷺ জিলহজের প্রথম ৯ দিন রোজা রাখতেন।' : '$h Dhul Hijjah — Keep fast! Prophet ﷺ fasted first 9 days.', 'color': const Color(0xFF81C784)});
      }

      // ১-১০ জিলহজ: চুল-নখ না কাটার reminder
      if (h >= 1 && h <= 10) {
        alerts.add({'icon': '✂️', 'text': isBn ? 'জিলহজের সুন্নত: কুরবানি সম্পন্ন না হওয়া পর্যন্ত চুল, নখ ও গোঁফ কাটবেন না। এতে কুরবানির সওয়াব পাবেন।' : 'Dhul Hijjah Sunnah: Don\'t cut hair/nails until Qurbani.', 'color': const Color(0xFF26A69A)});
      }

      // ৮ জিলহজ সন্ধ্যায়: আরাফার রোজার আগাম reminder
      if (h == 8 && now.isAfter(pt.maghrib)) {
        alerts.add({'icon': '🕋', 'text': isBn ? 'আগামীকাল ৯ জিলহজ — আরাফার রোজা! এই রোজায় আগের ও পরের ১ বছরের গুনাহ মাফ। এখনই সেহরির প্রস্তুতি নিন!' : 'Tomorrow 9 Dhul Hijjah — Arafah fast! 2 years of sins forgiven. Prepare for Sehri!', 'color': AppTheme.gold});
      }

      // ৯ জিলহজ: আরাফার দিনের সব reminder
      if (h == 9) {
        alerts.add({'icon': '🕋', 'text': isBn ? 'আজ ৯ জিলহজ — আরাফার দিন! রোজা রাখুন, বেশি দোয়া করুন। আগের ও পরের ১ বছরের গুনাহ মাফ হবে ইনশাআল্লাহ।' : 'Today 9 Dhul Hijjah — Day of Arafah! Fast & make lots of dua. 2 years sins forgiven.', 'color': AppTheme.gold});
        // আরাফার ইফতারের আগে ৩০ মিনিট
        if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 30))) && now.isBefore(pt.maghrib)) {
          final cd = _countdown(pt.maghrib);
          alerts.add({'icon': '🤲', 'text': isBn ? 'আরাফার রোজার ইফতার হতে বাকি $cd — রোজাদার অবস্থায় এখন দোয়া করুন! এই মুহূর্তের দোয়া কবুল হয়।' : 'Arafah Iftar in $cd — Make dua now as a fasting person!', 'color': AppTheme.gold});
        }
      }

      // ৯ আসরের পর থেকে ১৩ পর্যন্ত: তাকবিরে তাশরিক
      if ((h == 9 && now.isAfter(pt.asr)) || (h >= 10 && h <= 13)) {
        alerts.add({'icon': '📢', 'text': isBn ? 'তাকবিরে তাশরিক: প্রতি ফরজ নামাজের পর পড়ুন —\nআল্লাহু আকবার, আল্লাহু আকবার, লা ইলাহা ইল্লাল্লাহু, আল্লাহু আকবার, ওয়া লিল্লাহিল হামদ' : 'Takbeer al-Tashriq after every Fard: Allahu Akbar, Allahu Akbar...', 'color': const Color(0xFFFF8F00)});
      }

      // ১০ জিলহজ: ঈদুল আযহা
      if (h == 10) {
        alerts.add({'icon': '🎉', 'text': isBn ? 'আজ ১০ জিলহজ — ঈদুল আযহা মোবারক! ঈদের নামাজ আদায় করুন। সামর্থ্য থাকলে কুরবানি করুন।' : 'Today 10 Dhul Hijjah — Eid al-Adha Mubarak! Pray Eid & sacrifice if able.', 'color': AppTheme.gold});
      }
    }

    // ══ রমজানের reminder (শাবান মাসে ২৫-২৯ তারিখ) ══
    if (hijriMonth == 8 && h >= 25) {
      alerts.add({'icon': '🌙', 'text': isBn ? 'রমজান আসছে — এখনই নিয়ত ও প্রস্তুতি নিন। রমজানে উমরাহর সওয়াব হজের সমান!' : 'Ramadan is coming — Prepare now. Umrah in Ramadan equals Hajj in reward!', 'color': const Color(0xFF7C4DFF)});
    }

    

    // ১. ফজর ওয়াক্ত
    if (now.isAfter(pt.fajr) && now.isBefore(pt.sunrise)) {
      final cd = _countdown(pt.sunrise);
      if (cd.isNotEmpty) {
        alerts.add({
          'icon': '🕌',
          'text': isBn ? 'ফজর নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Fajr ends in $cd',
          'color': AppTheme.gold,
        });
      }
    }

    // ২. যোহর ওয়াক্ত
    if (now.isAfter(pt.dhuhr) && now.isBefore(pt.asr)) {
      final cd = _countdown(pt.asr);
      if (cd.isNotEmpty) {
        alerts.add({
          'icon': '🕌',
          'text': isBn ? 'যোহর নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Dhuhr ends in $cd',
          'color': AppTheme.gold,
        });
      }
    }

    // ৩. আসর ওয়াক্ত
    if (now.isAfter(pt.asr) && now.isBefore(pt.maghrib)) {
      final cd = _countdown(pt.maghrib);
      if (cd.isNotEmpty) {
        alerts.add({
          'icon': '🕌',
          'text': isBn ? 'আসর নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Asr ends in $cd',
          'color': AppTheme.gold,
        });
      }
    }

    // ৪. মাগরিব ওয়াক্ত
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      final cd = _countdown(pt.isha);
      if (cd.isNotEmpty) {
        alerts.add({
          'icon': '🕌',
          'text': isBn ? 'মাগরিব নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Maghrib ends in $cd',
          'color': AppTheme.gold,
        });
      }
    }

    // ৫. এশা ওয়াক্ত
    if (now.isAfter(pt.isha) && now.isBefore(ishaaEnd)) {
      final cd = _countdown(ishaaEnd);
      if (cd.isNotEmpty) {
        alerts.add({
          'icon': '🕌',
          'text': isBn ? 'এশা নামাজের ওয়াক্ত শেষ হতে বাকি $cd' : 'Isha ends in $cd',
          'color': AppTheme.gold,
        });
      }
    }

    // ৬. ইশরাক
    if (now.isAfter(ishraqStart) && now.isBefore(ishraqEnd)) {
      final cd = _countdown(ishraqEnd);
      alerts.add({
        'icon': '⭐',
        'text': isBn ? 'ইশরাকের ওয়াক্ত শেষ হতে বাকি $cd — হজ্জ-উমরার সওয়াব!' : 'Ishraq ends in $cd — Hajj & Umrah reward!',
        'color': const Color(0xFFFF8F00),
      });
    }

    // ৭. দুহা/চাশত
    if (now.isAfter(chashtStart) && now.isBefore(chashtEnd)) {
      final cd = _countdown(chashtEnd);
      alerts.add({
        'icon': '☀️',
        'text': isBn ? 'দুহা/চাশতের ওয়াক্ত শেষ হতে বাকি $cd' : 'Duha/Chasht ends in $cd',
        'color': const Color(0xFFFDD835),
      });
    }

    // ৮. আওওয়াবিন
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      final cd = _countdown(pt.isha);
      alerts.add({
        'icon': '⭐',
        'text': isBn ? 'আওওয়াবিনের ওয়াক্ত শেষ হতে বাকি $cd (৬-২০ রাকাত)' : 'Awwabin ends in $cd (6-20 rakats)',
        'color': const Color(0xFF26A69A),
      });
    }

    // ৯. তাহাজ্জুদ
    if (lastThird != null) {
      final isNightTime = now.hour >= 21 || now.hour <= 6;
      if (isNightTime && now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
        final cd = _countdown(pt.fajr);
        alerts.add({
          'icon': '🌙',
          'text': isBn ? 'তাহাজ্জুদের ওয়াক্ত শেষ হতে বাকি $cd — দোয়া কবুলের সর্বোত্তম সময়!' : 'Tahajjud ends in $cd — Best time for duas!',
          'color': const Color(0xFF7C4DFF),
        });
      } else if (now.isAfter(pt.isha) && now.isBefore(lastThird)) {
        final cd = _countdown(lastThird);
        alerts.add({
          'icon': '🌙',
          'text': isBn ? 'তাহাজ্জুদের সর্বোত্তম সময় শুরু হতে বাকি $cd' : 'Best Tahajjud time starts in $cd',
          'color': const Color(0xFF7C4DFF),
        });
      }
    }

    // ১০. সেহরি
    if (now.isBefore(pt.fajr)) {
      final diff = pt.fajr.difference(now);
      if (diff.inMinutes <= 90) {
        final cd = _countdown(pt.fajr);
        alerts.add({
          'icon': '🍽️',
          'text': isBn ? 'সেহরি শেষ হতে বাকি $cd (শেষ সময়: ${_fmtTime(pt.fajr)})' : 'Sehri ends in $cd (${_fmtTime(pt.fajr)})',
          'color': const Color(0xFF81C784),
        });
      }
    }

    // ১১. ইফতার
    if (now.isAfter(pt.fajr) && now.isBefore(pt.maghrib)) {
      final diff = pt.maghrib.difference(now);
      if (diff.inMinutes <= 120) {
        final cd = _countdown(pt.maghrib);
        alerts.add({
          'icon': '🌙',
          'text': isBn ? 'ইফতার শুরু হতে বাকি $cd (${_fmtTime(pt.maghrib)})' : 'Iftar in $cd (${_fmtTime(pt.maghrib)})',
          'color': const Color(0xFF64B5F6),
        });
      }
    }

    // ১২. সূর্যোদয়
    if (now.isAfter(pt.sunrise.subtract(const Duration(minutes: 5))) &&
        now.isBefore(pt.sunrise.add(const Duration(minutes: 5)))) {
      alerts.add({
        'icon': '🌅',
        'text': isBn ? 'এখন সূর্যোদয় হচ্ছে (${_fmtTime(pt.sunrise)})' : 'Sunrise now (${_fmtTime(pt.sunrise)})',
        'color': const Color(0xFFFFB300),
      });
    }

    // ১৩. সূর্যাস্ত
    if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 5))) &&
        now.isBefore(pt.maghrib.add(const Duration(minutes: 5)))) {
      alerts.add({
        'icon': '🌇',
        'text': isBn ? 'সূর্যাস্ত — ইফতারের সময় শুরু! (${_fmtTime(pt.maghrib)})' : 'Sunset — Iftar time! (${_fmtTime(pt.maghrib)})',
        'color': const Color(0xFFFF7043),
      });
    }

    // ১৪. নিষিদ্ধ সময়
    if (now.isAfter(pt.fajr) && now.isBefore(pt.sunrise)) {
      final cd = _countdown(pt.sunrise);
      alerts.add({
        'icon': '⛔',
        'text': isBn ? 'নামাজের নিষিদ্ধ সময় — ফজর ব্যতীত — শেষ হতে বাকি $cd' : 'Forbidden — Except Fajr — ends in $cd',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(pt.sunrise) && now.isBefore(sunriseForbiddenEnd)) {
      final cd = _countdown(sunriseForbiddenEnd);
      alerts.add({
        'icon': '⛔',
        'text': isBn ? 'নামাজের নিষিদ্ধ সময় — সূর্যোদয়কালীন — শেষ হতে বাকি $cd' : 'Forbidden — Sunrise — ends in $cd',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(zawalStart) && now.isBefore(zawalEnd)) {
      final cd = _countdown(zawalEnd);
      alerts.add({
        'icon': '⛔',
        'text': isBn ? 'নামাজের নিষিদ্ধ সময় — দ্বিপ্রহর — শেষ হতে বাকি $cd' : 'Forbidden — Noon — ends in $cd',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(pt.asr) && now.isBefore(sunsetForbiddenStart)) {
      final cd = _countdown(pt.maghrib);
      alerts.add({
        'icon': '⛔',
        'text': isBn ? 'নামাজের নিষিদ্ধ সময় — আসর ব্যতীত — শেষ হতে বাকি $cd' : 'Forbidden — Except Asr — ends in $cd',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(sunsetForbiddenStart) && now.isBefore(pt.maghrib)) {
      final cd = _countdown(pt.maghrib);
      alerts.add({
        'icon': '⛔',
        'text': isBn ? 'নামাজের নিষিদ্ধ সময় — সূর্যাস্তকালীন — শেষ হতে বাকি $cd' : 'Forbidden — Sunset — ends in $cd',
        'color': AppTheme.missed,
      });
    }

    // ১৫. পরবর্তী নামাজ ১৫ মিনিটের মধ্যে
    final next = PrayerTimeHelper.getNextPrayer(pt);
    final remaining = PrayerTimeHelper.getTimeToNextPrayer(pt);
    if (next != null && remaining != null && remaining.inMinutes <= 15) {
      final names = {
        'fajr': isBn ? 'ফজর' : 'Fajr',
        'dhuhr': isBn ? 'যোহর' : 'Dhuhr',
        'asr': isBn ? 'আসর' : 'Asr',
        'maghrib': isBn ? 'মাগরিব' : 'Maghrib',
        'isha': isBn ? 'এশা' : 'Isha',
      };
      final nextTime = PrayerTimeHelper.getPrayerTimesMap(pt)[next];
      final cd = nextTime != null ? _countdown(nextTime) : '';
      alerts.add({
        'icon': '🕌',
        'text': isBn
            ? '${names[next]} নামাজের সময় হতে বাকি $cd ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""}'
            : '${names[next]} in $cd ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""}',
        'color': AppTheme.accent,
      });
    }

    // ১৬. আইয়ামে বিজ
    if (h >= 13 && h <= 15) {
      alerts.add({
        'icon': '🌙',
        'text': isBn ? 'আজ আইয়ামে বিজের রোজার দিন (হিজরি $h তারিখ)! রোজা রাখুন।' : 'Today is Ayyam al-Beed (Hijri day $h)! Please fast.',
        'color': AppTheme.gold,
      });
    } else if (h == 12 && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌙',
        'text': isBn ? 'আগামীকাল থেকে আইয়ামে বিজের রোজা (১৩-১৫ তারিখ)!' : 'Ayyam al-Beed starts tomorrow (13th-15th)!',
        'color': AppTheme.gold,
      });
    }

    // ১৭. সোম/বৃহস্পতি
    final isFastDay = now.weekday == DateTime.monday || now.weekday == DateTime.thursday;
    final prevDayIsSunday = now.weekday == DateTime.sunday;
    final prevDayIsWed = now.weekday == DateTime.wednesday;

    if (isFastDay && now.isBefore(pt.fajr)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আজ ${now.weekday == DateTime.monday ? "সোমবার" : "বৃহস্পতিবার"} — নফল রোজার দিন! সেহরি খেতে ভুলবেন না।'
            : 'Today is ${now.weekday == DateTime.monday ? "Monday" : "Thursday"} — Nafl fast day!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    if (prevDayIsSunday && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn ? 'আগামীকাল সোমবার — নফল রোজার দিন! সেহরির প্রস্তুতি নিন।' : 'Tomorrow is Monday — Nafl fast day!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    if (prevDayIsWed && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn ? 'আগামীকাল বৃহস্পতিবার — নফল রোজার দিন! সেহরির প্রস্তুতি নিন।' : 'Tomorrow is Thursday — Nafl fast day!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // ১৮. জুমার দিন
    if (now.weekday == DateTime.friday) {
      if (now.isBefore(pt.dhuhr.add(const Duration(hours: 1, minutes: 30)))) {
        alerts.add({
          'icon': '🕌',
          'text': isBn ? 'আজ জুমার দিন — জুমার নামাজ আদায় করুন। দরূদ ও দোয়া করুন।' : 'Today is Friday — Pray Jumu\'ah.',
          'color': AppTheme.accent,
        });
      } else if (now.isBefore(pt.maghrib)) {
        final cd = _countdown(pt.maghrib);
        alerts.add({
          'icon': '🕌',
          'text': isBn ? 'জুমার দিন — দরূদ ও দোয়া করুন (শেষ হতে বাকি $cd)' : 'Friday — Send Salawat & dua (ends in $cd)',
          'color': AppTheme.accent,
        });
      }
    }

    // ══ জিলহজ মাসের বিশেষ আমল ══
    if (hijriMonth == 12) {
      // ১-৯ জিলহজ: প্রথম দিনগুলোর ফজিলত
      if (h >= 1 && h <= 9) {
        alerts.add({
          'icon': '🕋',
          'text': isBn
              ? 'আজ $h জিলহজ — বছরের শ্রেষ্ঠ দিন! বেশি বেশি ইবাদত, জিকির ও দান-সদকা করুন।'
              : 'Today is $h Dhul Hijjah — Best days of the year! More worship, dhikr & charity.',
          'color': AppTheme.gold,
        });
      }

      // ১-৮ জিলহজ সেহরির আগে: রোজার reminder
      if (h >= 1 && h <= 8 && now.isBefore(pt.fajr)) {
        alerts.add({
          'icon': '🌙',
          'text': isBn
              ? '$h জিলহজ — আজ রোজা রাখুন! রাসূল ﷺ জিলহজের প্রথম ৯ দিন রোজা রাখতেন।'
              : '$h Dhul Hijjah — Keep fast today! Prophet ﷺ fasted first 9 days.',
          'color': const Color(0xFF81C784),
        });
      }

      // ৮ জিলহজ সন্ধ্যায়: আরাফার রোজার reminder
      if (h == 8 && now.isAfter(pt.maghrib)) {
        alerts.add({
          'icon': '🕋',
          'text': isBn
              ? 'আগামীকাল ৯ জিলহজ — আরাফার রোজা! আগের ও পরের ১ বছরের গুনাহ মাফ। সেহরির প্রস্তুতি নিন!'
              : 'Tomorrow 9 Dhul Hijjah — Arafah fast! 2 years of sins forgiven. Prepare for Sehri!',
          'color': AppTheme.gold,
        });
      }

      // ৯ জিলহজ: আরাফার দিন
      if (h == 9) {
        alerts.add({
          'icon': '🕋',
          'text': isBn
              ? 'আজ ৯ জিলহজ — আরাফার দিন! রোজা রাখুন, বেশি দোয়া করুন। আগের ও পরের ১ বছরের গুনাহ মাফ।'
              : 'Today 9 Dhul Hijjah — Day of Arafah! Fast & make lots of dua. 2 years sins forgiven.',
          'color': AppTheme.gold,
        });
      }

      // ৯ আসরের পর থেকে ১৩ পর্যন্ত: তাকবিরে তাশরিক
      if ((h == 9 && now.isAfter(pt.asr)) || (h >= 10 && h <= 13)) {
        alerts.add({
          'icon': '📢',
          'text': isBn
              ? 'তাকবিরে তাশরিক: প্রতি ফরজ নামাজের পর পড়ুন — আল্লাহু আকবার, আল্লাহু আকবার, লা ইলাহা ইল্লাল্লাহু, আল্লাহু আকবার, ওয়া লিল্লাহিল হামদ'
              : 'Takbeer al-Tashriq after every Fard: Allahu Akbar, Allahu Akbar, La ilaha illallah...',
          'color': const Color(0xFFFF8F00),
        });
      }

      // ১০ জিলহজ: ঈদুল আযহা
      if (h == 10) {
        alerts.add({
          'icon': '🎉',
          'text': isBn
              ? 'আজ ১০ জিলহজ — ঈদুল আযহা মোবারক! ঈদের নামাজ আদায় করুন। সামর্থ্য থাকলে কুরবানি করুন।'
              : 'Today 10 Dhul Hijjah — Eid al-Adha Mubarak! Pray Eid & sacrifice if able.',
          'color': AppTheme.gold,
        });
      }

      // ১-১০ জিলহজ সকালে: চুল-নখ না কাটার reminder
      if (h >= 1 && h <= 10 && now.hour >= 6 && now.hour <= 9) {
        alerts.add({
          'icon': '✂️',
          'text': isBn
              ? 'জিলহজের সুন্নত: কুরবানি সম্পন্ন না হওয়া পর্যন্ত চুল, নখ ও গোঁফ কাটবেন না।'
              : 'Dhul Hijjah Sunnah: Don\'t cut hair, nails until Qurbani — earn its reward.',
          'color': const Color(0xFF26A69A),
        });
      }

      // ১-৯ জিলহজ সকালে: জিকিরের reminder
      if (h >= 1 && h <= 9 && now.hour >= 7 && now.hour <= 8) {
        alerts.add({
          'icon': '📿',
          'text': isBn
              ? 'জিলহজের আমল: বেশি বেশি পড়ুন — সুবহানাল্লাহ, আলহামদুলিল্লাহ, আল্লাহু আকবার, লা ইলাহা ইল্লাল্লাহ!'
              : 'Dhul Hijjah: Increase Tasbih, Tahmid, Takbir, Tahlil!',
          'color': const Color(0xFF7C4DFF),
        });
      }

      // ৯ জিলহজ ইফতারের ৩০ মিনিট আগে: বিশেষ দোয়া
      if (h == 9 &&
          now.isAfter(pt.maghrib.subtract(const Duration(minutes: 30))) &&
          now.isBefore(pt.maghrib)) {
        final cd = _countdown(pt.maghrib);
        alerts.add({
          'icon': '🤲',
          'text': isBn
              ? 'আরাফার রোজার ইফতার হতে বাকি $cd — রোজাদার অবস্থায় দোয়া করুন!'
              : 'Arafah Iftar in $cd — Make dua now as a fasting person!',
          'color': AppTheme.gold,
        });
      }
    }

    // Default
    if (alerts.isEmpty && next != null && remaining != null) {
      final names = {
        'fajr': isBn ? 'ফজর' : 'Fajr',
        'dhuhr': isBn ? 'যোহর' : 'Dhuhr',
        'asr': isBn ? 'আসর' : 'Asr',
        'maghrib': isBn ? 'মাগরিব' : 'Maghrib',
        'isha': isBn ? 'এশা' : 'Isha',
      };
      final nextTime = PrayerTimeHelper.getPrayerTimesMap(pt)[next];
      final cd = nextTime != null ? _countdown(nextTime) : '';
      alerts.add({
        'icon': '🕌',
        'text': isBn
            ? 'পরবর্তী নামাজ: ${names[next]} ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""} — বাকি $cd'
            : 'Next: ${names[next]} ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""} — in $cd',
        'color': AppTheme.accent,
      });
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final now = widget.now;
    final alerts = _getLiveAlerts(lang);

    return SafeArea(
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(lang.bismillah,
                style: const TextStyle(fontSize: 20, color: AppTheme.gold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(lang.prayerCount(widget.userName),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),

            if (alerts.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: alerts.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['icon'] as String, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          a['text'] as String,
                          style: TextStyle(
                              color: a['color'] as Color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        )),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            _ClockCard(now: now, lang: lang, prayerTimes: _prayerTimes, hijriDate: _hijriDate),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: _PendingCard(
                label: lang.namazBaki, count: widget.namazPending,
                suffix: lang.wakt, color: AppTheme.missed,
                icon: Icons.mosque, lang: lang,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MissedListScreen(lang: lang, type: 'prayer'),
                )).then((_) => widget.onRefresh()),
              )),
              const SizedBox(width: 12),
              Expanded(child: _PendingCard(
                label: lang.rozaBaki, count: widget.rozaPending,
                suffix: '', color: AppTheme.pending,
                icon: Icons.brightness_3, lang: lang,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MissedListScreen(lang: lang, type: 'roza'),
                )).then((_) => widget.onRefresh()),
              )),
            ]),
            const SizedBox(height: 12),

            _PrayerTimesCard(lang: lang, prayerTimes: _prayerTimes, sunnahTimes: _sunnahTimes),
            const SizedBox(height: 12),

            _TodaySection(
              lang: lang, todayPrayers: _todayPrayers,
              todayRoza: _todayRoza, prayerTimes: _prayerTimes,
              onSetPrayer: _setPrayer, onSetRoza: _setRoza,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _ClockCard extends StatelessWidget {
  final DateTime now;
  final AppLanguage lang;
  final PrayerTimes? prayerTimes;
  final String hijriDate;

  const _ClockCard({
    required this.now, required this.lang,
    required this.prayerTimes, required this.hijriDate,
  });

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    final sunrise = prayerTimes?.sunrise;
    final maghrib = prayerTimes?.maghrib;
    final fajr = prayerTimes?.fajr;
    const sunColor = AppTheme.gold;
    const fastColor = Color(0xFF00E676);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.3), AppTheme.cardBg],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(children: [
        Text(DateHelper.formatTime12(now, bangla: isBn),
            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(lang.dayName(now.weekday), style: TextStyle(
          fontSize: 18,
          color: now.weekday == DateTime.friday ? AppTheme.accent : Colors.white70,
          fontWeight: FontWeight.w700, letterSpacing: 1,
        )),
        const SizedBox(height: 10),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateHelper.formatGregorian(now, bangla: isBn),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(hijriDate.isEmpty ? DateHelper.toHijri(now, bangla: isBn) : hijriDate,
                    style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateHelper.toBangla(now),
                    style: const TextStyle(color: Color(0xFF80DEEA), fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            )),
            Container(width: 1, height: 125, color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 10)),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timeRow('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise',
                    sunrise != null ? PrayerTimeHelper.formatTime(sunrise) : '--', sunColor),
                const SizedBox(height: 3),
                _timeRow('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset',
                    maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--', sunColor),
                const SizedBox(height: 8),
                _timeRow('🍽️', isBn ? 'সেহরি' : 'Sehri',
                    fajr != null ? PrayerTimeHelper.formatTime(fajr) : '--', fastColor),
                const SizedBox(height: 3),
                _timeRow('🌙', isBn ? 'ইফতার' : 'Iftar',
                    maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--', fastColor),
              ],
            )),
          ],
        ),
      ]),
    );
  }

  Widget _timeRow(String icon, String label, String time, Color color) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Flexible(child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(children: [
          TextSpan(text: '$label ', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
          TextSpan(text: time, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════
class _PendingCard extends StatelessWidget {
  final String label, suffix;
  final int count;
  final Color color;
  final IconData icon;
  final AppLanguage lang;
  final VoidCallback onTap;

  const _PendingCard({
    required this.label, required this.count, required this.suffix,
    required this.color, required this.icon, required this.lang, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 6),
          Text(lang.toLocalNum(count),
              style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold)),
          if (suffix.isNotEmpty)
            Text(suffix, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _PrayerTimesCard extends StatelessWidget {
  final AppLanguage lang;
  final PrayerTimes? prayerTimes;
  final SunnahTimes? sunnahTimes;

  const _PrayerTimesCard({
    required this.lang, required this.prayerTimes, required this.sunnahTimes,
  });

  String _fmt(DateTime t) => PrayerTimeHelper.formatTime(t);

  String _prayerName(String key) {
    switch (key) {
      case 'fajr': return lang.fajr;
      case 'dhuhr': return lang.dhuhr;
      case 'asr': return lang.asr;
      case 'maghrib': return lang.maghrib;
      case 'isha': return lang.isha;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    if (prayerTimes == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    final prayers = [
      {'key': 'fajr', 'start': prayerTimes!.fajr, 'end': prayerTimes!.sunrise},
      {'key': 'dhuhr', 'start': prayerTimes!.dhuhr, 'end': prayerTimes!.asr},
      {'key': 'asr', 'start': prayerTimes!.asr, 'end': prayerTimes!.maghrib},
      {'key': 'maghrib', 'start': prayerTimes!.maghrib, 'end': prayerTimes!.isha},
      {'key': 'isha', 'start': prayerTimes!.isha,
        'end': sunnahTimes?.lastThirdOfTheNight ?? prayerTimes!.fajr},
    ];

    final nextPrayer = PrayerTimeHelper.getNextPrayer(prayerTimes!);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.4),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            Expanded(child: Text(isBn ? 'নামাজ' : 'Prayer',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15))),
            SizedBox(width: 85, child: Text(isBn ? 'শুরু' : 'Start',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center)),
            SizedBox(width: 85, child: Text(isBn ? 'শেষ' : 'End',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center)),
          ]),
        ),
        ...prayers.map((p) {
          final isNext = nextPrayer == p['key'];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNext ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(children: [
              Expanded(child: Row(children: [
                if (isNext) const Icon(Icons.arrow_right, color: AppTheme.accent, size: 20),
                Text(_prayerName(p['key'] as String), style: TextStyle(
                  color: isNext ? AppTheme.gold : AppTheme.textPrimary,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                )),
              ])),
              SizedBox(width: 85, child: Text(_fmt(p['start'] as DateTime),
                  style: TextStyle(color: isNext ? AppTheme.accent : AppTheme.textPrimary, fontSize: 14),
                  textAlign: TextAlign.center)),
              SizedBox(width: 85, child: Text(_fmt(p['end'] as DateTime),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center)),
            ]),
          );
        }),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            const Divider(color: Colors.white10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _chip('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise', _fmt(prayerTimes!.sunrise)),
              _chip('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset', _fmt(prayerTimes!.maghrib)),
              _chip('🍽️', isBn ? 'সেহরি' : 'Sehri', _fmt(prayerTimes!.fajr)),
              _chip('🌙', isBn ? 'ইফতার' : 'Iftar', _fmt(prayerTimes!.maghrib)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String icon, String label, String time) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      Text(time, style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ═══════════════════════════════════════════
class _TodaySection extends StatelessWidget {
  final AppLanguage lang;
  final Map<String, String> todayPrayers;
  final String? todayRoza;
  final PrayerTimes? prayerTimes;
  final Function(String, String) onSetPrayer;
  final Function(String) onSetRoza;

  const _TodaySection({
    required this.lang, required this.todayPrayers, required this.todayRoza,
    required this.prayerTimes, required this.onSetPrayer, required this.onSetRoza,
  });

  String _prayerName(String key) {
    switch (key) {
      case 'fajr': return lang.fajr;
      case 'dhuhr': return lang.dhuhr;
      case 'asr': return lang.asr;
      case 'maghrib': return lang.maghrib;
      case 'isha': return lang.isha;
      default: return key;
    }
  }

  String _prayerTime(String key) {
    if (prayerTimes == null) return '';
    switch (key) {
      case 'fajr': return PrayerTimeHelper.formatTime(prayerTimes!.fajr);
      case 'dhuhr': return PrayerTimeHelper.formatTime(prayerTimes!.dhuhr);
      case 'asr': return PrayerTimeHelper.formatTime(prayerTimes!.asr);
      case 'maghrib': return PrayerTimeHelper.formatTime(prayerTimes!.maghrib);
      case 'isha': return PrayerTimeHelper.formatTime(prayerTimes!.isha);
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final isBn = lang.isBn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.today, color: AppTheme.gold, size: 22),
          const SizedBox(width: 8),
          Text(isBn ? 'আজকের নামাজ ও রোজা' : "Today's Prayer & Fasting",
              style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        ...prayers.map((prayer) => _TodayPrayerRow(
          name: _prayerName(prayer), time: _prayerTime(prayer),
          status: todayPrayers[prayer], lang: lang,
          onAdai: () => onSetPrayer(prayer, 'prayed'),
          onQaza: () => onSetPrayer(prayer, 'missed'),
        )),
        const Divider(color: Colors.white12),
        const SizedBox(height: 4),
        _TodayPrayerRow(
          name: lang.roza, time: '', status: todayRoza, lang: lang,
          onAdai: () => onSetRoza('prayed'),
          onQaza: () => onSetRoza('missed'),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
class _TodayPrayerRow extends StatelessWidget {
  final String name, time;
  final String? status;
  final AppLanguage lang;
  final VoidCallback onAdai, onQaza;

  const _TodayPrayerRow({
    required this.name, required this.time, required this.status,
    required this.lang, required this.onAdai, required this.onQaza,
  });

  @override
  Widget build(BuildContext context) {
    final isAdai = status == 'prayed';
    final isQaza = status == 'missed';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(
              color: isAdai ? AppTheme.completed : isQaza ? AppTheme.missed : AppTheme.textPrimary,
              fontSize: 16, fontWeight: FontWeight.w500)),
            if (time.isNotEmpty)
              Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        )),
        _CircleBtn(icon: Icons.check, label: lang.isBn ? 'আদায়' : 'Prayed',
            color: AppTheme.completed, selected: isAdai, onTap: onAdai),
        const SizedBox(width: 12),
        _CircleBtn(icon: Icons.close, label: lang.isBn ? 'কাযা' : 'Qaza',
            color: AppTheme.missed, selected: isQaza, onTap: onQaza),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon, required this.label, required this.color,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: selected ? 2.5 : 1.5),
            boxShadow: selected
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                : [],
          ),
          child: Icon(icon, color: selected ? Colors.white : color, size: 26),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(
          color: selected ? color : AppTheme.textSecondary,
          fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
class _HijriSimple {
  static int fromDate(DateTime date) {
    try {
      final jd = _gjToJul(date.year, date.month, date.day);
      final l = jd - 1948440 + 10632;
      final n = (l - 1) ~/ 10631;
      final l2 = l - 10631 * n + 354;
      final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
          ((l2) ~/ 5670) * ((43 * l2) ~/ 15238);
      final l3 = l2 - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
          ((j) ~/ 16) * ((15238 * j) ~/ 43) + 29;
      final m = (24 * l3) ~/ 709;
      return l3 - (709 * m) ~/ 24;
    } catch (_) {
      return 0;
    }
  }

  static int getMonth(DateTime date) {
    try {
      final jd = _gjToJul(date.year, date.month, date.day);
      final l = jd - 1948440 + 10632;
      final n = (l - 1) ~/ 10631;
      final l2 = l - 10631 * n + 354;
      final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
          ((l2) ~/ 5670) * ((43 * l2) ~/ 15238);
      final l3 = l2 - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
          ((j) ~/ 16) * ((15238 * j) ~/ 43) + 29;
      final m = (24 * l3) ~/ 709;
      return m;
    } catch (_) {
      return 0;
    }
  }

  static int _gjToJul(int y, int m, int d) {
    int a = (14 - m) ~/ 12;
    int yr = y + 4800 - a;
    int mo = m + 12 * a - 3;
    return d + (153 * mo + 2) ~/ 5 + 365 * yr + yr ~/ 4 - yr ~/ 100 + yr ~/ 400 - 32045;
  }
}
