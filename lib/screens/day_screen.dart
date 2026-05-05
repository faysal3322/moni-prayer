import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/date_helper.dart';
import '../utils/database_helper.dart';

class DayScreen extends StatefulWidget {
  final DateTime date;
  final AppLanguage lang;
  final VoidCallback onDataChanged;
  final List<DateTime>? allDates;
  final int? initialIndex;

  const DayScreen({
    super.key,
    required this.date,
    required this.lang,
    required this.onDataChanged,
    this.allDates,
    this.initialIndex,
  });

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  late PageController _pageController;
  late List<DateTime> _dates;
  late int _currentIndex;
  Map<String, Map<String, String>> _prayerStatusCache = {};
  Map<String, String?> _rozaStatusCache = {};

  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  void initState() {
    super.initState();
    if (widget.allDates != null && widget.initialIndex != null) {
      _dates = widget.allDates!;
      _currentIndex = widget.initialIndex!;
    } else {
      _dates = [widget.date];
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);
    _loadAll();
  }

  Future<void> _loadAll() async {
    for (final date in _dates) {
      await _loadDate(date);
    }
  }

  Future<void> _loadDate(DateTime date) async {
    final dateKey = DateHelper.dateKey(date);
    final statuses = await DatabaseHelper.getDayPrayerStatuses(dateKey);
    final rozaStatus = await DatabaseHelper.getRozaStatus(dateKey);
    if (mounted) {
      setState(() {
        _prayerStatusCache[dateKey] = statuses;
        _rozaStatusCache[dateKey] = rozaStatus;
      });
    }
  }

  Future<void> _setPrayerStatus(DateTime date, String prayer, String status) async {
    final dateKey = DateHelper.dateKey(date);
    await DatabaseHelper.setPrayerStatus(dateKey, prayer, status);
    await _loadDate(date);
    widget.onDataChanged();
  }

  Future<void> _setRozaStatus(DateTime date, String status) async {
    final dateKey = DateHelper.dateKey(date);
    // Toggle: if same status clicked again, remove it
    final current = _rozaStatusCache[dateKey];
    if (current == status) {
      // Remove by setting to a neutral state — delete the record
      await DatabaseHelper.setRozaStatus(dateKey, 'none');
    } else {
      await DatabaseHelper.setRozaStatus(dateKey, status);
    }
    await _loadDate(date);
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          DateHelper.formatGregorian(_dates[_currentIndex], bangla: widget.lang.isBn),
        ),
        backgroundColor: AppTheme.surface,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _dates.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isFuture = date.isAfter(DateTime.now());
          final dateKey = DateHelper.dateKey(date);
          final prayerStatuses = _prayerStatusCache[dateKey] ?? {};
          final rozaStatus = _rozaStatusCache[dateKey];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Text(
                  DateHelper.toHijri(date, bangla: widget.lang.isBn),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.lang.dayName(date.weekday),
                  style: TextStyle(
                    color: date.weekday == DateTime.friday ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),

              if (_dates.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (index > 0)
                      TextButton.icon(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        icon: const Icon(Icons.arrow_back_ios, size: 14, color: AppTheme.accent),
                        label: Text(
                          widget.lang.isBn ? 'আগের দিন' : 'Prev',
                          style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                        ),
                      ),
                    if (index < _dates.length - 1)
                      TextButton.icon(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.accent),
                        label: Text(
                          widget.lang.isBn ? 'পরের দিন' : 'Next',
                          style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Text(
                widget.lang.isBn ? 'নামাজ' : 'Prayers',
                style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ..._prayers.map((prayer) => _PrayerRow(
                name: _prayerName(prayer),
                status: prayerStatuses[prayer],
                lang: widget.lang,
                disabled: isFuture,
                isRoza: false,
                onPrayed: () => _setPrayerStatus(date, prayer, 'prayed'),
                onMissed: () => _setPrayerStatus(date, prayer, 'missed'),
              )),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              Text(
                widget.lang.roza,
                style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _PrayerRow(
                name: widget.lang.roza,
                status: rozaStatus == 'none' ? null : rozaStatus,
                lang: widget.lang,
                disabled: isFuture,
                isRoza: true,
                onPrayed: () => _setRozaStatus(date, 'prayed'),
                onMissed: () => _setRozaStatus(date, 'missed'),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _PrayerRow extends StatelessWidget {
  final String name;
  final String? status;
  final AppLanguage lang;
  final bool disabled;
  final bool isRoza;
  final VoidCallback onPrayed, onMissed;

  const _PrayerRow({
    required this.name,
    required this.status,
    required this.lang,
    required this.disabled,
    required this.isRoza,
    required this.onPrayed,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    final isPrayed = status == 'prayed';
    final isMissed = status == 'missed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMissed ? AppTheme.missed.withOpacity(0.15)
            : isPrayed ? AppTheme.completed.withOpacity(0.15)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMissed ? AppTheme.missed.withOpacity(0.5)
              : isPrayed ? AppTheme.completed.withOpacity(0.5)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  isPrayed ? Icons.check_circle
                      : isMissed ? Icons.cancel
                      : Icons.radio_button_unchecked,
                  color: isPrayed ? AppTheme.completed
                      : isMissed ? AppTheme.missed
                      : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  name,
                  style: TextStyle(
                    color: isPrayed ? AppTheme.completed
                        : isMissed ? AppTheme.missed
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (!disabled) ...[
            // আদায় button — বড় গোলাকার
            _CircleButton(
              label: lang.isBn ? 'আদায়' : 'Prayed',
              icon: Icons.check,
              color: AppTheme.completed,
              selected: isPrayed,
              onTap: onPrayed,
            ),
            const SizedBox(width: 10),
            // কাযা button — বড় গোলাকার
            _CircleButton(
              label: lang.isBn ? 'কাযা' : 'Qaza',
              icon: Icons.close,
              color: AppTheme.missed,
              selected: isMissed,
              onTap: onMissed,
            ),
          ] else
            Text(
              lang.isBn ? 'ভবিষ্যৎ' : 'Future',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _CircleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CircleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected ? color : color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: selected ? 2 : 1.5),
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                  : [],
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : color,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? color : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
