import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/date_helper.dart';
import '../utils/database_helper.dart';

class DayScreen extends StatefulWidget {
  final DateTime date;
  final AppLanguage lang;
  final VoidCallback onDataChanged;
  const DayScreen({super.key, required this.date, required this.lang, required this.onDataChanged});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  Map<String, String> _prayerStatuses = {};
  String? _rozaStatus;
  bool _loading = true;
  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final dateKey = DateHelper.dateKey(widget.date);
    final statuses = await DatabaseHelper.getDayPrayerStatuses(dateKey);
    final rozaStatus = await DatabaseHelper.getRozaStatus(dateKey);
    if (mounted) setState(() { _prayerStatuses = statuses; _rozaStatus = rozaStatus; _loading = false; });
  }

  Future<void> _setPrayerStatus(String prayer, String status) async {
    await DatabaseHelper.setPrayerStatus(DateHelper.dateKey(widget.date), prayer, status);
    await _load();
    widget.onDataChanged();
  }

  Future<void> _setRozaStatus(String status) async {
    await DatabaseHelper.setRozaStatus(DateHelper.dateKey(widget.date), status);
    await _load();
    widget.onDataChanged();
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
    final isFuture = widget.date.isAfter(DateTime.now());
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(DateHelper.formatGregorian(widget.date, bangla: widget.lang.isBn))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: Text(DateHelper.toHijri(widget.date, bangla: widget.lang.isBn),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 14))),
                const SizedBox(height: 4),
                Center(child: Text(widget.lang.dayName(widget.date.weekday),
                  style: TextStyle(color: widget.date.weekday == DateTime.friday ? AppTheme.accent : AppTheme.textSecondary, fontSize: 13))),
                const SizedBox(height: 20),
                Text(widget.lang.isBn ? 'নামাজ' : 'Prayers',
                  style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._prayers.map((prayer) => _PrayerRow(
                  name: _prayerName(prayer),
                  status: _prayerStatuses[prayer],
                  lang: widget.lang,
                  disabled: isFuture,
                  onPrayed: () => _setPrayerStatus(prayer, 'prayed'),
                  onMissed: () => _setPrayerStatus(prayer, 'missed'),
                )),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Text(widget.lang.roza,
                  style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _PrayerRow(
                  name: widget.lang.roza,
                  status: _rozaStatus,
                  lang: widget.lang,
                  disabled: isFuture,
                  onPrayed: () => _setRozaStatus('prayed'),
                  onMissed: () => _setRozaStatus('missed'),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final String name;
  final String? status;
  final AppLanguage lang;
  final bool disabled;
  final VoidCallback onPrayed, onMissed;

  const _PrayerRow({required this.name, required this.status, required this.lang,
    required this.disabled, required this.onPrayed, required this.onMissed});

  @override
  Widget build(BuildContext context) {
    final isPrayed = status == 'prayed';
    final isMissed = status == 'missed';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMissed ? AppTheme.missed.withOpacity(0.15) : isPrayed ? AppTheme.completed.withOpacity(0.15) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMissed ? AppTheme.missed.withOpacity(0.5) : isPrayed ? AppTheme.completed.withOpacity(0.5) : Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(child: Row(children: [
            Icon(isPrayed ? Icons.check_circle : isMissed ? Icons.cancel : Icons.radio_button_unchecked,
              color: isPrayed ? AppTheme.completed : isMissed ? AppTheme.missed : AppTheme.textSecondary, size: 20),
            const SizedBox(width: 10),
            Text(name, style: TextStyle(
              color: isPrayed ? AppTheme.completed : isMissed ? AppTheme.missed : AppTheme.textPrimary,
              fontWeight: FontWeight.w500, fontSize: 16)),
          ])),
          if (!disabled) ...[
            _ActionButton(label: lang.prayed, icon: Icons.check, color: AppTheme.completed, selected: isPrayed, onTap: onPrayed),
            const SizedBox(width: 8),
            _ActionButton(label: lang.missed, icon: Icons.close, color: AppTheme.missed, selected: isMissed, onTap: onMissed),
          ] else
            Text(lang.isBn ? 'ভবিষ্যৎ' : 'Future', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? Colors.white : color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: selected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
