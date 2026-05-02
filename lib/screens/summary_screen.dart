import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/database_helper.dart';

class SummaryScreen extends StatefulWidget {
  final AppLanguage lang;
  const SummaryScreen({super.key, required this.lang});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _period = 'all';
  Map<String, int> _prayerStats = {};
  Map<String, int> _rozaStats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pStats = await DatabaseHelper.getPrayerStatsByPeriod(_period);
    final rStats = await DatabaseHelper.getRozaStatsByPeriod(_period);
    if (mounted) setState(() { _prayerStats = pStats; _rozaStats = rStats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Scaffold(
      appBar: AppBar(title: Text(lang.summary)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  _FilterChip(label: lang.allTime, selected: _period == 'all', onTap: () { _period = 'all'; _load(); }),
                  const SizedBox(width: 8),
                  _FilterChip(label: lang.thisYear, selected: _period == 'year', onTap: () { _period = 'year'; _load(); }),
                  const SizedBox(width: 8),
                  _FilterChip(label: lang.thisMonth, selected: _period == 'month', onTap: () { _period = 'month'; _load(); }),
                ]),
                const SizedBox(height: 20),
                _StatsCard(title: lang.namazHisab, icon: Icons.mosque,
                  missed: _prayerStats['missed'] ?? 0, prayed: _prayerStats['prayed'] ?? 0,
                  pending: _prayerStats['pending'] ?? 0, lang: lang),
                const SizedBox(height: 16),
                _StatsCard(title: lang.rozaHisab, icon: Icons.brightness_3,
                  missed: _rozaStats['missed'] ?? 0, prayed: _rozaStats['prayed'] ?? 0,
                  pending: _rozaStats['pending'] ?? 0, lang: lang),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.accent : Colors.white12),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontSize: 13)),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int missed, prayed, pending;
  final AppLanguage lang;

  const _StatsCard({required this.title, required this.icon, required this.missed,
    required this.prayed, required this.pending, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.gold, size: 22),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _StatItem(label: lang.totalMissed, value: lang.toLocalNum(missed), color: AppTheme.missed),
            _StatItem(label: lang.totalPrayed, value: lang.toLocalNum(prayed), color: AppTheme.completed),
            _StatItem(label: lang.currentPending, value: lang.toLocalNum(pending), color: AppTheme.pending),
          ]),
          if (missed > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: prayed / missed,
                backgroundColor: AppTheme.missed.withOpacity(0.3),
                color: AppTheme.completed,
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
    ]));
  }
}
