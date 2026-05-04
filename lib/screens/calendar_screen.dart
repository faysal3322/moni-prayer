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
  const CalendarScreen({super.key, required this.lang, required this.onDataChanged});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, String> _dayStatuses = {};

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

  List<DateTime> _getMonthDates(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final dates = <DateTime>[];
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (!date.isAfter(DateTime.now())) dates.add(date);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lang.calendar)),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              if (selected.isAfter(DateTime.now())) return;
              setState(() { _selectedDay = selected; _focusedDay = focused; });

              final monthDates = _getMonthDates(_focusedDay);
              final index = monthDates.indexWhere((d) => isSameDay(d, selected));

              Navigator.push(context, MaterialPageRoute(
                builder: (_) => DayScreen(
                  date: selected,
                  lang: widget.lang,
                  onDataChanged: () {
                    _loadMonthStatuses(_focusedDay);
                    widget.onDataChanged();
                  },
                  allDates: monthDates,
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
              selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(border: Border.all(color: AppTheme.gold), shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: AppTheme.gold),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.textPrimary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.textPrimary),
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
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isFri ? AppTheme.friday : isSat ? AppTheme.saturday : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    if (color != null)
                      Positioned(bottom: 4, child: Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
                    Center(child: Text('${day.day}', style: TextStyle(
                      color: isFri ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: isFri ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13))),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(AppTheme.missed, widget.lang.isBn ? 'মিস' : 'Missed'),
                _legend(AppTheme.pending, widget.lang.isBn ? 'পেন্ডিং' : 'Pending'),
                _legend(AppTheme.completed, widget.lang.isBn ? 'সম্পূর্ণ' : 'Completed'),
                _legend(AppTheme.friday, widget.lang.jummah),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }
}
