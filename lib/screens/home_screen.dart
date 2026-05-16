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
      if (startIsToday &&
          now.isAfter(start) &&
          now.isAfter(end) &&
          currentStatus == null) {
        await DatabaseHelper.setPrayerStatus(dateKey, prayer, 'missed');
        changed = true;
      }
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = DateHelper.dateKey(yesterday);
    final yesterdayStatuses =
        await DatabaseHelper.getDayPrayerStatuses(yesterdayKey);
    if (yesterdayStatuses['isha'] == null && now.isAfter(pt.fajr)) {
      await DatabaseHelper.setPrayerStatus(yesterdayKey, 'isha', 'missed');
      changed = true;
    }

    final ishaStatus = statuses['isha'];
    final ishaStart = pt.isha;
    final ishaStartIsToday = DateHelper.dateKey(ishaStart) == dateKey;
    final midNight = DateTime(now.year, now.month, now.day, 23, 59);
    if (ishaStartIsToday &&
        now.isAfter(ishaStart) &&
        now.isAfter(midNight) &&
        ishaStatus == null) {
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

    final ishraqStart = pt.sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = pt.sunrise.add(const Duration(minutes: 45));
    final chashtStart = pt.sunrise.add(const Duration(minutes: 45));
    final chashtEnd = pt.dhuhr.subtract(const Duration(minutes: 10));
    final sunriseForbiddenEnd = pt.sunrise.add(const Duration(minutes: 15));
    final zawalStart = pt.dhuhr.subtract(const Duration(minutes: 5));
    final zawalEnd = pt.dhuhr;
    final sunsetForbiddenStart = pt.maghrib.subtract(const Duration(minutes: 15));
    final ishaaEnd = lastThird ?? pt.fajr.add(const Duration(days: 1));

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
      if (now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
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

    // ১৯. হিজরি মাস ভিত্তিক বিশেষ নোটিফিকেশন
    final hijriMonth = _HijriSimple.getMonth(now);
    final hijriDay = h;

    // জিলহজ মাস — নখ-চুল কাটা নিষেধ
    if (hijriMonth == 12 && hijriDay >= 1 && hijriDay <= 10) {
      alerts.add({
        'icon': '✂️',
        'text': isBn
            ? 'জিলহজের ১-১০ তারিখ চলছে — যারা কোরবানি করবেন তারা নখ ও চুল কাটবেন না!'
            : 'Dhul Hijjah 1-10: Do not cut nails/hair if you plan to sacrifice.',
        'color': const Color(0xFFE65100),
      });
    }

    // জিলহজ শেষ হওয়ার আগে সতর্কতা
    if (hijriMonth == 11 && hijriDay >= 28) {
      alerts.add({
        'icon': '⚠️',
        'text': isBn
            ? 'জিলকদ শেষ হচ্ছে — জিলহজ শুরু হলে কোরবানিদাতারা নখ ও চুল কাটবেন না!'
            : 'Dhul Qa\'dah ending — Dhul Hijjah starts soon. Stop cutting nails/hair if sacrificing.',
        'color': const Color(0xFFE65100),
      });
    }

    // জিলহজের ৯ তারিখ — আরাফার দিন
    if (hijriMonth == 12 && hijriDay == 9) {
      alerts.add({
        'icon': '🕋',
        'text': isBn
            ? 'আজ আরাফার দিন! রোজা রাখুন — দুই বছরের গুনাহ মাফ হবে।'
            : 'Today is the Day of Arafah! Fast today — sins of 2 years forgiven.',
        'color': AppTheme.gold,
      });
    }

    // জিলহজের ১০ তারিখ — ঈদুল আযহা
    if (hijriMonth == 12 && hijriDay == 10) {
      alerts.add({
        'icon': '🐑',
        'text': isBn
            ? 'আজ ঈদুল আযহা — কোরবানির দিন! রোজা রাখা নিষেধ।'
            : 'Today is Eid al-Adha — Day of sacrifice! Fasting is forbidden.',
        'color': AppTheme.gold,
      });
    }

    // জিলহজের ১১-১৩ তারিখ — আইয়ামে তাশরিক
    if (hijriMonth == 12 && hijriDay >= 11 && hijriDay <= 13) {
      alerts.add({
        'icon': '🐑',
        'text': isBn
            ? 'আইয়ামে তাশরিক (${hijriDay} জিলহজ) — কোরবানির দিন। রোজা রাখা নিষেধ।'
            : 'Ayyam al-Tashriq (${hijriDay} Dhul Hijjah) — Fasting is forbidden.',
        'color': const Color(0xFFFF8F00),
      });
    }

    // রমজান মাস
    if (hijriMonth == 9) {
      if (hijriDay <= 10) {
        alerts.add({
          'icon': '🌙',
          'text': isBn ? 'রমজানের প্রথম দশক — রহমতের দশক চলছে!' : 'First 10 days of Ramadan — Days of Mercy!',
          'color': const Color(0xFF7C4DFF),
        });
      } else if (hijriDay <= 20) {
        alerts.add({
          'icon': '🌙',
          'text': isBn ? 'রমজানের দ্বিতীয় দশক — মাগফিরাতের দশক চলছে!' : 'Second 10 days of Ramadan — Days of Forgiveness!',
          'color': const Color(0xFF7C4DFF),
        });
      } else {
        alerts.add({
          'icon': '🌙',
          'text': isBn ? 'রমজানের শেষ দশক — নাজাতের দশক। লাইলাতুল কদর অন্বেষণ করুন!' : 'Last 10 days of Ramadan — Seek Laylatul Qadr!',
          'color': AppTheme.gold,
        });
      }
      if (hijriDay % 2 != 0 && hijriDay >= 21) {
        alerts.add({
          'icon': '✨',
          'text': isBn ? 'আজ রমজানের বিজোড় রাত — লাইলাতুল কদর হতে পারে! বেশি ইবাদত করুন।' : 'Odd night of last 10 — Possible Laylatul Qadr!',
          'color': AppTheme.gold,
        });
      }
    }

    // শাবান মাস
    if (hijriMonth == 8 && hijriDay == 15) {
      alerts.add({
        'icon': '🌟',
        'text': isBn ? 'আজ শবে বরাত (১৫ শাবান) — রাতে বেশি ইবাদত করুন।' : 'Tonight is Shab-e-Barat (15 Sha\'ban) — Night of Forgiveness.',
        'color': const Color(0xFF7C4DFF),
      });
    }
    if (hijriMonth == 8 && hijriDay == 14 && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌟',
        'text': isBn ? 'আজ রাতেই শবে বরাত শুরু — ইবাদতের প্রস্তুতি নিন!' : 'Shab-e-Barat starts tonight! Prepare for worship.',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // রজব মাস
    if (hijriMonth == 7 && hijriDay == 27) {
      alerts.add({
        'icon': '🕌',
        'text': isBn ? 'আজ রাতে শবে মেরাজ (২৭ রজব) — বিশেষ ইবাদত করুন।' : 'Tonight is Shab-e-Miraj (27 Rajab) — Night of Ascension.',
        'color': AppTheme.gold,
      });
    }

    // মহররম মাস
    if (hijriMonth == 1 && (hijriDay == 9 || hijriDay == 10)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আশুরার রোজা (${hijriDay} মহররম) — গত বছরের গুনাহ মাফ হবে!'
            : 'Day of Ashura (${hijriDay} Muharram) — Sins of past year forgiven!',
        'color': const Color(0xFF00BCD4),
      });
    }
    if (hijriMonth == 1 && hijriDay == 8 && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn ? 'আগামীকাল আশুরার রোজা (৯ ও ১০ মহররম) — প্রস্তুতি নিন!' : 'Ashura fast tomorrow (9th & 10th Muharram)!',
        'color': const Color(0xFF00BCD4),
      });
    }

    // ঈদুল ফিতর
    if (hijriMonth == 10 && hijriDay == 1) {
      alerts.add({
        'icon': '🎉',
        'text': isBn ? 'আজ ঈদুল ফিতর! ঈদের নামাজ আদায় করুন। রোজা রাখা নিষেধ।' : 'Today is Eid al-Fitr! Pray Eid salah. Fasting is forbidden.',
        'color': AppTheme.gold,
      });
    }

    // রমজানের আগে প্রস্তুতি
    if (hijriMonth == 8 && hijriDay >= 25) {
      alerts.add({
        'icon': '🌙',
        'text': isBn ? 'রমজান আসছে! শাবানের রোজা রেখে প্রস্তুতি নিন।' : 'Ramadan is coming! Prepare with Sha\'ban fasts.',
        'color': const Color(0xFF7C4DFF),
      });
    }
    
    // ২০. তাহাজ্জুদ ঠিকঠাক (রাত ১টা সমস্যা fix)
    if (lastThird != null && now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
      final cd = _countdown(pt.fajr);
      alerts.removeWhere((a) => (a['text'] as String).contains('তাহাজ্জুদ'));
      alerts.add({
        'icon': '🌙',
        'text': isBn
            ? 'এখন তাহাজ্জুদের সময় চলছে! ফজর শুরু হতে বাকি $cd — উঠুন, ওযু করুন, ২-১২ রাকাত পড়ুন। দোয়া কবুলের সর্বোত্তম সময়!'
            : 'Tahajjud time now! Fajr in $cd — Wake up, 2-12 rakats. Best time for duas!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // ২১. সূরা মুলক — সন্ধ্যার পর থেকে রাত ১১টা পর্যন্ত
    if (now.isAfter(pt.maghrib) && now.hour < 23) {
      alerts.add({
        'icon': '📖',
        'text': isBn
            ? 'প্রতি রাতে ঘুমানোর আগে সূরা মুলক তেলাওয়াত করুন — কবরের আযাব থেকে রক্ষা করবে।'
            : 'Recite Surah Mulk before sleeping — protects from grave punishment.',
        'color': const Color(0xFF26A69A),
      });
    }

    // ২২. ঘুমানোর আগে আমল — রাত ৯টা থেকে রাত ১২টা
    if (now.hour >= 21 && now.hour < 24) {
      alerts.add({
        'icon': '😴',
        'text': isBn
            ? 'ঘুমানোর আগে আমল:\n• আয়াতুল কুরসি পড়ুন\n• সূরা মুলক পড়ুন\n• ৩৩ বার সুবহানাল্লাহ, আলহামদুলিল্লাহ, আল্লাহু আকবার পড়ুন\n• ডান কাত হয়ে শোন'
            : 'Bedtime amal: Ayatul Kursi, Surah Mulk, 33x Tasbih, sleep on right side.',
        'color': const Color(0xFF5C6BC0),
      });
    }

    // ২৩. জামাতে নামাজের ফযিলত — দুপুর ১২টা থেকে আসরের আগে পর্যন্ত
    if (now.hour >= 12 && now.isBefore(pt.asr)) {
      alerts.add({
        'icon': '🕌',
        'text': isBn
            ? 'জামাতে নামাজ পড়লে একাকী পড়ার চেয়ে ২৭ গুণ বেশি সওয়াব — মসজিদে যান!'
            : 'Congregational prayer = 27x more reward — Go to the mosque!',
        'color': AppTheme.accent,
      });
    }

    // ২৪. জুমার দিনের বিশেষ আমল — শুক্রবার ফজরের পর থেকে
    if (now.weekday == DateTime.friday) {
      // ফজরের পর থেকে যোহরের আগে
      if (now.isAfter(pt.fajr) && now.isBefore(pt.dhuhr)) {
        alerts.add({
          'icon': '📖',
          'text': isBn
              ? 'জুমার দিন সূরা কাহাফ তেলাওয়াত করুন — দুই জুমার মধ্যবর্তী সময়ের গুনাহ মাফ হবে!'
              : 'Recite Surah Kahf today — sins between 2 Fridays forgiven!',
          'color': AppTheme.gold,
        });
        alerts.add({
          'icon': '🕌',
          'text': isBn
              ? 'জুমার সুন্নত আমল:\n• গোসল করুন\n• পরিষ্কার কাপড় পরুন\n• সুগন্ধি ব্যবহার করুন\n• আগে মসজিদে যান\n• বেশি দরূদ পড়ুন'
              : "Friday Sunnah: Ghusl, clean clothes, perfume, early to mosque, send Salawat.",
          'color': AppTheme.accent,
        });
      }

      // আসরের পর থেকে মাগরিব পর্যন্ত
      if (now.isAfter(pt.asr) && now.isBefore(pt.maghrib)) {
        final cd = _countdown(pt.maghrib);
        alerts.add({
          'icon': '🤲',
          'text': isBn
              ? 'জুমার দিন আসরের পর দোয়ায় মশগুল থাকুন (শেষ হতে বাকি $cd) — এই সময়ের দোয়া কবুল হয়! রাসূল ﷺ বলেছেন এটি দোয়া কবুলের বিশেষ মুহূর্ত।'
              : 'Friday after Asr — special time for dua (ends in $cd)! Rasul ﷺ said this is the golden hour.',
          'color': AppTheme.gold,
        });
      }

      // জুমার রাত — মাগরিবের পর
      if (now.isAfter(pt.maghrib)) {
        alerts.add({
          'icon': '⭐',
          'text': isBn
              ? 'জুমার রাত — বেশি বেশি দরূদ পড়ুন। রাসূল ﷺ বলেছেন: জুমার দিন ও রাতে বেশি দরূদ পড়ো।'
              : "Friday night — Recite many Salawat. Rasul ﷺ said: Send many blessings on Friday.",
          'color': AppTheme.accent,
        });
      }
    }

    // ২৫. সোমবার ও বৃহস্পতিবার — নফল রোজার দিন সকাল থেকে
    if ((now.weekday == DateTime.monday || now.weekday == DateTime.thursday) &&
        now.isAfter(pt.fajr) && now.isBefore(pt.maghrib)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আজ নফল রোজার দিন (${now.weekday == DateTime.monday ? "সোমবার" : "বৃহস্পতিবার"}) — রোজা রাখলে আমলনামা আল্লাহর কাছে পেশ হবে রোজাদার অবস্থায়!'
            : 'Nafl fast day (${now.weekday == DateTime.monday ? "Monday" : "Thursday"}) — Your deeds are presented to Allah while fasting!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // ২৬. ফজরের পর সকালের আমল
    if (now.isAfter(pt.fajr) &&
        now.isBefore(pt.fajr.add(const Duration(minutes: 60)))) {
      alerts.add({
        'icon': '🌅',
        'text': isBn
            ? 'ফজরের পর সকালের আমল:\n• সকালের দোয়া পড়ুন\n• আয়াতুল কুরসি পড়ুন\n• সূরা হাশরের শেষ ৩ আয়াত পড়ুন\n• ১০০ বার তাসবীহ পড়ুন'
            : 'Morning amal: Morning dua, Ayatul Kursi, last 3 ayats of Hashr, 100x tasbih.',
        'color': const Color(0xFFFF8F00),
      });
    }

    // ২৭. আসরের পর বিকেলের আমল
    if (now.isAfter(pt.asr) &&
        now.isBefore(pt.asr.add(const Duration(minutes: 60)))) {
      alerts.add({
        'icon': '🌆',
        'text': isBn
            ? 'আসরের পর সন্ধ্যার আমল:\n• সন্ধ্যার দোয়া পড়ুন\n• আয়াতুল কুরসি পড়ুন\n• সূরা হাশরের শেষ ৩ আয়াত পড়ুন'
            : 'Evening amal after Asr: Evening dua, Ayatul Kursi, last 3 ayats of Hashr.',
        'color': const Color(0xFF26A69A),
      });
    }

    // ২৮. নফল নামাজের সময় — দিনের বিভিন্ন সময়
    // ইশরাকের আগে — ফজরের পর বসে থাকুন
    if (now.isAfter(pt.fajr) &&
        now.isBefore(pt.fajr.add(const Duration(minutes: 20)))) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'ফজরের পর সূর্যোদয় পর্যন্ত মসজিদে বসে থাকুন তারপর ২ রাকাত ইশরাক পড়ুন — হজ ও উমরার সওয়াব পাবেন!'
            : 'Stay in mosque after Fajr till sunrise, then pray 2 rakats Ishraq — reward of Hajj & Umrah!',
        'color': const Color(0xFFFFB300),
      });
    }

    // ২৯. চাশতের সময় মনে করিয়ে দেওয়া
    if (now.isAfter(chashtStart) &&
        now.isBefore(chashtStart.add(const Duration(minutes: 30)))) {
      alerts.add({
        'icon': '☀️',
        'text': isBn
            ? 'চাশতের সময় শুরু হয়েছে — ২-১২ রাকাত নফল নামাজ পড়ুন। প্রতিটি সন্ধির পক্ষ থেকে সদকা হবে!'
            : 'Chasht time started — Pray 2-12 rakats nafl. Sadaqah for every joint of your body!',
        'color': const Color(0xFFFDD835),
      });
    }

    // ৩০. সন্ধ্যার পর — আওওয়াবিন নামাজ মনে করানো
    if (now.isAfter(pt.maghrib) &&
        now.isBefore(pt.maghrib.add(const Duration(minutes: 20)))) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'মাগরিবের পর আওওয়াবিনের সময় — ৬-২০ রাকাত নফল পড়ুন। রাসূল ﷺ নিয়মিত পড়তেন!'
            : 'After Maghrib — Awwabin time! Pray 6-20 rakats. The Prophet ﷺ regularly prayed this.',
        'color': const Color(0xFF26A69A),
      });
    }
    
   // ══════════════════════════════════════════
    // নফল আমলের নোটিফিকেশন
    // ══════════════════════════════════════════

    // সকাল ও বিকাল — সুবহানাল্লাহি ওয়া বিহামদিহি
    if ((now.isAfter(pt.fajr) && now.hour < 10) ||
        (now.isAfter(pt.asr) && now.hour < 19)) {
      final isMorning = now.hour < 12;
      alerts.add({
        'icon': '📿',
        'text': isBn
            ? '${isMorning ? "সকালে" : "বিকালে"} ১০০ বার পড়ুন:\n"সুবহানাল্লাহি ওয়া বিহামদিহি সুবহানাল্লাহিল আযীম"\nজান্নাতে একটি খেজুর গাছ রোপণ হবে এবং সৃষ্টিকুলের সবার চেয়ে বেশি মর্যাদা পাবেন!'
            : '${isMorning ? "Morning" : "Evening"}: Say 100x "Subhanallahi wa bihamdihi Subhanallahil Azim" — a date palm planted in Jannah!',
        'color': const Color(0xFF2E7D32),
      });
    }

    // সকাল ও বিকাল — ১০০ বার তাসবীহ
    if ((now.isAfter(pt.fajr) && now.hour < 10) ||
        (now.isAfter(pt.asr) && now.hour < 19)) {
      alerts.add({
        'icon': '✨',
        'text': isBn
            ? 'এখন ১০০ বার করে পড়ুন:\n• সুবহানাল্লাহ\n• আলহামদুলিল্লাহ\n• আল্লাহু আকবার\n• লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু লা শারীকা লাহু...\nঅগণিত সওয়াব হবে! — নাসাই, সহিহ তারগিব: ৬৫১'
            : 'Say 100x each: SubhanAllah, Alhamdulillah, Allahu Akbar, La ilaha illAllah — countless rewards!',
        'color': const Color(0xFF1565C0),
      });
    }

    // নামাজের ওয়াক্ত শুরু হলে জামাতের ফযিলত — ৩০ মিনিট
    final prayerTimes = [pt.fajr, pt.dhuhr, pt.asr, pt.maghrib, pt.isha];
    for (final pTime in prayerTimes) {
      if (now.isAfter(pTime) &&
          now.isBefore(pTime.add(const Duration(minutes: 30)))) {
        alerts.add({
          'icon': '🕌',
          'text': isBn
              ? 'এখন নামাজের ওয়াক্ত! ইমামের প্রথম তাকবীরের সাথে ৪০ দিন সালাত আদায় করুন — নিশ্চিত জাহান্নাম থেকে মুক্তি পাবেন! তিরমিযী: ৭৪৭'
              : 'Prayer time! Pray with first Takbeer for 40 days — guaranteed freedom from Hellfire! Tirmidhi: 747',
          'color': AppTheme.accent,
        });
        break;
      }
    }

    // ফজরের পর — চাশত/ইশরাক নোটিফিকেশন
    if (now.isAfter(pt.fajr) &&
        now.isBefore(pt.fajr.add(const Duration(minutes: 90)))) {
      alerts.add({
        'icon': '🌅',
        'text': isBn
            ? 'ফজরের পর মসজিদে বসে যিকির করুন। সূর্য উঠলে ২ রাকাত ইশরাক পড়ুন — প্রতিদিন ১টি নিশ্চিত কবুল হজ ও উমরার সওয়াব! তিরমিযী: ৪৬১'
            : 'Stay in mosque after Fajr doing dhikr. After sunrise pray 2 rakats Ishraq — daily reward of complete Hajj & Umrah! Tirmidhi: 461',
        'color': const Color(0xFFFF8F00),
      });
    }

    // চাশত সময় — সকাল ৯টা থেকে ১১টা
    if (now.hour >= 9 && now.hour < 11) {
      alerts.add({
        'icon': '☀️',
        'text': isBn
            ? 'এখন চাশতের উত্তম সময় (সকাল ৯-১১টা) — ২, ৪, ৮ বা ১২ রাকাত নফল পড়ুন। প্রতিটি সন্ধির পক্ষ থেকে সদকা হবে!'
            : 'Best time for Chasht/Duha prayer (9-11am) — Pray 2-12 rakats nafl. Sadaqah for every joint!',
        'color': const Color(0xFFFDD835),
      });
    }

    // ফজর ও মাগরিবের পর — সূরা হাশর + তিন কুল
    if ((now.isAfter(pt.fajr) &&
            now.isBefore(pt.fajr.add(const Duration(minutes: 45)))) ||
        (now.isAfter(pt.maghrib) &&
            now.isBefore(pt.maghrib.add(const Duration(minutes: 45))))) {
      final isFajrTime = now.isAfter(pt.fajr) && now.hour < 12;
      alerts.add({
        'icon': '📖',
        'text': isBn
            ? '${isFajrTime ? "ফজর" : "মাগরিব"}এর পর আমল:\n• সূরা হাশরের শেষ ৩ আয়াত পড়ুন\n• তিন কুল পড়ে শরীরে দম করুন\n• হাদিস বর্ণিত যিকির ও দোয়া করুন'
            : '${isFajrTime ? "Fajr" : "Maghrib"} amal: Last 3 ayats of Hashr, Three Quls with dam, prescribed dhikr & dua.',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // ঘুমানোর আগে — রাত ৯টা থেকে রাত ১২টা
    if (now.hour >= 21 && now.hour < 24) {
      alerts.add({
        'icon': '😴',
        'text': isBn
            ? 'ঘুমানোর আগে আমল:\n• সূরা মুলক পড়ুন (কবরের আযাব থেকে রক্ষা)\n• তিন কুল পড়ে ৩ বার শরীরে দম করুন\n• আয়াতুল কুরসি পড়ুন\n• সূরা কাফিরুন পড়ুন\n• ঘুমের দোয়া পড়ে ডান কাত হয়ে শোন'
            : 'Before sleep: Surah Mulk (protection from grave), Three Quls with dam, Ayatul Kursi, Surah Kafirun, sleep on right side.',
        'color': const Color(0xFF5C6BC0),
      });
    }

    // সন্ধ্যার পর — সূরা মুলক মনে করানো
    if (now.isAfter(pt.maghrib) && now.hour < 22) {
      alerts.add({
        'icon': '📖',
        'text': isBn
            ? 'আজ রাতে ঘুমানোর আগে সূরা মুলক পড়তে ভুলবেন না — কবরের আযাব থেকে রক্ষা করবে।'
            : "Don't forget Surah Mulk tonight — it protects from grave punishment.",
        'color': const Color(0xFF26A69A),
      });
    }

    // সন্ধ্যার পর — সূরা ইখলাসের ফযিলত (রাত ৯-১০টা)
    if (now.hour == 21) {
      alerts.add({
        'icon': '📿',
        'text': isBn
            ? 'প্রতি রাতে সূরা ইখলাস পড়লে কুরআনের এক তৃতীয়াংশ তিলাওয়াতের সওয়াব পাবেন! — মুসনাদে আহমদ: ২৩৫৫৪'
            : 'Recite Surah Ikhlas every night — reward of 1/3 of the Quran! Musnad Ahmad: 23554',
        'color': const Color(0xFF4A148C),
      });
    }

    // ইশা ও ফজর ওয়াক্তে — জামাতের বিশেষ ফযিলত (১ ঘন্টা)
    if ((now.isAfter(pt.isha) &&
            now.isBefore(pt.isha.add(const Duration(hours: 1)))) ||
        (now.isAfter(pt.fajr) &&
            now.isBefore(pt.fajr.add(const Duration(hours: 1))))) {
      final isIsha = now.isAfter(pt.isha) && now.hour > 18;
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? '${isIsha ? "ইশার" : "ফজরের"} জামাতে নামাজ পড়লে ${isIsha ? "অর্ধেক রাত ইবাদতের" : "পুরো রাত ইবাদতের"} সওয়াব পাবেন! এছাড়া ইশা = হজের সমান, ফজর = উমরার সমান সওয়াব! — সহীহ আল জামি: ৬৪৩২'
            : '${isIsha ? "Isha" : "Fajr"} in congregation = reward of ${isIsha ? "half the night" : "whole night"} of ibadah! Also = Hajj/Umrah reward!',
        'color': AppTheme.gold,
      });
    }

    // মাগরিবের পর আওওয়াবিন — ২০ মিনিট
    if (now.isAfter(pt.maghrib) &&
        now.isBefore(pt.maghrib.add(const Duration(minutes: 20)))) {
      alerts.add({
        'icon': '🌟',
        'text': isBn
            ? 'মাগরিবের পর আওওয়াবিন নামাজের সময় — ৬-২০ রাকাত পড়ুন। রাসূল ﷺ নিয়মিত পড়তেন!'
            : 'Awwabin time after Maghrib — Pray 6-20 rakats. The Prophet ﷺ prayed this regularly!',
        'color': const Color(0xFF26A69A),
      });
    }

    // প্রতিদিন ২০ মিনিট — রমজানে উমরার ফযিলত মনে করানো
    if (hijriMonth == 9 && now.minute < 20) {
      alerts.add({
        'icon': '🕋',
        'text': isBn
            ? 'রমজানে উমরাহ পালন করা রাসূল ﷺ-এর সাথে হজ করার সমান! — সহীহ বুখারী'
            : 'Umrah in Ramadan = Hajj with the Prophet ﷺ! — Sahih Bukhari',
        'color': const Color(0xFFFF6F00),
      });
    }

    // প্রতি মাসে ৩ রোজা — ১৩, ১৪, ১৫ তারিখ
    if (hijriDay >= 13 && hijriDay <= 15 && hijriMonth != 9) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আজ আইয়্যামুল বীদ (${hijriDay} তারিখ) — প্রতি মাসের ১৩, ১৪, ১৫ তারিখে রোজা রাখুন। সারা বছর রোজার সমান সওয়াব!'
            : 'Ayyam al-Beed (${hijriDay}th) — Fast 13, 14, 15 of each month = reward of year-long fasting!',
        'color': const Color(0xFF00BCD4),
      });
    }

    // জামাতে প্রথম সারির ফযিলত — জুমা বাদে প্রতিদিন
    if (now.hour >= 11 && now.hour < 13 && now.weekday != DateTime.friday) {
      alerts.add({
        'icon': '🕌',
        'text': isBn
            ? 'জামাতে প্রথম সারিতে দাঁড়ানোর চেষ্টা করুন — রাসূল ﷺ প্রথম সারির জন্য ৩ বার ও দ্বিতীয় সারির জন্য ১ বার ইস্তিগফার করতেন!'
            : 'Try to stand in first row — the Prophet ﷺ sought forgiveness 3x for first row, 1x for second row!',
        'color': AppTheme.accent,
      });
    }

    // ঘর থেকে বের হওয়ার সময় মনে করানো — সকাল ৭-৯টা
    if (now.hour >= 7 && now.hour < 9) {
      alerts.add({
        'icon': '🚪',
        'text': isBn
            ? 'ঘর থেকে বের হওয়ার সময়:\n• ডান পা দিয়ে বের হন\n• বের হওয়ার দোয়া পড়ুন: "বিসমিল্লাহ তাওয়াক্কালতু আলাল্লাহ"\n• ঘরে ফেরার সময় ডান পা দিয়ে প্রবেশ করে সালাম দিন'
            : 'When leaving home: Right foot first, say leaving dua, return with right foot & give salam.',
        'color': const Color(0xFF5D4037),
      });
    }

    // শাওয়ালের ৬ রোজা মনে করানো — শাওয়াল মাসে
    if (hijriMonth == 10 && hijriDay >= 2 && hijriDay <= 25) {
      alerts.add({
        'icon': '🌙',
        'text': isBn
            ? 'শাওয়ালের ৬টি রোজা বাকি আছে — রমজান + শাওয়ালের ৬ রোজা = পুরো বছর রোজার সমান সওয়াব!'
            : 'Shawwal 6 fasts remaining — Ramadan + 6 Shawwal fasts = reward of year-long fasting!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // বিশেষ ৫ রাতের নোটিফিকেশন — আগের সন্ধ্যা থেকে ফজর পর্যন্ত
    // জিলহজের ৮ তারিখের রাত
    if ((hijriMonth == 12 && hijriDay == 7 && now.isAfter(pt.maghrib)) ||
        (hijriMonth == 12 && hijriDay == 8 && now.isBefore(pt.fajr))) {
      alerts.add({
        'icon': '🌟',
        'text': isBn
            ? 'আজ রাতে জেগে ইবাদত করুন (জিলহজের ৮ তারিখের রাত) — এই রাতে ইবাদত করলে জান্নাত ওয়াজিব হয়ে যায়! — আত-তারগিব'
            : 'Tonight: 8th Dhul Hijjah night — worship tonight and Jannah becomes obligatory! At-Targheeb',
        'color': AppTheme.gold,
      });
    }
    // জিলহজের ৯ তারিখের রাত (আরাফার আগের রাত)
    if ((hijriMonth == 12 && hijriDay == 8 && now.isAfter(pt.maghrib)) ||
        (hijriMonth == 12 && hijriDay == 9 && now.isBefore(pt.fajr))) {
      alerts.add({
        'icon': '🕋',
        'text': isBn
            ? 'আজ আরাফার রাত! জেগে ইবাদত করুন — জান্নাত ওয়াজিব হয়ে যাবে। কাল আরাফার রোজা রাখুন!'
            : "Arafah eve! Worship tonight — Jannah becomes obligatory! Fast tomorrow (Day of Arafah)!",
        'color': AppTheme.gold,
      });
    }
    // ঈদুল আজহার রাত
    if ((hijriMonth == 12 && hijriDay == 9 && now.isAfter(pt.maghrib)) ||
        (hijriMonth == 12 && hijriDay == 10 && now.isBefore(pt.fajr))) {
      alerts.add({
        'icon': '🐑',
        'text': isBn
            ? 'আজ রাতে জেগে ইবাদত করুন (ঈদুল আজহার রাত) — এই রাতে দোয়া ফিরিয়ে দেওয়া হয় না এবং জান্নাত ওয়াজিব হয়ে যায়!'
            : 'Eid al-Adha eve! Worship tonight — duas are never rejected, Jannah becomes obligatory!',
        'color': AppTheme.gold,
      });
    }
    // ঈদুল ফিতরের রাত (৩০ রমজান মাগরিব থেকে ১ শাওয়াল ফজর পর্যন্ত)
    if ((hijriMonth == 9 && hijriDay == 30 && now.isAfter(pt.maghrib)) ||
        (hijriMonth == 10 && hijriDay == 1 && now.isBefore(pt.fajr))) {
      alerts.add({
        'icon': '🎉',
        'text': isBn
            ? 'আজ রাতে জেগে ইবাদত করুন (ঈদুল ফিতরের রাত) — এই রাতে দোয়া কবুল হয়, হৃদয় কিয়ামতের দিন সজীব থাকবে!'
            : 'Eid al-Fitr eve! Worship tonight — duas accepted, heart stays alive on Judgment Day!',
        'color': AppTheme.gold,
      });
    }

    // শুক্রবার — বিস্তারিত আমল
    if (now.weekday == DateTime.friday) {
      if (now.isAfter(pt.fajr) && now.isBefore(pt.dhuhr)) {
        alerts.add({
          'icon': '🕌',
          'text': isBn
              ? 'জুমার দিনের ১১টি আমল:\n১. আগে ঘুম থেকে উঠুন\n২. গোসল করুন\n৩. উত্তম পোশাক পরুন\n৪. সুগন্ধি ও মেসওয়াক ব্যবহার করুন\n৫. পায়ে হেঁটে মসজিদে যান\n৬. আগে আগে মসজিদে যান\n৭. বেশি দরূদ পড়ুন\n৮. সূরা কাহাফ পড়ুন\n৯. আসরের পর দোয়ায় মশগুল থাকুন\n১০. ভিন্ন পথে ফিরুন\n১১. বেশি বেশি ইস্তিগফার করুন'
              : 'Friday 11 amals: Early rise, Ghusl, best clothes, perfume, walk to mosque early, more Salawat, Surah Kahf, dua after Asr, return different route, istighfar.',
          'color': AppTheme.gold,
        });
        alerts.add({
          'icon': '📖',
          'text': isBn
              ? 'জুমার দিন সূরা কাহাফ তেলাওয়াত করুন — কেয়ামতের দিন নুরের আলো হবে এবং দাজ্জালের ফেতনা থেকে রক্ষা করবে! প্রতি কদমে ১ বছর রোজা ও কিয়ামুল লাইলের সওয়াব!'
              : 'Recite Surah Kahf — light on Judgment Day, protection from Dajjal! Every step to mosque = 1 year fasting & night prayer reward!',
          'color': const Color(0xFF26A69A),
        });
      }
      // আসরের পর দোয়ার সময়
      if (now.isAfter(pt.asr) && now.isBefore(pt.maghrib)) {
        final cd = _countdown(pt.maghrib);
        alerts.add({
          'icon': '🤲',
          'text': isBn
              ? 'এখন জুমার দোয়া কবুলের বিশেষ সময়! (মাগরিব পর্যন্ত: $cd) — দোয়ায় মশগুল থাকুন! রাসূল ﷺ বলেছেন এটি সপ্তাহের সেরা মুহূর্ত।'
              : 'Golden hour for Friday dua! (Till Maghrib: $cd) — Stay in dua! The Prophet ﷺ said this is the best moment of the week.',
          'color': AppTheme.gold,
        });
      }
    }

    // সোমবার ও বৃহস্পতিবার নফল রোজা
    if ((now.weekday == DateTime.monday || now.weekday == DateTime.thursday) &&
        now.isAfter(pt.fajr) &&
        now.isBefore(pt.maghrib)) {
      final day = now.weekday == DateTime.monday ? 'সোমবার' : 'বৃহস্পতিবার';
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আজ $day — নফল রোজার দিন! এই দিনে আমলনামা আল্লাহর দরবারে পেশ হয়, রোজাদার অবস্থায় পেশ হলে বিশেষ মর্যাদা পাওয়া যায়!'
            : 'Today is $day — nafl fast day! Deeds presented to Allah — better to be fasting when they are!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // জিলহজের প্রথম ১০ দিন — বিস্তারিত আমল
    if (hijriMonth == 12 && hijriDay >= 1 && hijriDay <= 9) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'জিলহজের ${hijriDay} তারিখ — এই ১০ দিনের আমল:\n• নফল রোজা রাখুন (বিশেষত ৯ জিলহজ)\n• নখ ও চুল কাটবেন না (কোরবানিদাতারা)\n• বেশি তাকবির ও জিকির পড়ুন\n• দান-সদকা করুন\n• তাহাজ্জুদ পড়ুন'
            : 'Dhul Hijjah ${hijriDay} — Best 10 days: Fast (esp. 9th), no haircut/nails (sacrificers), lots of takbeer, charity, tahajjud.',
        'color': AppTheme.gold,
      });
    }

    // জিলহজ মাসে তাকবিরে তাশরিক (৯-১৩ জিলহজ)
    if (hijriMonth == 12 && hijriDay >= 9 && hijriDay <= 13) {
      alerts.add({
        'icon': '📢',
        'text': isBn
            ? 'এখন তাকবিরে তাশরিক পড়ার সময় — প্রতি ফরজ নামাজের পর পড়ুন:\n"আল্লাহু আকবার আল্লাহু আকবার লা ইলাহা ইল্লাল্লাহু ওয়াল্লাহু আকবার আল্লাহু আকবার ওয়া লিল্লাহিল হামদ"'
            : 'Time for Takbeer al-Tashriq after every fard prayer: "Allahu Akbar Allahu Akbar La ilaha illAllah..."',
        'color': const Color(0xFFE65100),
      });
    }

    // রমজানের ইফতারি করানোর ফযিলত
    if (hijriMonth == 9 && now.isAfter(pt.asr) && now.isBefore(pt.maghrib)) {
      alerts.add({
        'icon': '🍽️',
        'text': isBn
            ? 'কোনো রোজাদারকে ইফতার করান — তার সমান সওয়াব পাবেন, অথচ তার সওয়াব কিছুমাত্র কমবে না!'
            : 'Feed a fasting person iftar — you get same reward without reducing theirs!',
        'color': const Color(0xFFE65100),
      });
    }

    // রমজানের শেষ দশকের বিজোড় রাত — লাইলাতুল কদর
    if (hijriMonth == 9 &&
        hijriDay >= 20 &&
        hijriDay % 2 != 0 &&
        now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '✨',
        'text': isBn
            ? 'আজ রাতে লাইলাতুল কদর হতে পারে! রাতভর ইবাদত করুন — "আল্লাহুম্মা ইন্নাকা আফুওয়্যুন কারীমুন তুহিব্বুল আফওয়া ফাফু আন্নী" পড়ুন।\nএই রাতের ইবাদত ১০০০ মাসের চেয়ে উত্তম!'
            : "Tonight could be Laylatul Qadr! Worship all night — 'Allahumma innaka afuwwun...' This night > 1000 months!",
        'color': AppTheme.gold,
      });
    }
    
    // জিলহজের প্রথম ১০ দিন — বিস্তারিত আমল (সারাদিন)
    if (hijriMonth == 12 && hijriDay >= 1 && hijriDay <= 9) {
      alerts.add({
        'icon': '🌟',
        'text': isBn
            ? 'জিলহজের ${hijriDay} তারিখ — বছরের শ্রেষ্ঠ দিন!\n\n'
                '✦ নফল রোজা রাখুন\n'
                '✦ বেশি তাহলিল পড়ুন: "লা ইলাহা ইল্লাল্লাহ"\n'
                '✦ তাকবির পড়ুন: "আল্লাহু আকবার আল্লাহু আকবার লা ইলাহা ইল্লাল্লাহু ওয়াল্লাহু আকবার ওয়া লিল্লাহিল হামদ"\n'
                '✦ তাহমিদ পড়ুন: "আলহামদুলিল্লাহ"\n'
                '✦ দান-সদকা করুন\n'
                '✦ আত্মীয়তার সম্পর্ক জোরদার করুন\n'
                '✦ গুনাহ থেকে বেঁচে থাকুন\n'
                '✦ তওবা ও ইস্তিগফার করুন\n\n'
                '"এই দিনগুলোর নেক আমল আল্লাহর কাছে সর্বাধিক প্রিয় — জিহাদের চেয়েও!" — বুখারী'
            : 'Dhul Hijjah ${hijriDay} — Best days! Fast, say Takbeer, Tahleel, Tahmeed, give charity, maintain family ties, repent!',
        'color': AppTheme.gold,
      });

      // তওবা ও ইস্তিগফার আলাদা নোটিফিকেশন
      alerts.add({
        'icon': '🤲',
        'text': isBn
            ? 'জিলহজের ${hijriDay} তারিখ — গুনাহ মাফের শ্রেষ্ঠ সময়!\n\n'
                'আল্লাহ বলেন: "তোমরা তোমাদের রবের কাছে ক্ষমা প্রার্থনা করো, অতঃপর তাঁর কাছেই ফিরে এসো।" — সূরা হুদ: ৯০\n\n'
                '✦ বেশি বেশি তওবা করুন\n'
                '✦ আস্তাগফিরুল্লাহ পড়ুন\n'
                '✦ নফল নামাজ আদায় করুন'
            : 'Dhul Hijjah ${hijriDay} — Best time for Tawbah! Seek forgiveness abundantly — Surah Hud: 90',
        'color': const Color(0xFF4A148C),
      });
    }

    // জিলহজের ১-৯ তারিখ — রোজার নোটিফিকেশন (দিনের বেলা)
    if (hijriMonth == 12 &&
        hijriDay >= 1 &&
        hijriDay <= 9 &&
        now.isAfter(pt.fajr) &&
        now.isBefore(pt.maghrib)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আজ জিলহজের ${hijriDay} তারিখ — নফল রোজার দিন!\n\n'
                'রাসূল ﷺ জিলহজের প্রথম ৯ দিন রোজা রাখতেন এবং কখনো ছাড়তেন না। — আবু দাউদ: ২১০৬\n\n'
                '✦ আরাফার দিন (৯ জিলহজ) রোজা রাখলে আগের ও পরের ১ বছরের গুনাহ মাফ!'
            : 'Dhul Hijjah ${hijriDay} — Fast today! Prophet ﷺ never missed these fasts. Arafah fast (9th) = 2 years sins forgiven!',
        'color': const Color(0xFF00BCD4),
      });
    }

    // জিলহজ ১-৯ তারিখ ইফতারের আগে — রোজাদারের দোয়া
    if (hijriMonth == 12 &&
        hijriDay >= 1 &&
        hijriDay <= 9 &&
        now.isAfter(pt.asr) &&
        now.isBefore(pt.maghrib)) {
      final cd = _countdown(pt.maghrib);
      alerts.add({
        'icon': '🤲',
        'text': isBn
            ? 'ইফতার পর্যন্ত: $cd — এখন দোয়ায় মশগুল থাকুন!\n'
                'রোজাদারের দোয়া ফিরিয়ে দেওয়া হয় না!'
            : 'Iftar in: $cd — Make dua now! Fasting person\'s dua is never rejected!',
        'color': const Color(0xFFE65100),
      });
    }

    // কোরবানি ও আত্মীয়তা — জিলহজে
    if (hijriMonth == 12 && hijriDay >= 1 && hijriDay <= 10) {
      alerts.add({
        'icon': '🐑',
        'text': isBn
            ? 'কোরবানির প্রস্তুতি:\n\n'
                '✦ হালাল উপায়ে পশু নির্বাচন করুন\n'
                '✦ কোরবানির গোশত তিন ভাগ করুন — নিজের, আত্মীয়দের ও গরিবদের জন্য\n'
                '✦ "কোরবানির রক্ত জমিনে পড়ার আগেই আল্লাহর কাছে কবুল হয়ে যায়" — তিরমিযী: ১৪৯৩\n'
                '✦ আত্মীয়তার সম্পর্ক জোরদার করুন'
            : 'Qurbani preparation: Choose halal animal, divide meat 3 ways (self/relatives/poor). "Blood accepted before it falls!" Tirmidhi: 1493',
        'color': const Color(0xFFB71C1C),
      });
    }

    // ঈদের নামাজের নিয়ম — ঈদের সকালে
    if ((hijriMonth == 12 && hijriDay == 10 && now.hour < 10) ||
        (hijriMonth == 10 && hijriDay == 1 && now.hour < 10)) {
      final isAzha = hijriMonth == 12;
      alerts.add({
        'icon': '🎉',
        'text': isBn
            ? '${isAzha ? "ঈদুল আজহার" : "ঈদুল ফিতরের"} নামাজের প্রস্তুতি:\n\n'
                '✦ গোসল করুন\n'
                '✦ উত্তম পোশাক পরুন\n'
                '${isAzha ? "✦ কোরবানির আগে কিছু খাবেন না\n" : "✦ ঈদগাহে যাওয়ার আগে মিষ্টি খান\n"}'
                '✦ পায়ে হেঁটে ঈদগাহে যান\n'
                '✦ তাকবির বলতে বলতে যান\n'
                '✦ ভিন্ন পথে ফিরুন'
            : '${isAzha ? "Eid al-Adha" : "Eid al-Fitr"} prayer prep: Ghusl, best clothes, walk to Eidgah, say Takbeer, return different route.',
        'color': AppTheme.gold,
      });
    }

    // জামাতে প্রথম সারির ফযিলত — সকল নামাজের ওয়াক্তে
    for (final pTime in prayerTimes) {
      if (now.isAfter(pTime.subtract(const Duration(minutes: 15))) &&
          now.isBefore(pTime)) {
        alerts.add({
          'icon': '⭐',
          'text': isBn
              ? 'নামাজের সময় হচ্ছে — জামাতে প্রথম সারিতে দাঁড়ানোর চেষ্টা করুন!\n\n'
                  'রাসূল ﷺ প্রথম সারির জন্য ৩ বার দোয়া করতেন, দ্বিতীয় সারির জন্য ১ বার!'
              : 'Prayer time soon — try for the first row! Prophet ﷺ prayed 3x for first row, 1x for second!',
          'color': AppTheme.accent,
        });
        break;
      }
    }

    // সৎ কাজে প্রতিযোগিতার অনুপ্রেরণা — প্রতিদিন দুপুরে
    if (now.hour == 13) {
      alerts.add({
        'icon': '🏆',
        'text': isBn
            ? 'আল্লাহ বলেন: "তোমরা কল্যাণমূলক কাজে প্রতিযোগিতা করো।" — সূরা বাকারা: ১৪৮\n\n'
                'আজ কি কি নেক আমল করলেন? দান-সদকা, অসহায়কে সাহায্য, দ্বীনি কাজে অংশগ্রহণ করুন!'
            : '"Compete in good deeds!" — Surah Baqarah: 148. What good have you done today? Give charity, help others!',
        'color': const Color(0xFF1565C0),
      });
    }

    // নফল ইবাদতের গুরুত্ব — প্রতিদিন বিকালে
    if (now.hour == 16) {
      alerts.add({
        'icon': '💎',
        'text': isBn
            ? 'আল্লাহ বলেন (হাদিসে কুদসি): "আমার বান্দা নফল ইবাদতের মাধ্যমে সর্বদা আমার সান্নিধ্য লাভ করতে থাকে, একপর্যায়ে আমি তাকে আমার প্রিয় পাত্রে পরিণত করি।" — বুখারী: ৬৫০২'
            : 'Allah says (Hadith Qudsi): "My servant keeps drawing near to Me through nafl worship until I love him." — Bukhari: 6502',
        'color': const Color(0xFF7C4DFF),
      });
    }
    
    // ১. প্রতিদিন ২০ মিনিট — রমজানে উমরার ফযিলত (যেকোনো সময়)
    if (hijriMonth != 9 && now.minute >= 0 && now.minute < 20) {
      alerts.add({
        'icon': '🕋',
        'text': isBn
            ? 'রমজানে উমরাহ করার পরিকল্পনা করুন!\n\n'
                'রাসূল ﷺ বলেছেন: "রমজানে উমরাহ পালন করা আমার সাথে হজ করার সমান।"\n\n'
                'এখনই নিয়ত করুন এবং প্রস্তুতি শুরু করুন।'
            : 'Plan Umrah in Ramadan!\n\nProphet ﷺ said: "Umrah in Ramadan = Hajj with me."\n\nMake intention now and start preparing!',
        'color': const Color(0xFFFF6F00),
      });
    }

    // ২. প্রতি মাসে ৩টি রোজা — আইয়্যামুল বীদ ছাড়া অন্য সময়েও মনে করানো
    if (hijriDay == 12 && hijriMonth != 9) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আগামীকাল থেকে আইয়্যামুল বীদ শুরু (১৩, ১৪, ১৫ তারিখ)!\n\n'
                '"প্রত্যেক মাসে ৩টি রোজা রাখা সারা বছর রোজা রাখার সমান।"\n\n'
                'আগামীকাল থেকে ৩ দিন রোজার নিয়ত করুন!'
            : 'Ayyam al-Beed starts tomorrow (13, 14, 15)!\n\n"3 fasts per month = year-long fasting reward."\n\nMake intention now!',
        'color': const Color(0xFF00BCD4),
      });
    }

    // ৩. রমজানের শেষ দশক — প্রতি রাতে মাগরিব থেকে ফজর পর্যন্ত
    if (hijriMonth == 9 && hijriDay >= 20) {
      if (now.isAfter(pt.maghrib) || now.isBefore(pt.fajr)) {
        alerts.add({
          'icon': '✨',
          'text': isBn
              ? 'রমজানের শেষ দশকের রাত চলছে!\n\n'
                  '"লাইলাতুল কদর হাজার মাসের চেয়ে উত্তম।"\n\n'
                  '✦ বেশি বেশি পড়ুন:\n'
                  '"আল্লাহুম্মা ইন্নাকা আফুওয়্যুন কারীমুন তুহিব্বুল আফওয়া ফাফু আন্নী"\n\n'
                  '✦ তাহাজ্জুদ পড়ুন\n'
                  '✦ কুরআন তেলাওয়াত করুন\n'
                  '✦ দোয়ায় মশগুল থাকুন'
              : 'Last 10 nights of Ramadan!\n\n"Laylatul Qadr > 1000 months."\n\nPray Tahajjud, recite Quran, make dua: "Allahumma innaka afuwwun..."',
          'color': AppTheme.gold,
        });
      }
    }

    // ৪. জুমার দিন — মসজিদে যাওয়ার পথে প্রতি কদমে ১ বছরের সওয়াব
    if (now.weekday == DateTime.friday &&
        now.isAfter(pt.fajr) &&
        now.isBefore(pt.dhuhr)) {
      alerts.add({
        'icon': '👣',
        'text': isBn
            ? 'জুমার দিন পায়ে হেঁটে মসজিদে যান!\n\n'
                '"যে ব্যক্তি জুমার দিন পায়ে হেঁটে মসজিদে যাবে, তার প্রতি কদমে ১ বছরের রোজা ও কিয়ামুল লাইলের সওয়াব লেখা হবে।"\n'
                '— আবু দাউদ: ৩৪৫\n\n'
                'আগে আগে মসজিদে গিয়ে ইমামের কাছে বসুন — প্রতি পদক্ষেপে ১ বছরের সালাত ও রোজার সওয়াব!'
            : 'Walk to Jummah today!\n\n"Every step = 1 year fasting & night prayer reward." Abu Dawud: 345\n\nGo early, sit near imam!',
        'color': AppTheme.gold,
      });
    }

    // ৫. ঘরে ফেরার সময় — সন্ধ্যা ৬-৮টা
    if (now.hour >= 18 && now.hour < 20) {
      alerts.add({
        'icon': '🏠',
        'text': isBn
            ? 'ঘরে ফেরার সুন্নত:\n\n'
                '✦ ডান পা দিয়ে প্রবেশ করুন\n'
                '✦ "বিসমিল্লাহি ওয়ালাজনা ওয়া বিসমিল্লাহি খারাজনা" পড়ুন\n'
                '✦ পরিবারকে সালাম দিন\n'
                '✦ কেউ না থাকলেও সালাম দিন — ঘরের ফেরেশতারা উত্তর দেবেন!'
            : 'Returning home sunnah: Right foot first, say entry dua, give salam — even if no one is home, angels will answer!',
        'color': const Color(0xFF5D4037),
      });
    }

    // ৬. আমল: ৫৩ ও ৫৪ — ইশা ও ফজর জামাতের বিশেষ ফযিলত (বিস্তারিত)
    if ((now.isAfter(pt.isha) &&
            now.isBefore(pt.isha.add(const Duration(hours: 1)))) ||
        (now.isAfter(pt.fajr) &&
            now.isBefore(pt.fajr.add(const Duration(hours: 1))))) {
      final isIshaTime = now.isAfter(pt.isha);
      alerts.add({
        'icon': '🌙',
        'text': isBn
            ? '${isIshaTime ? "ইশার" : "ফজরের"} জামাত — বিশেষ ফযিলত!\n\n'
                '"আল্লাহ কি তোমাদের জন্য ইশার জামাত হজের সমান এবং ফজরের জামাত উমরার সমান করেননি?"\n'
                '— সহীহ আল জামি: ৬৪৩২\n\n'
                '"যে ফরজ সালাত জামাতে পড়ার জন্য হেঁটে যায়, তা হজের সমান।"'
            : '${isIshaTime ? "Isha" : "Fajr"} congregation!\n\n"Isha in jamaat = Hajj, Fajr in jamaat = Umrah!" Sahih al-Jami: 6432\n\nWalking to fard prayer = Hajj reward!',
        'color': const Color(0xFF7C4DFF),
      });
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

            _ClockCard(
                now: now, lang: lang,
                prayerTimes: _prayerTimes, hijriDate: _hijriDate),
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

            _PrayerTimesCard(
                lang: lang, prayerTimes: _prayerTimes, sunnahTimes: _sunnahTimes),
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
            Container(width: 1, height: 120, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 10)),
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
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 6),
          Text(lang.toLocalNum(count), style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold)),
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
      {'key': 'isha', 'start': prayerTimes!.isha, 'end': sunnahTimes?.lastThirdOfTheNight ?? prayerTimes!.fajr},
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
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
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
        _CircleBtn(icon: Icons.check, label: lang.isBn ? 'আদায়' : 'Prayed', color: AppTheme.completed, selected: isAdai, onTap: onAdai),
        const SizedBox(width: 12),
        _CircleBtn(icon: Icons.close, label: lang.isBn ? 'কাযা' : 'Qaza', color: AppTheme.missed, selected: isQaza, onTap: onQaza),
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
            boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)] : [],
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
  static int getMonth(DateTime date) {
    final jd = _gjToJul(date.year, date.month, date.day);
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) ~/ 10631);
    final ll = l - 10631 * n + 354;
    final j = ((10985 - ll) ~/ 5316) * ((50 * ll) ~/ 17719) +
        (ll ~/ 5670) * ((43 * ll) ~/ 15238);
    final lll = ll -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * lll) ~/ 709;
    return month;
  }
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

  static int _gjToJul(int y, int m, int d) {
    int a = (14 - m) ~/ 12;
    int yr = y + 4800 - a;
    int mo = m + 12 * a - 3;
    return d + (153 * mo + 2) ~/ 5 + 365 * yr + yr ~/ 4 - yr ~/ 100 + yr ~/ 400 - 32045;
  }
}
