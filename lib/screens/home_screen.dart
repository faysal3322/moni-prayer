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
import 'summary_screen.dart';
import 'settings_screen.dart';
import 'missed_list_screen.dart';
import 'names_screen.dart';

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

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          AppLanguage(_lang).isBn ? 'অ্যাপ বন্ধ করবেন?' : 'Exit App?',
          style: const TextStyle(color: AppTheme.gold),
        ),
        content: Text(
          AppLanguage(_lang).isBn
              ? 'আপনি কি MONI PRAYER বন্ধ করতে চান?'
              : 'Do you want to close MONI PRAYER?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLanguage(_lang).isBn ? 'না' : 'No',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.missed),
            child: Text(AppLanguage(_lang).isBn ? 'হ্যাঁ, বন্ধ করুন' : 'Yes, Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
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
      ),
      CalendarScreen(lang: lang, onDataChanged: _loadCounts),
      SummaryScreen(lang: lang),
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
              label: lang.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: lang.calendar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart),
              label: lang.summary,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_stories_outlined),
              selectedIcon: const Icon(Icons.auto_stories),
              label: isBn ? '৯৯ নাম' : '99 Names',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: lang.settings,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
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
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, String> _todayPrayers = {};
  String? _todayRoza;
  PrayerTimes? _prayerTimes;
  SunnahTimes? _sunnahTimes;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    final statuses = await DatabaseHelper.getDayPrayerStatuses(dateKey);
    final roza = await DatabaseHelper.getRozaStatus(dateKey);
    final times = await PrayerTimeHelper.getPrayerTimes();
    final sunnah = SunnahTimes(times);
    if (mounted) {
      setState(() {
        _todayPrayers = statuses;
        _todayRoza = roza;
        _prayerTimes = times;
        _sunnahTimes = sunnah;
      });
    }
  }

  Future<void> _setPrayer(String prayer, String status) async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    await DatabaseHelper.setPrayerStatus(dateKey, prayer, status);
    await _loadToday();
    widget.onRefresh();
  }

  Future<void> _setRoza(String status) async {
    final dateKey = DateHelper.dateKey(DateTime.now());
    await DatabaseHelper.setRozaStatus(dateKey, status);
    await _loadToday();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final now = widget.now;
    final isBn = lang.isBn;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              lang.bismillah,
              style: const TextStyle(fontSize: 20, color: AppTheme.gold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              lang.prayerCount(widget.userName),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _ClockCard(now: now, lang: lang, prayerTimes: _prayerTimes),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _PendingCard(
                label: lang.namazBaki,
                count: widget.namazPending,
                suffix: lang.wakt,
                color: AppTheme.missed,
                icon: Icons.mosque,
                lang: lang,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MissedListScreen(lang: lang, type: 'prayer')),
                ).then((_) => widget.onRefresh()),
              )),
              const SizedBox(width: 12),
              Expanded(child: _PendingCard(
                label: lang.rozaBaki,
                count: widget.rozaPending,
                suffix: '',
                color: AppTheme.pending,
                icon: Icons.brightness_3,
                lang: lang,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MissedListScreen(lang: lang, type: 'roza')),
                ).then((_) => widget.onRefresh()),
              )),
            ]),
            const SizedBox(height: 12),
            _PrayerTimesCard(
              lang: lang,
              prayerTimes: _prayerTimes,
              sunnahTimes: _sunnahTimes,
            ),
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

class _ClockCard extends StatelessWidget {
  final DateTime now;
  final AppLanguage lang;
  final PrayerTimes? prayerTimes;

  const _ClockCard({
    required this.now,
    required this.lang,
    required this.prayerTimes,
  });

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    final sunrise = prayerTimes?.sunrise;
    final maghrib = prayerTimes?.maghrib;
    final fajr = prayerTimes?.fajr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            DateHelper.formatTime12(now, bangla: isBn),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            lang.dayName(now.weekday),
            style: TextStyle(
              fontSize: 16,
              color: now.weekday == DateTime.friday
                  ? AppTheme.accent
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateHelper.formatGregorian(now, bangla: isBn),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateHelper.toHijri(now, bangla: isBn),
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateHelper.toBangla(now),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 65,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _timeRow('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise',
                      sunrise != null ? PrayerTimeHelper.formatTime(sunrise) : '--'),
                    const SizedBox(height: 4),
                    _timeRow('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset',
                      maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--'),
                    const SizedBox(height: 4),
                    _timeRow('🍽️', isBn ? 'সেহরি' : 'Sehri',
                      fajr != null ? PrayerTimeHelper.formatTime(fajr) : '--'),
                    const SizedBox(height: 4),
                    _timeRow('🌙', isBn ? 'ইফতার' : 'Iftar',
                      maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeRow(String icon, String label, String time) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      Text(time, style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
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
    required this.label,
    required this.count,
    required this.suffix,
    required this.color,
    required this.icon,
    required this.lang,
    required this.onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 6),
            Text(lang.toLocalNum(count),
              style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold)),
            if (suffix.isNotEmpty)
              Text(suffix, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
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

  String _name(String key) {
    switch (key) {
      case 'fajr': return lang.fajr;
      case 'dhuhr': return lang.dhuhr;
      case 'asr': return lang.asr;
      case 'maghrib': return lang.maghrib;
      case 'isha': return lang.isha;
      default: return key;
    }
  }

  Widget _infoChip(String icon, String label, String time) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      Text(time, style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              Expanded(child: Text(
                isBn ? 'নামাজ' : 'Prayer',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
              )),
              SizedBox(width: 85, child: Text(
                isBn ? 'শুরু' : 'Start',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )),
              SizedBox(width: 85, child: Text(
                isBn ? 'শেষ' : 'End',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )),
            ]),
          ),
          ...prayers.map((p) {
            final isNext = nextPrayer == p['key'];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isNext ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(children: [
                Expanded(child: Row(children: [
                  if (isNext)
                    const Icon(Icons.arrow_right, color: AppTheme.accent, size: 18),
                  Text(_name(p['key'] as String), style: TextStyle(
                    color: isNext ? AppTheme.gold : AppTheme.textPrimary,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  )),
                ])),
                SizedBox(width: 85, child: Text(
                  _fmt(p['start'] as DateTime),
                  style: TextStyle(
                    color: isNext ? AppTheme.accent : AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                )),
                SizedBox(width: 85, child: Text(
                  _fmt(p['end'] as DateTime),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                )),
              ]),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Divider(color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoChip('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise', _fmt(prayerTimes!.sunrise)),
                    _infoChip('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset', _fmt(prayerTimes!.maghrib)),
                    _infoChip('🍽️', isBn ? 'সেহরি' : 'Sehri', _fmt(prayerTimes!.fajr)),
                    _infoChip('🌙', isBn ? 'ইফতার' : 'Iftar', _fmt(prayerTimes!.maghrib)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    }
  }
}

