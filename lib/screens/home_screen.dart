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
            child: Text(AppLanguage(_lang).isBn ? 'না' : 'No',
                style: const TextStyle(color: AppTheme.textSecondary)),
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
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: lang.home),
            NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: lang.calendar),
            NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: lang.summary),
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

  const _HomeTab({
    required this.lang, required this.now, required this.userName,
    required this.namazPending, required this.rozaPending, required this.onRefresh,
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

  @override
  void initState() {
    super.initState();
    _loadToday();
    _loadHijri();
  }

  @override
  void didUpdateWidget(_HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadHijri();
  }

  Future<void> _loadHijri() async {
    final h = await DateHelper.toHijriWithUserAdjust(DateTime.now(), bangla: widget.lang.isBn);
    if (mounted) setState(() => _hijriDate = h);
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

  // চলমান অবস্থা নির্ণয়
  List<Map<String, dynamic>> _getLiveAlerts(AppLanguage lang) {
    final isBn = lang.isBn;
    final now = DateTime.now();
    final pt = _prayerTimes;
    final alerts = <Map<String, dynamic>>[];

    if (pt == null) return alerts;

    // নামাজের নিষিদ্ধ সময় চেক
    final sunriseForbiddenEnd = pt.sunrise.add(const Duration(minutes: 15));
    final zawalStart = pt.dhuhr.subtract(const Duration(minutes: 5));
    final zawalEnd = pt.dhuhr;
    final sunsetForbiddenStart = pt.maghrib.subtract(const Duration(minutes: 15));

    if (now.isAfter(pt.sunrise) && now.isBefore(sunriseForbiddenEnd)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'এখন নামাজের নিষিদ্ধ সময় চলছে (সূর্যোদয়কালীন)'
            : 'Forbidden prayer time (sunrise)',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(zawalStart) && now.isBefore(zawalEnd)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'এখন নামাজের নিষিদ্ধ সময় চলছে (দ্বিপ্রহর)'
            : 'Forbidden prayer time (noon)',
        'color': AppTheme.missed,
      });
    } else if (now.isAfter(sunsetForbiddenStart) && now.isBefore(pt.maghrib)) {
      alerts.add({
        'icon': '⛔',
        'text': isBn
            ? 'এখন নামাজের নিষিদ্ধ সময় চলছে (সূর্যাস্তকালীন)'
            : 'Forbidden prayer time (sunset)',
        'color': AppTheme.missed,
      });
    }

    // আইয়ামে বিজ চেক
    final hijriDay = _HijriSimple.fromDate(now);
    if (hijriDay >= 13 && hijriDay <= 15) {
      alerts.add({
        'icon': '🌙',
        'text': isBn
            ? 'আজ আইয়ামে বিজের রোজার দিন! (হিজরি $hijriDay তারিখ) রোজা রাখুন।'
            : 'Today is Ayyam al-Beed! (Hijri day $hijriDay) Fast today.',
        'color': AppTheme.gold,
      });
    }

    // ইশরাক সময়
    final ishraqStart = pt.sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = pt.sunrise.add(const Duration(minutes: 45));
    if (now.isAfter(ishraqStart) && now.isBefore(ishraqEnd)) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'এখন ইশরাকের নামাজের সময় চলছে (২-৪ রাকাত)'
            : 'Ishraq prayer time now (2-4 rakats)',
        'color': const Color(0xFFFF8F00),
      });
    }

    // আওওয়াবিন সময়
    if (now.isAfter(pt.maghrib) && now.isBefore(pt.isha)) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'এখন আওওয়াবিনের নামাজের সময় (৬-২০ রাকাত)'
            : 'Awwabin prayer time now (6-20 rakats)',
        'color': const Color(0xFF26A69A),
      });
    }

    // তাহাজ্জুদ সময়
    final lastThird = _sunnahTimes?.lastThirdOfTheNight;
    if (lastThird != null && now.isAfter(lastThird) && now.isBefore(pt.fajr)) {
      alerts.add({
        'icon': '⭐',
        'text': isBn
            ? 'এখন তাহাজ্জুদের সর্বোত্তম সময় চলছে!'
            : 'Best time for Tahajjud prayer now!',
        'color': const Color(0xFF7C4DFF),
      });
    }

    // পরবর্তী নামাজ ১৫ মিনিটের মধ্যে
    final next = PrayerTimeHelper.getNextPrayer(pt);
    final remaining = PrayerTimeHelper.getTimeToNextPrayer(pt);
    if (next != null && remaining != null && remaining.inMinutes <= 15) {
      final prayerNames = {
        'fajr': isBn ? 'ফজর' : 'Fajr',
        'dhuhr': isBn ? 'যোহর' : 'Dhuhr',
        'asr': isBn ? 'আসর' : 'Asr',
        'maghrib': isBn ? 'মাগরিব' : 'Maghrib',
        'isha': isBn ? 'এশা' : 'Isha',
      };
      alerts.add({
        'icon': '🕌',
        'text': isBn
            ? '${prayerNames[next]} নামাজের সময় হতে মাত্র ${remaining.inMinutes} মিনিট বাকি!'
            : '${prayerNames[next]} prayer in ${remaining.inMinutes} minutes!',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(lang.bismillah, style: const TextStyle(fontSize: 20, color: AppTheme.gold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(lang.prayerCount(widget.userName), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),

            // Live Alerts
            if (alerts.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: alerts.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['icon'] as String, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          a['text'] as String,
                          style: TextStyle(
                            color: a['color'] as Color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
                label: lang.namazBaki, count: widget.namazPending, suffix: lang.wakt,
                color: AppTheme.missed, icon: Icons.mosque, lang: lang,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MissedListScreen(lang: lang, type: 'prayer'),
                )).then((_) => widget.onRefresh()),
              )),
              const SizedBox(width: 12),
              Expanded(child: _PendingCard(
                label: lang.rozaBaki, count: widget.rozaPending, suffix: '',
                color: AppTheme.pending, icon: Icons.brightness_3, lang: lang,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MissedListScreen(lang: lang, type: 'roza'),
                )).then((_) => widget.onRefresh()),
              )),
            ]),
            const SizedBox(height: 12),

            _PrayerTimesCard(lang: lang, prayerTimes: _prayerTimes, sunnahTimes: _sunnahTimes),
            const SizedBox(height: 12),

            _TodaySection(
              lang: lang,
              todayPrayers: _todayPrayers,
              todayRoza: _todayRoza,
              prayerTimes: _prayerTimes,
              onSetPrayer: _setPrayer,
              onSetRoza: _setRoza,
            ),
            const SizedBox(height: 12),

            _NaflSection(lang: lang, prayerTimes: _prayerTimes, sunnahTimes: _sunnahTimes),
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
      child: Column(
        children: [
          Text(
            DateHelper.formatTime12(now, bangla: isBn),
            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            lang.dayName(now.weekday),
            style: TextStyle(
              fontSize: 18,
              color: now.weekday == DateTime.friday ? AppTheme.accent : Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: 3 dates
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateHelper.formatGregorian(now, bangla: isBn),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hijriDate.isEmpty ? DateHelper.toHijri(now, bangla: isBn) : hijriDate,
                      style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateHelper.toBangla(now),
                      style: const TextStyle(
                        color: Color(0xFF80DEEA),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 12)),
              // Right: sun/sehri/iftar times
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // সূর্যোদয় — কমলা রঙ
                    _timeRow('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise',
                        sunrise != null ? PrayerTimeHelper.formatTime(sunrise) : '--',
                        const Color(0xFFFFB74D)),
                    const SizedBox(height: 5),
                    // সূর্যাস্ত — লাল-কমলা রঙ
                    _timeRow('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset',
                        maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--',
                        const Color(0xFFFF7043)),
                    const SizedBox(height: 5),
                    // সেহরি — সবুজ রঙ
                    _timeRow('🍽️', isBn ? 'সেহরি' : 'Sehri',
                        fajr != null ? PrayerTimeHelper.formatTime(fajr) : '--',
                        const Color(0xFF81C784)),
                    const SizedBox(height: 5),
                    // ইফতার — নীল রঙ
                    _timeRow('🌙', isBn ? 'ইফতার' : 'Iftar',
                        maghrib != null ? PrayerTimeHelper.formatTime(maghrib) : '--',
                        const Color(0xFF64B5F6)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeRow(String icon, String label, String time, Color timeColor) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 4),
      Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      Text(time, style: TextStyle(color: timeColor, fontSize: 13, fontWeight: FontWeight.bold)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 6),
            Text(lang.toLocalNum(count), style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold)),
            if (suffix.isNotEmpty)
              Text(suffix, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _PrayerTimesCard extends StatelessWidget {
  final AppLanguage lang;
  final PrayerTimes? prayerTimes;
  final SunnahTimes? sunnahTimes;

  const _PrayerTimesCard({required this.lang, required this.prayerTimes, required this.sunnahTimes});

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
    if (prayerTimes == null) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));

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
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(children: [
              Expanded(child: Text(isBn ? 'নামাজ' : 'Prayer',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))),
              SizedBox(width: 85, child: Text(isBn ? 'শুরু' : 'Start',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(width: 85, child: Text(isBn ? 'শেষ' : 'End',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
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
                  if (isNext) const Icon(Icons.arrow_right, color: AppTheme.accent, size: 18),
                  Text(_prayerName(p['key'] as String), style: TextStyle(
                    color: isNext ? AppTheme.gold : AppTheme.textPrimary,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  )),
                ])),
                SizedBox(width: 85, child: Text(_fmt(p['start'] as DateTime),
                    style: TextStyle(color: isNext ? AppTheme.accent : AppTheme.textPrimary, fontSize: 13),
                    textAlign: TextAlign.center)),
                SizedBox(width: 85, child: Text(_fmt(p['end'] as DateTime),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center)),
              ]),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
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
            ]),
          ),
        ],
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.today, color: AppTheme.gold, size: 20),
            const SizedBox(width: 8),
            Text(isBn ? 'আজকের নামাজ ও রোজা' : "Today's Prayer & Fasting",
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
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
            name: lang.roza, time: '', status: todayRoza,
            lang: lang,
            onAdai: () => onSetRoza('prayed'),
            onQaza: () => onSetRoza('missed'),
          ),
        ],
      ),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(
                  color: isAdai ? AppTheme.completed : isQaza ? AppTheme.missed : AppTheme.textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w500)),
                if (time.isNotEmpty)
                  Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
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
        ],
      ),
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
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: selected ? color : color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: selected ? 2.5 : 1.5),
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                  : [],
            ),
            child: Icon(icon, color: selected ? Colors.white : color, size: 24),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color: selected ? color : AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _NaflSection extends StatelessWidget {
  final AppLanguage lang;
  final PrayerTimes? prayerTimes;
  final SunnahTimes? sunnahTimes;

  const _NaflSection({required this.lang, required this.prayerTimes, required this.sunnahTimes});

  String _fmt(DateTime t) => PrayerTimeHelper.formatTime(t);

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    final pt = prayerTimes;

    final ishraqStart = pt != null ? pt.sunrise.add(const Duration(minutes: 15)) : null;
    final ishraqEnd = pt != null ? pt.sunrise.add(const Duration(minutes: 45)) : null;
    final chashtStart = pt != null ? pt.sunrise.add(const Duration(minutes: 45)) : null;
    final chashtEnd = pt != null ? pt.dhuhr.subtract(const Duration(minutes: 10)) : null;
    final tahaqqudStart = sunnahTimes?.lastThirdOfTheNight;
    final tahaqqudEnd = pt?.fajr;

    final now = DateTime.now();
    final h = _HijriSimple.fromDate(now);

    final nafls = [
      {
        'icon': '🌙',
        'name': isBn ? 'তাহাজ্জুদ' : 'Tahajjud',
        'time': tahaqqudStart != null && tahaqqudEnd != null
            ? '${_fmt(tahaqqudStart)} - ${_fmt(tahaqqudEnd)}'
            : isBn ? 'রাতের শেষ তৃতীয়াংশ' : 'Last third of night',
        'desc': isBn ? '২-১২ রাকাত • রাতের সর্বশ্রেষ্ঠ নফল' : '2-12 rakats • Best night prayer',
        'color': const Color(0xFF7C4DFF),
      },
      {
        'icon': '🌅',
        'name': isBn ? 'ইশরাক' : 'Ishraq',
        'time': ishraqStart != null && ishraqEnd != null
            ? '${_fmt(ishraqStart)} - ${_fmt(ishraqEnd)}'
            : isBn ? 'সূর্যোদয়ের ১৫ মিনিট পর' : '15 min after sunrise',
        'desc': isBn ? '২-৪ রাকাত • এক হজ্জ-উমরার সওয়াব' : '2-4 rakats • Reward of Hajj & Umrah',
        'color': const Color(0xFFFF8F00),
      },
      {
        'icon': '☀️',
        'name': isBn ? 'দুহা/চাশত' : 'Duha/Chasht',
        'time': chashtStart != null && chashtEnd != null
            ? '${_fmt(chashtStart)} - ${_fmt(chashtEnd)}'
            : isBn ? 'সূর্যোদয়ের ৪৫ মিনিট পর থেকে যোহরের আগে' : '45 min after sunrise to before Dhuhr',
        'desc': isBn ? '২-১২ রাকাত • রোজ সদকার সওয়াব' : '2-12 rakats • Daily charity reward',
        'color': const Color(0xFFFDD835),
      },
      {
        'icon': '🌆',
        'name': isBn ? 'আওওয়াবিন' : 'Awwabin',
        'time': pt != null
            ? '${_fmt(pt.maghrib)} - ${_fmt(pt.isha)}'
            : isBn ? 'মাগরিবের পর ইশার আগে' : 'Between Maghrib and Isha',
        'desc': isBn ? '৬-২০ রাকাত • মাগরিবের পর পড়তে হয়' : '6-20 rakats • After Maghrib',
        'color': const Color(0xFF26A69A),
      },
      {
        'icon': '🕌',
        'name': isBn ? 'জাওয়াল' : 'Zawal',
        'time': pt != null
            ? '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}'
            : isBn ? 'যোহরের ঠিক আগে' : 'Just before Dhuhr',
        'desc': isBn ? '২-৪ রাকাত • দিনের তাহাজ্জুদ' : '2-4 rakats • Daytime Tahajjud',
        'color': const Color(0xFF66BB6A),
      },
    ];

    return Column(
      children: [
        // নফল নামাজ
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.star, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Text(isBn ? 'নফল সালাতের সময়' : 'Nafl Prayer Times',
                    style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              ...nafls.map((n) => _NaflRow(
                icon: n['icon'] as String,
                name: n['name'] as String,
                time: n['time'] as String,
                desc: n['desc'] as String,
                color: n['color'] as Color,
              )),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // আইয়ামে বিজ
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('🌙', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(isBn ? 'আইয়ামে বিজের রোজা' : 'Ayyam al-Beed Fasting',
                    style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              Text(
                isBn
                    ? 'প্রতি হিজরি মাসের ১৩, ১৪ ও ১৫ তারিখ রোজা রাখা সুন্নত।\n"এটি সারা বছর রোজা রাখার সমতুল্য।" — নবীজি (সা.)'
                    : 'Fasting on 13th, 14th & 15th of each Hijri month is Sunnah.\n"It is like fasting the whole year." — Prophet (S)',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: h >= 13 && h <= 15
                      ? AppTheme.gold.withOpacity(0.2)
                      : AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: h >= 13 && h <= 15 ? AppTheme.gold : AppTheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    h >= 13 && h <= 15 ? Icons.notifications_active : Icons.calendar_today,
                    color: h >= 13 && h <= 15 ? AppTheme.gold : AppTheme.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    h >= 13 && h <= 15
                        ? (isBn ? '🎉 আজ আইয়ামে বিজের রোজার দিন! রোজা রাখুন।' : '🎉 Today is Ayyam al-Beed! Please fast.')
                        : h < 13
                            ? (isBn ? 'আইয়ামে বিজ শুরু হতে ${13 - h} দিন বাকি' : '${13 - h} days until Ayyam al-Beed')
                            : (isBn ? 'এই মাসের আইয়ামে বিজ শেষ হয়েছে' : 'Ayyam al-Beed ended this month'),
                    style: TextStyle(
                      color: h >= 13 && h <= 15 ? AppTheme.gold : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: h >= 13 && h <= 15 ? FontWeight.bold : FontWeight.normal,
                    ),
                  )),
                ]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // নামাজের নিষিদ্ধ সময়
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.missed.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.block, color: AppTheme.missed, size: 20),
                const SizedBox(width: 8),
                Text(isBn ? 'নামাজের নিষিদ্ধ সময়' : 'Forbidden Prayer Times',
                    style: const TextStyle(color: AppTheme.missed, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              if (pt != null) ...[
                _forbiddenRow(
                  isBn ? 'সূর্যোদয়কালীন' : 'At Sunrise',
                  '${_fmt(pt.sunrise)} - ${_fmt(pt.sunrise.add(const Duration(minutes: 15)))}',
                  isBn ? 'সূর্যোদয়ের ১৫ মিনিট পর্যন্ত' : 'For 15 min after sunrise',
                ),
                _forbiddenRow(
                  isBn ? 'দ্বিপ্রহরে' : 'At Noon',
                  '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}',
                  isBn ? 'সূর্য মাথার উপর থাকার সময়' : 'When sun is at zenith',
                ),
                _forbiddenRow(
                  isBn ? 'সূর্যাস্তকালীন' : 'At Sunset',
                  '${_fmt(pt.maghrib.subtract(const Duration(minutes: 15)))} - ${_fmt(pt.maghrib)}',
                  isBn ? 'সূর্যাস্তের ১৫ মিনিট আগে' : '15 min before sunset',
                ),
              ] else
                Text(isBn ? 'লোড হচ্ছে...' : 'Loading...',
                    style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _forbiddenRow(String title, String time, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        const Icon(Icons.remove_circle_outline, color: AppTheme.missed, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(time, style: const TextStyle(color: AppTheme.missed, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
class _HijriSimple {
  static int fromDate(DateTime date) {
    try {
      final jd = _gregorianToJulian(date.year, date.month, date.day);
      final l = jd - 1948440 + 10632;
      final n = (l - 1) ~/ 10631;
      final l2 = l - 10631 * n + 354;
      final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
          ((l2) ~/ 5670) * ((43 * l2) ~/ 15238);
      final l3 = l2 - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
          ((j) ~/ 16) * ((15238 * j) ~/ 43) + 29;
      final m = (24 * l3) ~/ 709;
      final d = l3 - (709 * m) ~/ 24;
      return d;
    } catch (_) {
      return 0;
    }
  }

  static int _gregorianToJulian(int year, int month, int day) {
    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    return day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }
}

// ═══════════════════════════════════════════
class _NaflRow extends StatelessWidget {
  final String icon, name, time, desc;
  final Color color;

  const _NaflRow({
    required this.icon, required this.name, required this.time,
    required this.desc, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
