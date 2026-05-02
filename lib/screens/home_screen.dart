import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/date_helper.dart';
import '../utils/database_helper.dart';
import '../utils/prayer_time_helper.dart';
import 'calendar_screen.dart';
import 'summary_screen.dart';
import 'prayer_time_screen.dart';
import 'settings_screen.dart';
import 'missed_list_screen.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage(_lang);
    final screens = [
      _HomeTab(
        lang: lang,
        now: _now,
        userName: _userName,
        namazPending: _namazPending,
        rozaPending: _rozaPending,
        onRefresh: _loadCounts,
      ),
      CalendarScreen(lang: lang, onDataChanged: _loadCounts),
      PrayerTimeScreen(lang: lang),
      SummaryScreen(lang: lang),
      SettingsScreen(lang: lang, onChanged: () {
        _loadPrefs();
        _loadCounts();
      }),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surface,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: AppTheme.primary,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: lang.home),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: lang.calendar),
          NavigationDestination(icon: const Icon(Icons.access_time_outlined), selectedIcon: const Icon(Icons.access_time), label: lang.prayerTimes),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: lang.summary),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: lang.settings),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final AppLanguage lang;
  final DateTime now;
  final String userName;
  final int namazPending;
  final int rozaPending;
  final VoidCallback onRefresh;

  const _HomeTab({
    required this.lang,
    required this.now,
    required this.userName,
    required this.namazPending,
    required this.rozaPending,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              lang.bismillah,
              style: const TextStyle(fontSize: 22, color: AppTheme.gold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              lang.prayerCount(userName),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _ClockCard(now: now, lang: lang),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PendingCard(
                    label: lang.namazBaki,
                    count: namazPending,
                    suffix: lang.wakt,
                    color: AppTheme.missed,
                    icon: Icons.mosque,
                    lang: lang,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                        MissedListScreen(lang: lang, type: 'prayer'))
                    ).then((_) => onRefresh()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PendingCard(
                    label: lang.rozaBaki,
                    count: rozaPending,
                    suffix: '',
                    color: AppTheme.pending,
                    icon: Icons.brightness_3,
                    lang: lang,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                        MissedListScreen(lang: lang, type: 'roza'))
                    ).then((_) => onRefresh()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _NextPrayerCard(lang: lang),
          ],
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final DateTime now;
  final AppLanguage lang;
  const _ClockCard({required this.now, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.3), AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            DateHelper.formatTime12(now, bangla: lang.isBn),
            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            lang.dayName(now.weekday),
            style: TextStyle(
              fontSize: 16,
              color: now.weekday == DateTime.friday ? AppTheme.accent : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Text(DateHelper.formatGregorian(now, bangla: lang.isBn),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(DateHelper.toHijri(now, bangla: lang.isBn),
            style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(DateHelper.toBangla(now),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final String label, suffix;
  final int count;
  final Color color;
  final IconData icon;
  final AppLanguage lang;
  final VoidCallback onTap;

  const _PendingCard({
    required this.label, required this.count, required this.suffix,
    required this.color, required this.icon, required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text(lang.toLocalNum(count), style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
            if (suffix.isNotEmpty)
              Text(suffix, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerCard extends StatefulWidget {
  final AppLanguage lang;
  const _NextPrayerCard({required this.lang});

  @override
  State<_NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<_NextPrayerCard> {
  Map<String, DateTime>? _times;
  String? _nextPrayer;
  Duration? _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  Future<void> _load() async {
    final times = await PrayerTimeHelper.getPrayerTimes();
    final map = PrayerTimeHelper.getPrayerTimesMap(times);
    final next = PrayerTimeHelper.getNextPrayer(times);
    final remaining = PrayerTimeHelper.getTimeToNextPrayer(times);
    if (mounted) setState(() { _times = map; _nextPrayer = next; _remaining = remaining; });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String _name(String key) {
    switch (key) {
      case 'fajr': return widget.lang.fajr;
      case 'dhuhr': return widget.lang.dhuhr;
      case 'asr': return widget.lang.asr;
      case 'maghrib': return widget.lang.maghrib;
      case 'isha': return widget.lang.isha;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_times == null) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _nextPrayer != null ? '${widget.lang.nextPrayer}: ${_name(_nextPrayer!)}' : widget.lang.prayerTimes,
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (_remaining != null)
                Text(PrayerTimeHelper.formatDuration(_remaining!),
                  style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ..._times!.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_name(e.key), style: TextStyle(
                  color: e.key == _nextPrayer ? AppTheme.gold : AppTheme.textPrimary,
                  fontWeight: e.key == _nextPrayer ? FontWeight.bold : FontWeight.normal,
                )),
                Text(PrayerTimeHelper.formatTime(e.value), style: TextStyle(
                  color: e.key == _nextPrayer ? AppTheme.accent : AppTheme.textSecondary,
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
