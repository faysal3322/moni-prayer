import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/prayer_time_helper.dart';
import '../utils/date_helper.dart';
import 'package:adhan/adhan.dart';

class PrayerTimeScreen extends StatefulWidget {
  final AppLanguage lang;
  const PrayerTimeScreen({super.key, required this.lang});

  @override
  State<PrayerTimeScreen> createState() => _PrayerTimeScreenState();
}

class _PrayerTimeScreenState extends State<PrayerTimeScreen> {
  PrayerTimes? _times;
  SunnahTimes? _sunnahTimes;
  String? _nextPrayer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final times = await PrayerTimeHelper.getPrayerTimes();
    final sunnah = SunnahTimes(times);
    final next = PrayerTimeHelper.getNextPrayer(times);
    if (mounted) {
      setState(() {
        _times = times;
        _sunnahTimes = sunnah;
        _nextPrayer = next;
        _loading = false;
      });
    }
  }

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

  String _fmt(DateTime t) => PrayerTimeHelper.formatTime(t);

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isBn = lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.prayerTimes),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: () async {
              await PrayerTimeHelper.refreshLocation();
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date header
                Center(child: Text(
                  DateHelper.formatGregorian(DateTime.now(), bangla: isBn),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
                )),
                Center(child: Text(
                  DateHelper.toHijri(DateTime.now(), bangla: isBn),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                )),
                const SizedBox(height: 20),

                // Farz Prayer Times Table
                _sectionTitle(isBn ? 'সালাতের সময়' : 'Prayer Times'),
                const SizedBox(height: 8),
                _prayerTable(),
                const SizedBox(height: 20),

                // Forbidden Times
                _sectionTitle(isBn ? 'সালাতের নিষিদ্ধ সময়' : 'Forbidden Times', color: AppTheme.missed),
                const SizedBox(height: 8),
                _forbiddenTimesCard(),
                const SizedBox(height: 20),

                // Nafl Prayer Times
                _sectionTitle(isBn ? 'নফল সালাতের সময়' : 'Nafl Prayer Times'),
                const SizedBox(height: 8),
                _naflTimesCard(),
                const SizedBox(height: 20),

                // Sehri & Iftar
                _sectionTitle(isBn ? 'সাওমের সময়সূচি' : 'Fasting Schedule'),
                const SizedBox(height: 8),
                _fastingCard(),
                const SizedBox(height: 20),

                // Sunrise & Sunset
                _sectionTitle(isBn ? 'সূর্যোদয় ও সূর্যাস্ত' : 'Sunrise & Sunset'),
                const SizedBox(height: 8),
                _sunCard(),
                const SizedBox(height: 20),

                // Method info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    isBn
                        ? 'হিসাব পদ্ধতি: করাচি\nমাযহাব: হানাফি\nঅবস্থান: বর্তমান অবস্থান (ডিফল্ট: ঢাকা)'
                        : 'Method: Karachi\nMadhab: Hanafi\nLocation: Current (Default: Dhaka)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title, {Color color = AppTheme.gold}) {
    return Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _prayerTable() {
    if (_times == null) return const SizedBox();
    final isBn = widget.lang.isBn;

    final prayers = [
      {'key': 'fajr', 'start': _times!.fajr, 'end': _times!.sunrise},
      {'key': 'dhuhr', 'start': _times!.dhuhr, 'end': _times!.asr},
      {'key': 'asr', 'start': _times!.asr, 'end': _times!.maghrib},
      {'key': 'maghrib', 'start': _times!.maghrib, 'end': _times!.isha},
      {'key': 'isha', 'start': _times!.isha, 'end': _sunnahTimes!.lastThirdOfTheNight},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text(isBn ? 'নামাজ' : 'Prayer',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))),
                SizedBox(width: 90, child: Text(isBn ? 'শুরু' : 'Start',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 90, child: Text(isBn ? 'শেষ' : 'End',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Rows
          ...prayers.asMap().entries.map((entry) {
            final p = entry.value;
            final isNext = _nextPrayer == p['key'];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isNext ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(child: Row(children: [
                    if (isNext) const Icon(Icons.arrow_right, color: AppTheme.accent, size: 18),
                    Text(_name(p['key'] as String), style: TextStyle(
                      color: isNext ? AppTheme.gold : AppTheme.textPrimary,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    )),
                  ])),
                  SizedBox(width: 90, child: Text(_fmt(p['start'] as DateTime),
                    style: TextStyle(color: isNext ? AppTheme.accent : AppTheme.textPrimary, fontSize: 14),
                    textAlign: TextAlign.center)),
                  SizedBox(width: 90, child: Text(_fmt(p['end'] as DateTime),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _forbiddenTimesCard() {
    if (_times == null) return const SizedBox();
    final isBn = widget.lang.isBn;

    // Forbidden: after fajr until sunrise + 15min, zawal, before maghrib
    final fajrEnd = _times!.sunrise;
    final fajrForbiddenEnd = fajrEnd.add(const Duration(minutes: 15));
    final zawalStart = _times!.dhuhr.subtract(const Duration(minutes: 5));
    final zawalEnd = _times!.dhuhr.add(const Duration(minutes: 5));
    final asrForbiddenStart = _times!.maghrib.subtract(const Duration(minutes: 15));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.missed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? 'এই সময়গুলোতে নামাজ পড়া নিষিদ্ধ:' : 'Prayer is forbidden at these times:',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _forbiddenChip(isBn ? 'সকাল' : 'Morning', '${_fmt(fajrEnd)} - ${_fmt(fajrForbiddenEnd)}')),
              const SizedBox(width: 8),
              Expanded(child: _forbiddenChip(isBn ? 'দুপুর' : 'Noon', '${_fmt(zawalStart)} - ${_fmt(zawalEnd)}')),
              const SizedBox(width: 8),
              Expanded(child: _forbiddenChip(isBn ? 'সন্ধ্যা' : 'Evening', '${_fmt(asrForbiddenStart)} - ${_fmt(_times!.maghrib)}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forbiddenChip(String label, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.missed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: AppTheme.missed, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _naflTimesCard() {
    if (_times == null || _sunnahTimes == null) return const SizedBox();
    final isBn = widget.lang.isBn;

    final ishraqStart = _times!.sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = _times!.sunrise.add(const Duration(minutes: 45));
    final chashtStart = _times!.sunrise.add(const Duration(minutes: 45));
    final chashtEnd = _times!.dhuhr.subtract(const Duration(minutes: 15));

    final nafls = [
      {'name': isBn ? 'তাহাজ্জুদ' : 'Tahajjud', 'time': '${_fmt(_times!.isha)} - ${_fmt(_sunnahTimes!.lastThirdOfTheNight)}', 'icon': '🌙'},
      {'name': isBn ? 'ইশরাক' : 'Ishraq', 'time': '${_fmt(ishraqStart)} - ${_fmt(ishraqEnd)}', 'icon': '🌅'},
      {'name': isBn ? 'দুহা/চাশত' : 'Duha/Chasht', 'time': '${_fmt(chashtStart)} - ${_fmt(chashtEnd)}', 'icon': '☀️'},
      {'name': isBn ? 'আওওয়াবিন' : 'Awwabin', 'time': isBn ? 'মাগরিবের পর - ${_fmt(_times!.isha)}' : 'After Maghrib - ${_fmt(_times!.isha)}', 'icon': '🌆'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: nafls.map((n) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Text(n['icon'] as String, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(n['name'] as String,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15))),
              Text(n['time'] as String,
                style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _fastingCard() {
    if (_times == null) return const SizedBox();
    final isBn = widget.lang.isBn;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _infoRow('🍽️', isBn ? 'সেহরি (শেষ সময়)' : 'Sehri (Last Time)', _fmt(_times!.fajr), AppTheme.gold),
          _infoRow('🌙', isBn ? 'ইফতার (শুরু)' : 'Iftar (Start)', _fmt(_times!.maghrib), AppTheme.accent),
        ],
      ),
    );
  }

  Widget _sunCard() {
    if (_times == null) return const SizedBox();
    final isBn = widget.lang.isBn;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _infoRow('🌅', isBn ? 'সূর্যোদয়' : 'Sunrise', _fmt(_times!.sunrise), AppTheme.gold),
          _infoRow('🌇', isBn ? 'সূর্যাস্ত' : 'Sunset', _fmt(_times!.maghrib), AppTheme.pending),
        ],
      ),
    );
  }

  Widget _infoRow(String icon, String label, String time, Color timeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15))),
          Text(time, style: TextStyle(color: timeColor, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
