import 'package:hijri/hijri_calendar.dart';

class DateHelper {
  static String toHijri(DateTime date, {bool bangla = true}) {
    final h = HijriCalendar.fromDate(date);
    final months_bn = [
      'মুহাররম','সফর','রবিউল আউয়াল','রবিউস সানি',
      'জামাদিউল আউয়াল','জামাদিউস সানি','রজব','শাবান',
      'রমজান','শাওয়াল','জিলকদ','জিলহজ'
    ];
    final months_en = [
      'Muharram','Safar','Rabi al-Awwal','Rabi al-Thani',
      'Jumada al-Awwal','Jumada al-Thani','Rajab','Sha\'ban',
      'Ramadan','Shawwal','Dhu al-Qi\'dah','Dhu al-Hijjah'
    ];
    final monthName = bangla ? months_bn[h.hMonth - 1] : months_en[h.hMonth - 1];
    final day = bangla ? _toBangla(h.hDay) : h.hDay.toString();
    final year = bangla ? _toBangla(h.hYear) : h.hYear.toString();
    return '$day $monthName $year';
  }

  static String toBangla(DateTime date) {
    final bMonths = ['বৈশাখ','জ্যৈষ্ঠ','আষাঢ়','শ্রাবণ','ভাদ্র','আশ্বিন',
      'কার্তিক','অগ্রহায়ণ','পৌষ','মাঘ','ফাল্গুন','চৈত্র'];
    int bYear = date.year - 594;
    int bMonth;
    int bDay;
    final dayOfYear = _dayOfYear(date);
    if (dayOfYear <= 13) { bMonth = 9; bDay = dayOfYear + 17; bYear -= 1; }
    else if (dayOfYear <= 44) { bMonth = 10; bDay = dayOfYear - 13; }
    else if (dayOfYear <= 75) { bMonth = 11; bDay = dayOfYear - 44; }
    else if (dayOfYear <= 106) { bMonth = 12; bDay = dayOfYear - 75; }
    else if (dayOfYear <= 137) { bMonth = 1; bDay = dayOfYear - 105; bYear += 1; }
    else if (dayOfYear <= 168) { bMonth = 2; bDay = dayOfYear - 136; }
    else if (dayOfYear <= 198) { bMonth = 3; bDay = dayOfYear - 167; }
    else if (dayOfYear <= 229) { bMonth = 4; bDay = dayOfYear - 198; }
    else if (dayOfYear <= 260) { bMonth = 5; bDay = dayOfYear - 229; }
    else if (dayOfYear <= 291) { bMonth = 6; bDay = dayOfYear - 260; }
    else if (dayOfYear <= 321) { bMonth = 7; bDay = dayOfYear - 291; }
    else if (dayOfYear <= 352) { bMonth = 8; bDay = dayOfYear - 321; }
    else { bMonth = 9; bDay = dayOfYear - 352; }
    return '${_toBangla(bDay)} ${bMonths[bMonth - 1]} ${_toBangla(bYear)}';
  }

  static int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  static String _toBangla(int n) {
    const map = {'0':'০','1':'১','2':'২','3':'৩','4':'৪',
      '5':'৫','6':'৬','7':'৭','8':'৮','9':'৯'};
    return n.toString().split('').map((c) => map[c] ?? c).join();
  }

  static String formatGregorian(DateTime date, {bool bangla = true}) {
    final months_bn = ['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন',
      'জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];
    final months_en = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    if (bangla) {
      return '${_toBangla(date.day)} ${months_bn[date.month - 1]} ${_toBangla(date.year)}';
    }
    return '${date.day} ${months_en[date.month - 1]} ${date.year}';
  }

  static String formatTime12(DateTime time, {bool bangla = true}) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    final h = bangla ? _toBangla(hour) : hour.toString();
    final m = bangla ? _toBangla(int.parse(minute)) : minute;
    return '$h:$m $period';
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
  }
}
