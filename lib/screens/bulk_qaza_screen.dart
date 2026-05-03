import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/date_helper.dart';
import '../utils/database_helper.dart';

class BulkQazaScreen extends StatefulWidget {
  final AppLanguage lang;
  final VoidCallback onDataChanged;
  const BulkQazaScreen({super.key, required this.lang, required this.onDataChanged});

  @override
  State<BulkQazaScreen> createState() => _BulkQazaScreenState();
}

class _BulkQazaScreenState extends State<BulkQazaScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final Map<String, bool> _selectedPrayers = {
    'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': true,
  };
  bool _includeRoza = false;
  bool _loading = false;
  String _status = 'missed'; // missed or prayed

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

  int get _totalDays => _toDate.difference(_fromDate).inDays + 1;

  int get _totalEntries {
    int count = _selectedPrayers.values.where((v) => v).length * _totalDays;
    if (_includeRoza) count += _totalDays;
    return count;
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _apply() async {
    if (_totalDays <= 0) return;
    setState(() => _loading = true);

    int count = 0;
    DateTime current = _fromDate;

    while (!current.isAfter(_toDate)) {
      final dateKey = DateHelper.dateKey(current);

      for (final prayer in _prayers) {
        if (_selectedPrayers[prayer] == true) {
          await DatabaseHelper.setPrayerStatus(dateKey, prayer, _status);
          count++;
        }
      }

      if (_includeRoza) {
        await DatabaseHelper.setRozaStatus(dateKey, _status);
        count++;
      }

      current = current.add(const Duration(days: 1));
    }

    setState(() => _loading = false);
    widget.onDataChanged();

    if (mounted) {
      final isBn = widget.lang.isBn;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isBn
            ? '$count টি এন্ট্রি সফলভাবে ${_status == 'missed' ? 'কাযা' : 'আদায়'} করা হয়েছে!'
            : '$count entries marked as ${_status == 'missed' ? 'Qaza' : 'Prayed'}!'),
        backgroundColor: _status == 'missed' ? AppTheme.missed : AppTheme.completed,
        duration: const Duration(seconds: 3),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isBn = lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'একসাথে কাযা/আদায়' : 'Bulk Entry'),
      ),
      body: _loading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.accent),
                const SizedBox(height: 16),
                Text(isBn ? 'প্রক্রিয়া চলছে...' : 'Processing...',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    isBn
                        ? '💡 এই ফিচার দিয়ে আপনি একসাথে অনেকদিনের নামাজ/রোজা কাযা বা আদায় হিসেবে mark করতে পারবেন।'
                        : '💡 Use this feature to mark multiple days of prayers/fasting at once.',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),

                // Status selection
                Text(isBn ? 'কী হিসেবে mark করবেন?' : 'Mark as:',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _status = 'missed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _status == 'missed' ? AppTheme.missed : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.missed.withOpacity(0.6)),
                      ),
                      child: Center(child: Text(
                        isBn ? '❌ কাযা' : '❌ Qaza',
                        style: TextStyle(
                          color: _status == 'missed' ? Colors.white : AppTheme.missed,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _status = 'prayed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _status == 'prayed' ? AppTheme.completed : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.completed.withOpacity(0.6)),
                      ),
                      child: Center(child: Text(
                        isBn ? '✅ আদায়' : '✅ Prayed',
                        style: TextStyle(
                          color: _status == 'prayed' ? Colors.white : AppTheme.completed,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                  )),
                ]),
                const SizedBox(height: 20),

                // Date range
                Text(isBn ? 'তারিখ নির্বাচন করুন' : 'Select Date Range',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      child: Column(children: [
                        Text(isBn ? 'শুরুর তারিখ' : 'From',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(DateHelper.formatGregorian(_fromDate, bangla: isBn),
                          style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      ]),
                    ),
                  )),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('→', style: TextStyle(color: AppTheme.textSecondary, fontSize: 20)),
                  ),
                  Expanded(child: GestureDetector(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      child: Column(children: [
                        Text(isBn ? 'শেষের তারিখ' : 'To',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(DateHelper.formatGregorian(_toDate, bangla: isBn),
                          style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      ]),
                    ),
                  )),
                ]),
                const SizedBox(height: 8),
                Center(child: Text(
                  isBn ? 'মোট: ${lang.toLocalNum(_totalDays)} দিন' : 'Total: $_totalDays days',
                  style: const TextStyle(color: AppTheme.accent, fontSize: 13),
                )),
                const SizedBox(height: 20),

                // Prayer selection
                Text(isBn ? 'নামাজ নির্বাচন করুন' : 'Select Prayers',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    // Select All
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isBn ? 'সব নামাজ' : 'All Prayers',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        Switch(
                          value: _selectedPrayers.values.every((v) => v),
                          onChanged: (val) => setState(() {
                            for (final key in _selectedPrayers.keys) {
                              _selectedPrayers[key] = val;
                            }
                          }),
                          activeColor: AppTheme.accent,
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    ..._prayers.map((prayer) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_prayerName(prayer),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                        Switch(
                          value: _selectedPrayers[prayer] ?? false,
                          onChanged: (val) => setState(() => _selectedPrayers[prayer] = val),
                          activeColor: AppTheme.accent,
                        ),
                      ],
                    )),
                    const Divider(color: Colors.white12),
                    // Roza
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.roza,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                        Switch(
                          value: _includeRoza,
                          onChanged: (val) => setState(() => _includeRoza = val),
                          activeColor: AppTheme.accent,
                        ),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryItem(isBn ? 'দিন' : 'Days', lang.toLocalNum(_totalDays)),
                      _summaryItem(isBn ? 'মোট এন্ট্রি' : 'Total', lang.toLocalNum(_totalEntries)),
                      _summaryItem(
                        isBn ? 'ধরন' : 'Type',
                        _status == 'missed' ? (isBn ? 'কাযা' : 'Qaza') : (isBn ? 'আদায়' : 'Prayed'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Apply button
                ElevatedButton(
                  onPressed: _totalEntries > 0 ? _apply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _status == 'missed' ? AppTheme.missed : AppTheme.completed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isBn
                        ? '${lang.toLocalNum(_totalEntries)} টি এন্ট্রি ${_status == 'missed' ? 'কাযা' : 'আদায়'} করুন'
                        : 'Mark $_totalEntries entries as ${_status == 'missed' ? 'Qaza' : 'Prayed'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]);
  }
}
