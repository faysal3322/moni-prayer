import 'package:flutter/material.dart';
import 'prayer_time_helper.dart';

/// "ভবিষ্যতের আমল ট্র্যাক করা সম্ভব নয়" — হোম স্ক্রিন ও ক্যালেন্ডার, দুই জায়গার
/// জন্য একই নিয়ম ও একই বার্তা। (হোম স্ক্রিনের বার্তা ও স্টাইল হুবহু এক।)
class FutureDeedGuard {
  FutureDeedGuard._();

  /// আজকের পাঁচ ওয়াক্তের শুরুর সময়। GPS না ডেকে cache করা লোকেশন থেকে হিসাব
  /// (তাৎক্ষণিক)। কোনো কারণে হিসাব না মিললে null — তখন আটকানো হয় না।
  static Future<Map<String, DateTime>?> todayPrayerStarts() async {
    try {
      final list = await PrayerTimeHelper.getPrayerTimesRange(days: 1);
      final pt = list.first;
      return {
        'fajr': pt.fajr,
        'dhuhr': pt.dhuhr,
        'asr': pt.asr,
        'maghrib': pt.maghrib,
        'isha': pt.isha,
      };
    } catch (_) {
      return null;
    }
  }

  /// [date] কি আজকের তারিখের (শুধু দিন-মাস-বছর ধরে) পরে?
  static bool isFutureDay(DateTime date) {
    final n = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .isAfter(DateTime(n.year, n.month, n.day));
  }

  static bool isToday(DateTime date) {
    final n = DateTime.now();
    return date.year == n.year && date.month == n.month && date.day == n.day;
  }

  /// [prayer]-এর ওয়াক্ত কি এখনও শুরু হয়নি? (শুধু আজকের তারিখের জন্য অর্থবহ)
  static bool prayerNotStarted(
      Map<String, DateTime>? starts, String prayer) {
    final s = starts?[prayer];
    if (s == null) return false;
    return DateTime.now().isBefore(s);
  }

  static void showWarning(BuildContext context, bool isBn) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(
        isBn
            ? 'ভবিষ্যতের আ\'মল ট্র্যাক করা সম্ভব নয়'
            : 'Future deeds cannot be tracked yet',
        style: const TextStyle(color: Colors.black87, fontSize: 16),
      ),
      backgroundColor: const Color(0xFFE0E0DC),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}
