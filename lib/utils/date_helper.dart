import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'time_format_prefs.dart';

/// হোমের "আজকের রোজা" কার্ডে কী কী দেখাবে — তার হিসাবের ফলাফল।
class RozaCardInfo {
  /// রমজান মাসে আজকের হিজরি তারিখ (১..৩০); রমজান না হলে null।
  final int? ramadanDay;

  /// রমজান শুরু হতে বাকি দিন (১..১০০); না দেখানোর হলে null।
  final int? daysToRamadan;

  /// এখন শবে বরাতের রাত চলছে কি না।
  final bool isBaratNight;

  /// শবে বরাত শুরু হতে বাকি দিন (১..১৫); না দেখানোর হলে null।
  final int? daysToBarat;

  /// এখন কততম শবে কদরের রাত চলছে (১..৫); না হলে null।
  final int? qadrNightNumber;

  /// পরের শবে কদর শুরু হতে বাকি দিন (১..১৫); না দেখানোর হলে null।
  final int? daysToQadr;

  const RozaCardInfo({
    this.ramadanDay,
    this.daysToRamadan,
    this.isBaratNight = false,
    this.daysToBarat,
    this.qadrNightNumber,
    this.daysToQadr,
  });

  /// কার্ডে দেখানোর মতো কিছুই না থাকলে true।
  bool get isEmpty =>
      ramadanDay == null &&
      daysToRamadan == null &&
      !isBaratNight &&
      daysToBarat == null &&
      qadrNightNumber == null &&
      daysToQadr == null;
}

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
      'জুমাদাল উলা','জুমাদাল উখরা','রজব',"শা’বান",
      'রমাদান','শাওয়াল','জুলক্বা’দাহ','জুলহিজ্জাহ'
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

  /// ব্যবহারকারীর সেট করা হিজরি অ্যাডজাস্ট (দিন)।
  static Future<int> getHijriAdjustValue() => _getHijriAdjust();

  // একটা ইংরেজি তারিখের হিজরি তারিখ — toHijri-এর মতোই (-১ + user adjust)।
  static HijriCalendar _hijriOf(DateTime d, int adjust) {
    return HijriCalendar.fromDate(DateTime(d.year, d.month, d.day - 1 + adjust, 12));
  }

  // from তারিখ থেকে শুরু করে (from সহ) কত দিন পরে হিজরি [month]/[day] আসবে।
  // maxDays-এর মধ্যে না পেলে -1।
  static int _daysUntilHijri(DateTime from, int month, int day, int adjust, int maxDays) {
    final start = DateTime(from.year, from.month, from.day);
    for (int i = 0; i <= maxDays; i++) {
      final h = _hijriOf(DateTime(start.year, start.month, start.day + i), adjust);
      if (h.hMonth == month && h.hDay == day) return i;
    }
    return -1;
  }

  /// "আজকের রোজা" কার্ডের তথ্য হিসাব করে।
  ///
  /// • রমজানের টাইটেল ও "রমজান শুরু হতে বাকি দিন" — হোমে দেখানো হিজরি তারিখ
  ///   (রাত ১২টায় বদলায়) অনুযায়ী।
  /// • শবে বরাত ও শবে কদরের রাত শুরু হয় মাগরিব থেকে, চলে ফজরের আগ পর্যন্ত।
  ///   তাই এ দুটোর জন্য মাগরিবের পর "পরের হিজরি দিন" ধরা হয়
  ///   (যেমন ২০ রমজানের মাগরিবের পর = ২১ রমজানের রাত = ১ম শবে কদর)।
  static RozaCardInfo rozaCardInfo({
    required DateTime now,
    DateTime? maghrib,
    DateTime? fajr,
    int adjust = 0,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final appH = _hijriOf(today, adjust);

    final afterMaghrib = maghrib != null && now.isAfter(maghrib);
    final beforeFajr = fajr != null && now.isBefore(fajr);
    final isNight = afterMaghrib || beforeFajr;

    final effDate = afterMaghrib
        ? DateTime(today.year, today.month, today.day + 1)
        : today;
    final effH = _hijriOf(effDate, adjust);

    // ── রমজান ──
    int? ramadanDay;
    int? daysToRamadan;
    if (appH.hMonth == 9) {
      ramadanDay = appH.hDay;
    } else {
      final r = _daysUntilHijri(today, 9, 1, adjust, 100);
      if (r >= 1 && r <= 100) daysToRamadan = r;
    }

    // ── শবে বরাত (১৫ শা'বানের রাত = ১৪ শা'বানের মাগরিব থেকে) ──
    bool isBaratNight = false;
    int? daysToBarat;
    if (effH.hMonth == 8 && effH.hDay == 15) {
      isBaratNight = isNight;
    } else {
      final r = _daysUntilHijri(effDate, 8, 15, adjust, 15);
      if (r >= 1 && r <= 15) daysToBarat = r;
    }

    // ── শবে কদর (২১, ২৩, ২৫, ২৭, ২৯ রমজান শুরু হওয়ার রাত) ──
    int? qadrNightNumber;
    int? daysToQadr;
    if (effH.hMonth == 9) {
      const nights = [21, 23, 25, 27, 29];
      final d = effH.hDay;
      final idx = nights.indexOf(d);
      if (idx >= 0 && isNight) {
        qadrNightNumber = idx + 1;
      } else {
        for (final n in nights) {
          if (n > d) {
            if (n - d <= 15) daysToQadr = n - d;
            break;
          }
        }
      }
    }

    return RozaCardInfo(
      ramadanDay: ramadanDay,
      daysToRamadan: daysToRamadan,
      isBaratNight: isBaratNight,
      daysToBarat: daysToBarat,
      qadrNightNumber: qadrNightNumber,
      daysToQadr: daysToQadr,
    );
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

  // বাংলা মাসের index (০=বৈশাখ ... ১১=চৈত্র) থেকে ঋতুর নাম
  static const List<String> _seasonNames = [
    'গ্রীষ্মকাল', 'গ্রীষ্মকাল',   // বৈশাখ, জ্যৈষ্ঠ
    'বর্ষাকাল', 'বর্ষাকাল',       // আষাঢ়, শ্রাবণ
    'শরৎকাল', 'শরৎকাল',           // ভাদ্র, আশ্বিন
    'হেমন্তকাল', 'হেমন্তকাল',     // কার্তিক, অগ্রহায়ণ
    'শীতকাল', 'শীতকাল',           // পৌষ, মাঘ
    'বসন্তকাল', 'বসন্তকাল',       // ফাল্গুন, চৈত্র
  ];

  // "৩০ শ্রাবণ ১৪৩৩" এর বদলে "৩০ শ্রাবণ, বর্ষাকাল" — ক্লক কার্ডে দেখানোর জন্য
  static String toBanglaWithSeason(DateTime date) {
    final bMonths = [
      'বৈশাখ','জ্যৈষ্ঠ','আষাঢ়','শ্রাবণ',
      'ভাদ্র','আশ্বিন','কার্তিক','অগ্রহায়ণ',
      'পৌষ','মাঘ','ফাল্গুন','চৈত্র'
    ];

    final year = date.year;
    int bMonth = 0;
    int bDay = 1;
    int bYear = year - 593;

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

    final season = _seasonNames[bMonth];
    return '$season, ${_toBangla(bDay)} ${bMonths[bMonth]} ${_toBangla(bYear)}';
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
    if (TimeFormatPrefs.use24Hour) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      if (bangla) {
        return '${_toBanglaStr(hour)}:${_toBanglaStr(minute)}';
      }
      return '$hour:$minute';
    }
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
