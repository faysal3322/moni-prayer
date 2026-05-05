import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/date_helper.dart';
import '../utils/database_helper.dart';
import 'day_screen.dart';

class CalendarScreen extends StatefulWidget {
  final AppLanguage lang;
  final VoidCallback onDataChanged;
  const CalendarScreen({
    super.key,
    required this.lang,
    required this.onDataChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, String> _dayStatuses = {};

  // Bulk entry state
  Set<String> _selectedBulkPrayers = {};
  bool _bulkRoza = false;
  Set<DateTime> _bulkSelectedDates = {};
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadMonthStatuses(_focusedDay);
  }

  Future<void> _loadMonthStatuses(DateTime month) async {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final statuses = <String, String>{};
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.isAfter(DateTime.now())) break;
      final key = DateHelper.dateKey(date);
      statuses[key] = await DatabaseHelper.getDayStatus(key);
    }
    if (mounted) setState(() => _dayStatuses = statuses);
  }

  List<DateTime> _getAllDatesInYear(DateTime month) {
    final year = month.year;
    final dates = <DateTime>[];
    for (int m = 1; m <= 12; m++) {
      final daysInMonth = DateUtils.getDaysInMonth(year, m);
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, m, d);
        if (!date.isAfter(DateTime.now())) dates.add(date);
      }
    }
    final prevYear = year - 1;
    final daysInDec = DateUtils.getDaysInMonth(prevYear, 12);
    for (int d = 1; d <= daysInDec; d++) {
      dates.insert(0, DateTime(prevYear, 12, d));
    }
    return dates;
  }

  Color? _getDayColor(DateTime day) {
    if (day.isAfter(DateTime.now())) return null;
    final status = _dayStatuses[DateHelper.dateKey(day)];
    switch (status) {
      case 'missed': return AppTheme.missed;
      case 'pending': return AppTheme.pending;
      case 'completed': return AppTheme.completed;
      default: return null;
    }
  }

  bool get _isBulkMode => _selectedBulkPrayers.isNotEmpty || _bulkRoza;

  void _toggleDate(DateTime date) {
    if (date.isAfter(DateTime.now())) return;
    setState(() {
      final existing = _bulkSelectedDates.where((d) => isSameDay(d, date)).toList();
      if (existing.isNotEmpty) {
        _bulkSelectedDates.removeWhere((d) => isSameDay(d, date));
      } else {
        _bulkSelectedDates.add(date);
      }
    });
  }

  void _addDate(DateTime date) {
    if (date.isAfter(DateTime.now())) return;
    if (!_bulkSelectedDates.any((d) => isSameDay(d, date))) {
      setState(() => _bulkSelectedDates.add(date));
    }
  }

  Future<void> _applyBulkQaza() async {
    if ((_selectedBulkPrayers.isEmpty && !_bulkRoza) || _bulkSelectedDates.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          widget.lang.isBn ? 'নিশ্চিত করুন' : 'Confirm',
          style: const TextStyle(color: AppTheme.gold),
        ),
        content: Text(
          widget.lang.isBn
              ? '${_bulkSelectedDates.length} দিনের নির্বাচিত নামাজ/রোজা কাযা করবেন?'
              : 'Mark selected prayers/fasting as Qaza for ${_bulkSelectedDates.length} days?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.lang.isBn ? 'না' : 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.missed),
            child: Text(widget.lang.isBn ? 'হ্যাঁ' : 'Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final date in _bulkSelectedDates) {
      final key = DateHelper.dateKey(date);
      for (final prayer in _selectedBulkPrayers) {
        await DatabaseHelper.setPrayerStatus(key, prayer, 'missed');
      }
      if (_bulkRoza) {
        await DatabaseHelper.setRozaStatus(key, 'missed');
      }
    }

    setState(() {
      _bulkSelectedDates.clear();
      _selectedBulkPrayers.clear();
      _bulkRoza = false;
    });

    _loadMonthStatuses(_focusedDay);
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.lang.isBn ? 'কাযা সফলভাবে সেভ হয়েছে!' : 'Qaza saved successfully!'),
        backgroundColor: AppTheme.completed,
      ));
    }
  }

  void _showYearMonthPicker() async {
    int selectedYear = _focusedDay.year;
    int selectedMonth = _focusedDay.month;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            widget.lang.isBn ? 'সাল ও মাস নির্বাচন' : 'Select Year & Month',
            style: const TextStyle(color: AppTheme.gold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setDialogState(() => selectedYear--),
                      icon: const Icon(Icons.chevron_left, color: AppTheme.gold),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final years = List.generate(50, (i) => DateTime.now().year - 49 + i);
                        final picked = await showDialog<int>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppTheme.cardBg,
                            title: Text(
                              widget.lang.isBn ? 'সাল নির্বাচন' : 'Select Year',
                              style: const TextStyle(color: AppTheme.gold),
                            ),
                            content: SizedBox(
                              height: 300,
                              width: double.maxFinite,
                              child: ListView.builder(
                                itemCount: years.length,
                                itemBuilder: (_, i) => ListTile(
                                  title: Text(
                                    years[i].toString(),
                                    style: TextStyle(
                                      color: years[i] == selectedYear ? AppTheme.gold : AppTheme.textPrimary,
                                      fontWeight: years[i] == selectedYear ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () => Navigator.pop(context, years[i]),
                                ),
                              ),
                            ),
                          ),
                        );
                        if (picked != null) setDialogState(() => selectedYear = picked);
                      },
                      child: Text(
                        selectedYear.toString(),
                        style: const TextStyle(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => selectedYear++),
                      icon: const Icon(Icons.chevron_right, color: AppTheme.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final monthsBn = ['জানু','ফেব্রু','মার্চ','এপ্রিল','মে','জুন','জুলাই','আগস্ট','সেপ্টে','অক্টো','নভে','ডিসে'];
                    final monthsEn = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                    final isSelected = i + 1 == selectedMonth;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedMonth = i + 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? AppTheme.accent : Colors.white12),
                        ),
                        child: Center(
                          child: Text(
                            widget.lang.isBn ? monthsBn[i] : monthsEn[i],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.lang.isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _focusedDay = DateTime(selectedYear, selectedMonth, 1));
                _loadMonthStatuses(_focusedDay);
              },
              child: Text(widget.lang.isBn ? 'যান' : 'Go'),
            ),
          ],
        ),
      ),
    );
  }

  String _prayerDisplayName(String key) {
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
    final isBn = widget.lang.isBn;
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lang.calendar),
        actions: [
          IconButton(
            onPressed: _showYearMonthPicker,
            icon: const Icon(Icons.date_range, color: AppTheme.gold),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          GestureDetector(
            onPanUpdate: _isBulkMode ? (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPos = box.globalToLocal(details.globalPosition);
              // approximate date from position — handled via day builder tap
            } : null,
            child: TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              selectedDayPredicate: (day) {
                if (_isBulkMode) {
                  return _bulkSelectedDates.any((d) => isSameDay(d, day));
                }
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selected, focused) {
                if (selected.isAfter(DateTime.now())) return;
                if (_isBulkMode) {
                  _toggleDate(selected);
                  setState(() => _focusedDay = focused);
                  return;
                }
                setState(() { _selectedDay = selected; _focusedDay = focused; });
                final allDates = _getAllDatesInYear(_focusedDay);
                final index = allDates.indexWhere((d) => isSameDay(d, selected));
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DayScreen(
                    date: selected,
                    lang: widget.lang,
                    onDataChanged: () {
                      _loadMonthStatuses(_focusedDay);
                      widget.onDataChanged();
                    },
                    allDates: allDates,
                    initialIndex: index >= 0 ? index : 0,
                  ),
                ));
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadMonthStatuses(focusedDay);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: AppTheme.textPrimary),
                weekendTextStyle: const TextStyle(color: AppTheme.textPrimary),
                selectedDecoration: BoxDecoration(
                  color: _isBulkMode ? AppTheme.missed.withOpacity(0.7) : AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gold),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppTheme.gold),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16),
                titleTextFormatter: (date, locale) {
                  final monthsBn = ['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন','জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];
                  final monthsEn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
                  final month = isBn ? monthsBn[date.month - 1] : monthsEn[date.month - 1];
                  return '$month ${date.year}';
                },
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final color = _getDayColor(day);
                  final isFri = day.weekday == DateTime.friday;
                  final isSat = day.weekday == DateTime.saturday;
                  final isBulkSelected = _bulkSelectedDates.any((d) => isSameDay(d, day));

                  return GestureDetector(
                    onLongPressStart: _isBulkMode ? (_) => _addDate(day) : null,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isBulkSelected
                            ? AppTheme.missed.withOpacity(0.5)
                            : isFri ? AppTheme.friday
                            : isSat ? AppTheme.saturday
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isBulkSelected ? Border.all(color: AppTheme.missed, width: 2) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (color != null)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                            ),
                          Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isBulkSelected ? Colors.white
                                    : isFri ? AppTheme.accent
                                    : AppTheme.textPrimary,
                                fontWeight: isFri || isBulkSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(AppTheme.missed, isBn ? 'মিস' : 'Missed'),
                _legend(AppTheme.pending, isBn ? 'পেন্ডিং' : 'Pending'),
                _legend(AppTheme.completed, isBn ? 'সম্পূর্ণ' : 'Completed'),
                _legend(AppTheme.friday, widget.lang.jummah),
              ],
            ),
          ),

          const Divider(color: Colors.white12),

          // Bulk Qaza Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_calendar, color: AppTheme.gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isBn ? 'বাল্ক কাযা এন্ট্রি' : 'Bulk Qaza Entry',
                        style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'নামাজ/রোজা সিলেক্ট করুন → ক্যালেন্ডারে তারিখ ট্যাপ করুন'
                        : 'Select prayers/fasting → Tap dates on calendar',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Prayer & Roza buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...prayers.map((prayer) {
                        final isSelected = _selectedBulkPrayers.contains(prayer);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedBulkPrayers.remove(prayer);
                              } else {
                                _selectedBulkPrayers.add(prayer);
                              }
                              _bulkSelectedDates.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.missed : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppTheme.missed : AppTheme.primary.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              _prayerDisplayName(prayer),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Roza button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _bulkRoza = !_bulkRoza;
                            _bulkSelectedDates.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _bulkRoza ? AppTheme.missed : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _bulkRoza ? AppTheme.missed : AppTheme.primary.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            widget.lang.roza,
                            style: TextStyle(
                              color: _bulkRoza ? Colors.white : AppTheme.textPrimary,
                              fontWeight: _bulkRoza ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isBulkMode) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.missed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn
                                ? 'সিলেক্ট করা: ${_bulkSelectedDates.length} দিন'
                                : 'Selected: ${_bulkSelectedDates.length} days',
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() {
                                    _bulkSelectedDates.clear();
                                    _selectedBulkPrayers.clear();
                                    _bulkRoza = false;
                                  }),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white24),
                                  ),
                                  child: Text(
                                    isBn ? 'বাতিল' : 'Cancel',
                                    style: const TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _bulkSelectedDates.isNotEmpty ? _applyBulkQaza : null,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.missed),
                                  child: Text(isBn ? 'কাযা করুন' : 'Mark Qaza'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
