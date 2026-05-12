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

  // প্রতিটি tab এর ScrollController
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

  // scroll to top হবে কিনা চেক করো
  bool _isScrolledDown() {
    final controller = _scrollControllers[_currentIndex];
    if (controller == null || !controller.hasClients) return false;
    return controller.offset > 50;
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    // যদি scroll করা থাকে — উপরে উঠে যাও
    if (_isScrolledDown()) {
      _scrollControllers[_currentIndex]?.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return false;
    }

    // home এ না থাকলে home এ যাও
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // home এ আছি — দুইবার back চাপলে বন্ধ হবে
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
        lang: lang, now: _now, userName: _userName,
        namazPending: _namazPending, rozaPending: _rozaPending,
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
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: lang.home),
            NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: lang.calendar),
            NavigationDestination(icon: const Icon(Icons.mosque_outlined), selectedIcon: const Icon(Icons.mosque), label: isBn ? 'নামাজ' : 'Prayer'),
            NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: isBn ? 'দোয়া' : 'Dua'),
            NavigationDestination(icon: const Icon(Icons.auto_stories_outlined), selectedIcon: const Icon(Icons.auto_stories), label: isBn ? '৯৯ নাম' : '99 Names'),
            NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: lang.settings),
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
    required this.lang, required this.now, required this.userName,
    required this.namazPending, required this.rozaPending,
    required this.onRefresh, required this.scrollController,
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
    // ১. আগে database থেকে status load করো — এটা দ্রুত
    final statuses = await DatabaseHelper.getDayPrayerStatuses(dateKey);
    final roza = await DatabaseHelper.getRozaStatus(dateKey);
    if (mounted) {
      setState(() {
        _todayPrayers = statuses;
        _todayRoza = roza;
      });
    }
    // ২. prayer times আলাদাভাবে load করো — GPS এর জন্য সময় লাগে
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

  // শুধু prayer status refresh — GPS ছাড়াই, দ্রুত
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

    // প্রতিটি নামাজের ওয়াক্ত — শুধু তখনই কাযা হবে যখন:
    // ১. এখন ওয়াক্তের start time এর পরে
    // ২. এখন ওয়াক্তের end time এর পরে
    // ৩. ওয়াক্তের status null (আদায়ও না, কাযাও না)
    // ৪. end time আজকের তারিখের মধ্যে (ভবিষ্যৎ ওয়াক্ত নয়)
    final entries = <String, Map<String, DateTime>>{
      'fajr':    {'start': pt.fajr,    'end': pt.sunrise},
      'dhuhr':   {'start': pt.dhuhr,   'end': pt.asr},
      'asr':     {'start': pt.asr,     'end': pt.maghrib},
      'maghrib': {'start': pt.maghrib, 'end': pt.isha},
    };
    // ইশা আলাদাভাবে — শুধু যদি পরের দিনের ফজর শুরু হয়ে যায়
    // কিন্তু আজকের date key তে save হবে

    for (final entry in entries.entries) {
      final prayer = entry.key;
      final start = entry.value['start']!;
      final end = entry.value['end']!;
      final currentStatus = statuses[prayer];

      // শুধুমাত্র start এবং end উভয়ই অতীত হলে কাযা করো
      // এবং start আজকের তারিখের মধ্যে হতে হবে
      final startIsToday = DateHelper.dateKey(start) == dateKey;

      if (startIsToday &&
          now.isAfter(start) &&
          now.isAfter(end) &&
          currentStatus == null) {
        await DatabaseHelper.setPrayerStatus(dateKey, prayer, 'missed');
        changed = true;
      }
    }

    // ইশা — পরের দিনের ফজর শুরু হলে গতকালের ইশা কাযা হবে
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = DateHelper.dateKey(yesterday);
    final yesterdayStatuses = await DatabaseHelper.getDayPrayerStatuses(yesterdayKey);
    if (yesterdayStatuses['isha'] == null && now.isAfter(pt.fajr)) {
      await DatabaseHelper.setPrayerStatus(yesterdayKey, 'isha', 'missed');
      changed = true;
    }

    // আজকের ইশা — শুধু যদি pt.isha এর পরে এবং রাত ১১:৫৯ এর পরে
    // (সাধারণত পরদিন ফজরে গতকালের ইশা হিসেবে ধরা হয়)
    final ishaStatus = statuses['isha'];
    final ishaStart = pt.isha;
    final ishaStartIsToday = DateHelper.dateKey(ishaStart) == dateKey;
    // ইশার ওয়াক্ত শেষ = রাত ১২টার আগে মধ্যরাতে
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
    // ১. আগে UI তে সাথে সাথে দেখাও
    setState(() => _todayPrayers = {..._todayPrayers, prayer: status});
    // ২. database এ save করো
    await DatabaseHelper.setPrayerStatus(dateKey, prayer, status);
    // ৩. count update করো
    widget.onRefresh();
  }

  Future<void> _setRoza(String status) async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    // ১. আগে UI তে সাথে সাথে দেখাও
    setState(() => _todayRoza = status);
    // ২. database এ save করো
    await DatabaseHelper.setRozaStatus(dateKey, status);
    // ৩. count update করো
    widget.onRefresh();
  }

  String _fmtTime(DateTime t) => PrayerTimeHelper.formatTime(t);

  List<Map<String, dynamic>> _getLiveAlerts(AppLanguage lang) {
    final isBn = lang.isBn;
    final now = DateTime.now();
    final pt = _prayerTimes;
    final alerts = <Map<String, dynamic>>[];
    if (pt == null) return alerts;

    final sunriseForbiddenEnd = pt.sunrise.add(const Duration(minutes: 15));
    final zawalStart = pt.dhuhr.subtract(const Duration(minutes: 5));
    final zawalEnd = pt.dhuhr;
    final sunsetForbiddenStart = pt.maghrib.subtract(const Duration(minutes: 15));
    final ishraqStart = pt.sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = pt.sunrise.add(const Duration(minutes: 45));
    final chashtStart = pt.sunrise.add(const Duration(minutes: 45));
    final chashtEnd = pt.dhuhr.subtract(const Duration(minutes: 10));
    final lastThird = _sunnahTimes?.lastThirdOfTheNight;
    final h = _HijriSimple.fromDate(now);

    // ১. সেহরি countdown
    if (now.isBefore(pt.fajr)) {
      final diff = pt.fajr.difference(now);
      if (diff.inMinutes <= 90) {
        final hr = diff.inHours.toString().padLeft(2, '0');
        final mn = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final sc = (diff.inSeconds % 60).toString().padLeft(2, '0');
        alerts.add({
          'icon': '🍽️',
          'text': isBn
              ? 'সেহরি শেষ হতে বাকি $hr:$mn:$sc (শেষ সময়: ${_fmtTime(pt.fajr)})'
              : 'Sehri ends in $hr:$mn:$sc (${_fmtTime(pt.fajr)})',
          'color': const Color(0xFF81C784),
        });
      }
    }

    // ২. ইফতার countdown
    if (now.isAfter(pt.fajr) && now.isBefore(pt.maghrib)) {
      final diff = pt.maghrib.difference(now);
      if (diff.inMinutes <= 120) {
        final hr = diff.inHours.toString().padLeft(2, '0');
        final mn = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final sc = (diff.inSeconds % 60).toString().padLeft(2, '0');
        alerts.add({
          'icon': '🌙',
          'text': isBn
              ? 'ইফতার শুরু হতে বাকি $hr:$mn:$sc (${_fmtTime(pt.maghrib)})'
              : 'Iftar in $hr:$mn:$sc (${_fmtTime(pt.maghrib)})',
          'color': const Color(0xFF64B5F6),
        });
      }
    }

    // ৩. সূর্যোদয়
    if (now.isAfter(pt.sunrise.subtract(const Duration(minutes: 5))) &&
        now.isBefore(pt.sunrise.add(const Duration(minutes: 5)))) {
      alerts.add({
        'icon': '🌅',
        'text': isBn
            ? 'এখন সূর্যোদয় হচ্ছে (${_fmtTime(pt.sunrise)})'
            : 'Sunrise now (${_fmtTime(pt.sunrise)})',
        'color': const Color(0xFFFFB300),
      });
    }

    // ৪. সূর্যাস্ত
    if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 5))) &&
        now.isBefore(pt.maghrib.add(const Duration(minutes: 5)))) {
      alerts.add({
        'icon': '🌇',
        'text': isBn
            ? 'সূর্যাস্ত — ইফতারের সময় শুরু! (${_fmtTime(pt.maghrib)})'
            : 'Sunset — Iftar time! (${_fmtTime(pt.maghrib)})',
        'color': const Color(0xFFFF7043),
      });
    }

    // ৫. নামাজের নিষিদ্ধ সময়
    if (now.isAfter(pt.sunrise) && now.isBefore(sunriseForbiddenEnd)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'নামাজের নিষিদ্ধ সময় — সূর্যোদয়কালীন (${_fmtTime(pt.sunrise)} - ${_fmtTime(sunriseForbiddenEnd)})'
            : 'Forbidden prayer time — Sunrise (${_fmtTime(pt.sunrise)} - ${_fmtTime(sunriseForbiddenEnd)})',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(zawalStart) && now.isBefore(zawalEnd)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'নামাজের নিষিদ্ধ সময় — দ্বিপ্রহর (${_fmtTime(zawalStart)} - ${_fmtTime(zawalEnd)})'
            : 'Forbidden prayer time — Noon (${_fmtTime(zawalStart)} - ${_fmtTime(zawalEnd)})',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(sunsetForbiddenStart) && now.isBefore(pt.maghrib)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'নামাজের নিষিদ্ধ সময় — সূর্যাস্তকালীন (${_fmtTime(sunsetForbiddenStart)} - ${_fmtTime(pt.maghrib)})'
            : 'Forbidden prayer time — Sunset (${_fmtTime(sunsetForbiddenStart)} - ${_fmtTime(pt.maghrib)})',
        'color': AppTheme.missed,
      });
    }

    // ৬. ফজর ব্যতীত নিষিদ্ধ
    if (now.isAfter(pt.fajr) && now.isBefore(pt.sunrise)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'নামাজের নিষিদ্ধ সময় — ফজর ব্যতীত (${_fmtTime(pt.fajr)} - ${_fmtTime(pt.sunrise)})'
            : 'Forbidden — Except Fajr (${_fmtTime(pt.fajr)} - ${_fmtTime(pt.sunrise)})',
        'color': AppTheme.missed,
      });
    }

    // ৭. আসর ব্যতীত নিষিদ্ধ
    if (now.isAfter(pt.asr) && now.isBefore(sunsetForbiddenStart)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'নামাজের নিষিদ্ধ সময় — আসর ব্যতীত (${_fmtTime(pt.asr)} - ${_fmtTime(pt.maghrib)})'
            : 'Forbidden — Except Asr (${_fmtTime(pt.asr)} - ${_fmtTime(pt.maghrib)})',
        'color': AppTheme.missed,
      });
    }

    // ৮. ইশরাক
    if (now.isAfter(ishraqStart) && now.isBefore(ishraqEnd)) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'ইশরাকের নামাজের সময় (${_fmtTime(ishraqStart)} - ${_fmtTime(ishraqEnd)}) — হজ্জ-উমরার সওয়াব!'
            : 'Ishraq time (${_fmtTime(ishraqStart)} - ${_fmtTime(ishraqEnd)}) — Hajj & Umrah reward!',
        'color': const Color(0xFFFF8F00),
      });
    }

    // ৯. দুহা/চাশত
    if (now.isAfter(chashtStart) && now.isBefore(chashtEnd)) {
      alerts.add({
        'icon': '☀️',
        'text': isBn
            ? 'দুহা/চাশতের নামাজের সময় (${_fmtTime(chashtStart)} - ${_fmtTime(chashtEnd)})'
            : 'Duha/Chasht prayer time (${_fmtTime(chashtStart)} - ${_fmtTime(chashtEnd)})',
        'color': const Color(0xFFFDD835),
      });
    }

    // ১০. আওওয়াবিন
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'আওওয়াবিনের নামাজের সময় (${_fmtTime(pt.maghrib)} - ${_fmtTime(pt.isha)}) — ৬-২০ রাকাত'
            : 'Awwabin prayer time (${_fmtTime(pt.maghrib)} - ${_fmtTime(pt.isha)}) — 6-20 rakats',
        'color': const Color(0xFF26A69A),
      });
    }

    // ১১. তাহাজ্জুদ
    if (lastThird != null && now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
      final remaining = pt.fajr.difference(now);
      final hr = remaining.inHours.toString().padLeft(2, '0');
      final mn = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final sc = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      alerts.add({
        'icon': '🌙',
        'text': isBn
            ? 'তাহাজ্জুদের সর্বোত্তম সময় (${_fmtTime(lastThird)} - ${_fmtTime(pt.fajr)}) — বাকি $hr:$mn:$sc। দোয়া কবুলের সময়!'
            : 'Best Tahajjud time (${_fmtTime(lastThird)} - ${_fmtTime(pt.fajr)}) — $hr:$mn:$sc left!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // ১২. পরবর্তী নামাজ ১৫ মিনিটের মধ্যে
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
      final hr = remaining.inHours.toString().padLeft(2, '0');
      final mn = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final sc = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      final nextTime = PrayerTimeHelper.getPrayerTimesMap(pt)[next];
      alerts.add({
        'icon': '🕌',
        'text': isBn
            ? '${names[next]} নামাজের সময় হতে বাকি $hr:$mn:$sc ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""}'
            : '${names[next]} in $hr:$mn:$sc ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""}',
        'color': AppTheme.accent,
      });
    }

    // ১৩. আইয়ামে বিজ
    if (h >= 13 && h <= 15) {
      alerts.add({
        'icon': '🌙',
        'text': isBn
            ? 'আজ আইয়ামে বিজের রোজার দিন (হিজরি $h তারিখ)! রোজা রাখুন।'
            : 'Today is Ayyam al-Beed (Hijri day $h)! Please fast.',
        'color': AppTheme.gold,
      });
    } else if (h == 12 && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌙',
        'text': isBn
            ? 'আগামীকাল থেকে আইয়ামে বিজের রোজা (১৩-১৫ তারিখ)! সেহরির প্রস্তুতি নিন।'
            : 'Ayyam al-Beed starts tomorrow (13th-15th)! Prepare for Sehri.',
        'color': AppTheme.gold,
      });
    }

    // ১৪. সোমবার/বৃহস্পতিবার
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
    } else if (prevDayIsSunday && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আগামীকাল সোমবার — নফল রোজার দিন! সেহরির প্রস্তুতি নিন।'
            : 'Tomorrow is Monday — Nafl fast day! Prepare for Sehri.',
        'color': const Color(0xFF7C4DFF),
      });
    } else if (prevDayIsWed && now.isAfter(pt.maghrib)) {
      alerts.add({
        'icon': '🌿',
        'text': isBn
            ? 'আগামীকাল বৃহস্পতিবার — নফল রোজার দিন! সেহরির প্রস্তুতি নিন।'
            : 'Tomorrow is Thursday — Nafl fast day! Prepare for Sehri.',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // ১৫. জুমার দিন
    if (now.weekday == DateTime.friday) {
      if (now.isBefore(pt.dhuhr.add(const Duration(hours: 1, minutes: 30)))) {
        alerts.add({
          'icon': '🕌',
          'text': isBn
              ? 'আজ জুমার দিন — জুমার নামাজ আদায় করুন। দরূদ ও দোয়া করুন।'
              : 'Today is Friday — Pray Jumu\'ah. Send Salawat & make dua.',
          'color': AppTheme.accent,
        });
      } else if (now.isBefore(pt.maghrib)) {
        alerts.add({
          'icon': '🕌',
          'text': isBn
              ? 'জুমার দিন — বেশি বেশি দরূদ পড়ুন ও দোয়া করুন (${_fmtTime(pt.maghrib)} পর্যন্ত)'
              : 'Friday — Send Salawat & make dua (until ${_fmtTime(pt.maghrib)})',
          'color': AppTheme.accent,
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
      final hr = remaining.inHours.toString().padLeft(2, '0');
      final mn = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final sc = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      alerts.add({
        'icon': '🕌',
        'text': isBn
            ? 'পরবর্তী নামাজ: ${names[next]} ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""} — বাকি $hr:$mn:$sc'
            : 'Next: ${names[next]} ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""} — in $hr:$mn:$sc',
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
                            fontSize: 14, fontWeight: FontWeight.w600),
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
                lang: lang,
                prayerTimes: _prayerTimes,
                sunnahTimes: _sunnahTimes),
            const SizedBox(height: 12),

            _TodaySection(
              lang: lang,
              todayPrayers: _todayPrayers,
              todayRoza: _todayRoza,
              prayerTimes: _prayerTimes,
              onSetPrayer: _setPrayer,
              onSetRoza: _setRoza,
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
            style: const TextStyle(
                fontSize: 52, fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        Text(lang.dayName(now.weekday), style: TextStyle(
          fontSize: 18,
          color: now.weekday == DateTime.friday
              ? AppTheme.accent : Colors.white70,
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
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(hijriDate.isEmpty
                    ? DateHelper.toHijri(now, bangla: isBn)
                    : hijriDate,
                    style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateHelper.toBangla(now),
                    style: const TextStyle(
                        color: Color(0xFF80DEEA),
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            )),
            Container(
                width: 1, height: 105, color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 10)),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timeRow('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise',
                    sunrise != null
                        ? PrayerTimeHelper.formatTime(sunrise) : '--',
                    sunColor),
                const SizedBox(height: 3),
                _timeRow('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset',
                    maghrib != null
                        ? PrayerTimeHelper.formatTime(maghrib) : '--',
                    sunColor),
                const SizedBox(height: 8),
                _timeRow('🍽️', isBn ? 'সেহরি' : 'Sehri',
                    fajr != null
                        ? PrayerTimeHelper.formatTime(fajr) : '--',
                    fastColor),
                const SizedBox(height: 3),
                _timeRow('🌙', isBn ? 'ইফতার' : 'Iftar',
                    maghrib != null
                        ? PrayerTimeHelper.formatTime(maghrib) : '--',
                    fastColor),
              ],
            )),
          ],
        ),
      ]),
    );
  }

  Widget _timeRow(String icon, String label, String time, Color color) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 3),
      Flexible(child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(children: [
          TextSpan(text: '$label ',
              style: TextStyle(color: color, fontSize: 13,
                  fontWeight: FontWeight.w700)),
          TextSpan(text: time,
              style: TextStyle(color: color, fontSize: 13,
                  fontWeight: FontWeight.bold)),
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
    required this.color, required this.icon,
    required this.lang, required this.onTap,
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
                style: TextStyle(color: color, fontSize: 13,
                    fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 6),
          Text(lang.toLocalNum(count),
              style: TextStyle(color: color, fontSize: 30,
                  fontWeight: FontWeight.bold)),
          if (suffix.isNotEmpty)
            Text(suffix,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
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
    required this.lang,
    required this.prayerTimes,
    required this.sunnahTimes,
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
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
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
                style: const TextStyle(color: AppTheme.gold,
                    fontWeight: FontWeight.bold, fontSize: 15))),
            SizedBox(width: 85, child: Text(isBn ? 'শুরু' : 'Start',
                style: const TextStyle(color: AppTheme.gold,
                    fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center)),
            SizedBox(width: 85, child: Text(isBn ? 'শেষ' : 'End',
                style: const TextStyle(color: AppTheme.gold,
                    fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center)),
          ]),
        ),
        ...prayers.map((p) {
          final isNext = nextPrayer == p['key'];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNext
                  ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(children: [
              Expanded(child: Row(children: [
                if (isNext)
                  const Icon(Icons.arrow_right, color: AppTheme.accent, size: 20),
                Text(_prayerName(p['key'] as String), style: TextStyle(
                  color: isNext ? AppTheme.gold : AppTheme.textPrimary,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                )),
              ])),
              SizedBox(width: 85, child: Text(_fmt(p['start'] as DateTime),
                  style: TextStyle(
                      color: isNext ? AppTheme.accent : AppTheme.textPrimary,
                      fontSize: 14),
                  textAlign: TextAlign.center)),
              SizedBox(width: 85, child: Text(_fmt(p['end'] as DateTime),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center)),
            ]),
          );
        }),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            const Divider(color: Colors.white10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _chip('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise',
                  _fmt(prayerTimes!.sunrise)),
              _chip('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset',
                  _fmt(prayerTimes!.maghrib)),
              _chip('🍽️', isBn ? 'সেহরি' : 'Sehri',
                  _fmt(prayerTimes!.fajr)),
              _chip('🌙', isBn ? 'ইফতার' : 'Iftar',
                  _fmt(prayerTimes!.maghrib)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String icon, String label, String time) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      Text(label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      Text(time,
          style: const TextStyle(color: AppTheme.accent, fontSize: 12,
              fontWeight: FontWeight.bold)),
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
    required this.lang, required this.todayPrayers,
    required this.todayRoza, required this.prayerTimes,
    required this.onSetPrayer, required this.onSetRoza,
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
              style: const TextStyle(color: AppTheme.gold,
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        ...prayers.map((prayer) => _TodayPrayerRow(
          name: _prayerName(prayer),
          time: _prayerTime(prayer),
          status: todayPrayers[prayer],
          lang: lang,
          onAdai: () => onSetPrayer(prayer, 'prayed'),
          onQaza: () => onSetPrayer(prayer, 'missed'),
        )),
        const Divider(color: Colors.white12),
        const SizedBox(height: 4),
        _TodayPrayerRow(
          name: lang.roza, time: '',
          status: todayRoza, lang: lang,
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
              color: isAdai ? AppTheme.completed
                  : isQaza ? AppTheme.missed
                  : AppTheme.textPrimary,
              fontSize: 16, fontWeight: FontWeight.w500)),
            if (time.isNotEmpty)
              Text(time, style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          ],
        )),
        _CircleBtn(
          icon: Icons.check,
          label: lang.isBn ? 'আদায়' : 'Prayed',
          color: AppTheme.completed,
          selected: isAdai,
          onTap: onAdai,
        ),
        const SizedBox(width: 12),
        _CircleBtn(
          icon: Icons.close,
          label: lang.isBn ? 'কাযা' : 'Qaza',
          color: AppTheme.missed,
          selected: isQaza,
          onTap: onQaza,
        ),
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
                ? [BoxShadow(color: color.withOpacity(0.4),
                blurRadius: 8, spreadRadius: 1)]
                : [],
          ),
          child: Icon(icon,
              color: selected ? Colors.white : color, size: 26),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(
          color: selected ? color : AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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

  static int _gjToJul(int y, int m, int d) {
    int a = (14 - m) ~/ 12;
    int yr = y + 4800 - a;
    int mo = m + 12 * a - 3;
    return d + (153 * mo + 2) ~/ 5 + 365 * yr +
        yr ~/ 4 - yr ~/ 100 + yr ~/ 400 - 32045;
  }
}
