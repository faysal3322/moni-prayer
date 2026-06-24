import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:adhan/adhan.dart';
import 'prayer_time_helper.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> schedulePrayerNotifications() async {
    await _plugin.cancelAll();

    final times = await PrayerTimeHelper.getPrayerTimes();

    final prayers = {
      'ফজর': times.fajr,
      'যোহর': times.dhuhr,
      'আসর': times.asr,
      'মাগরিব': times.maghrib,
      'এশা': times.isha,
    };

    int id = 0;
    for (final entry in prayers.entries) {
      await _scheduleNotification(
        id: id++,
        title: '🕌 ${entry.key} নামাজের সময়',
        body: '${entry.key} নামাজের সময় হয়েছে। এখন ${_fmt(entry.value)}',
        scheduledTime: entry.value,
      );
    }

    // Sunrise notification
    await _scheduleNotification(
      id: id++,
      title: '🌅 সূর্যোদয়',
      body: 'সূর্যোদয় হচ্ছে। এখন নামাজের নিষিদ্ধ সময় শুরু হয়েছে।',
      scheduledTime: times.sunrise,
    );

    // Forbidden time end (15 min after sunrise)
    final forbiddenEnd = times.sunrise.add(const Duration(minutes: 15));
    await _scheduleNotification(
      id: id++,
      title: '✅ নিষিদ্ধ সময় শেষ',
      body: 'নামাজের নিষিদ্ধ সময় শেষ হয়েছে। এখন নফল নামাজ পড়তে পারবেন।',
      scheduledTime: forbiddenEnd,
    );

    // Sehri warning (30 min before fajr)
    final sehriWarning = times.fajr.subtract(const Duration(minutes: 30));
    await _scheduleNotification(
      id: id++,
      title: '🍽️ সেহরির সময় শেষ হতে ৩০ মিনিট বাকি',
      body: 'সেহরির শেষ সময়: ${_fmt(times.fajr)}। তাড়াতাড়ি সেহরি করুন।',
      scheduledTime: sehriWarning,
    );

    // তাহাজ্জুদ: এশা থেকে ফজর পর্যন্ত মোট সময়ের ২/৩ পার হলে শুরু
    final ishaTime = times.isha;
    final fajrNext = times.fajr.isBefore(ishaTime)
        ? times.fajr.add(const Duration(days: 1))
        : times.fajr;
    final totalNightMinutes = fajrNext.difference(ishaTime).inMinutes;
    final tahajjudStart = ishaTime.add(Duration(minutes: (totalNightMinutes * 2 ~/ 3)));
    await _scheduleNotification(
      id: id++,
      title: '🌙 তাহাজ্জুদের সময় শুরু',
      body: 'এখন রাতের শেষ তৃতীয়াংশ। তাহাজ্জুদ নামাজ পড়ুন — দোয়া কবুলের সর্বোত্তম সময়।',
      scheduledTime: tahajjudStart,
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'moni_prayer_channel',
      'MONI PRAYER',
      channelDescription: 'নামাজের সময় ও অনুস্মারক',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static String _fmt(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute $period';
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
