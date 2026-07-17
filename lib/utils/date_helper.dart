import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DateHelper {
  static Future<int> _getHijriAdjust() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('hijri_adjust') ?? 0;
  }

  static String toHijri(DateTime date, {bool bangla = true, int adjust = 0}) {
    // বাংলাদেশে সৌদি থেকে ১ দিন পিছিয়ে, তারপর user adjust যোগ
    final totalAdjust = -1 + adjust;
    final adjustedDate = date.add(Duration(days: totalAdjust));
    final h = HijriCalendar.fromDate(adjustedDate);

    final monthsBn = [
      'মুহাররম','সফর','রবিউল আউয়াল','রবিউস সানি',
      'জামাদিউল আউয়াল','জামাদিউস সানি','রজব','শাবান',
      'রমজান','শাওয়াল','জিলকদ','জিলহজ'
    ];
    final monthsEn = [
      'Muharram','Safar','Rabi al-Awwal','Rabi al-Thani',
      'Jumada al-Awwal','Jumada al-Thani','Rajab','Sha\'ban',
      'Ramadan','Shawwal','Dhu al-Qi\'dah','Dhu al-Hijjah'
    ];

    final monthName = bangla ? monthsBn[h.hMonth - 1] : monthsEn[h.hMonth - 1];
    final day = bangla ? _toBangla(h.hDay) : h.hDay.toString();
    final year = bangla ? _toBangla(h.hYear) : h.hYear.toString();
    return '$day $monthName $year';
  }

  static Future<String> toHijriWithUserAdjust(DateTime date, {bool bangla = true}) async {
    final adjust = await _getHijriAdjust();
    return toHijri(date, bangla: bangla, adjust: adjust);
  }

  // হোম স্ক্রিনের হিজরি তারিখের সাথে এলার্ট লজিক মিলানোর জন্য —
  // একই hijri package + user adjust ব্যবহার করে (hMonth, hDay) রিটার্ন করে
  static Future<Map<String, int>> getHijriMonthDayWithUserAdjust(DateTime date) async {
    final adjust = await _getHijriAdjust();
    final totalAdjust = -1 + adjust;
    final adjustedDate = date.add(Duration(days: totalAdjust));
    final h = HijriCalendar.fromDate(adjustedDate);
    return {'month': h.hMonth, 'day': h.hDay};
  }

  static String toBangla(DateTime date) {
    final bMonths = [
      'বৈশাখ','জ্যৈষ্ঠ','আষাঢ়','শ্রাবণ',
      'ভাদ্র','আশ্বিন','কার্তিক','অগ্রহায়ণ',
      'পৌষ','মাঘ','ফাল্গুন','চৈত্র'
    ];

    final year = date.year;
    int bYear;
    int bMonth;
    int bDay;

    final monthStarts = [
      DateTime(year, 4, 14),
      DateTime(year, 5, 15),
      DateTime(year, 6, 15),
      DateTime(year, 7, 16),
      DateTime(year, 8, 16),
      DateTime(year, 9, 16),
      DateTime(year, 10, 16),
      DateTime(year, 11, 15),
      DateTime(year, 12, 15),
      DateTime(year + 1, 1, 14),
      DateTime(year + 1, 2, 13),
      DateTime(year + 1, 3, 14),
    ];

    bYear = year - 593;
    bMonth = 0;
    bDay = 1;

    if (date.isBefore(DateTime(year, 4, 14))) {
      bYear = year - 594;
      final prevMonthStarts = [
        DateTime(year - 1, 4, 14),
        DateTime(year - 1, 5, 15),
        DateTime(year - 1, 6, 15),
        DateTime(year - 1, 7, 16),
        DateTime(year - 1, 8, 16),
        DateTime(year - 1, 9, 16),
        DateTime(year - 1, 10, 16),
        DateTime(year - 1, 11, 15),
        DateTime(year - 1, 12, 15),
        DateTime(year, 1, 14),
        DateTime(year, 2, 13),
        DateTime(year, 3, 14),
      ];
      for (int i = prevMonthStarts.length - 1; i >= 0; i--) {
        if (!date.isBefore(prevMonthStarts[i])) {
          bMonth = i;
          bDay = date.difference(prevMonthStarts[i]).inDays + 1;
          break;
        }
      }
    } else {
      for (int i = monthStarts.length - 1; i >= 0; i--) {
        if (!date.isBefore(monthStarts[i])) {
          bMonth = i;
          bDay = date.difference(monthStarts[i]).inDays + 1;
          break;
        }
      }
    }

    return '${_toBangla(bDay)} ${bMonths[bMonth]} ${_toBangla(bYear)}';
  }

  static String _toBangla(int n) {
    const map = {
      '0':'০','1':'১','2':'২','3':'৩','4':'৪',
      '5':'৫','6':'৬','7':'৭','8':'৮','9':'৯'
    };
    return n.toString().split('').map((c) => map[c] ?? c).join();
  }

  static String _toBanglaStr(String s) {
    const map = {
      '0':'০','1':'১','2':'২','3':'৩','4':'৪',
      '5':'৫','6':'৬','7':'৭','8':'৮','9':'৯'
    };
    return s.split('').map((c) => map[c] ?? c).join();
  }

  static String formatGregorian(DateTime date, {bool bangla = true}) {
    final monthsBn = ['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন',
      'জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];
    final monthsEn = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    if (bangla) {
      return '${_toBangla(date.day)} ${monthsBn[date.month - 1]} ${_toBangla(date.year)}';
    }
    return '${date.day} ${monthsEn[date.month - 1]} ${date.year}';
  }

  static String formatTime12(DateTime time, {bool bangla = true}) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    if (bangla) {
      return '${_toBangla(hour)}:${_toBanglaStr(minute)} $period';
    }
    return '$hour:$minute $period';
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
  }
}
