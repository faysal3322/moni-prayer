import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/time_format_prefs.dart';

/// "নামাজ" ক্যাটাগরির প্রথম ট্যাব — ফরজ নামাজের ওয়াক্ত, নফল নামাজের সময়
/// ও নিষিদ্ধ সময় একসাথে। চলমান ওয়াক্তে "অতিবাহিত" সময় প্রতি সেকেন্ডে চলে।
class PrayerScheduleTab extends StatefulWidget {
  final AppLanguage lang;
  final PrayerTimes times;
  const PrayerScheduleTab({super.key, required this.lang, required this.times});

  @override
  State<PrayerScheduleTab> createState() => _PrayerScheduleTabState();
}

class _Slot {
  final String icon, name;
  final DateTime start, end;
  const _Slot(this.icon, this.name, this.start, this.end);
}

class _PrayerScheduleTabState extends State<PrayerScheduleTab> {
  Timer? _timer;

  bool get _bn => widget.lang.isBn;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── ফরম্যাট ──────────────────────────────
  String _d(String s) {
    if (!_bn) return s;
    const m = '০১২৩৪৫৬৭৮৯';
    return s.replaceAllMapped(RegExp(r'\d'), (x) => m[int.parse(x[0]!)]);
  }

  String _t(DateTime t) {
    final is24 = TimeFormatPrefs.use24Hour;
    final h = is24 ? t.hour : (t.hour % 12 == 0 ? 12 : t.hour % 12);
    final hs = is24 ? h.toString().padLeft(2, '0') : h.toString();
    return _d('$hs:${t.minute.toString().padLeft(2, '0')}');
  }

  String _range(_Slot s) => '${_t(s.start)} - ${_t(s.end)}';

  String _elapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return _d('${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}');
  }

  // ── সময় হিসাব ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final pt = widget.times;
    final lang = widget.lang;
    final now = DateTime.now();

    final nextFajr = pt.fajr.add(const Duration(days: 1));
    // রাতের শেষ তৃতীয়াংশ — হোম স্ক্রিনের মতো নিজে হিসাব করা
    final nightMs = nextFajr.difference(pt.maghrib).inMilliseconds;
    final lastThird =
        pt.maghrib.add(Duration(milliseconds: (nightMs * 2 / 3).round()));

    final fard = <_Slot>[
      _Slot('🌅', lang.fajr, pt.fajr, pt.sunrise),
      _Slot('🌤️', lang.dhuhr, pt.dhuhr, pt.asr),
      _Slot('⛅', lang.asr, pt.asr, pt.maghrib),
      _Slot('🌇', lang.maghrib, pt.maghrib, pt.isha),
      _Slot('🌙', lang.isha, pt.isha, nextFajr),
    ];

    final nafl = <_Slot>[
      _Slot('🌌', _bn ? 'তাহাজ্জুদ' : 'Tahajjud', lastThird, nextFajr),
      _Slot('☀️', _bn ? 'ইশরাক' : 'Ishraq',
          pt.sunrise.add(const Duration(minutes: 15)),
          pt.sunrise.add(const Duration(minutes: 45))),
      _Slot('🌞', _bn ? 'চাশত / দুহা' : 'Duha / Chasht',
          pt.sunrise.add(const Duration(minutes: 45)),
          pt.dhuhr.subtract(const Duration(minutes: 10))),
      _Slot('🌓', _bn ? 'আউয়াবীন' : 'Awwabin', pt.maghrib, pt.isha),
    ];

    final forbidden = <_Slot>[
      _Slot('🌄', _bn ? 'সূর্যোদয়কালীন' : 'At sunrise', pt.sunrise,
          pt.sunrise.add(const Duration(minutes: 15))),
      _Slot('☀️', _bn ? 'দুপুর (যাওয়াল)' : 'Noon (Zawal)',
          pt.dhuhr.subtract(const Duration(minutes: 5)), pt.dhuhr),
      _Slot('🌅', _bn ? 'সূর্যাস্তকালীন' : 'At sunset',
          pt.maghrib.subtract(const Duration(minutes: 15)), pt.maghrib),
    ];

    bool inSlot(_Slot s) => !now.isBefore(s.start) && now.isBefore(s.end);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _header(_bn ? 'ফরজ নামাজ সমূহ' : 'Fard Prayers', AppTheme.accent),
        _card(fard.map((s) {
          var cur = inSlot(s);
          var from = s.start;
          // মধ্যরাতের পর ফজরের আগে — এখনো গতকালের ইশার ওয়াক্ত চলছে
          if (s.name == lang.isha && now.isBefore(pt.fajr)) {
            cur = true;
            from = pt.isha.subtract(const Duration(days: 1));
          }
          return _row(s.icon, s.name, _range(s), cur,
              elapsed: cur ? now.difference(from) : null);
        }).toList()),
        const SizedBox(height: 22),
        _header(_bn ? 'নফল নামাজ সমূহ' : 'Nafl Prayers', const Color(0xFF4A90E2)),
        _card(nafl.map((s) => _row(s.icon, s.name, _range(s), inSlot(s))).toList()),
        const SizedBox(height: 22),
        _header(_bn ? 'নামাজের নিষিদ্ধ সময়' : 'Forbidden Prayer Times',
            AppTheme.missed),
        _card(forbidden
            .map((s) => _row(s.icon, s.name, _range(s), inSlot(s), forbidden: true))
            .toList()),
        const SizedBox(height: 10),
        Text(
          _bn
              ? 'এই সময়গুলোতে নফল নামাজ পড়া যাবে না। ফজর ও আসরের ফরজের পর থেকে যথাক্রমে সূর্যোদয় ও সূর্যাস্ত পর্যন্তও নফল নামাজ মাকরূহ।'
              : 'Nafl prayers must not be offered at these times. After Fajr and Asr fard, nafl is also disliked until sunrise and sunset respectively.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  // ── UI ───────────────────────────────────
  Widget _header(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 5,
          height: 22,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: TextStyle(
                  color: AppTheme.readable(color),
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _card(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(String icon, String name, String time, bool current,
      {Duration? elapsed, bool forbidden = false}) {
    final timeColor = forbidden ? AppTheme.missed : AppTheme.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: current
            ? (forbidden ? AppTheme.missed : AppTheme.accent).withOpacity(0.15)
            : Colors.transparent,
        border: Border(bottom: BorderSide(color: AppTheme.divider10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(name,
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: current ? FontWeight.bold : FontWeight.normal)),
          ),
          Expanded(
            flex: 6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(time,
                  style: TextStyle(
                      color: timeColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        if (elapsed != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.overlay.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_bn ? 'অতিবাহিত' : 'Elapsed'}: ${_elapsed(elapsed)}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ]),
    );
  }
}
