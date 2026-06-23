import 'dart:async';
import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
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

  // ══ লোকেশন ও আবহাওয়া ══
  String _locationName = '';
  String _weatherText = '';
  String _weatherIcon = '🌤️';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _loadToday();
    _loadHijri();
    _fetchLocationAndWeather();
    _autoQazaTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _checkAndAutoMarkQaza();
      if (mounted) _updateHomeWidget();
    });
    // আবহাওয়া প্রতি ১৫ মিনিটে আপডেট
    Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) _fetchLocationAndWeather();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkAndAutoMarkQaza();
      if (mounted) _updateHomeWidget();
    });
  }

  // ══ Home Screen Widget এ data পাঠানো (হোমস্ক্রিনের widget আপডেট) ══
  Future<void> _updateHomeWidget() async {
    try {
      final pt = _prayerTimes;
      if (pt == null) {
        debugPrint('WIDGET: prayerTimes null, skip');
        return;
      }
      final isBn = widget.lang.isBn;
      final now = DateTime.now();

      await HomeWidget.saveWidgetData('widget_time', DateHelper.formatTime12(now, bangla: isBn));
      await HomeWidget.saveWidgetData('widget_day', widget.lang.dayName(now.weekday));
      await HomeWidget.saveWidgetData('widget_gregorian', DateHelper.formatGregorian(now, bangla: isBn));
      await HomeWidget.saveWidgetData('widget_hijri',
          _hijriDate.isEmpty ? DateHelper.toHijri(now, bangla: isBn) : _hijriDate);
      await HomeWidget.saveWidgetData('widget_bangla_date', DateHelper.toBangla(now));
      await HomeWidget.saveWidgetData('widget_sunrise',
          (isBn ? '🌅 সূর্যোদয় ' : '🌅 Sunrise ') + PrayerTimeHelper.formatTime(pt.sunrise));
      await HomeWidget.saveWidgetData('widget_sunset',
          (isBn ? '🌇 সূর্যাস্ত ' : '🌇 Sunset ') + PrayerTimeHelper.formatTime(pt.maghrib));
      await HomeWidget.saveWidgetData('widget_sehri',
          (isBn ? '🍽️ সেহরি ' : '🍽️ Sehri ') + PrayerTimeHelper.formatTime(pt.fajr));
      await HomeWidget.saveWidgetData('widget_iftar',
          (isBn ? '🌙 ইফতার ' : '🌙 Iftar ') + PrayerTimeHelper.formatTime(pt.maghrib));

      // আবহাওয়া save
      await HomeWidget.saveWidgetData('widget_weather',
          _weatherText.isEmpty ? '' : '$_weatherIcon $_weatherText');

      // alert: নিষিদ্ধ সময়ে শুধু সেটাই দেখাও, নইলে rotating
      final alertList = _getLiveAlerts(widget.lang);
      final forbiddenAlerts = alertList.where((a) =>
          (a['text'] as String).contains('নিষিদ্ধ') ||
          (a['text'] as String).contains('Forbidden')).toList();
      final String alertText;
      if (forbiddenAlerts.isNotEmpty) {
        // নিষিদ্ধ সময় — শুধু এই সতর্কবার্তাই দেখাও
        alertText = '${forbiddenAlerts.first['icon']} ${(forbiddenAlerts.first['text'] as String).split('\n').first}';
      } else {
        alertText = alertList.isEmpty
            ? ''
            : alertList.map((a) =>
                '${a['icon']} ${(a['text'] as String).split('\n').first}'
              ).join(' | ');
      }
      await HomeWidget.saveWidgetData('widget_alert', alertText);

      await HomeWidget.updateWidget(
        name: 'PrayerWidgetProvider',
        androidName: 'com.example.moni_prayer.PrayerWidgetProvider',
      );
      debugPrint('WIDGET: update success');
    } catch (e) {
      debugPrint('WIDGET ERROR: $e');
    }
  }

  // ══ লোকেশন ও আবহাওয়া fetch ══
  Future<void> _fetchLocationAndWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;

      // Reverse geocode via nominatim (free, no API key)
      final geoUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&accept-language=bn',
      );
      final geoRes = await http.get(geoUrl, headers: {'User-Agent': 'MoniPrayerApp/1.0'});
      if (geoRes.statusCode == 200) {
        final geoData = jsonDecode(geoRes.body);
        final addr = geoData['address'] as Map<String, dynamic>? ?? {};
        final sub = addr['suburb'] ?? addr['village'] ?? addr['town'] ?? addr['city_district'] ?? addr['neighbourhood'] ?? '';
        final district = addr['county'] ?? addr['state_district'] ?? addr['city'] ?? '';
        final locationStr = [sub, district].where((s) => s.toString().isNotEmpty).join(', ');
        if (mounted && locationStr.isNotEmpty) {
          setState(() => _locationName = locationStr);
        }
      }

      // আবহাওয়া: Open-Meteo (free, no API key, caiyunapp এর মতো ডাটা)
      final wUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${pos.latitude}&longitude=${pos.longitude}'
        '&current=temperature_2m,apparent_temperature,weathercode,windspeed_10m'
        '&timezone=auto',
      );
      final wRes = await http.get(wUrl);
      if (wRes.statusCode == 200) {
        final wData = jsonDecode(wRes.body);
        final current = wData['current'] as Map<String, dynamic>? ?? {};
        final temp = (current['temperature_2m'] ?? 0).round();
        final feelsLike = (current['apparent_temperature'] ?? 0).round();
        final wcode = current['weathercode'] ?? 0;
        final isBn = widget.lang.isBn;
        final icon = _weatherCodeIcon(wcode);
        final desc = _weatherCodeDesc(wcode, isBn);
        if (mounted) {
          setState(() {
            _weatherIcon = icon;
            _weatherText = isBn
                ? '$temp°C (অনুভব ${feelsLike}°C) $desc'
                : '${temp}°C (feels ${feelsLike}°C) $desc';
          });
        }
      }
    } catch (e) {
      debugPrint('Location/Weather error: $e');
    }
  }

  String _weatherCodeIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌤️';
  }

  String _weatherCodeDesc(int code, bool isBn) {
    if (code == 0) return isBn ? 'পরিষ্কার আকাশ' : 'Clear sky';
    if (code == 1) return isBn ? 'প্রায় পরিষ্কার' : 'Mainly clear';
    if (code == 2) return isBn ? 'আংশিক মেঘলা' : 'Partly cloudy';
    if (code == 3) return isBn ? 'মেঘলা' : 'Overcast';
    if (code <= 49) return isBn ? 'কুয়াশা' : 'Foggy';
    if (code <= 55) return isBn ? 'গুঁড়ি বৃষ্টি' : 'Drizzle';
    if (code <= 65) return isBn ? 'বৃষ্টি' : 'Rain';
    if (code <= 67) return isBn ? 'ঠান্ডা বৃষ্টি' : 'Freezing rain';
    if (code <= 77) return isBn ? 'তুষারপাত' : 'Snowfall';
    if (code <= 82) return isBn ? 'বৃষ্টি ঝরছে' : 'Rain showers';
    if (code <= 86) return isBn ? 'তুষার ঝড়' : 'Snow showers';
    if (code <= 99) return isBn ? 'বজ্রঝড়' : 'Thunderstorm';
    return '';
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
    // রাতের সঠিক ১/৩ অংশ ম্যানুয়ালি হিসাব — মাগরিব থেকে পরের দিনের ফজর পর্যন্ত
    // (adhan package এর lastThirdOfTheNight কখনো ভুল asymmetric রাত ধরতে পারে, তাই নিজে হিসাব করছি)
    final nextFajr = pt.fajr.isAfter(pt.maghrib)
        ? pt.fajr
        : pt.fajr.add(const Duration(days: 1));
    final nightDuration = nextFajr.difference(pt.maghrib);
    final manualLastThird = pt.maghrib.add(
      Duration(milliseconds: (nightDuration.inMilliseconds * 2 / 3).round()),
    );
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
    final ishaaEnd = manualLastThird;

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
    // ══ তাহাজ্জুদ — সময় বাকি + ফজিলত + নির্দেশনা (এশার পর থেকে ফজরের আগ পর্যন্ত) ══
    final tahajjudStart = manualLastThird;
    if (now.isAfter(pt.isha) && now.isBefore(tahajjudStart)) {
      // তাহাজ্জুদের উত্তম সময় শুরু হতে বাকি
      final cd = _countdown(tahajjudStart);
      alerts.add({'icon': '🌙', 'text': isBn ? 'তাহাজ্জুদের সর্বোত্তম সময় শুরু হতে বাকি $cd' : 'Best Tahajjud time starts in $cd', 'color': const Color(0xFF7C4DFF)});
    } else if (now.isAfter(tahajjudStart) && now.isBefore(pt.fajr)) {
      // তাহাজ্জুদের সময় চলছে — ফজর শুরু হওয়া পর্যন্ত বাকি সময়
      final cd = _countdown(pt.fajr);
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'তাহাজ্জুদের সময় বাকি আছে — $cd (ফজরের আগ পর্যন্ত)'
          : 'Tahajjud time remaining — $cd (until Fajr)', 'color': const Color(0xFF7C4DFF)});
      alerts.add({'icon': '✨', 'text': isBn
          ? 'তাহাজ্জুদের ফজিলত:\n◆ আল্লাহ এ সময় নিচের আকাশে নেমে আসেন: "কে দোয়া করছে? আমি কবুল করব" (বুখারি: ১১৪৫)\n◆ এটি ফরজ ছাড়া সর্বোত্তম নামাজ (মুসলিম: ১১৬৩)\n◆ তাহাজ্জুদ আদায়কারীদের জন্য জান্নাতে বিশেষ মর্যাদা (সূরা সাজদাহ: ১৬-১৭)\n◆ দোয়া কবুলের সবচেয়ে উপযুক্ত সময়'
          : 'Tahajjud Virtues:\n◆ Allah descends to the lowest heaven now: "Who is asking? I will grant" (Bukhari: 1145)\n◆ Best prayer after the obligatory ones (Muslim: 1163)\n◆ Special rank in Jannah for those who pray it (Surah Sajdah: 16-17)\n◆ Most suitable time for dua acceptance', 'color': const Color(0xFF7C4DFF)});
      alerts.add({'icon': '📋', 'text': isBn
          ? 'তাহাজ্জুদ পড়ার নির্দেশনা:\n◆ কমপক্ষে ২ রাকাত, সামর্থ্য অনুযায়ী বেশি পড়তে পারেন\n◆ প্রতি ২ রাকাত পর সালাম দিন\n◆ দীর্ঘ কিরাত ও ধীরে ধীরে পড়ুন\n◆ সিজদায় বেশি বেশি দোয়া করুন\n◆ "রাতের কিছু অংশে তাহাজ্জুদ পড়বে" (সূরা বনি ইসরাঈল: ৭৯)'
          : 'How to pray Tahajjud:\n◆ At least 2 rakats, more if able\n◆ Give Salam after every 2 rakats\n◆ Recite slowly with long Qiraat\n◆ Make abundant dua in Sujood\n◆ "Pray Tahajjud at night" (Surah Bani Isra\'il: 79)', 'color': const Color(0xFF7C4DFF)});
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

    // ══ রাতের reminder — শুধু এশার পর থেকে ঘুমানো পর্যন্ত ══
    if (now.isAfter(pt.isha)) {
      alerts.add({'icon': '📖', 'text': isBn ? 'ঘুমানোর আগে সূরা মুলক পড়তে ভুলবেন না — কবরের আযাব থেকে রক্ষা করবে।' : 'Don\'t forget Surah Mulk before sleep — protection from grave punishment.', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ সন্ধ্যার reminder (মাগরিবের পর) ══
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      alerts.add({'icon': '🏠', 'text': isBn
          ? 'ঘরে ফেরার সুন্নত:\n◆ ডান পা দিয়ে প্রবেশ করুন\n◆ "বিসমিল্লা-হি ওয়ালাজনা, ওয়াবিসমিল্লা-হি খারাজনা, ওয়া আলাল্লা-হি রাব্বিনা তাওয়াক্কালনা" পড়ুন\n◆ পরিবারকে সালাম দিন'
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

      // ৯ জিলহজ: আরাফার দিনের reminder — শুধু সেহরি শেষ হওয়া পর্যন্ত
      if (h == 9 && now.isBefore(pt.fajr)) {
        alerts.add({'icon': '🕋', 'text': isBn ? 'আজ ৯ জিলহজ — আরাফার দিন! রোজা রাখুন, বেশি দোয়া করুন। আগের ও পরের ১ বছরের গুনাহ মাফ হবে ইনশাআল্লাহ।' : 'Today 9 Dhul Hijjah — Day of Arafah! Fast & make lots of dua. 2 years sins forgiven.', 'color': AppTheme.gold});
        // আরাফার ইফতারের আগে ৩০ মিনিট
        if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 30))) && now.isBefore(pt.maghrib)) {
          final cd = _countdown(pt.maghrib);
          alerts.add({'icon': '🤲', 'text': isBn ? 'আরাফার রোজার ইফতার হতে বাকি $cd — রোজাদার অবস্থায় এখন দোয়া করুন! এই মুহূর্তের দোয়া কবুল হয়।' : 'Arafah Iftar in $cd — Make dua now as a fasting person!', 'color': AppTheme.gold});
        }
      }

      // ৯ আসরের পর থেকে ১৩ পর্যন্ত: তাকবিরে তাশরিক
      if ((h == 9 && now.isAfter(pt.asr)) || (h >= 10 && h <= 13)) {
        alerts.add({'icon': '📢', 'text': isBn ? 'তাকবিরে তাশরিক: প্রতি ফরজ নামাজের পর পড়ুন —\nআল্লাহু আকবর, আল্লাহু আকবর, লা ইলাহা ইল্লাল্লাহু, ওয়াল্লাহু আকবর, আল্লাহু আকবর, ওয়ালিল্লাহিল হামদ।' : 'Takbeer al-Tashriq after every Fard: Allahu Akbar, Allahu Akbar...', 'color': const Color(0xFFFF8F00)});
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

    // ══ Default: পরবর্তী নামাজ ══
    if (alerts.isEmpty) {
      if (next != null && remaining != null) {
        final names = {'fajr': isBn ? 'ফজর' : 'Fajr', 'dhuhr': isBn ? 'যোহর' : 'Dhuhr', 'asr': isBn ? 'আসর' : 'Asr', 'maghrib': isBn ? 'মাগরিব' : 'Maghrib', 'isha': isBn ? 'এশা' : 'Isha'};
        final nextTime = PrayerTimeHelper.getPrayerTimesMap(pt)[next];
        final cd = nextTime != null ? _countdown(nextTime) : '';
        alerts.add({'icon': '🕌', 'text': isBn ? 'পরবর্তী নামাজ: ${names[next]} ${nextTime != null ? "(${_fmtTime(nextTime)})" : ""} — বাকি $cd' : 'Next: ${names[next]} — in $cd', 'color': AppTheme.accent});
      }
    }

    return alerts;
  }

  // ══ নফল আমল ও বিশেষ দিনের alerts (আজকের নামাজ ও রোজার নিচে দেখাবে) ══
  List<Map<String, dynamic>> _getNaflAmalAlerts(AppLanguage lang) {
    final isBn = lang.isBn;
    final now = DateTime.now();
    final pt = _prayerTimes;
    final alerts = <Map<String, dynamic>>[];
    if (pt == null) return alerts;

    final h = _HijriSimple.fromDate(now);
    final hijriMonth = _HijriSimple.getMonth(now);

    // ══ ফজর ও মাগরিবের ওয়াক্তে বিশেষ দোয়া ও সূরা — খুবই গুরুত্বপূর্ণ ══
    final isFajrWaqt = now.isAfter(pt.fajr) && now.isBefore(pt.sunrise);
    final isMaghribWaqt = now.isAfter(pt.maghrib) && now.isBefore(pt.isha);
    if (isFajrWaqt || isMaghribWaqt) {
      final waqtName = isBn
          ? (isFajrWaqt ? 'ফজরের ওয়াক্ত' : 'মাগরিবের ওয়াক্ত')
          : (isFajrWaqt ? 'Fajr time' : 'Maghrib time');
      alerts.add({'icon': '⭐', 'text': isBn
          ? '($waqtName) এখনই পড়ুন — ওয়াক্ত শেষে চলে যাবে!\n\n'
            '৩ বার পড়ুন:\nআউযু বিল্লাহিস সামীঈল আলীমি মিনাশ শাইত্বোয়ানির রাজীম\n\n'
            '━ সূরা হাশর (শেষ ৩ আয়াত) ━\n'
            'হুওয়াল্লা হুল্লাযী লা- ইলাহা ইল্লা হুওয়া আলিমুল গাইবি ওয়াশ শাহাদাহ। হুওয়ার রহমানুর রহীম।\n\n'
            'হুওয়াল্লা হুল্লাযী লা- ইলাহা ইল্লা হুওয়াল মালিকুল কুদ্দুসুস সালামুল মুমিনুল মুহাইমিনুল আযীযুল জাব্বারুল মুতাকাব্বির। সুবহানাল্লাহি আম্মা ইউশরিকুন।\n\n'
            'হুওয়াল্লাহুল খলিকুল বারিউল মুসাওবিরু লাহুল আসমাউল হুসনা। ইউসাব্বিহু লাহু মা ফিস সামাওয়াতি ওয়াল আরদি, ওয়া হুওয়াল আযীযুল হাকীম।\n\n'
            '━ আয়তুল কুরসি ━\n'
            'আল্লাহু লা-ইলাহা ইল্লা হু-ওয়াল হাই-য়্যুল ক্বাই-য়্যুম। লা তা-খুযুহু সিনাতুঁ ওয়ালা না-উম। লাহূ মা ফিস-সামা-ওয়াতি ওয়ামা ফিল আর-দ্ব। মান যাল্লা-যী ইয়াশ-ফাউ ই-ন্দাহূ ইল্লা বিইজ-নিহ। ইয়া-লামু মা-বাইনা আইদি-হিম ওয়ামা খালফাহুম। ওয়ালা ইউহি-তূনা বিশাইয়্যিম্ মিন ইলমিহি ইল্লা বিমা শাআ’। ওয়াসি-আ’ কুরসিইয়্যুহুস সামা-ওয়াতি ওয়াল আরদ্ব। ওয়ালা ইয়াউ-দুহূ হিফযুহুমা ওয়া হুওয়াল আলিই-য়্যুল আ-জিম।\n\n'
            '━ সূরা কাফিরুন ━\n'
            'কুল ইয়া আইয়ুহাল কাফিরুন। লা আবুদু মা তাবুদুন। ওয়ালা আনতুম আবিদুনা মা আবুদ। ওয়ালা আনা আবিদুম মা আবাত্তুম। ওয়ালা আনতুম আবিদুনা মা আবুদ। লাকুম দীনুকুম ওয়ালিয়া দীন।\n\n'
            '━ সূরা ইখলাস ━\n'
            'কুল হুওয়াল্লাহু আহাদ। আল্লাহুস সামাদ। লাম ইয়ালিদ ওয়ালাম ইউলাদ। ওয়ালাম ইয়াকুল্লাহু কুফুওয়ান আহাদ।\n\n'
            '━ সূরা ফালাক ━\n'
            'কুল আউযু বিরব্বিল ফালাক। মিন শাররি মা খালাক। ওয়া মিন শাররি গাসিকিন ইযা ওয়াকাব। ওয়া মিন শাররিন নাফ্ফাসাতি ফিল উকাদ। ওয়া মিন শাররি হাসিদিন ইযা হাসাদ।\n\n'
            '━ সূরা নাস ━\n'
            'কুল আউযু বিরব্বিন নাস। মালিকিন নাস। ইলাহিন নাস। মিন শাররিল ওয়াসওয়াসিল খান্নাস। আল্লাযী ইউওয়াসবিসু ফী সুদুরিন নাস। মিনাল জিন্নাতি ওয়ান নাস।'
          : '($waqtName) Read now — disappears after waqt!\n\n'
            'Read 3 times:\nAuzubillahis Sami\'il Alimi minash Shaitanir Rajim\n\n'
            '━ Surah Hashr (last 3 verses) ━\n'
            'Huwallahullazi la ilaha illa Huwa Alimul ghaibi wash shahadah. Huwar Rahmanur Rahim.\n'
            'Huwallahullazi la ilaha illa Huwal Malikul Quddusus Salamul Muminul Muhaiminul Azizul Jabbarul Mutakabbir. Subhanallahi amma yushrikun.\n'
            'Huwallahul Khaliqul Bari\'ul Musawwiru lahul asmaul husna. Yusabbihu lahu ma fis samawati wal ardi wa Huwal Azizul Hakim.\n\n'
            '━ Surah Kafirun ━\n'
            'Qul ya ayyuhal kafirun. La abudu ma tabudun. Wala antum abiduna ma abud. Wala ana abidum ma abattum. Wala antum abiduna ma abud. Lakum dinukum waliya din.\n\n'
            '━ Surah Ikhlas ━\n'
            'Qul Huwallahu Ahad. Allahus Samad. Lam yalid walam yulad. Walam yakul lahu kufuwan ahad.\n\n'
            '━ Surah Falaq ━\n'
            'Qul auzhu birabbil falaq. Min sharri ma khalaq. Wa min sharri ghasiqin iza waqab. Wa min sharrin naffasati fil uqad. Wa min sharri hasidin iza hasad.\n\n'
            '━ Surah Nas ━\n'
            'Qul auzhu birabbin nas. Malikin nas. Ilahin nas. Min sharril waswasil khannas. Alladhi yuwaswisu fi sudurin nas. Minal jinnati wan nas.',
          'color': AppTheme.gold});
    }

    // ══ রাতের reminder — শুধু এশার পর থেকে ঘুমানো পর্যন্ত ══
    if (now.isAfter(pt.isha)) {
      alerts.add({'icon': '📖', 'text': isBn ? 'ঘুমানোর আগে সূরা মুলক পড়তে ভুলবেন না — কবরের আযাব থেকে রক্ষা করবে।' : 'Don\'t forget Surah Mulk before sleep — protection from grave punishment.', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ সন্ধ্যার reminder (মাগরিবের পর) ══
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      alerts.add({'icon': '🏠', 'text': isBn
          ? 'ঘরে ফেরার সুন্নত:\n◆ ডান পা দিয়ে প্রবেশ করুন\n◆ "বিসমিল্লা-হি ওয়ালাজনা, ওয়াবিসমিল্লা-হি খারাজনা, ওয়া আলাল্লা-হি রাব্বিনা তাওয়াক্কালনা" পড়ুন\n◆ পরিবারকে সালাম দিন'
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
      // ১-৯ জিলহজ: ফজিলত ও আমলের reminder
      if (h >= 1 && h <= 9) {
        alerts.add({'icon': '🕋', 'text': isBn
            ? 'আজ $h জিলহজ — বছরের শ্রেষ্ঠ দিন!\n◆ এই দিনের আমল জিহাদের চেয়েও উত্তম (বুখারি)\n◆ সূরা ফাজরে আল্লাহ এই ১০ রাতের শপথ করেছেন\n◆ প্রতিটি মুহূর্ত ইবাদতে কাজে লাগান'
            : 'Today $h Dhul Hijjah — Best days of the year!\n◆ Worship better than Jihad (Bukhari)\n◆ Allah swore by these 10 nights in Surah Fajr', 'color': AppTheme.gold});
        alerts.add({'icon': '📿', 'text': isBn
            ? 'জিলহজের জিকির বেশি বেশি পড়ুন:\n◆ তাহলিল: লা ইলাহা ইল্লাল্লাহ\n◆ তাকবির: আল্লাহু আকবার\n◆ তাহমিদ: আলহামদুলিল্লাহ\n◆ তাসবিহ: সুবহানাল্লাহ\n(মুসনাদে আহমাদ: ৫৪৪৬)'
            : 'Dhul Hijjah Dhikr:\n◆ Tahlil: La ilaha illallah\n◆ Takbeer: Allahu Akbar\n◆ Tahmeed: Alhamdulillah\n◆ Tasbeeh: Subhanallah (Ahmad: 5446)', 'color': const Color(0xFF7C4DFF)});
        alerts.add({'icon': '🤲', 'text': isBn
            ? 'জিলহজের বিশেষ আমলসমূহ:\n◆ তওবা ও ইস্তিগফার করুন\n◆ দান-সদকা বাড়িয়ে দিন (সওয়াব বহুগুণ)\n◆ আত্মীয়তার সম্পর্ক জোরদার করুন\n◆ পাপাচার থেকে সম্পূর্ণ বিরত থাকুন'
            : 'Dhul Hijjah special deeds:\n◆ Make Tawbah & Istighfar\n◆ Give Sadaqah (multiplied reward)\n◆ Strengthen family ties\n◆ Avoid all sins', 'color': const Color(0xFF26A69A)});
      }

      // ১-৮ জিলহজ সেহরির আগে: রোজার reminder
      if (h >= 1 && h <= 8 && now.isBefore(pt.fajr)) {
        alerts.add({'icon': '🌙', 'text': isBn
            ? '$h জিলহজ — আজ রোজা রাখুন!\n◆ রাসূল ﷺ প্রথম ৯ দিন রোজা রাখতেন\n◆ হাফসা (রা.) বর্ণিত: এই আমল তিনি কখনো ছাড়তেন না\n◆ (সুনানে আবু দাউদ: ২১০৬)'
            : '$h Dhul Hijjah — Keep fast!\n◆ Prophet ﷺ fasted first 9 days\n◆ Never missed this (Abu Dawud: 2106)', 'color': const Color(0xFF81C784)});
      }

      // ১-১০ জিলহজ: চুল-নখ না কাটার reminder
      if (h >= 1 && h <= 10) {
        alerts.add({'icon': '✂️', 'text': isBn
            ? 'জিলহজের সুন্নত (কুরবানিদাতার জন্য):\n◆ কুরবানি সম্পন্ন না হওয়া পর্যন্ত চুল, নখ ও গোঁফ কাটবেন না\n◆ এতে কুরবানির পূর্ণ সওয়াব পাবেন\n◆ (সহিহ মুসলিম, ইবনে হিব্বান)'
            : 'Dhul Hijjah Sunnah (for those sacrificing):\n◆ Don\'t cut hair, nails or mustache until Qurbani\n◆ Gain full Qurbani reward (Muslim, Ibn Hibban)', 'color': const Color(0xFF26A69A)});
      }

      // ৮ জিলহজ সন্ধ্যায়: আরাফার রোজার আগাম reminder
      if (h == 8 && now.isAfter(pt.maghrib)) {
        alerts.add({'icon': '🕋', 'text': isBn
            ? 'আগামীকাল ৯ জিলহজ — আরাফার দিন!\n◆ রোজা রাখলে আগের ও পরের ১ বছরের গুনাহ মাফ (মুসলিম)\n◆ এখনই সেহরির প্রস্তুতি নিন\n◆ বেশি বেশি দোয়া ও জিকির করুন'
            : 'Tomorrow 9 Dhul Hijjah — Day of Arafah!\n◆ Fasting forgives 2 years of sins (Muslim)\n◆ Prepare for Sehri now', 'color': AppTheme.gold});
      }

      // ৯ জিলহজ: আরাফার দিনের reminder — শুধু সেহরি শেষ হওয়া পর্যন্ত
      if (h == 9 && now.isBefore(pt.fajr)) {
        alerts.add({'icon': '🕋', 'text': isBn
            ? 'আজ ৯ জিলহজ — আরাফার দিন!\n◆ রোজা রাখুন — আগের ও পরের ১ বছরের গুনাহ মাফ ইনশাআল্লাহ (মুসলিম)\n◆ আরাফার রাত মুজদালিফায় অবস্থান — শবে কদরের মতো গুরুত্বপূর্ণ\n◆ বেশি বেশি দোয়া ও ইস্তিগফার করুন'
            : 'Today 9 Dhul Hijjah — Day of Arafah!\n◆ Fast — 2 years sins forgiven insha\'Allah (Muslim)\n◆ Night at Muzdalifah — like Laylatul Qadr in importance\n◆ Make lots of dua & Istighfar', 'color': AppTheme.gold});
        if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 30))) && now.isBefore(pt.maghrib)) {
          final cd = _countdown(pt.maghrib);
          alerts.add({'icon': '🤲', 'text': isBn ? 'আরাফার রোজার ইফতার হতে বাকি $cd — রোজাদার অবস্থায় এখন দোয়া করুন! এই মুহূর্তের দোয়া কবুল হয়।' : 'Arafah Iftar in $cd — Make dua now as a fasting person!', 'color': AppTheme.gold});
        }
      }

      // ৯ আসরের পর থেকে ১৩ পর্যন্ত: তাকবিরে তাশরিক
      if ((h == 9 && now.isAfter(pt.asr)) || (h >= 10 && h <= 13)) {
        alerts.add({'icon': '📢', 'text': isBn
            ? 'তাকবিরে তাশরিক (ওয়াজিব):\n◆ প্রতি ফরজ নামাজের পর পড়ুন\n◆ ৯ জিলহজ ফজর থেকে ১৩ জিলহজ আসর পর্যন্ত — মোট ২৩ ওয়াক্ত\n◆ পুরুষ: উচ্চ স্বরে | মহিলা: নিচু স্বরে\n◆ আল্লাহু আকবর, আল্লাহু আকবর, লা ইলাহা ইল্লাল্লাহু, ওয়াল্লাহু আকবর, আল্লাহু আকবর, ওয়ালিল্লাহিল হামদ।'
            : 'Takbeer al-Tashriq (Wajib):\n◆ After every Fard prayer\n◆ From 9 Dhul Hijjah Fajr to 13 Dhul Hijjah Asr (23 prayers)\n◆ Men: aloud | Women: softly\n◆ Allahu Akbar, Allahu Akbar, La ilaha illallahu wallahu Akbar, Allahu Akbar wa lillahil hamd', 'color': const Color(0xFFFF8F00)});
      }

      // ১০ জিলহজ: ঈদুল আযহা
      if (h == 10) {
        alerts.add({'icon': '🎉', 'text': isBn
            ? 'আজ ১০ জিলহজ — ঈদুল আযহা মোবারক!\n◆ ঈদের নামাজ জামাতে আদায় করুন (ওয়াজিব)\n◆ সামর্থ্য থাকলে কুরবানি করুন\n◆ কুরবানির গোশত আত্মীয়দের মাঝে বণ্টন করুন\n◆ ঈদের দিন কোনো নফল রোজা রাখবেন না'
            : 'Today 10 Dhul Hijjah — Eid al-Adha Mubarak!\n◆ Pray Eid Salah in congregation\n◆ Perform Qurbani if able\n◆ Distribute meat to relatives\n◆ No nafl fasting today', 'color': AppTheme.gold});
        alerts.add({'icon': '🐄', 'text': isBn
            ? 'কুরবানির ফজিলত:\n◆ কুরবানির রক্ত জমিনে পড়ার আগেই আল্লাহর কাছে কবুল হয়\n◆ কিয়ামতে শিং, পশম ও ক্ষুরসহ উপস্থিত করা হবে\n◆ সন্তুষ্টচিত্তে কুরবানি করুন\n◆ (জামে তিরমিজি: ১৪৯৩)'
            : 'Qurbani reward:\n◆ Accepted before blood touches ground\n◆ Presented with horns, hair & hooves on Qiyamah\n◆ Sacrifice with a content heart (Tirmidhi: 1493)', 'color': const Color(0xFFFF8F00)});
      }

      // ১১-১৩ জিলহজ: আইয়ামে তাশরিক
      if (h >= 11 && h <= 13) {
        alerts.add({'icon': '🕋', 'text': isBn
            ? 'আজ আইয়ামে তাশরিকের দিন ($h জিলহজ):\n◆ প্রতি ফরজ নামাজের পর তাকবিরে তাশরিক পড়ুন\n◆ এই তিন দিনে নফল রোজা রাখা নিষেধ\n◆ বেশি বেশি জিকির ও দোয়া করুন'
            : 'Today is Ayyam al-Tashriq ($h Dhul Hijjah):\n◆ Continue Takbeer al-Tashriq after every Fard\n◆ Nafl fasting forbidden these 3 days\n◆ Increase dhikr & dua', 'color': const Color(0xFFFF8F00)});
      }

      // সার্বক্ষণিক হজের reminder (১-১৩ জিলহজ)
      if (h >= 1 && h <= 13) {
        alerts.add({'icon': '🕌', 'text': isBn
            ? 'হজের ফজিলত:\n◆ মাবরুর হজের একমাত্র পুরস্কার জান্নাত (বুখারি: ১৭৭৩)\n◆ সামর্থ্যবান হলে জীবনে একবার হজ ফরজ\n◆ হজের মাধ্যমে সব পাপ মাফ হয়\n◆ সক্ষম হলে এখনই প্রস্তুতি নিন'
            : 'Hajj reward:\n◆ Only reward for Mabrur Hajj is Jannah (Bukhari: 1773)\n◆ Obligatory once for those able\n◆ All sins forgiven\n◆ Start preparing if able', 'color': const Color(0xFF7C4DFF)});
      }
    }

    // ══ রমজানের reminder (শাবান মাসে ২৫-২৯ তারিখ) ══
    if (hijriMonth == 8 && h >= 25) {
      alerts.add({'icon': '🌙', 'text': isBn ? 'রমজান আসছে — এখনই নিয়ত ও প্রস্তুতি নিন। রমজানে উমরাহর সওয়াব হজের সমান!' : 'Ramadan is coming — Prepare now. Umrah in Ramadan equals Hajj in reward!', 'color': const Color(0xFF7C4DFF)});
    }

    // ══════════════════════════════════════════════════
    // নতুন আমলসমূহ — সময়ভিত্তিক নোটিফিকেশন
    // ══════════════════════════════════════════════════

    // ══ ফজরের পরের আমল ══
    if (now.isAfter(pt.fajr) && now.isBefore(pt.sunrise)) {
      alerts.add({'icon': '🌅', 'text': isBn
          ? 'ফজরের পরের আমল:\n◆ নামাজের জায়গায় বসে জিকির করুন\n◆ সূর্য উঠলে ২ রাকাত ইশরাক পড়ুন — হজ ও উমরার সওয়াব!\n◆ ফজরের পর না ঘুমানো সুন্নত — রাসূল ﷺ উম্মতের জন্য সকালে বরকতের দোয়া করেছেন\n◆ তাহিয়্যাতুল অযু আদায় করুন'
          : 'After Fajr deeds:\n◆ Stay & make dhikr\n◆ Pray 2 rakat Ishraq after sunrise — Hajj & Umrah reward!\n◆ Don\'t sleep after Fajr — Prophet ﷺ made dua for morning blessings', 'color': const Color(0xFFFDD835)});
      alerts.add({'icon': '📿', 'text': isBn
          ? 'ফজর ও মাগরিবের পরের বিশেষ আমল:\n◆ সূরা হাশরের শেষ তিন আয়াত পড়ুন\n◆ আয়াতুল কুরসি পড়ুন — মৃত্যু পর্যন্ত জান্নাতে যাওয়ার পথ খোলা থাকবে (নাসাই: ৯৭২)\n◆ তিন কূল (ইখলাস, ফালাক, নাস) পড়ে শরীরে দম করুন\n◆ সূরা কাফিরুন পড়ুন'
          : 'After Fajr & Maghrib:\n◆ Last 3 verses of Surah Hashr\n◆ Ayatul Kursi — path to Jannah opened (Nasai: 972)\n◆ 3 Quls, blow on body\n◆ Surah Kafirun', 'color': const Color(0xFF7C4DFF)});
      alerts.add({'icon': '✨', 'text': isBn
          ? 'ফজরের পর তাসবিহ:\n◆ ৩৩ বার সুবহানাল্লাহ\n◆ ৩৩ বার আলহামদুলিল্লাহ\n◆ ৩৪ বার আল্লাহু আকবার\n◆ ১ বার লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু লা-শারিকালাহু লাহুল মুলকু ওয়া লাহুল হামদু ওয়া হুয়া আলা কুল্লি শাইয়িন কাদির। পড়লে সব পাপ মাফ (মুসলিম: ১২২৮)'
          : 'After Fajr Tasbih:\n◆ 33x Subhanallah\n◆ 33x Alhamdulillah\n◆ 34x Allahu Akbar\n◆ 1x La ilaha illallahu... all sins forgiven (Muslim: 1228)', 'color': const Color(0xFF26A69A)});
    }

    // ══ সকালের আমল (ফজর থেকে দুপুর) ══
    if (now.isAfter(pt.fajr) && now.isBefore(pt.dhuhr)) {
      alerts.add({'icon': '☀️', 'text': isBn
          ? 'সকালের আমল:\n◆ সকালে ১০ বার দরুদ পড়ুন — রাসূল ﷺ-এর সুপারিশ নিশ্চিত (তিবরানি: ৬৫৬)\n◆ ১০০ বার সুবহানাল্লাহিল আজিম ওয়া বিহামদিহি — সৃষ্টিকুলের সবার চেয়ে বেশি মর্যাদা (আবু দাউদ: ৫০৯১)\n◆ আজান শুনলে সাথে সাথে জবাব দিন ও দোয়া করুন'
          : 'Morning deeds:\n◆ 10x Salawat — Guaranteed Prophet\'s intercession (Tirmidhi: 656)\n◆ 100x Subhanallahil Azim — highest rank among creation (Abu Dawud: 5091)\n◆ Answer the Adhan & make dua', 'color': const Color(0xFFFDD835)});
      alerts.add({'icon': '🚶', 'text': isBn
          ? 'সকালের সুন্নত:\n◆ ঘর থেকে বের হলে ডান পা দিয়ে বিসমিল্লাহ বলে বের হন\n◆ বের হওয়ার আগে ২ রাকাত নফল পড়ুন — সব মন্দ থেকে রক্ষা হবে\n◆ রাস্তায় কষ্টদায়ক কিছু দেখলে সরিয়ে দিন — ঈমানের অংশ\n◆ পরিচিত-অপরিচিত সবাইকে সালাম দিন'
          : 'Morning Sunnah:\n◆ Exit home right foot first, say Bismillah\n◆ Pray 2 rakats before leaving — protection from all harm\n◆ Remove harmful things from road — part of faith\n◆ Give Salam to all, known & unknown', 'color': const Color(0xFF26A69A)});
    }

    // ══ ইশরাকের ওয়াক্ত (সূর্যোদয়ের ১৫-৪৫ মিনিট পর) ══
    final ishraqS = pt.sunrise.add(const Duration(minutes: 15));
    final ishraqE = pt.sunrise.add(const Duration(minutes: 45));
    if (now.isAfter(ishraqS) && now.isBefore(ishraqE)) {
      alerts.add({'icon': '⭐', 'text': isBn
          ? 'ইশরাকের বিশেষ ফজিলত:\n◆ ফজর জামাতে পড়ে সূর্যোদয় পর্যন্ত জিকির করুন\n◆ তারপর ২ রাকাত পড়ুন — পূর্ণ হজ ও উমরার সওয়াব! (তিরমিজি: ৪৬১)\n◆ এই নামাজ পড়লে সারাদিনের সদকার সওয়াব হয়'
          : 'Ishraq special:\n◆ Stay after Fajr in dhikr till sunrise\n◆ Pray 2 rakats — Full Hajj & Umrah reward! (Tirmidhi: 461)\n◆ Replaces full day\'s Sadaqah', 'color': const Color(0xFFFF8F00)});
    }

    // ══ দুপুরের আমল (যোহরের আগে ও পরে) ══
    if (now.isAfter(pt.dhuhr) && now.isBefore(pt.asr)) {
      alerts.add({'icon': '🕌', 'text': isBn
          ? 'যোহরের পরের আমল:\n◆ ফরজ নামাজের পর আয়াতুল কুরসি পড়ুন\n◆ ৩৩+৩৩+৩৪ তাসবিহ পড়ুন\n◆ নফল নামাজ ঘরে পড়ুন — ঘরে নফল পড়া জনসম্মুখে ২৫ গুণ বেশি সওয়াব\n◆ হাদিসে বর্ণিত দোয়া পড়ুন'
          : 'After Dhuhr:\n◆ Recite Ayatul Kursi\n◆ 33+33+34 Tasbih\n◆ Pray nafl at home — 25x more reward than in public\n◆ Recite hadith-prescribed duas', 'color': const Color(0xFF64B5F6)});
    }

    // ══ আসরের পরের আমল ══
    if (now.isAfter(pt.asr) && now.isBefore(pt.maghrib)) {
      alerts.add({'icon': '🌤️', 'text': isBn
          ? 'আসরের পরের আমল:\n◆ ফরজের পর আয়াতুল কুরসি ও তাসবিহ পড়ুন\n◆ সন্ধ্যার আগে শিশুদের বাইরে যেতে দেবেন না — এ সময় শয়তান ছড়িয়ে পড়ে (বুখারি: ৩৩০৪)\n◆ জুমার দিন হলে আসর থেকে মাগরিব পর্যন্ত বেশি দোয়া করুন — দোয়া কবুলের বিশেষ সময়!'
          : 'After Asr:\n◆ Ayatul Kursi & Tasbih\n◆ Keep children indoors — shayateen spread now (Bukhari: 3304)\n◆ On Friday: lots of dua till Maghrib — best time for acceptance!', 'color': const Color(0xFFFF8F00)});
      alerts.add({'icon': '📖', 'text': isBn
          ? 'বিকেলের জিকির:\n◆ বিকেলে ১০০ বার সুবহানাল্লাহ ওয়া বিহামদিহি পড়ুন — কিয়ামতে সবার চেয়ে বেশি সওয়াব (মুসলিম: ২৬৯২)\n◆ ১০ বার দরুদ পড়ুন — রাসূল ﷺ-এর সুপারিশ নিশ্চিত (তিবরানি)\n◆ ইস্তেগফার পড়ুন — রাসূল ﷺ প্রতিদিন ৭০-১০০ বার পড়তেন'
          : 'Afternoon dhikr:\n◆ 100x Subhanallah wa bihamdih — best reward on Qiyamah (Muslim: 2692)\n◆ 10x Salawat — Guaranteed intercession\n◆ Istighfar — Prophet ﷺ read 70-100x daily', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ মাগরিবের পরের আমল ══
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'মাগরিবের পরের বিশেষ আমল:\n◆ সূরা হাশরের শেষ তিন আয়াত পড়ুন\n◆ আয়াতুল কুরসি পড়ুন\n◆ তিন কূল পড়ে শরীরে দম করুন\n◆ সূরা কাফিরুন পড়ুন\n◆ সন্ধ্যার দোয়া-আজকার পড়ুন'
          : 'After Maghrib special deeds:\n◆ Last 3 verses of Surah Hashr\n◆ Ayatul Kursi\n◆ 3 Quls, blow on body\n◆ Surah Kafirun\n◆ Evening adhkar', 'color': const Color(0xFF7C4DFF)});
      alerts.add({'icon': '🏠', 'text': isBn
          ? 'সন্ধ্যার সুন্নত:\n◆ ঘরে ঢুকলে ডান পা দিয়ে সালাম দিয়ে প্রবেশ করুন\n◆ আওয়াবিনের ৬ রাকাত পড়ুন — ১২ বছর ইবাদতের সওয়াব\n◆ ঘরের দরজা বন্ধ করুন ও আল্লাহর নাম নিন — শয়তান বন্ধ দরজা খুলতে পারে না'
          : 'Evening Sunnah:\n◆ Enter home right foot first, give Salam\n◆ Pray 6 Awwabin rakats — 12 years worship reward\n◆ Close doors & say Bismillah — shaytan can\'t open closed doors', 'color': const Color(0xFF26A69A)});
      // বৃহস্পতিবার সন্ধ্যায়: জুমার রাতের reminder
      if (now.weekday == DateTime.thursday) {
        alerts.add({'icon': '✨', 'text': isBn
            ? 'আজ বৃহস্পতিবার সন্ধ্যা — জুমার রাত শুরু!\n◆ বেশি বেশি দরুদ পড়ুন (আবু দাউদ: ১০৪৭)\n◆ জুমার দিন পর্যন্ত দরুদ পড়তে থাকুন\n◆ আগামীকাল জুমার ১১টি আমল করার নিয়ত করুন'
            : 'Thursday evening — Jumu\'ah night begins!\n◆ Send lots of Salawat (Abu Dawud: 1047)\n◆ Continue till Friday\n◆ Intend to do Friday\'s 11 deeds tomorrow', 'color': AppTheme.accent});
      }
    }

    // ══ এশার পরের আমল ══
    if (now.isAfter(pt.isha) && now.hour < 23) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'রাতের আমল (ঘুমানোর আগে):\n◆ সূরা মুলক পড়ুন — কবরের আযাব থেকে রক্ষা (নাসাই: ৩৮৩৯)\n◆ আয়াতুল কুরসি পড়ুন\n◆ তিন কূল পড়ে তিনবার শরীরে দম করুন\n◆ সূরা কাফিরুন পড়ে ডান কাত হয়ে শোন\n◆ অযু করে ঘুমান (বুখারি ও মুসলিম)'
          : 'Nighttime deeds (before sleep):\n◆ Surah Mulk — protection from grave (Nasai: 3839)\n◆ Ayatul Kursi\n◆ 3 Quls, blow on body 3x\n◆ Surah Kafirun, sleep on right side\n◆ Sleep with wudu (Bukhari & Muslim)', 'color': const Color(0xFF7C4DFF)});
      alerts.add({'icon': '💤', 'text': isBn
          ? 'ঘুমের সুন্নত:\n◆ তাড়াতাড়ি ঘুমানো সুন্নত — এশার পর কথা না বলে ঘুমান\n◆ ঘুমের দোয়া পড়ুন\n◆ ঘুমের মাঝে খারাপ স্বপ্ন দেখলে বামে তিনবার থু থু ফেলুন ও আউযুবিল্লাহ পড়ুন\n◆ নিয়ত করুন রাতে তাহাজ্জুদ পড়বেন — নিয়তেও সওয়াব (নাসাই: ১৭৮৭)'
          : 'Sleep Sunnah:\n◆ Sleep early after Isha — Prophet\'s sunnah\n◆ Read sleep dua\n◆ Bad dream: spit left 3x & say Auzubillah\n◆ Intend Tahajjud — even intention gets reward (Nasai: 1787)', 'color': const Color(0xFF26A69A)});
    }

    // ══ সারাদিনের (যেকোনো সময়ের) আমল ══
    alerts.add({'icon': '💎', 'text': isBn
        ? 'সহজ কিন্তু মূল্যবান আমল:\n◆ "সুবহানাল্লাহি ওয়া বিহামদিহি সুবহানাল্লাহিল আজিম" — আমলে ভারী, বলায় সহজ (বুখারি: ৬৪০৬)\n◆ মুচকি হাসি — সদকা!\n◆ হাসিমুখে কথা বলুন — রাসূল ﷺ এর সুন্নত\n◆ প্রতিটি ভালো কাজ ডান দিক দিয়ে বিসমিল্লাহ বলে শুরু করুন'
        : 'Easy but valuable deeds:\n◆ "Subhanallahi wa bihamdih..." — heavy in scale, easy to say (Bukhari: 6406)\n◆ A smile is Sadaqah!\n◆ Speak with a smile — Sunnah of Prophet ﷺ\n◆ Start every good deed from right with Bismillah', 'color': const Color(0xFF26A69A)});

    // ══ ওযুর পরের আমল ══
    alerts.add({'icon': '💧', 'text': isBn
        ? 'ওযুর পরের আমল:\n◆ কালেমা শাহাদত পড়ুন — জান্নাতের ৮টি দরজার যেকোনোটি দিয়ে প্রবেশ করতে পারবেন (মুসলিম: ২৩৪)\n◆ ওযুর আগে মিসওয়াক করুন — মুখের পবিত্রতা ও আল্লাহর সন্তুষ্টি\n◆ তাহিয়্যাতুল অযু ২ রাকাত পড়ুন — জান্নাতে যাওয়ার পথ খোলা (মুসলিম: ৪৪১)'
        : 'After Wudu:\n◆ Say Kalimah Shahadah — enter Jannah from any of 8 gates (Muslim: 234)\n◆ Use Miswak before wudu — mouth purity & Allah\'s pleasure\n◆ Pray 2 rakats Tahiyyatul Wudu — path to Jannah (Muslim: 441)', 'color': const Color(0xFF64B5F6)});

    // ══ খাবারের আমল ══
    alerts.add({'icon': '🍽️', 'text': isBn
        ? 'খাবারের সুন্নত:\n◆ বিসমিল্লাহ বলে ডান হাতে খান\n◆ সামনে থেকে খান\n◆ তিন চুমুকে পানি পান করুন — পাত্রে শ্বাস ফেলবেন না\n◆ খাওয়া শেষে আলহামদুলিল্লাহ বলুন\n◆ পড়ে যাওয়া খাবার তুলে পরিষ্কার করে খান — বরকত নষ্ট হয়ে যায়\n◆ আঙুল চেটে খান — কোথায় বরকত আছে জানা নেই'
        : 'Eating Sunnah:\n◆ Say Bismillah, eat with right hand\n◆ Eat from in front of you\n◆ Sip water 3 times — don\'t breathe in vessel\n◆ Say Alhamdulillah after eating\n◆ Pick up fallen food — barakah may be in it\n◆ Lick fingers — barakah unknown', 'color': const Color(0xFFFF8F00)});

    // ══ মসজিদের আমল ══
    alerts.add({'icon': '🕌', 'text': isBn
        ? 'মসজিদের আমল:\n◆ ডান পা দিয়ে দরুদ পড়ে প্রবেশ করুন\n◆ বাম পা দিয়ে দরুদ পড়ে বের হন\n◆ তাহিয়্যাতুল মসজিদ পড়ুন\n◆ প্রথম সারিতে দাঁড়ানোর চেষ্টা করুন — রাসূল ﷺ প্রথম সারির জন্য ৩ বার দোয়া করতেন\n◆ অন্ধকারে মসজিদে যাওয়া — কিয়ামতে পূর্ণ নূর!'
        : 'Mosque deeds:\n◆ Enter right foot, recite Salawat & dua\n◆ Exit left foot, recite Salawat & dua\n◆ Pray Tahiyyatul Masjid\n◆ Try first row — Prophet ﷺ made dua for it 3x\n◆ Walking to mosque in dark — full Noor on Qiyamah!', 'color': const Color(0xFF26A69A)});

    // ══ বাজারে যাওয়ার আমল ══
    alerts.add({'icon': '🛒', 'text': isBn
        ? 'বাজারে প্রবেশের দোয়া পড়ুন:\n◆ "লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু লা শারিকালাহু, লাহুল মুলকু ওয়ালা হুল হামদু, ইয়ুহয়ি ওয়া ইয়ুমিতু, ওয়া হুয়া হাইয়ুন লা ইয়ামুতু, বিয়াদিহিল খাইর, ওয়া হুয়া আলা কুল্লি শাইয়িন কাদির।" পড়ুন\n◆ ১০ লক্ষ পুণ্য + ১০ লক্ষ পাপ মোচন + জান্নাতে ঘর নির্মাণ\n◆ (তিরমিজি: ৩৪২৮)\n◆ ব্যবসায় সততা রাখুন — মিথ্যা কসম করবেন না'
        : 'Market entry dua:\n◆ "La ilaha illallahu wahdahu la sharika lahu..."\n◆ 1 million good deeds + 1 million sins erased + house in Jannah\n◆ (Tirmidhi: 3428)\n◆ Be honest in trade — never false oath', 'color': const Color(0xFFFDD835)});

    // ══ বিশেষ নফল নামাজের reminder ══
    alerts.add({'icon': '🙏', 'text': isBn
        ? 'বিশেষ নফল নামাজ:\n◆ সালাতুত তওবা — গুনাহের পর ২ রাকাত পড়ে ক্ষমা চান (ইবনে মাজাহ: ১৩৯৫)\n◆ সিজদাতুস শুকুর — সুসংবাদ পেলে শুকরানার সিজদা দিন\n◆ সালাতুল হাজত — যেকোনো প্রয়োজনে ২ রাকাত পড়ুন\n◆ নফল ঘরে পড়ুন — ঘরে পড়া ২৫ গুণ বেশি সওয়াব'
        : 'Special Nafl prayers:\n◆ Salat al-Tawbah — 2 rakats after sin, seek forgiveness (Ibn Majah: 1395)\n◆ Sajda al-Shukr — prostrate in gratitude for good news\n◆ Salat al-Hajat — 2 rakats for any need\n◆ Nafl at home — 25x more reward', 'color': const Color(0xFF7C4DFF)});

    // ══ দান-সদকার reminder ══
    alerts.add({'icon': '💰', 'text': isBn
        ? 'দান সদকার ফজিলত:\n◆ প্রতিদিন ছোট হলেও কিছু সদকা করুন\n◆ সদকা গুনাহ মুছে দেয় — যেমন পানি আগুন নেভায় (আহমাদ: ২২০১৬)\n◆ মাসিক আয়ের অংশ এতিম, মসজিদ বা গরিবদের দিন — জিহাদের সওয়াব (বুখারি: ৬০০৭)\n◆ রোগীকে দেখতে যান — ৭০ হাজার ফেরেশতা সন্ধ্যা পর্যন্ত দোয়া করবে (আহমাদ: ৯৫৫)'
        : 'Sadaqah reward:\n◆ Give Sadaqah daily, even small\n◆ Sadaqah erases sins like water extinguishes fire (Ahmad: 22016)\n◆ Monthly donation to orphans/mosque — equals Jihad reward (Bukhari: 6007)\n◆ Visit the sick — 70,000 angels make dua till evening (Ahmad: 955)', 'color': const Color(0xFFFF8F00)});

    // ══ সাদাকায়ে জারিয়াহ ══
    alerts.add({'icon': '🌱', 'text': isBn
        ? 'সাদাকায়ে জারিয়াহ:\n◆ মৃত্যুর পরও তিনটি আমল বন্ধ হয় না:\n  ১. সাদাকায়ে জারিয়াহ\n  ২. উপকারী ইলম\n  ৩. সুসন্তান যে দোয়া করে\n◆ (তিরমিজি: ১৩৭৬)\n◆ এখনই অসিয়ত লিখুন — মুসলিমের উচিত অসিয়ত লিখে রাখা (বুখারি: ২৫৮৭)'
        : 'Sadaqah Jariyah:\n◆ 3 deeds continue after death:\n  1. Ongoing charity\n  2. Beneficial knowledge\n  3. Righteous child making dua\n◆ (Tirmidhi: 1376)\n◆ Write your wasiyyah now (Bukhari: 2587)', 'color': const Color(0xFF26A69A)});

    // ══ আত্মীয়তা ও মানুষের সাথে ব্যবহার ══
    alerts.add({'icon': '🤝', 'text': isBn
        ? 'মানুষের সাথে ব্যবহার:\n◆ আত্মীয়তার সম্পর্ক রক্ষা করুন — রিজিক ও আয়ু বৃদ্ধি পায়\n◆ মুসলিম ভাইয়ের প্রয়োজনে সাহায্য করুন — ১ মাস ইতেকাফের চেয়ে বেশি সওয়াব (আল-মু\'জাম: ১৩৬৪৬)\n◆ সৎ কাজ ছোট মনে করবেন না — হাসিমুখে দেখা করাও সদকা (মুসলিম)\n◆ মানুষকে ভালোবাসলে জানান — "আমি আপনাকে আল্লাহর জন্য ভালোবাসি"'
        : 'Relations & character:\n◆ Maintain family ties — increases rizq & lifespan\n◆ Help a brother — better than 1 month i\'tikaf (Al-Mu\'jam: 13646)\n◆ No good deed is small — even smiling is Sadaqah (Muslim)\n◆ Tell those you love: "I love you for Allah\'s sake"', 'color': const Color(0xFF64B5F6)});

    // ══ মুহররম মাসের বিশেষ আমল ══
    if (hijriMonth == 1) {
      alerts.add({'icon': '📅', 'text': isBn
          ? 'মুহররম মাসের বিশেষ আমল:\n◆ রমজানের পর সবচেয়ে উত্তম রোজা মুহররমের (মুসলিম: ১১৬৩)\n◆ ১০ মুহররম (আশুরার রোজা) রাখুন — আগের ১ বছরের গুনাহ মাফ\n◆ পুরো মাস নফল রোজার চেষ্টা করুন\n◆ সম্মানিত মাসে পাপ থেকে বিরত থাকুন'
          : 'Muharram special deeds:\n◆ Best nafl fast after Ramadan is Muharram (Muslim: 1163)\n◆ 10 Muharram (Ashura fast) — 1 year of sins forgiven\n◆ Try to fast throughout the month\n◆ Avoid sins in this sacred month', 'color': AppTheme.gold});
    }

    // ══ রজব মাসের বিশেষ আমল ══
    if (hijriMonth == 7) {
      alerts.add({'icon': '📅', 'text': isBn
          ? 'রজব মাসের আমল (সম্মানিত মাস):\n◆ নফল রোজা রাখুন\n◆ নেক আমল বাড়িয়ে দিন\n◆ পাপ থেকে বিরত থাকুন — এ মাসে পাপের শাস্তি বেশি\n◆ রমজানের প্রস্তুতি শুরু করুন'
          : 'Rajab deeds (sacred month):\n◆ Keep nafl fasts\n◆ Increase good deeds\n◆ Avoid sins — punishment is heavier this month\n◆ Start preparing for Ramadan', 'color': AppTheme.gold});
    }

    // ══ শবে বরাত (১৪ শাবান রাত) ══
    if (hijriMonth == 8 && h == 14 && now.isAfter(pt.maghrib)) {
      alerts.add({'icon': '✨', 'text': isBn
          ? 'আজ রাত — শবে বরাত (১৫ শাবানের রাত):\n◆ এ রাতে ইবাদত করুন — বিশেষ ফজিলত রয়েছে\n◆ নফল নামাজ, কুরআন তিলাওয়াত, জিকির করুন\n◆ দোয়া কবুলের রাত\n◆ কবরস্থানে গিয়ে মৃতদের জন্য দোয়া করুন'
          : 'Tonight — Shab-e-Barat (15th Shaban night):\n◆ Worship tonight — special virtue\n◆ Nafl prayers, Quran, dhikr\n◆ Night of acceptance of dua\n◆ Pray for the deceased', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ ৫টি বিশেষ রাতের ইবাদত ══
    final isSpecialNight = (hijriMonth == 12 && (h == 8 || h == 9 || h == 10) && now.isAfter(pt.maghrib)) ||
        (hijriMonth == 10 && h == 1 && now.isAfter(pt.maghrib)) ||
        (hijriMonth == 8 && h == 15 && now.isAfter(pt.maghrib));
    if (isSpecialNight) {
      alerts.add({'icon': '🌟', 'text': isBn
          ? 'আজ রাত বিশেষ ইবাদতের রাত!\n◆ এই ৫টি রাতে ইবাদত করলে জান্নাত ওয়াজিব (আত-তারগিব)\n◆ রাতে ইবাদত করুন: নফল নামাজ, কুরআন, জিকির, দোয়া\n◆ এ রাতের দোয়া ফিরিয়ে দেওয়া হয় না'
          : 'Tonight is a special worship night!\n◆ Worship on these 5 nights — Jannah becomes guaranteed (At-Targhib)\n◆ Worship tonight: nafl prayers, Quran, dhikr, dua\n◆ No dua is rejected this night', 'color': AppTheme.gold});
    }


    // ══ লাইলাতুল কদর (রমজানের শেষ ১০ রাত) ══
    if (hijriMonth == 9 && h >= 20 && now.isAfter(pt.maghrib)) {
      final isOddNight = (h == 21 || h == 23 || h == 25 || h == 27 || h == 29);
      if (isOddNight) {
        alerts.add({'icon': '⭐', 'text': isBn
            ? 'আজ রাত — লাইলাতুল কদর হতে পারে!\n◆ এই রাত হাজার মাসের চেয়ে উত্তম (সূরা কদর)\n◆ দোয়া: "আল্লাহুম্মা ইন্নাকা আফুউউন তুহিব্বুল আফওয়া ফাফু আন্নী"\n◆ নফল নামাজ, কুরআন, তওবা, ইস্তিগফার করুন\n◆ সকাল পর্যন্ত জেগে ইবাদত করুন'
            : 'Tonight could be Laylatul Qadr!\n◆ Better than 1000 months (Surah Qadr)\n◆ Dua: "Allahumma innaka Afuwwun tuhibbul afwa fa\'fu anni"\n◆ Nafl prayers, Quran, tawbah, istighfar\n◆ Stay awake till Fajr', 'color': AppTheme.gold});
      } else {
        alerts.add({'icon': '🌙', 'text': isBn
            ? 'রমজানের শেষ দশক — লাইলাতুল কদর খুঁজুন!\n◆ বিজোড় রাতে (২১, ২৩, ২৫, ২৭, ২৯) বেশি ইবাদত করুন\n◆ ইতেকাফ করলে সবচেয়ে ভালো\n◆ দোয়া: "আল্লাহুম্মা ইন্নাকা আফুউউন তুহিব্বুল আফওয়া ফাফু আন্নী"'
            : 'Last 10 nights of Ramadan — seek Laylatul Qadr!\n◆ More worship on odd nights (21,23,25,27,29)\n◆ I\'tikaf is best\n◆ Dua: "Allahumma innaka Afuwwun..."', 'color': const Color(0xFF7C4DFF)});
      }
    }

    // ══ নারীদের বিশেষ আমল ══
    alerts.add({'icon': '👩', 'text': isBn
        ? 'মহিলাদের জন্য জান্নাতের চাবিকাঠি:\n◆ ৫ ওয়াক্ত সালাত আদায় করুন\n◆ রমজানের সিয়াম পালন করুন\n◆ লজ্জাস্থানের হেফাজত করুন\n◆ স্বামীর আনুগত্য করুন — জান্নাতের যেকোনো দরজা দিয়ে প্রবেশ করবেন\n◆ (সহিহ ইবনে হিব্বান: ৪১৬৩)'
        : 'For women — keys to Jannah:\n◆ Pray 5 daily prayers\n◆ Keep Ramadan fasts\n◆ Guard chastity\n◆ Obey husband — enter Jannah from any gate\n◆ (Ibn Hibban: 4163)', 'color': const Color(0xFFE91E63)});

    // ══ টয়লেট/বাথরুমের সুন্নত ══
    alerts.add({'icon': '🚿', 'text': isBn
        ? 'টয়লেট/বাথরুমের সুন্নত:\n◆ প্রবেশের আগে দোয়া: "আল্লাহুম্মা ইন্নি আউযুবিকা মিনাল খুবুসি ওয়াল খাবায়িস"\n◆ বাম পা দিয়ে প্রবেশ করুন\n◆ বের হওয়ার সময় ডান পা দিয়ে বের হয়ে পড়ুন: "গুফরানাক"\n◆ কিবলামুখী হয়ে বা পিঠ দিয়ে বসবেন না'
        : 'Toilet/Bathroom Sunnah:\n◆ Dua before entering: "Allahumma inni auzubika minal khubuthi wal khaba\'ith"\n◆ Enter with left foot\n◆ Exit right foot & say: "Ghufranaka"\n◆ Don\'t face or turn back to Qiblah', 'color': const Color(0xFF78909C)});

    // ══ যাকাত ══
    alerts.add({'icon': '💵', 'text': isBn
        ? 'যাকাতের কথা মনে রাখুন:\n◆ নিসাব পরিমাণ সম্পদে যাকাত ফরজ\n◆ যাকাত না দিলে সম্পদ পবিত্র হয় না\n◆ যাকাত দিলে সম্পদে বরকত আসে\n◆ এতিম, বিধবা, গরিব, ঋণগ্রস্তদের দিন\n◆ প্রতি বছর হিসাব করুন ও সময়মতো আদায় করুন'
        : 'Zakat reminder:\n◆ Obligatory when wealth reaches Nisab\n◆ Wealth not purified without Zakat\n◆ Zakat brings barakah\n◆ Give to orphans, widows, poor, indebted\n◆ Calculate yearly & pay on time', 'color': const Color(0xFF26A69A)});

    // ══ জিহাদ ══
    alerts.add({'icon': '🛡️', 'text': isBn
        ? 'জিহাদের মর্যাদা:\n◆ আল্লাহর পথে জিহাদের সারিতে এক মুহূর্ত — ৬০ বছর ইবাদতের চেয়ে উত্তম\n◆ আজকের যুগে কলম, জ্ঞান ও দাওয়াতের মাধ্যমে জিহাদ করুন\n◆ পরিবারকে ইসলামে প্রতিষ্ঠিত রাখাও জিহাদ\n◆ নফসের বিরুদ্ধে জিহাদ — সবচেয়ে বড় জিহাদ\n◆ রিবাত: ১ দিন-রাত সীমান্ত পাহারা = ১ মাস রোজা ও রাতের ইবাদতের চেয়ে বেশি'
        : 'Jihad (striving):\n◆ Moment in Allah\'s path — better than 60 years worship\n◆ Today: Jihad through pen, knowledge & dawah\n◆ Keeping family on Islam is also Jihad\n◆ Jihad against nafs — the greatest Jihad\n◆ Ribat 1 day-night = more than 1 month fasting & worship', 'color': const Color(0xFF546E7A)});

    // ══ কাজের শুরুতে ══
    alerts.add({'icon': '✍️', 'text': isBn
        ? 'কাজের শুরুতে:\n◆ প্রতিটি ভালো কাজ ডান দিক দিয়ে বিসমিল্লাহ বলে শুরু করুন\n◆ যেকোনো কাজ পরামর্শ করে করুন (শুরা: ৩৮)\n◆ হালাল উপায়ে উপার্জন করুন\n◆ কাজে মনোযোগ দিন — আল্লাহ উৎকর্ষতা পছন্দ করেন'
        : 'Before starting work:\n◆ Start every good deed right side with Bismillah\n◆ Consult in all matters (Shura: 38)\n◆ Earn through halal means\n◆ Be focused — Allah loves excellence', 'color': const Color(0xFF8D6E63)});

    // ══ যিকর ও তিলাওয়াত ══
    alerts.add({'icon': '📖', 'text': isBn
        ? 'যিকর ও তিলাওয়াত:\n◆ "সুবহানাল্লাহি ওয়া বিহামদিহি সুবহানাল্লাহিল আজিম" — বলায় সহজ, পাল্লায় ভারী (বুখারি: ৬৪০৬)\n◆ সূরা ইখলাস = কুরআনের ১/৩ ভাগ\n◆ সূরা কাফিরুন = কুরআনের ১/৪ ভাগ\n◆ লা ইলাহা ইল্লাল্লাহ ইখলাসের সাথে বললে আরশ পর্যন্ত পৌঁছায়\n◆ প্রতিদিন নিয়মিত কুরআন তিলাওয়াত করুন'
        : 'Dhikr & Tilawah:\n◆ "Subhanallahi wa bihamdih..." — easy, heavy in scale (Bukhari: 6406)\n◆ Surah Ikhlas = 1/3 Quran\n◆ Surah Kafirun = 1/4 Quran\n◆ La ilaha illallah with sincerity reaches the Arsh\n◆ Recite Quran daily', 'color': const Color(0xFF7C4DFF)});

    // ══ রোজার বিস্তারিত — সময়ভিত্তিক ══

    // শাওয়ালের ৬ রোজা — শাওয়াল মাস জুড়ে
    if (hijriMonth == 10) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'শাওয়াল মাস — ৬টি নফল রোজা রাখুন!\n◆ সারা বছর রোজার সওয়াব পাবেন (মুসলিম)\n◆ রমজানের পর এই ৬ রোজা = পূর্ণ বছর রোজার সমান'
          : 'Shawwal — Keep 6 nafl fasts!\n◆ Whole year reward (Muslim)\n◆ Ramadan + 6 Shawwal = Full year of fasting', 'color': const Color(0xFF64B5F6)});
    }

    // আইয়ামে বিজ রোজা — ১৩-১৫ তারিখ চলাকালীন
    if (h >= 13 && h <= 15) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'আইয়ামে বিজের রোজা চলছে ($h তারিখ)!\n◆ প্রতি মাসে এই ৩টি রোজা = সারা বছর রোজার সমান\n◆ রোজা রাখুন — এখনো সময় আছে'
          : 'Ayyam al-Beed fasting ($h)!\n◆ These 3 fasts = whole year fasting\n◆ Fast now — there is still time', 'color': AppTheme.gold});
    }

    // ইফতার তাড়াতাড়ি করুন — ইফতারের ৩০ মিনিট আগে থেকে
    if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 30))) && now.isBefore(pt.maghrib)) {
      alerts.add({'icon': '🍽️', 'text': isBn
          ? 'ইফতার তাড়াতাড়ি করুন — নবুওয়তের আদর্শ!\n◆ মাগরিবের আযান হওয়ার সাথে সাথে ইফতার করুন\n◆ দেরি করা মাকরুহ'
          : 'Break fast quickly — Prophetic sunnah!\n◆ Break fast as soon as Maghrib Adhan\n◆ Delaying is makruh', 'color': const Color(0xFF64B5F6)});
    }

    // সেহরি দেরিতে করুন — ফজরের ৯০ মিনিট আগে থেকে
    if (now.isBefore(pt.fajr) && pt.fajr.difference(now).inMinutes <= 90) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'সেহরি দেরিতে করুন — সুন্নত!\n◆ ফজরের কাছাকাছি সময়ে সেহরি খান\n◆ সেহরিতে বরকত আছে — ছেড়ে দেবেন না'
          : 'Delay Sehri — it\'s Sunnah!\n◆ Eat close to Fajr time\n◆ Sehri has barakah — don\'t skip it', 'color': const Color(0xFF81C784)});
    }

    // রোজাদারকে ইফতার করান — রমজান মাসে
    if (hijriMonth == 9) {
      alerts.add({'icon': '🤲', 'text': isBn
          ? 'রোজাদারকে ইফতার করান!\n◆ তার সমান সওয়াব পাবেন — রোজার কিছু কমবে না\n◆ (তিরমিজি: ৮০৭)'
          : 'Feed a fasting person!\n◆ Same reward as the faster — their reward doesn\'t decrease\n◆ (Tirmidhi: 807)', 'color': const Color(0xFF26A69A)});
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
                style: const TextStyle(fontSize: 28, color: AppTheme.gold, fontFamily: 'ScheherazadeNew', height: 1.8),
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

            _ClockCard(now: now, lang: lang, prayerTimes: _prayerTimes, hijriDate: _hijriDate, liveAlerts: _getLiveAlerts(lang), locationName: _locationName, weatherText: _weatherText, weatherIcon: _weatherIcon),
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
            const SizedBox(height: 16),

            // ══ নফল আমল ও বিশেষ দিনের নোটিফিকেশন ══
            Builder(builder: (context) {
              final naflAlerts = _getNaflAmalAlerts(lang);
              if (naflAlerts.isEmpty) return const SizedBox.shrink();
              final isBn = lang.isBn;
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(children: [
                        const Text('📿', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          isBn ? 'নফল আমল ও বিশেষ দিনের তথ্য' : 'Nafl Deeds & Special Days',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: naflAlerts.asMap().entries.map((entry) {
                          final i = entry.key;
                          final a = entry.value;
                          return Column(
                            children: [
                              if (i > 0) const Divider(color: Colors.white10, height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a['icon'] as String, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(
                                      a['text'] as String,
                                      style: TextStyle(
                                        color: a['color'] as Color,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.5,
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _ClockCard extends StatefulWidget {
  final DateTime now;
  final AppLanguage lang;
  final PrayerTimes? prayerTimes;
  final String hijriDate;
  final List<Map<String, dynamic>> liveAlerts;
  final String locationName;
  final String weatherText;
  final String weatherIcon;

  const _ClockCard({
    required this.now,
    required this.lang,
    required this.prayerTimes,
    required this.hijriDate,
    required this.liveAlerts,
    required this.locationName,
    required this.weatherText,
    required this.weatherIcon,
  });

  @override
  State<_ClockCard> createState() => _ClockCardState();
}

class _ClockCardState extends State<_ClockCard> with SingleTickerProviderStateMixin {
  late ScrollController _marqueeController;
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    _marqueeController = ScrollController();
    _startMarquee();
  }

  void _startMarquee() {
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_marqueeController.hasClients) return;
      final max = _marqueeController.position.maxScrollExtent;
      if (max <= 0) return;
      final current = _marqueeController.offset;
      if (current >= max) {
        _marqueeController.jumpTo(0);
      } else {
        _marqueeController.jumpTo(current + 1.0);
      }
    });
  }

  @override
  void dispose() {
    _marqueeTimer?.cancel();
    _marqueeController.dispose();
    super.dispose();
  }

  String _buildMarqueeText() {
    if (widget.liveAlerts.isEmpty) return '';
    return widget.liveAlerts
        .map((a) => '${a['icon']}  ${(a['text'] as String).replaceAll('\n', ' ')}')
        .join('          ✦          ');
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    final now = widget.now;
    final pt = widget.prayerTimes;
    final sunrise = pt?.sunrise;
    final maghrib = pt?.maghrib;
    final fajr = pt?.fajr;
    const sunColor = AppTheme.gold;
    const fastColor = Color(0xFF00E676);
    final isFriday = now.weekday == DateTime.friday;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B0D), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.6), width: 1.2),
      ),
      child: Column(
        children: [
          // ══ উপরের অংশ: সময় + বার ══
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // সময়
                Text(
                  DateHelper.formatTime12(now, bangla: isBn),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                // বার + আবহাওয়া placeholder row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // বার
                    Text(
                      widget.lang.dayName(now.weekday),
                      style: TextStyle(
                        fontSize: 26,
                        color: isFriday ? AppTheme.accent : Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // আবহাওয়া (real data)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Text(widget.weatherIcon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.weatherText.isEmpty
                                  ? (isBn ? 'লোড হচ্ছে...' : 'Loading...')
                                  : widget.weatherText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.1), thickness: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // ══ মাঝের অংশ: তারিখ বাম | নামাজ ডান ══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // বাম: তারিখ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ইংরেজি তারিখ
                      Text(
                        DateHelper.formatGregorian(now, bangla: isBn),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // হিজরি তারিখ
                      Text(
                        widget.hijriDate.isEmpty
                            ? DateHelper.toHijri(now, bangla: isBn)
                            : widget.hijriDate,
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // বাংলা তারিখ
                      Text(
                        DateHelper.toBangla(now),
                        style: const TextStyle(
                          color: Color(0xFF80DEEA),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // ডিভাইডার
                Container(
                  width: 1,
                  height: 110,
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),

                // ডান: সূর্যোদয়, সূর্যাস্ত, সেহরি, ইফতার
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _timeRow('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise',
                          sunrise != null ? PrayerTimeHelper.formatTime(sunrise) : '--', sunColor),
                      const SizedBox(height: 4),
                      _timeRow('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset',
                          maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--', sunColor),
                      const SizedBox(height: 8),
                      _timeRow('🍽️', isBn ? 'সেহরি' : 'Sehri',
                          fajr != null ? PrayerTimeHelper.formatTime(fajr) : '--', fastColor),
                      const SizedBox(height: 4),
                      _timeRow('🌙', isBn ? 'ইফতার' : 'Iftar',
                          maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--', fastColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ══ লোকেশন — মাঝ বরাবর ══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF80DEEA), size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.locationName.isEmpty
                        ? (isBn ? 'লোকেশন খোঁজা হচ্ছে...' : 'Getting location...')
                        : widget.locationName,
                    style: const TextStyle(
                      color: Color(0xFF80DEEA),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ══ নিচে: Scrolling Marquee Text ══
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: widget.liveAlerts.isEmpty
                ? Center(
                    child: Text(
                      isBn ? '⏳ তথ্য লোড হচ্ছে...' : '⏳ Loading...',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                : SizedBox(
                    height: 20,
                    child: SingleChildScrollView(
                      controller: _marqueeController,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          // দুইবার text রাখলে loop seamless হয়
                          Text(
                            '${_buildMarqueeText()}          ✦          ${_buildMarqueeText()}',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(String icon, String label, String time, Color color) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: time,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
        ),
      ],
    );
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
      final l = jd - 1948441 + 10632;
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
      final l = jd - 1948441 + 10632;
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
