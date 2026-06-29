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

      // weather: icon + temp + short description
      final shortWeather = _weatherText.isEmpty ? '' : '$_weatherIcon $_weatherText';
      await HomeWidget.saveWidgetData('widget_weather', shortWeather);

      // alert: সূর্যোদয় ও দ্বিপ্রহরের নিষিদ্ধ সময়ে শুধু সতর্কবার্তা
      final alertList = _getLiveAlerts(widget.lang);
      final strictForbidden = alertList.where((a) {
        final txt = (a['text'] as String);
        return txt.contains('সূর্যোদয়কালীন') ||
               txt.contains('দ্বিপ্রহর') ||
               txt.contains('Sunrise forbidden') ||
               txt.contains('Noon forbidden');
      }).toList();

      final String alertText;
      if (strictForbidden.isNotEmpty) {
        final txt = (strictForbidden.first['text'] as String).split('\n').first;
        alertText = '${strictForbidden.first['icon']} $txt';
      } else {
        final normalAlerts = alertList.where((a) =>
            !(a['text'] as String).contains('নিষিদ্ধ') &&
            !(a['text'] as String).contains('Forbidden')).toList();
        alertText = normalAlerts.isEmpty
            ? ''
            : normalAlerts.map((a) =>
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
      final jummaCutoff = pt.dhuhr.add(const Duration(hours: 1, minutes: 30));

      // সকাল ৮টা থেকে দুপুর ১:৩০ — জুমার প্রস্তুতি
      if (now.hour >= 8 && now.isBefore(jummaCutoff)) {
        alerts.add({'icon': '🕌', 'text': isBn
            ? 'জুমার নামাজ আদায়ের প্রস্তুতি নিন:\n◆ গোসল করুন (বুখারি: ৮৭৭)\n◆ সুগন্ধি ও পরিষ্কার পোশাক পরুন\n◆ হেঁটে আগে আগে মসজিদে যান\n◆ খুতবার আগে পৌঁছান ও নফল নামাজ পড়ুন\n◆ সামনের কাতারে বসুন'
            : 'Prepare for Jumu\'ah:\n◆ Take a bath (Bukhari: 877)\n◆ Apply perfume & wear clean clothes\n◆ Walk early to the mosque\n◆ Arrive before khutbah & pray nafl\n◆ Sit in front rows', 'color': AppTheme.accent});

        alerts.add({'icon': '🚶', 'text': isBn
            ? 'জুমায় আগে গেলে সওয়াব (বুখারি: ৮৮১):\n◆ ১ম ঘণ্টায় — উট কুরবানির সওয়াব\n◆ ২য় ঘণ্টায় — গরু কুরবানির সওয়াব\n◆ ৩য় ঘণ্টায় — ছাগল কুরবানির সওয়াব\n◆ ৪র্থ ঘণ্টায় — মুরগি সদকার সওয়াব\n◆ ৫ম ঘণ্টায় — ডিম সদকার সওয়াব'
            : 'Reward for going early (Bukhari: 881):\n◆ 1st hour — sacrificing a camel\n◆ 2nd hour — sacrificing a cow\n◆ 3rd hour — sacrificing a goat\n◆ 4th hour — giving a chicken\n◆ 5th hour — giving an egg', 'color': AppTheme.accent});

        alerts.add({'icon': '📿', 'text': isBn
            ? 'জুমার নামাজে করণীয়:\n◆ ইমামের খুতবা মনোযোগ দিয়ে শুনুন\n◆ খুতবার সময় কথা বলবেন না — সওয়াব নষ্ট হয়\n◆ জুমার পরে ৪ রাকাত সুন্নত পড়ুন\n◆ বেশি বেশি দরুদ পড়ুন (আবু দাউদ: ১০৪৭)'
            : 'During Jumu\'ah:\n◆ Listen to khutbah attentively\n◆ Don\'t talk during khutbah — reward is lost\n◆ Pray 4 sunnah after Jumu\'ah\n◆ Send lots of Salawat (Abu Dawud: 1047)', 'color': AppTheme.accent});
      }

      // দুপুর ১:৩০ থেকে মাগরিব
      if (!now.isBefore(jummaCutoff) && now.isBefore(pt.maghrib)) {
        alerts.add({'icon': '🕌', 'text': isBn
            ? 'জুমার দিন — দরূদ ও দোয়া করুন:\n◆ আসর থেকে মাগরিব — দোয়া কবুলের বিশেষ সময়!\n◆ বেশি বেশি দরুদ ও ইস্তিগফার করুন\n◆ সূরা কাহাফ তেলাওয়াত করুন — কিয়ামতে নূরের আলো হবে'
            : 'Friday — Salawat & dua:\n◆ Asr to Maghrib — special time for accepted dua!\n◆ Send lots of Salawat & Istighfar\n◆ Recite Surah Kahaf — light on Judgment Day', 'color': AppTheme.accent});
      }

      // সারাদিন ফজর থেকে মাগরিব
      if (now.isBefore(pt.maghrib)) {
        alerts.add({'icon': '⭐', 'text': isBn
            ? 'জুমার দিনের ফজিলত:\n◆ সপ্তাহের শ্রেষ্ঠ দিন (মুসলিম: ৮৫৪)\n◆ জুমার নামাজ দুই জুমার মাঝের গুনাহ মাফ করে (মুসলিম: ২৩৩)\n◆ এই দিনে একটি বিশেষ মুহূর্তে সব দোয়া কবুল হয়\n◆ বেশি বেশি দরুদ পড়ুন'
            : 'Friday Virtues:\n◆ Best day of the week (Muslim: 854)\n◆ Expiates sins between two Fridays (Muslim: 233)\n◆ Special moment when all duas are accepted\n◆ Send lots of Salawat', 'color': AppTheme.accent});

        alerts.add({'icon': '📖', 'text': isBn
            ? 'আজ জুমার দিন — সূরা কাহাফ তেলাওয়াত করুন! কিয়ামতে নূরের আলো হবে।'
            : 'Friday — Recite Surah Kahaf! Light on Judgment Day.', 'color': const Color(0xFF7C4DFF)});
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

    // ══ বিশেষ নফল নামাজ — সকাল ৯টা থেকে দুপুর ১২:৩০ ══
    if (now.hour >= 9 && (now.hour < 12 || (now.hour == 12 && now.minute <= 30))) {
      alerts.add({'icon': '🙏', 'text': isBn
          ? 'সালাতুত তাসবীহ — জীবনে অবশ্যই পড়ুন:\n◆ ৪ রাকাত নামাজে ৩০০ বার তাসবীহ পড়ুন\n◆ তাসবীহ: "সুবহানাল্লাহ ওয়াল হামদুলিল্লাহ ওয়ালা ইলাহা ইল্লাল্লাহু ওয়াল্লাহু আকবার"\n◆ ফজিলত: আগের ও পরের সব গুনাহ মাফ হয়\n◆ (আবু দাউদ: ১২৯৭, ইবনে মাজাহ: ১৩৮৭)\n◆ প্রতিদিন, সপ্তাহে বা মাসে একবার পড়া উত্তম'
          : 'Salat al-Tasbih — Must pray in lifetime:\n◆ 4 rakats with 300 tasbeeh\n◆ "SubhanAllah walhamdulillah wala ilaha illallahu wallahu akbar"\n◆ Virtue: All sins forgiven\n◆ (Abu Dawud: 1297, Ibn Majah: 1387)', 'color': const Color(0xFF7C4DFF)});

      alerts.add({'icon': '🤲', 'text': isBn
          ? 'সালাতুল ইস্তিখারা — সিদ্ধান্তে পড়ুন:\n◆ যেকোনো গুরুত্বপূর্ণ সিদ্ধান্তে ২ রাকাত পড়ুন\n◆ আল্লাহ যা ভালো মনে করেন তাই করার তাওফিক দেন\n◆ নামাজের পর নির্দিষ্ট দোয়া পড়ুন (বুখারি: ১১৬৬)\n◆ সালাতুল হাজত: যেকোনো প্রয়োজনে ২ রাকাত পড়ুন (তিরমিজি: ৪৭৯)'
          : 'Salat al-Istikhara — For decisions:\n◆ 2 rakats before any important decision\n◆ Allah guides you to what is best\n◆ Recite specific dua after (Bukhari: 1166)\n◆ Salat al-Hajat: 2 rakats for any need (Tirmidhi: 479)', 'color': const Color(0xFF7C4DFF)});

      alerts.add({'icon': '💧', 'text': isBn
          ? 'তাহিয়্যাতুল ওযু ও মসজিদ:\n◆ তাহিয়্যাতুল ওযু: ওযুর পর ২ রাকাত — জান্নাতে পথ খোলে (মুসলিম: ৪৪১)\n◆ তাহিয়্যাতুল মসজিদ: মসজিদে ঢুকে বসার আগে ২ রাকাত পড়ুন (বুখারি: ১১৬৭)\n◆ সালাতুত তাওবা: গুনাহের পর ২ রাকাত পড়ে ক্ষমা চান (ইবনে মাজাহ: ১৩৯৫)\n◆ নফল ঘরে পড়ুন — ঘরে পড়া ২৫ গুণ বেশি সওয়াব'
          : 'Tahiyyatul Wudhu & Masjid:\n◆ Tahiyyatul Wudhu: 2 rakats after wudu — path to Jannah (Muslim: 441)\n◆ Tahiyyatul Masjid: 2 rakats before sitting (Bukhari: 1167)\n◆ Salat al-Tawbah: 2 rakats after sin, seek forgiveness (Ibn Majah: 1395)\n◆ Nafl at home — 25x more reward', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ দান-সদকার reminder — সকাল ৬টা থেকে দুপুর ১২টা ══
    if (now.hour >= 6 && now.hour < 12) {
      alerts.add({'icon': '💝', 'text': isBn
          ? 'আজকের দানের অনুপ্রেরণা:\n◆ আল্লাহ বলেন: যে আল্লাহর পথে ব্যয় করে — প্রতিটি বীজ থেকে ৭০০ গুণ সওয়াব (বাকারা: ২৬১)\n◆ রাসূল ﷺ: সদকা করলে সম্পদ কমে না — বরং আল্লাহ বরকত দেন (সহীহ মুসলিম)\n◆ প্রতিদিন ফেরেশতা দোয়া করেন: "হে আল্লাহ! দানকারীকে আরও দান করুন" (বুখারী ও মুসলিম)\n◆ অর্ধেক খেজুর দান করেও জাহান্নাম থেকে বাঁচার চেষ্টা করুন (বুখারী)'
          : 'Today\'s Sadaqah Inspiration:\n◆ Allah says: Spend in His path — each seed grows 700 fold (Baqarah: 261)\n◆ Prophet ﷺ: Sadaqah does not decrease wealth (Sahih Muslim)\n◆ Angels make dua: "O Allah! Give more to the one who gives" (Bukhari & Muslim)\n◆ Save yourself from Hellfire even with half a date (Bukhari)', 'color': const Color(0xFFFF8F00)});
    }

    // ══ মুহররম মাসের বিশেষ আমল ══
    if (hijriMonth == 1) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'মুহররম — আল্লাহর মাস:\n◆ ইসলামের ৪টি সম্মানিত মাসের একটি\n◆ রাসূল ﷺ এ মাসকে "আল্লাহর মাস" বলেছেন\n◆ রমজানের পর সর্বোত্তম নফল রোজা মুহররমের (সহীহ মুসলিম)\n◆ এ মাসে গুনাহ থেকে বিশেষভাবে বিরত থাকুন\n◆ বেশি বেশি তাওবা, ইস্তিগফার ও নফল ইবাদত করুন'
          : 'Muharram — Month of Allah:\n◆ One of the 4 sacred months in Islam\n◆ Prophet ﷺ called it "Month of Allah"\n◆ Best nafl fast after Ramadan (Sahih Muslim)\n◆ Especially avoid sins this month', 'color': AppTheme.gold});

      if (h >= 1 && h <= 11) {
        alerts.add({'icon': '⭐', 'text': isBn
            ? 'আশুরার রোজার ফজিলত (১০ মুহররম):\n◆ আশুরার রোজা পূর্ববর্তী ১ বছরের গুনাহ মাফ (সহীহ মুসলিম)\n◆ উত্তম: ৯ ও ১০ অথবা ১০ ও ১১ মুহররম একসাথে রোজা রাখা\n◆ মুসনাদে আহমাদ: ২৪১ | তিরমিযী: ৭৪১'
            : 'Ashura Fast (10 Muharram):\n◆ Expiates 1 year of sins (Sahih Muslim)\n◆ Best: Fast 9 & 10 OR 10 & 11 together\n◆ Musnad Ahmad: 241 | Tirmidhi: 741', 'color': AppTheme.gold});
      }

      if (h == 8 && now.isAfter(pt.maghrib)) {
        alerts.add({'icon': '🌙', 'text': isBn
            ? 'আগামীকাল ৯ মুহররম — আশুরার আগের রোজা!\n◆ ৯ ও ১০ মুহররম একসাথে রোজা রাখা উত্তম\n◆ আজ রাতেই সেহরির নিয়ত করুন\n◆ ফজিলত: ১ বছরের গুনাহ মাফ (সহীহ মুসলিম)'
            : 'Tomorrow 9 Muharram — Fast before Ashura!\n◆ Best to fast 9 & 10 together\n◆ Make Sehri intention tonight\n◆ Reward: 1 year of sins forgiven', 'color': AppTheme.gold});
      }

      if (h == 9 && now.isAfter(pt.maghrib)) {
        alerts.add({'icon': '⭐', 'text': isBn
            ? 'আগামীকাল ১০ মুহররম — পবিত্র আশুরার দিন!\n◆ আশুরার রোজা রাখুন — ১ বছরের গুনাহ মাফ\n◆ আজ রাতেই সেহরির প্রস্তুতি নিন\n◆ ৯ ও ১০ একসাথে রোজা রাখা সর্বোত্তম (সহীহ মুসলিম: ১১৬২)'
            : 'Tomorrow 10 Muharram — Sacred Ashura!\n◆ Fast on Ashura — 1 year of sins forgiven\n◆ Prepare for Sehri tonight\n◆ Fasting 9 & 10 together is best (Muslim: 1162)', 'color': const Color(0xFFFFD700)});
      }

      if (h == 10 && now.isAfter(pt.maghrib)) {
        alerts.add({'icon': '🌙', 'text': isBn
            ? 'আগামীকাল ১১ মুহররম — আশুরার পরের রোজা!\n◆ ১০ ও ১১ মুহররম একসাথে রোজা রাখা উত্তম\n◆ আজ রাতেই সেহরির নিয়ত করুন\n◆ বেশি বেশি দোয়া, জিকির ও ইস্তিগফার করুন'
            : 'Tomorrow 11 Muharram — Fast after Ashura!\n◆ Best to fast 10 & 11 together\n◆ Make Sehri intention tonight\n◆ Increase dua, dhikr & istighfar', 'color': AppTheme.gold});
      }
    }

    // ══ দৈনিক আমল — রাতের শেষ তৃতীয়াংশ (তাহাজ্জুদের সময়) ══
    if (lastThird != null && now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'তাহাজ্জুদের সময়ের আমল:\n◆ ঘুম থেকে জাগরণের দোয়া পড়ুন\n◆ মিসওয়াক/দাঁতন করুন\n◆ অজু করে তাহিয়্যাতুল অজুর নামাজ পড়ুন\n◆ তাহাজ্জুদ নামাজ পড়ুন (সামর্থ্য অনুযায়ী রাকাত)\n◆ রাতে উঠার নিয়ত করে ঘুমালেও সওয়াব মেলে — ঘুম হলে তা সদকাস্বরূপ'
          : 'Tahajjud time deeds:\n◆ Recite waking up dua\n◆ Use miswak\n◆ Perform wudhu & pray Tahiyyatul Wudhu\n◆ Pray Tahajjud (as many rakats as able)\n◆ Intending to wake up for prayer earns reward even if you sleep', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ দৈনিক আমল — ফজরের সময় ══
    if (now.isAfter(pt.fajr.subtract(const Duration(minutes: 30))) && now.isBefore(pt.sunrise)) {
      alerts.add({'icon': '🌅', 'text': isBn
          ? 'ফজরের সময়ের আমল:\n◆ আযান শুনে আযানের জবাব দিন — মুয়াজ্জিন যা বলে পুনরাবৃত্তি করুন\n◆ আযানের পর হাদিসে বর্ণিত দোয়া পড়ুন\n◆ মসজিদে গিয়ে জামাআতে ফজর পড়ুন — প্রথম সারিতে দাঁড়ানোর চেষ্টা করুন\n◆ মসজিদে ডান পা দিয়ে দরুদ পড়ে প্রবেশ করুন\n◆ ফরজ শেষে আয়াতুল কুরসি পড়ুন\n◆ ৩৩ বার সুবহানাল্লাহ + ৩৩ বার আলহামদুলিল্লাহ + ৩৩ বার আল্লাহু আকবার পড়ুন'
          : 'Fajr time deeds:\n◆ Answer the adhan when you hear it\n◆ Recite the dua after adhan\n◆ Pray Fajr in congregation — try the first row\n◆ Enter mosque with right foot, reciting salawat\n◆ Recite Ayatul Kursi after fard\n◆ Say 33x SubhanAllah + 33x Alhamdulillah + 33x AllahuAkbar', 'color': const Color(0xFFFF8F00)});
    }

    // ══ দৈনিক আমল — সকালের জিকির (সূর্যোদয়ের পর) ══
    if (now.isAfter(pt.sunrise) && now.hour < 10) {
      alerts.add({'icon': '☀️', 'text': isBn
          ? 'সকালের জিকির ও আমল:\n◆ সকালের আযকার পড়ুন\n◆ ১০ বার দরুদ পড়ুন\n◆ ১০০ বার "সুবহানাল্লাহিল আজিম ওয়া বিহামদিহি" পড়ুন — জান্নাতে খেজুরগাছ রোপণ\n◆ ১০০ বার "সুবহানাল্লাহি ওয়া বিহামদিহি" পড়ুন — কিয়ামতে সর্বোচ্চ সওয়াব\n◆ বাজারে যাওয়ার দোয়া পড়ুন — ১০ লক্ষ সওয়াব, ১০ লক্ষ গুনাহ মাফ'
          : 'Morning dhikr & deeds:\n◆ Recite morning adhkar\n◆ Send 10x Salawat\n◆ Say 100x "SubhanAllahil Azim wa bihamdih" — tree in Jannah\n◆ Say 100x "SubhanAllahi wa bihamdih" — greatest reward on Judgment Day\n◆ Recite market dua — 1 million rewards, 1 million sins forgiven', 'color': const Color(0xFFFF8F00)});
    }

    // ══ দৈনিক আমল — যোহরের সময় ══
    if (now.isAfter(pt.dhuhr.subtract(const Duration(minutes: 20))) && now.isBefore(pt.asr)) {
      alerts.add({'icon': '🕌', 'text': isBn
          ? 'যোহরের সময়ের আমল:\n◆ যাওয়ালের আগে ও পরে নফল নামাজ পড়ুন (পরে ৪ রাকাত)\n◆ মসজিদে গিয়ে যোহরের নামাজ জামাআতে পড়ুন\n◆ খাবারের আদব মেনে চলুন — বিসমিল্লাহ বলে শুরু, আলহামদুলিল্লাহ বলে শেষ\n◆ পানি পান করার ৬টি সুন্নত মেনে চলুন\n◆ দুপুরে একটু কাইলুলা (ভাতঘুম) নিন — তাহাজ্জুদ সহজ হবে'
          : 'Dhuhr time deeds:\n◆ Pray nafl before & after Dhuhr (4 rakats after)\n◆ Pray Dhuhr in congregation\n◆ Follow eating etiquette — start with Bismillah, end with Alhamdulillah\n◆ Follow 6 sunnahs of drinking water\n◆ Take a short nap (qaylula) — helps for Tahajjud', 'color': const Color(0xFFFF8F00)});
    }

    // ══ দৈনিক আমল — আসরের সময় ══
    if (now.isAfter(pt.asr.subtract(const Duration(minutes: 20))) && now.isBefore(pt.maghrib)) {
      alerts.add({'icon': '🌤️', 'text': isBn
          ? 'আসরের সময়ের আমল:\n◆ আসরের আগে ৪ রাকাত সুন্নত নামাজ পড়ুন\n◆ মসজিদে গিয়ে আসরের নামাজ জামাআতে পড়ুন\n◆ আসরের পর তিলাওয়াত ও জিকির করুন, ইলমি মজলিসে বসুন\n◆ বিকালে ১০০ বার "সুবহানাল্লাহিল আজিম ওয়া বিহামদিহি" পড়ুন\n◆ আসরের পর কোনো নফল নামাজ পড়বেন না (নিষিদ্ধ সময়)'
          : 'Asr time deeds:\n◆ Pray 4 rakats sunnah before Asr\n◆ Pray Asr in congregation\n◆ Recite Quran & dhikr after Asr, attend Islamic gatherings\n◆ Say 100x "SubhanAllahil Azim wa bihamdih"\n◆ No nafl prayers after Asr (forbidden time)', 'color': const Color(0xFFFF8F00)});
    }

    // ══ দৈনিক আমল — মাগরিবের সময় ══
    if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 10))) && now.isBefore(pt.isha)) {
      alerts.add({'icon': '🌇', 'text': isBn
          ? 'মাগরিবের সময়ের আমল:\n◆ মসজিদে গিয়ে মাগরিবের নামাজ জামাআতে পড়ুন\n◆ মাগরিবের পর সূরা হাশরের শেষ তিন আয়াত ও তিন কুল পড়ে দম করুন\n◆ সন্ধ্যার জিকির-আযকার পড়ুন\n◆ ১০ বার দরুদ পড়ুন\n◆ ১০০ বার "সুবহানাল্লাহি ওয়া বিহামদিহি" পড়ুন'
          : 'Maghrib time deeds:\n◆ Pray Maghrib in congregation\n◆ Recite last 3 verses of Surah Hashr & 3 Quls after Maghrib\n◆ Recite evening adhkar\n◆ Send 10x Salawat\n◆ Say 100x "SubhanAllahi wa bihamdih"', 'color': const Color(0xFFFF8F00)});
    }

    // ══ দৈনিক আমল — এশার সময় ══
    if (now.isAfter(pt.isha.subtract(const Duration(minutes: 10))) && now.isBefore(pt.isha.add(const Duration(hours: 2)))) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'এশার সময়ের আমল:\n◆ এশার নামাজ জামাআতে পড়ুন — অর্ধেক রাত ইবাদতের সওয়াব\n◆ ফজর ও এশা দুটোই জামাআতে পড়লে পুরো রাত ইবাদতের সওয়াব\n◆ সুন্নত পড়ে দ্রুত ঘুমিয়ে পড়ুন — রাতের শেষে উঠতে সহজ হবে\n◆ প্রয়োজনে এশার পরই বিতর পড়ে নিন\n◆ কোনো পাপ হলে সালাতুত তাওবা পড়ে ক্ষমা চান'
          : 'Isha time deeds:\n◆ Pray Isha in congregation — reward of half the night in worship\n◆ Praying both Isha & Fajr in congregation = entire night in worship\n◆ Sleep early after sunnah — easier to wake for Tahajjud\n◆ Pray Witr after Isha if needed\n◆ If you sinned, pray Salat al-Tawbah & seek forgiveness', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ দৈনিক আমল — ঘুমানোর আগে ══
    if (now.hour >= 21 || now.hour < 2) {
      alerts.add({'icon': '📖', 'text': isBn
          ? 'ঘুমানোর আগের আমল:\n◆ সূরা মুলক তিলাওয়াত করুন — কবরের শাস্তি থেকে মুক্তি\n◆ তিন কুল (ইখলাস, ফালাক, নাস) পড়ে শরীরে ৩ বার দম করুন\n◆ আয়াতুল কুরসি পড়ুন\n◆ সূরা কাফিরুন পড়ে ডান কাতে শুয়ে পড়ুন\n◆ ঘুমের দোয়া পড়ুন'
          : 'Before sleep deeds:\n◆ Recite Surah Mulk — protection from grave punishment\n◆ Recite 3 Quls & blow on body 3x\n◆ Recite Ayatul Kursi\n◆ Recite Surah Kafirun & sleep on right side\n◆ Recite sleeping dua', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ সাধারণ আমল (সারাদিন) ══
    alerts.add({'icon': '✨', 'text': isBn
        ? 'সারাদিনের সাধারণ আমল:\n◆ প্রতি অজুর পর কালেমা শাহাদাত পড়ুন — জান্নাতের ৮ দরজার যেকোনোটি খোলে\n◆ ঘর থেকে বের হওয়ার দোয়া পড়ে ডান পা দিয়ে বের হন\n◆ সবাইকে সালাম দিন — ছোট-বড় সবাইকে\n◆ হাসিমুখে মানুষের সাথে দেখা করুন — এটাও সদকা\n◆ অসুস্থ মুসলিমকে দেখতে যান — ৭০ হাজার ফেরেশতা দোয়া করবে\n◆ ইখলাসের সাথে "লা ইলাহা ইল্লাল্লাহ" পড়ুন — আসমানের দরজা খুলে যায়'
        : 'General daily deeds:\n◆ Recite Shahada after each wudhu — opens all 8 Jannah gates\n◆ Recite going-out dua & step out with right foot\n◆ Give salam to everyone — young & old\n◆ Meet people with a smile — it is sadaqah\n◆ Visit the sick — 70,000 angels make dua\n◆ Say "La ilaha illallah" sincerely — heavens open up', 'color': const Color(0xFF26A69A)});


    // ══ তাহাজ্জুদের সময় — রাতের শেষ তৃতীয়াংশ ══
    if (lastThird != null && now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'তাহাজ্জুদের সময়ের আমল:\n◆ ঘুম থেকে জাগরণের দোয়া পড়ুন\n◆ মিসওয়াক করুন, অজু করুন\n◆ তাহিয়্যাতুল অজুর নামাজ পড়ুন\n◆ তাহাজ্জুদ নামাজ পড়ুন (সামর্থ্য অনুযায়ী)\n◆ দুঃস্বপ্ন দেখলে বাম দিকে ৩ বার থুতু ফেলে আউযুবিল্লাহ পড়ুন (আমল ২৮)\n◆ রাতে উঠার নিয়তে ঘুমালেও সওয়াব — ঘুম হলে সদকাস্বরূপ (আমল ৬১)'
          : 'Tahajjud time deeds:\n◆ Recite waking up dua\n◆ Use miswak, make wudhu\n◆ Pray Tahiyyatul Wudhu\n◆ Pray Tahajjud (as able)\n◆ Bad dream: spit left 3x & say Audhu billah (Amal 28)\n◆ Intending to wake earns reward — sleep counts as sadaqah (Amal 61)', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ ফজরের সময় ══
    if (now.isAfter(pt.fajr.subtract(const Duration(minutes: 30))) && now.isBefore(pt.sunrise)) {
      alerts.add({'icon': '🌅', 'text': isBn
          ? 'ফজরের সময়ের আমল:\n◆ আযানের জবাব দিন, আযানের পর দোয়া পড়ুন (আমল ৪১)\n◆ মসজিদে জামাআতে ফজর পড়ুন — প্রথম সারিতে চেষ্টা করুন (আমল ৩৯)\n◆ ডান পা দিয়ে দরুদ পড়ে মসজিদে প্রবেশ করুন (আমল ২০)\n◆ ইমামের প্রথম তাকবিরে ৪০ দিন নামাজ — জাহান্নাম থেকে মুক্তি (আমল ১১)\n◆ ফরজ শেষে আয়াতুল কুরসি পড়ুন (আমল ২)\n◆ ৩৩ সুবহানাল্লাহ + ৩৩ আলহামদুলিল্লাহ + ৩৩ আল্লাহু আকবার (আমল ৩)\n◆ ফজরের পর সূরা হাশরের শেষ ৩ আয়াত ও তিন কুল পড়ে দম করুন (আমল ২২)'
          : 'Fajr time deeds:\n◆ Answer adhan, recite post-adhan dua (Amal 41)\n◆ Pray Fajr in congregation, try first row (Amal 39)\n◆ Enter mosque with right foot, reciting salawat (Amal 20)\n◆ 40 days with first takbeer = freed from Hell (Amal 11)\n◆ Recite Ayatul Kursi after fard (Amal 2)\n◆ 33x SubhanAllah + 33x Alhamdulillah + 33x AllahuAkbar (Amal 3)\n◆ Recite last 3 verses Surah Hashr & 3 Quls after Fajr (Amal 22)', 'color': const Color(0xFFFF8F00)});
    }

    // ══ সকাল — সূর্যোদয় থেকে যোহরের আগে ══
    if (now.isAfter(pt.sunrise) && now.isBefore(pt.dhuhr)) {
      alerts.add({'icon': '☀️', 'text': isBn
          ? 'সকালের আমল:\n◆ সূর্যোদয় পর্যন্ত মুসাল্লায় তিলাওয়াত ও জিকির করুন — পূর্ণ হজ-উমরার সওয়াব\n◆ সকালের জিকির-আযকার পড়ুন\n◆ ১০ বার দরুদ পড়ুন (আমল ৫)\n◆ ১০০ বার "সুবহানাল্লাহিল আজিম ওয়া বিহামদিহি" — জান্নাতে খেজুরগাছ (আমল ৬)\n◆ ১০০ বার "সুবহানাল্লাহি ওয়া বিহামদিহি" — কিয়ামতে সর্বোচ্চ সওয়াব (আমল ৭)\n◆ বাজারে নির্দিষ্ট দোয়া পড়ুন — ১০ লক্ষ সওয়াব, ১০ লক্ষ গুনাহ মাফ (আমল ৯)\n◆ ইশরাকের নামাজ পড়ুন (সূর্যোদয়ের ১৫-৪৫ মিনিট পর)'
          : 'Morning deeds:\n◆ Stay in musalla till sunrise doing dhikr — full Hajj & Umrah reward\n◆ Recite morning adhkar\n◆ Send 10x Salawat (Amal 5)\n◆ 100x SubhanAllahil Azim wa bihamdih — tree in Jannah (Amal 6)\n◆ 100x SubhanAllahi wa bihamdih — greatest reward (Amal 7)\n◆ Market dua — 1 million rewards, 1 million sins forgiven (Amal 9)\n◆ Pray Ishraq (15-45 min after sunrise)', 'color': const Color(0xFFFF8F00)});
    }

    // ══ দুপুর — যোহরের সময় ══
    if (now.isAfter(pt.dhuhr.subtract(const Duration(minutes: 20))) && now.isBefore(pt.asr)) {
      alerts.add({'icon': '🕌', 'text': isBn
          ? 'যোহরের সময়ের আমল:\n◆ যাওয়ালের আগে ও পরে নফল নামাজ পড়ুন (পরে ৪ রাকাত)\n◆ মসজিদে গিয়ে যোহরের নামাজ জামাআতে পড়ুন\n◆ দস্তরখানায় বিসমিল্লাহ বলে শুরু, আলহামদুলিল্লাহ বলে শেষ করুন (আমল ২৬)\n◆ পানি পান করার ৬টি সুন্নত মেনে চলুন (আমল ২৫)\n◆ দুপুরে একটু কাইলুলা নিন — তাহাজ্জুদ সহজ হবে'
          : 'Dhuhr time deeds:\n◆ Pray nafl before & after Dhuhr (4 rakats after)\n◆ Pray Dhuhr in congregation\n◆ Bismillah to start eating, Alhamdulillah to end (Amal 26)\n◆ Follow 6 sunnahs of drinking water (Amal 25)\n◆ Take a short qaylula — easier Tahajjud', 'color': const Color(0xFFFF8F00)});
    }

    // ══ বিকেল — আসরের সময় ══
    if (now.isAfter(pt.asr.subtract(const Duration(minutes: 20))) && now.isBefore(pt.maghrib)) {
      alerts.add({'icon': '🌤️', 'text': isBn
          ? 'আসরের সময়ের আমল:\n◆ আসরের আগে ৪ রাকাত সুন্নাত নামাজ পড়ুন\n◆ মসজিদে গিয়ে আসরের নামাজ জামাআতে পড়ুন\n◆ বিকালে ১০০ বার "সুবহানাল্লাহিল আজিম ওয়া বিহামদিহি" পড়ুন (আমল ৬)\n◆ ১০০ বার সুবহানাল্লাহ + আলহামদুলিল্লাহ + আল্লাহু আকবার + কালিমা পড়ুন (আমল ৮)\n◆ আসরের পর কোনো নফল নামাজ নেই (নিষিদ্ধ সময়)\n◆ আসরের পর বসে তিলাওয়াত ও জিকির করুন'
          : 'Asr time deeds:\n◆ Pray 4 sunnah rakats before Asr\n◆ Pray Asr in congregation\n◆ 100x SubhanAllahil Azim wa bihamdih (Amal 6)\n◆ 100x SubhanAllah + Alhamdulillah + AllahuAkbar + Kalimah (Amal 8)\n◆ No nafl prayers after Asr (forbidden time)\n◆ Sit with Quran & dhikr after Asr', 'color': const Color(0xFFFF8F00)});
    }

    // ══ সন্ধ্যা — মাগরিবের সময় ══
    if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 15))) && now.isBefore(pt.isha)) {
      alerts.add({'icon': '🌇', 'text': isBn
          ? 'মাগরিবের সময়ের আমল:\n◆ মসজিদে গিয়ে মাগরিবের নামাজ জামাআতে পড়ুন\n◆ মাগরিবের পর সূরা হাশরের শেষ ৩ আয়াত ও তিন কুল পড়ে দম করুন (আমল ২২)\n◆ সন্ধ্যায় ১০ বার দরুদ পড়ুন (আমল ৫)\n◆ ১০০ বার "সুবহানাল্লাহি ওয়া বিহামদিহি" পড়ুন (আমল ৭)\n◆ সন্ধ্যার জিকির-আযকার পড়ুন'
          : 'Maghrib time deeds:\n◆ Pray Maghrib in congregation\n◆ Recite last 3 verses Surah Hashr & 3 Quls, blow on body (Amal 22)\n◆ Send 10x Salawat in evening (Amal 5)\n◆ 100x SubhanAllahi wa bihamdih (Amal 7)\n◆ Recite evening adhkar', 'color': const Color(0xFFFF8F00)});
    }

    // ══ রাত — এশার সময় ══
    if (now.isAfter(pt.isha.subtract(const Duration(minutes: 15))) && now.isBefore(pt.isha.add(const Duration(hours: 2)))) {
      alerts.add({'icon': '🌙', 'text': isBn
          ? 'এশার সময়ের আমল:\n◆ এশার নামাজ জামাআতে পড়ুন — অর্ধেক রাত ইবাদতের সওয়াব (আমল ৩২)\n◆ ফজর ও এশা দুটোই জামাআতে = পুরো রাত ইবাদতের সওয়াব\n◆ এশার আগে ঘুমানো ও পরে অনর্থক কথা নিষেধ\n◆ সুন্নাত পড়ে দ্রুত ঘুমান — রাতে উঠতে সহজ হবে\n◆ উঠতে না পারার আশঙ্কায় এশার পরই বিতর পড়ুন\n◆ দ্বিধায় সালাতুল ইস্তিখারা, বিপদে সালাতুল হাজত, পাপে সালাতুত তাওবা পড়ুন'
          : 'Isha time deeds:\n◆ Pray Isha in congregation — half night worship reward (Amal 32)\n◆ Both Fajr & Isha in congregation = full night worship\n◆ Avoid sleeping before Isha & idle talk after\n◆ Sleep early after sunnah — easier Tahajjud\n◆ Pray Witr after Isha if worried about missing it\n◆ Istikhara for doubt, Hajat for need, Tawbah for sin', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ ঘুমানোর আগে — রাত ৯টার পর ══
    if (now.hour >= 21 || now.hour < 3) {
      alerts.add({'icon': '📖', 'text': isBn
          ? 'ঘুমানোর আগের আমল:\n◆ সূরা মুলক তিলাওয়াত করুন — কবরের শাস্তি থেকে মুক্তি (আমল ৪)\n◆ তিন কুল পড়ে শরীরে ৩ বার দম করুন\n◆ আয়াতুল কুরসি পড়ুন\n◆ সূরা কাফিরুন পড়ে ডান কাতে শুয়ে পড়ুন\n◆ ঘুমের দোয়া পড়ুন (আমল ১৬)\n◆ কাল ভালো কাজের নিয়ত করে ঘুমান'
          : 'Before sleep deeds:\n◆ Recite Surah Mulk — protection from grave (Amal 4)\n◆ Recite 3 Quls & blow on body 3x\n◆ Recite Ayatul Kursi\n◆ Recite Surah Kafirun & sleep on right side\n◆ Recite sleeping dua (Amal 16)\n◆ Sleep with intention to do good tomorrow', 'color': const Color(0xFF7C4DFF)});
    }

    // ══ বিশেষ মুহূর্তের আমল (সারাদিন) ══
    alerts.add({'icon': '💫', 'text': isBn
        ? 'বিশেষ মুহূর্তের আমল:\n◆ প্রতি অজুর পর কালেমা শাহাদাত — জান্নাতের ৮ দরজার যেকোনোটি খোলে (আমল ১)\n◆ অজুর আগে মিসওয়াক, অজুর শুরু-শেষে দোয়া পড়ুন (আমল ১৮)\n◆ বাথরুমে বাম পা দিয়ে ঢুকুন, ডান পা দিয়ে বের হন (আমল ১৭)\n◆ বাড়িতে সালাম দিয়ে প্রবেশ করুন — কেউ না থাকলেও ফেরেশতাদের জন্য (আমল ১০)\n◆ জামা-জুতা পরায় ডান দিক আগে, খোলায় বাম দিক আগে (আমল ২৪)\n◆ মন্দ কাজের পর ভালো কাজ করুন — মন্দ মুছে যায় (আমল ৭০)'
        : 'Special moments deeds:\n◆ Shahada after each wudhu — opens all 8 Jannah gates (Amal 1)\n◆ Miswak before wudhu, dua at start & end (Amal 18)\n◆ Left foot in bathroom, right foot out (Amal 17)\n◆ Give salam entering home — for angels if empty (Amal 10)\n◆ Right side first when dressing, left when undressing (Amal 24)\n◆ Follow bad with good — it erases the bad (Amal 70)', 'color': const Color(0xFF26A69A)});

    // ══ চরিত্র ও জীবনাচরণ (সারাদিন) ══
    alerts.add({'icon': '🌿', 'text': isBn
        ? 'উত্তম চরিত্র ও জীবনাচরণ:\n◆ নিজের জন্য যা পছন্দ, অপরের জন্যও তা পছন্দ করুন\n◆ অন্যের দোষ গোপন রাখুন, ক্ষমা প্রদর্শন করুন\n◆ বড়দের সম্মান করুন, আলেমদের শ্রদ্ধা করুন\n◆ সৎকাজে আদেশ, মন্দ কাজে বাধা দিন\n◆ বিবদমান পক্ষের মধ্যে মিল করিয়ে দিন\n◆ মা-বাপের অবাধ্য হবেন না\n◆ আত্মীয়তার সম্পর্ক রক্ষা করুন — রিজিক বৃদ্ধি ও আয়ু দীর্ঘ হয় (আমল ২৯)\n◆ প্রতিবেশীকে কষ্ট দেবেন না'
        : 'Good character & conduct:\n◆ Love for others what you love for yourself\n◆ Conceal others faults, show forgiveness\n◆ Respect elders, honor scholars\n◆ Command good, forbid evil\n◆ Reconcile between disputing parties\n◆ Never disobey parents\n◆ Maintain family ties — increases rizq & lifespan (Amal 29)\n◆ Never harm your neighbor', 'color': const Color(0xFF26A69A)});

    // ══ মহৎ ফজিলতপূর্ণ আমল (সারাদিন) ══
    alerts.add({'icon': '🏆', 'text': isBn
        ? 'মহৎ ফজিলতপূর্ণ আমল:\n◆ "সুবহানাল্লাহি ওয়া বিহামদিহি, সুবহানাল্লাহিল আজিম" — বলা সহজ, মিজানে ভারী (আমল ৫৬)\n◆ জামাআতে নামাজ পড়ুন — একাকীর চেয়ে ২৭ গুণ বেশি মর্যাদা (আমল ৩১)\n◆ নফল নামাজ ঘরে পড়ুন — বেশি সওয়াব (আমল ৩৩)\n◆ সূরা ইখলাস পড়ুন — কুরআনের এক-তৃতীয়াংশের সমান (আমল ৪৯)\n◆ মুসলিম ভাইয়ের প্রয়োজন পূরণ করুন — আল্লাহ আপনার প্রয়োজন পূরণ করবেন (আমল ৬০)\n◆ ইখলাসের সাথে প্রতিটি কাজের নিয়ত ঠিক রাখুন (আমল ৬৩)'
        : 'Most virtuous deeds:\n◆ SubhanAllahi wa bihamdih, SubhanAllahil Azim — easy, heavy in scales (Amal 56)\n◆ Pray in congregation — 27x more than alone (Amal 31)\n◆ Pray nafl at home — more reward (Amal 33)\n◆ Recite Surah Ikhlas — equals 1/3 of Quran (Amal 49)\n◆ Fulfill a brothers need — Allah will fulfill yours (Amal 60)\n◆ Keep sincere intention in every deed (Amal 63)', 'color': const Color(0xFF26A69A)});

    // ══ উপদেশমূলক সমাপনী ══
    alerts.add({'icon': '📌', 'text': isBn
        ? 'মূল শিক্ষা:\n◆ আল্লাহর কাছে সবচেয়ে প্রিয় — নিয়মিত আমল, পরিমাণে কম হলেও\n◆ নিয়ত ঠিক না হলে আমল মূল্যহীন — ইখলাসের সাথে করুন\n◆ নিজের আমলের ভরসায় না থেকে আল্লাহর রহমত কামনা করুন\n◆ বাড়াবাড়ি বা অবহেলা — দুটোই এড়িয়ে মধ্যপন্থা মেনে চলুন\n◆ সদকায়ে জারিয়াহ, উপকারী ইলম ও সুসন্তান রেখে যাওয়ার চেষ্টা করুন (আমল ৫৭)'
        : 'Key lessons:\n◆ Allah loves consistent deeds most — even if small\n◆ Without sincere intention, deeds are worthless\n◆ Do not rely on deeds — always seek Allahs mercy\n◆ Avoid extremes — follow the middle path\n◆ Leave Sadaqah Jariyah, beneficial knowledge & righteous children (Amal 57)', 'color': const Color(0xFF26A69A)});

    return alerts;
  }
  List<Map<String, dynamic>> _getNaflAmalAlerts(AppLanguage lang) {
    final isBn = lang.isBn;
    final now = DateTime.now();
    final pt = _prayerTimes;
    final alerts = <Map<String, dynamic>>[];

    // ══ কবিরা গুনাহ — আকিদা সংক্রান্ত (১-১৮) ══
    alerts.add({'icon': '⚠️', 'text': isBn
        ? 'কবিরা গুনাহ ১-৯ (আকিদা):\n১. শির্ক — অতি মহাপাপ\n২. দুনিয়ার জন্য ইলম শেখা\n৩. শরয়ী ইলম গোপন করা\n৪. বিশ্বাসঘাতকতা করা\n৫. গণকের কথা বিশ্বাস করা\n৬. গায়রুল্লাহর নামে যবেহ করা\n৭. গায়রুল্লাহর নামে নযর মানা\n৮. গায়রুল্লাহর নামে কসম করা\n৯. যাদু করা'
        : 'Major sins 1-9 (Aqeedah):\n1. Shirk — greatest sin\n2. Seeking knowledge for worldly gain\n3. Concealing religious knowledge\n4. Betrayal/treachery\n5. Believing fortune tellers\n6. Sacrificing in other than Allahs name\n7. Making vows to other than Allah\n8. Swearing by other than Allah\n9. Practicing magic', 'color': const Color(0xFFE53935)});

    alerts.add({'icon': '⚠️', 'text': isBn
        ? 'কবিরা গুনাহ ১০-১৮ (আকিদা):\n১০. আল্লাহর প্রতি কুধারণা রাখা\n১১. মুসলিমের প্রতি কুধারণা রাখা\n১২. মুসলিমকে বিনা দলিলে কাফের বলা\n১৩. কাফেরকে কাফের না জানা\n১৪. আল্লাহ ও রাসূলের প্রতি মিথ্যা আরোপ করা\n১৫. আল্লাহর আযাব থেকে নিজেকে নিরাপদ ভাবা\n১৬. আল্লাহর রহমত থেকে নিরাশ হওয়া\n১৭. তকদীর অস্বীকার করা\n১৮. তাবিজ বাঁধা'
        : 'Major sins 10-18 (Aqeedah):\n10. Having bad thoughts about Allah\n11. Having bad thoughts about Muslims\n12. Calling a Muslim kafir without proof\n13. Not recognizing a kafir as kafir\n14. Attributing falsehood to Allah or Prophet\n15. Feeling safe from Allahs punishment\n16. Despairing of Allahs mercy\n17. Denying divine decree\n18. Wearing amulets/talismans', 'color': const Color(0xFFE53935)});

    // ══ কবিরা গুনাহ — জীবন ও সম্মান (১৯-৩৭) ══
    alerts.add({'icon': '🚫', 'text': isBn
        ? 'কবিরা গুনাহ ১৯-২৮ (জীবন ও সম্মান):\n১৯. প্রাণ হত্যা করা\n২০. আত্মহত্যা করা\n২১. জুলুম করা\n২২. অপমান ও অপদস্থ করা\n২৩. মিথ্যা বলা\n২৪. পরচর্চা বা গীবত করা\n২৫. চোগলখুরি করা\n২৬. গালি দেওয়া\n২৭. মাদকদ্রব্য সেবন করা\n২৮. মৃত বা হারাম পশুর মাংস খাওয়া'
        : 'Major sins 19-28 (life & honor):\n19. Murder\n20. Suicide\n21. Oppression/injustice\n22. Humiliating others\n23. Lying\n24. Backbiting/gossip\n25. Tale-bearing/slander\n26. Cursing/insulting\n27. Consuming intoxicants\n28. Eating dead animals or haram meat', 'color': const Color(0xFFE53935)});

    alerts.add({'icon': '🚫', 'text': isBn
        ? 'কবিরা গুনাহ ২৯-৩৭ (চরিত্র):\n২৯. বাজে তর্ক করা\n৩০. সত্য প্রত্যাখ্যান করা\n৩১. ঠাট্টা বা ব্যঙ্গ-বিদ্রুপ করা\n৩২. গালি দেওয়া\n৩৩. অহংকার করা\n৩৪. নিজের প্রশংসা নিজেই করা\n৩৫. অপরের দোষ খোঁজা\n৩৬. মূর্তি বা ছবি তৈরি করা\n৩৭. এতিমের মাল ভক্ষণ করা'
        : 'Major sins 29-37:\n29. Useless argumentation\n30. Rejecting the truth\n31. Mockery and ridicule\n32. Cursing\n33. Arrogance/pride\n34. Self-praise\n35. Seeking others faults\n36. Making idols or pictures\n37. Consuming orphans wealth', 'color': const Color(0xFFE53935)});

    // ══ কবিরা গুনাহ — আর্থিক ও লেনদেন (৩৮-৫৭) ══
    alerts.add({'icon': '💰', 'text': isBn
        ? 'কবিরা গুনাহ ৩৮-৪৭ (আর্থিক):\n৩৮. জুয়া (ফ্লাশ) খেলা\n৩৯. লটারি খেলা\n৪০. চুরি করা\n৪১. আমানতে খেয়ানত করা\n৪২. পরের সম্পদ আত্মসাৎ করা\n৪৩. জমি-জায়গা দাবিয়ে নেওয়া\n৪৪. ঘুষ খাওয়া\n৪৫. সুদ খাওয়া\n৪৬. ওজনে কম দেওয়া\n৪৭. মিথ্যা কসম খাওয়া'
        : 'Major sins 38-47 (financial):\n38. Gambling\n39. Lottery\n40. Stealing\n41. Betraying a trust\n42. Misappropriating others property\n43. Seizing land by force\n44. Taking bribes\n45. Dealing in usury/interest\n46. Giving short measure/weight\n47. False oath', 'color': const Color(0xFFE53935)});

    alerts.add({'icon': '💰', 'text': isBn
        ? 'কবিরা গুনাহ ৪৮-৫৭ (লেনদেন):\n৪৮. ধোঁকা দেওয়া\n৪৯. কসম করে মাল বিক্রি করা\n৫০. প্রতিশ্রুতি পালন না করা\n৫১. চুক্তি ভঙ্গ করা\n৫২. মিথ্যা সাক্ষ্য দেওয়া\n৫৩. সাক্ষ্য গোপন করা\n৫৪. মালে ভেজাল দেওয়া\n৫৫. প্রয়োজনের সময় মাল গুদামজাত করা\n৫৬. অসিয়ত পালন না করা\n৫৭. আল্লাহর ভাগ করা ভাগ্যে সন্তুষ্ট না হওয়া'
        : 'Major sins 48-57 (transactions):\n48. Deception/cheating\n49. Selling with false oath\n50. Breaking promises\n51. Breaking contracts\n52. False testimony\n53. Concealing testimony\n54. Adulterating goods\n55. Hoarding goods in time of need\n56. Not fulfilling a will/wasiyyah\n57. Discontentment with Allahs decree', 'color': const Color(0xFFE53935)});

    // ══ কবিরা গুনাহ — পোশাক ও গান-বাজনা (৫৮-৬১) ══
    alerts.add({'icon': '🎵', 'text': isBn
        ? 'কবিরা গুনাহ ৫৮-৬১ (পোশাক ও বিনোদন):\n৫৮. পুরুষের সোনা ও রেশম ব্যবহার\n৫৯. পুরুষের গোড়ালির নিচে কাপড় ঝুলিয়ে পরা\n৬০. দান করে গেয়ে বেড়ানো (মান্নান)\n৬১. গান-বাজনা শোনা'
        : 'Major sins 58-61 (dress & entertainment):\n58. Men wearing gold or silk\n59. Men letting garment hang below ankles\n60. Reminding others of charity given (mannan)\n61. Listening to music/singing', 'color': const Color(0xFFE53935)});

    // ══ কবিরা গুনাহ — ইবাদত ত্যাগ (৬২-৭৪) ══
    alerts.add({'icon': '🙅', 'text': isBn
        ? 'কবিরা গুনাহ ৬২-৭৪ (ইবাদত):\n৬২. ফরজ নামাজ ত্যাগ করা\n৬৩. সময় পার করে নামাজ পড়া\n৬৪. লোক দেখিয়ে ইবাদত করা\n৬৫. জাকাত না দেওয়া\n৬৬. রোজা না রাখা\n৬৭. হজ্জ না করা (সামর্থ্য থাকলে)\n৬৮. জিহাদ না করা (সামর্থ্য থাকলে)\n৬৯. জিহাদের ময়দানে পৃষ্ঠপ্রদর্শন করা\n৭০. জুমা ত্যাগ করা\n৭১. জামাআত ত্যাগ করা\n৭২. সৎকাজে আদেশ ও মন্দ কাজে বাধা না দেওয়া\n৭৩. পেশাবের ছিটা থেকে না বাঁচা\n৭৪. ইলম অনুযায়ী আমল না করা'
        : 'Major sins 62-74 (worship):\n62. Abandoning obligatory prayers\n63. Praying after time has passed\n64. Showing off in worship (riya)\n65. Not paying Zakat\n66. Not fasting in Ramadan\n67. Not performing Hajj (if able)\n68. Abandoning Jihad (if able)\n69. Fleeing the battlefield\n70. Abandoning Jumuah\n71. Abandoning congregation\n72. Not enjoining good & forbidding evil (when able)\n73. Not protecting from urine splashes\n74. Not acting on knowledge', 'color': const Color(0xFFE53935)});

    // ══ কবিরা গুনাহ — যৌন ও পর্দা (৭৫-৮৪) ══
    alerts.add({'icon': '👁️', 'text': isBn
        ? 'কবিরা গুনাহ ৭৫-৮৪ (পর্দা ও যৌন):\n৭৫. ব্যভিচার করা\n৭৬. মাসিক অবস্থায় সহবাস করা\n৭৭. পায়খানাদ্বারে সঙ্গম করা\n৭৮. অবৈধ প্রেম করা\n৭৯. সমকাম করা\n৮০. হস্তমৈথুন করা\n৮১. মিথ্যা অপবাদ দেওয়া\n৮২. মহিলার বেপর্দা হওয়া\n৮৩. পুরুষের নারীর মতো বেশ ধারণ করা\n৮৪. দাড়ি চাঁছা'
        : 'Major sins 75-84 (modesty & sexual):\n75. Zina/adultery\n76. Intercourse during menses\n77. Anal intercourse\n78. Illicit/forbidden love relationships\n79. Homosexuality\n80. Masturbation\n81. False accusation of adultery\n82. Women not observing hijab\n83. Men dressing like women or vice versa\n84. Shaving the beard', 'color': const Color(0xFFE53935)});

    // ══ কবিরা গুনাহ — পরিবার ও সমাজ (৮৫-১০০) ══
    alerts.add({'icon': '👨‍👩‍👧', 'text': isBn
        ? 'কবিরা গুনাহ ৮৫-৯৪ (পরিবার ও সমাজ):\n৮৫. মা-বাপের অবাধ্য হওয়া\n৮৬. আত্মীয়তার বন্ধন ছেদন করা\n৮৭. স্বামীর কথা না মানা\n৮৮. পর্যাপ্ত কারণ ছাড়া তালাক দেওয়া\n৮৯. পর্যাপ্ত কারণ ছাড়া তালাক নেওয়া\n৯০. হালালা বিবাহ দেওয়া ও করা\n৯১. মহরম ছাড়া মহিলার একা সফর করা\n৯২. অন্যের বাপকে নিজের বাপ দাবি করা\n৯৩. বাড়ির মহিলার ব্যাপারে বেপরোয়া হওয়া\n৯৪. প্রতিবেশীকে কষ্ট দেওয়া'
        : 'Major sins 85-94 (family & society):\n85. Disobeying parents\n86. Severing family ties\n87. Wife disobeying husband\n88. Divorcing without sufficient reason\n89. Seeking divorce without sufficient reason\n90. Halala marriage (to remarry divorced spouse)\n91. Woman travelling alone without mahram\n92. Claiming another mans father as own\n93. Being indifferent about womens honor at home\n94. Harming neighbors', 'color': const Color(0xFFE53935)});

    alerts.add({'icon': '🔚', 'text': isBn
        ? 'কবিরা গুনাহ ৯৫-১০০ (বিবিধ):\n৯৫. মহিলার ভ্রু ও মুখের লোম চাঁছা\n৯৬. মহিলার পরচুলা ব্যবহার\n৯৭. দেহে দাগ কেটে নকশা করা (ট্যাটু)\n৯৮. দাঁত ঘষে ফাঁক ফাঁক করা\n৯৯. উঁকি দিয়ে অন্যের গোপন কথা শোনা\n১০০. শোকে মাতম করা\n\n✅ এই ১০০টি কবিরা গুনাহ থেকে আল্লাহ আমাদের রক্ষা করুন — আমীন'
        : 'Major sins 95-100 (misc):\n95. Women plucking eyebrows/facial hair\n96. Women wearing wigs\n97. Tattoos/body scarification\n98. Filing teeth to create gaps\n99. Eavesdropping on others secrets\n100. Wailing/lamenting excessively in grief\n\n✅ May Allah protect us from all 100 major sins — Ameen', 'color': const Color(0xFFE53935)});

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
