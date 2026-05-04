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
  String? _selectedBulkPrayer;
  Set<DateTime> _bulkSelectedDates = {};

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

  List<DateTime> _getAllDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (!current.isAfter(DateTime.now())) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
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
                // Year selector
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
                                    widget.lang.isBn
                                        ? _toBangla(years[i])
                                        : years[i].toString(),
                                    style: TextStyle(
                                      color: years[i] == selectedYear
                                          ? AppTheme.gold
                                          : AppTheme.textPrimary,
                                      fontWeight: years[i] == selectedYear
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () => Navigator.pop(context, years[i]),
                                ),
                              ),
                            ),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedYear = picked);
                        }
                      },
                      child: Text(
                        widget.lang.isBn
                            ? _toBangla(selectedYear)
                            : selectedYear.toString(),
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => selectedYear++),
                      icon: const Icon(Icons.chevron_right, color: AppTheme.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Month grid
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
                    final months_bn = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
                      'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
                    final months_en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    final isSelected = i + 1 == selectedMonth;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedMonth = i + 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.accent : Colors.white12,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.lang.isBn ? months_bn[i] : months_en[i],
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
              child: Text(
                widget.lang.isBn ? 'বাতিল' : 'Cancel',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _focusedDay = DateTime(selectedYear, selectedMonth, 1);
                });
                _loadMonthStatuses(_focusedDay);
              },
              child: Text(widget.lang.isBn ? 'যান' : 'Go'),
            ),
          ],
        ),
      ),
    );
  }

  String _toBangla(int n) {
    const map = {'0':'০','1':'১','2':'২','3':'৩','4':'৪','5':'৫','6':'৬','7':'৭','8':'৮','9':'৯'};
    return n.toString().split('').map((c) => map[c] ?? c).join();
  }

  Future<void> _applyBulkQaza() async {
    if (_selectedBulkPrayer == null || _bulkSelectedDates.isEmpty) return;

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
              ? '${_bulkSelectedDates.length} দিনের ${_prayerName(_selectedBulkPrayer!)} নামাজ কাযা করবেন?'
              : 'Mark ${_prayerName(_selectedBulkPrayer!)} as Qaza for ${_bulkSelectedDates.length} days?',
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
      await DatabaseHelper.setPrayerStatus(key, _selectedBulkPrayer!, 'missed');
    }

    setState(() {
      _bulkSelectedDates.clear();
      _selectedBulkPrayer = null;
    });

    _loadMonthStatuses(_focusedDay);
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          widget.lang.isBn ? 'কাযা সফলভাবে সেভ হয়েছে!' : 'Qaza saved successfully!',
        ),
        backgroundColor: AppTheme.completed,
      ));
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
    final isBn = widget.lang.isBn;
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lang.calendar),
        actions: [
          IconButton(
            onPressed: _showYearMonthPicker,
            icon: const Icon(Icons.date_range, color: AppTheme.gold),
            tooltip: isBn ? 'সাল/মাস' : 'Year/Month',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            selectedDayPredicate: (day) {
              if (_selectedBulkPrayer != null) {
                return _bulkSelectedDates.any((d) => isSameDay(d, day));
              }
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selected, focused) {
              if (selected.isAfter(DateTime.now())) return;

              if (_selectedBulkPrayer != null) {
                setState(() {
                  _focusedDay = focused;
                  final existing = _bulkSelectedDates.where((d) => isSameDay(d, selected)).toList();
                  if (existing.isNotEmpty) {
                    _bulkSelectedDates.removeWhere((d) => isSameDay(d, selected));
                  } else {
                    _bulkSelectedDates.add(selected);
                  }
                });
                return;
              }

              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });

              final allDates = _getAllDatesInYear(_focusedDay);
              final index = allDates.indexWhere((d) => isSameDay(d, selected));

              Navigator.push(
                context,
                MaterialPageRoute(
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
                ),
              );
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
                color: _selectedBulkPrayer != null
                    ? AppTheme.missed.withOpacity(0.7)
                    : AppTheme.primary,
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
              titleTextStyle: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 4),
              titleTextFormatter: (date, locale) {
                final months_bn = ['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন',
                  'জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];
                final months_en = ['January','February','March','April','May','June',
                  'July','August','September','October','November','December'];
                final month = isBn ? months_bn[date.month - 1] : months_en[date.month - 1];
                final year = isBn ? _toBangla(date.year) : date.year.toString();
                return '$month $year';
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

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isBulkSelected
                        ? AppTheme.missed.withOpacity(0.5)
                        : isFri
                            ? AppTheme.friday
                            : isSat
                                ? AppTheme.saturday
                                : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isBulkSelected
                        ? Border.all(color: AppTheme.missed, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (color != null)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isBulkSelected
                                ? Colors.white
                                : isFri
                                    ? AppTheme.accent
                                    : AppTheme.textPrimary,
                            fontWeight: isFri || isBulkSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isBn
                        ? 'একটি নামাজ সিলেক্ট করুন, তারপর ক্যালেন্ডারে তারিখ ট্যাপ করুন'
                        : 'Select a prayer, then tap dates on calendar',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Prayer buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: prayers.map((prayer) {
                      final isSelected = _selectedBulkPrayer == prayer;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedBulkPrayer == prayer) {
                              _selectedBulkPrayer = null;
                              _bulkSelectedDates.clear();
                            } else {
                              _selectedBulkPrayer = prayer;
                              _bulkSelectedDates.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.missed
                                : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.missed
                                  : AppTheme.primary.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            _prayerName(prayer),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_selectedBulkPrayer != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.missed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isBn
                                  ? '${_prayerName(_selectedBulkPrayer!)} সিলেক্ট: ${_bulkSelectedDates.length} দিন'
                                  : '${_prayerName(_selectedBulkPrayer!)} selected: ${_bulkSelectedDates.length} days',
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                          if (_bulkSelectedDates.isNotEmpty)
                            ElevatedButton(
                              onPressed: _applyBulkQaza,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.missed,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                isBn ? 'কাযা করুন' : 'Mark Qaza',
                                style: const TextStyle(fontSize: 12),
                              ),
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

  List<DateTime> _getAllDatesInYear(DateTime month) {
    // পুরো বছরের তারিখ দিই যাতে swipe করে month boundary পার হওয়া যায়
    final year = month.year;
    final dates = <DateTime>[];
    for (int m = 1; m <= 12; m++) {
      final daysInMonth = DateUtils.getDaysInMonth(year, m);
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, m, d);
        if (!date.isAfter(DateTime.now())) {
          dates.add(date);
        }
      }
    }
    // আগের বছরের শেষ মাসও যোগ করি
    final prevYear = year - 1;
    final daysInDec = DateUtils.getDaysInMonth(prevYear, 12);
    for (int d = 1; d <= daysInDec; d++) {
      dates.insert(0, DateTime(prevYear, 12, d));
    }
    return dates;
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
