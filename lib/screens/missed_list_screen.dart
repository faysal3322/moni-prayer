import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/date_helper.dart';
import '../utils/database_helper.dart';
import 'day_screen.dart';

class MissedListScreen extends StatefulWidget {
  final AppLanguage lang;
  final String type;
  const MissedListScreen({super.key, required this.lang, required this.type});

  @override
  State<MissedListScreen> createState() => _MissedListScreenState();
}

class _MissedListScreenState extends State<MissedListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.type == 'prayer') {
      final data = await DatabaseHelper.getMissedPrayerDates();
      setState(() { _items = data; _loading = false; });
    } else {
      final data = await DatabaseHelper.getMissedRozaDates();
      setState(() { _items = data; _loading = false; });
    }
  }

  String _prayerName(String key) {
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
    final title = widget.type == 'prayer' ? lang.missedNamaz : lang.missedRoza;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, color: AppTheme.completed, size: 64),
                  const SizedBox(height: 16),
                  Text(lang.isBn ? 'কোনো মিস নেই! আলহামদুলিল্লাহ 🎉' : 'No missed records! Alhamdulillah 🎉',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16), textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    if (widget.type == 'prayer') {
                      final item = _items[i] as Map<String, dynamic>;
                      final date = DateTime.parse(item['date'] as String);
                      final prayers = (item['prayers'] as String).split(',');
                      return _MissedTile(
                        dateText: DateHelper.formatGregorian(date, bangla: lang.isBn),
                        subtitle: prayers.map(_prayerName).join(', '),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DayScreen(date: date, lang: lang, onDataChanged: _load))),
                      );
                    } else {
                      final date = DateTime.parse(_items[i] as String);
                      return _MissedTile(
                        dateText: DateHelper.formatGregorian(date, bangla: lang.isBn),
                        subtitle: lang.roza,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DayScreen(date: date, lang: lang, onDataChanged: _load))),
                      );
                    }
                  },
                ),
    );
  }
}

class _MissedTile extends StatelessWidget {
  final String dateText, subtitle;
  final VoidCallback onTap;
  const _MissedTile({required this.dateText, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.circle, color: AppTheme.missed, size: 10),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateText, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ])),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }
}
