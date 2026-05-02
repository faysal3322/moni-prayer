import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/prayer_time_helper.dart';
import '../utils/date_helper.dart';

class PrayerTimeScreen extends StatefulWidget {
  final AppLanguage lang;
  const PrayerTimeScreen({super.key, required this.lang});

  @override
  State<PrayerTimeScreen> createState() => _PrayerTimeScreenState();
}

class _PrayerTimeScreenState extends State<PrayerTimeScreen> {
  Map<String, DateTime>? _times;
  String? _nextPrayer;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final times = await PrayerTimeHelper.getPrayerTimes();
    final map = PrayerTimeHelper.getPrayerTimesMap(times);
    final next = PrayerTimeHelper.getNextPrayer(times);
    if (mounted) setState(() { _times = map; _nextPrayer = next; _loading = false; });
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

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.prayerTimes),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold),
          onPressed: () async { await PrayerTimeHelper.refreshLocation(); _load(); })],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: Text(DateHelper.formatGregorian(DateTime.now(), bangla: lang.isBn),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold))),
                Center(child: Text(DateHelper.toHijri(DateTime.now(), bangla: lang.isBn),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                const SizedBox(height: 20),
                if (_times != null)
                  ..._times!.entries.map((e) {
                    final isNext = _nextPrayer == e.key;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isNext ? AppTheme.primary.withOpacity(0.3) : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isNext ? AppTheme.accent : Colors.white12, width: isNext ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Icon(Icons.mosque, color: isNext ? AppTheme.gold : AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Text(_name(e.key), style: TextStyle(
                              color: isNext ? AppTheme.gold : AppTheme.textPrimary,
                              fontWeight: isNext ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
                            if (isNext) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(10)),
                                child: Text(lang.isBn ? 'পরবর্তী' : 'Next',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ]),
                          Text(PrayerTimeHelper.formatTime(e.value), style: TextStyle(
                            color: isNext ? AppTheme.accent : AppTheme.textSecondary,
                            fontSize: 16, fontWeight: isNext ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                  child: Text(
                    lang.isBn ? 'হিসাব পদ্ধতি: করাচি\nমাযহাব: হানাফি\nঅবস্থান: বর্তমান অবস্থান (ডিফল্ট: ঢাকা)' : 'Method: Karachi\nMadhab: Hanafi\nLocation: Current (Default: Dhaka)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ),
              ],
            ),
    );
  }
}
