import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:adhan/adhan.dart';
import 'prayer_time_helper.dart';

/// দিনের সব গুরুত্বপূর্ণ ওয়াক্ত/মুহূর্তের জন্য notification পাঠায় —
/// নামাজের ৫ ওয়াক্ত শুরু, ৩টা নিষিদ্ধ সময় (সূর্যোদয়, মধ্যাহ্ন/ইস্তিওয়া,
/// সূর্যাস্তের ঠিক আগে) শুরু ও শেষ, সেহরি শেষ হওয়ার আগাম সতর্কতা, ইফতার
/// এবং তাহাজ্জুদ শুরু।
///
/// প্রতিটা notification "heads-up" (স্ক্রিনের উপরে ভেসে ওঠা ব্যানার আকারে,
/// ফোন চালু অবস্থায়) এবং lock screen-এও পুরোপুরি দেখা যাওয়ার মতো করে
/// (Importance.max + high priority + public visibility) কনফিগার করা —
/// অন্য অনেক ইসলামিক অ্যাপে যেমন দেখা যায় (স্ক্রিনশটে যেমন নমুনা
/// দেওয়া হয়েছে) সেরকম।
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Android 8+ এ চ্যানেলের importance/visibility প্রথমবার তৈরির সময়ই
    // ঠিক করে দিতে হয় (পরে অ্যাপ থেকে বদলানো যায় না, ব্যবহারকারীকে
    // সিস্টেম সেটিংস থেকে ম্যানুয়ালি বদলাতে হয়) — তাই এখানেই
    // createNotificationChannel দিয়ে সবচেয়ে বেশি priority (max) এবং
    // lock screen-এ পুরোপুরি দেখানোর (public) ব্যবস্থা করে রাখা হচ্ছে।
    const channel = AndroidNotificationChannel(
      'moni_prayer_channel',
      'MONI PRAYER',
      description: 'নামাজের সময়, নিষিদ্ধ সময়, সেহরি/ইফতার ও তাহাজ্জুদের অনুস্মারক',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    // Android 12+ এ exact alarm (SCHEDULE_EXACT_ALARM) আলাদা করে চাইতে
    // হয় — এটা না পেলে নামাজের সময়মতো (ঠিক মিনিটে) notification আসবে
    // না, কিছুটা দেরিতে আসতে পারে।
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// প্রতিদিনের সব গুরুত্বপূর্ণ ওয়াক্ত/মুহূর্তের জন্য notification
  /// শিডিউল করে। প্রতিবার কল করলে আগেরগুলো বাতিল করে নতুন করে বসায় —
  /// তাই এটা প্রতিদিন একবার (যেমন অ্যাপ খোলার সময় বা মধ্যরাতে) কল করা
  /// দরকার, কারণ নামাজের সময় প্রতিদিন কিছুটা বদলায়।
  static Future<void> schedulePrayerNotifications() async {
    await _plugin.cancelAll();

    final isBn = await _isBangla();
    final today = await PrayerTimeHelper.getPrayerTimes();
    final tomorrow = await PrayerTimeHelper.getPrayerTimes(
      date: DateTime.now().add(const Duration(days: 1)),
    );

    int id = 0;
    id = await _scheduleForDay(id, today, isBn);
    // আজকের অনেক ওয়াক্ত (বিশেষ করে ফজর, সেহরি, তাহাজ্জুদ) ইতিমধ্যে
    // পার হয়ে গেলেও কালকেরগুলো যেন আগে থেকেই শিডিউল হয়ে থাকে, তাই
    // পরের দিনেরও একই সাথে বসিয়ে রাখা হচ্ছে (past সময়গুলো এমনিতেই
    // স্কিপ হয়ে যায়)।
    await _scheduleForDay(id, tomorrow, isBn);
  }

  static Future<bool> _isBangla() async {
    // এই হেল্পার নিজে থেকে ভাষা জানে না, তাই ডিফল্ট বাংলা ধরে নেওয়া
    // হচ্ছে (অ্যাপের ডিফল্ট ভাষা অনুযায়ী) — চাইলে ভবিষ্যতে
    // language prefs থেকে সরাসরি পড়া যাবে।
    return true;
  }

  static Future<int> _scheduleForDay(int startId, PrayerTimes times, bool isBn) async {
    int id = startId;

    final prayers = isBn
        ? {
            'ফজর': times.fajr,
            'যোহর': times.dhuhr,
            'আসর': times.asr,
            'মাগরিব': times.maghrib,
            'এশা': times.isha,
          }
        : {
            'Fajr': times.fajr,
            'Dhuhr': times.dhuhr,
            'Asr': times.asr,
            'Maghrib': times.maghrib,
            'Isha': times.isha,
          };

    for (final entry in prayers.entries) {
      await _scheduleNotification(
        id: id++,
        title: isBn ? '🕌 ${entry.key} ওয়াক্ত শুরু' : '🕌 ${entry.key} time has started',
        body: isBn
            ? 'এখন ${entry.key} নামাজের ওয়াক্ত। সময়: ${_fmt(entry.value)}'
            : 'It is now time for ${entry.key} prayer. Time: ${_fmt(entry.value)}',
        scheduledTime: entry.value,
      );
    }

    // ── নিষিদ্ধ সময় ১: সূর্যোদয়ের সময় ও তার পরের ~১৫ মিনিট ──
    await _scheduleNotification(
      id: id++,
      title: isBn ? '⛔ নিষিদ্ধ সময় শুরু' : '⛔ Forbidden time has started',
      body: isBn
          ? 'সূর্য উঠছে। এখন নামাজের নিষিদ্ধ সময়, নামাজ পড়বেন না।'
          : 'The sun is rising. This is a forbidden time to pray — please do not pray now.',
      scheduledTime: times.sunrise,
    );
    final forbidden1End = times.sunrise.add(const Duration(minutes: 15));
    await _scheduleNotification(
      id: id++,
      title: isBn ? '✅ নিষিদ্ধ সময় শেষ' : '✅ Forbidden time has ended',
      body: isBn
          ? 'নিষিদ্ধ সময় শেষ হয়েছে। এখন থেকে নফল নামাজ পড়া যাবে।'
          : 'The forbidden time has ended. You may now pray nafl prayers.',
      scheduledTime: forbidden1End,
    );

    // ── নিষিদ্ধ সময় ২: মধ্যাহ্ন/ইস্তিওয়া (ঠিক দুপুরে সূর্য মাথার
    //    উপর থাকা অবস্থা, যোহরের ওয়াক্ত শুরুর ঠিক আগ পর্যন্ত) ──
    // adhan প্যাকেজে সরাসরি "zenith" টাইম নেই, তবে এটা দুহর ওয়াক্তের
    // ঠিক আগের কয়েক মিনিট (আনুমানিক ৫-১০ মিনিট) হিসেবে ধরা হয়।
    final zenithStart = times.dhuhr.subtract(const Duration(minutes: 10));
    await _scheduleNotification(
      id: id++,
      title: isBn ? '⛔ নিষিদ্ধ সময় শুরু (ইস্তিওয়া)' : '⛔ Forbidden time has started',
      body: isBn
          ? 'সূর্য ঠিক মাথার উপর। এখন নামাজের নিষিদ্ধ সময়, নামাজ পড়বেন না।'
          : 'The sun is at its zenith. This is a forbidden time to pray — please do not pray now.',
      scheduledTime: zenithStart,
    );
    await _scheduleNotification(
      id: id++,
      title: isBn ? '✅ নিষিদ্ধ সময় শেষ' : '✅ Forbidden time has ended',
      body: isBn
          ? 'নিষিদ্ধ সময় শেষ হয়েছে। যোহরের ওয়াক্ত হয়ে গেছে।'
          : 'The forbidden time has ended. It is now Dhuhr time.',
      scheduledTime: times.dhuhr,
    );

    // ── নিষিদ্ধ সময় ৩: সূর্যাস্তের ঠিক আগে (~১৫ মিনিট, আসর শেষ
    //    হওয়া থেকে মাগরিব পর্যন্ত সূর্য হলুদ/লাল হয়ে যাওয়ার সময়) ──
    final forbidden3Start = times.maghrib.subtract(const Duration(minutes: 15));
    await _scheduleNotification(
      id: id++,
      title: isBn ? '⛔ নিষিদ্ধ সময় শুরু' : '⛔ Forbidden time has started',
      body: isBn
          ? 'সূর্য অস্ত যাচ্ছে। এখন নামাজের নিষিদ্ধ সময়, নামাজ পড়বেন না।'
          : 'The sun is setting. This is a forbidden time to pray — please do not pray now.',
      scheduledTime: forbidden3Start,
    );
    await _scheduleNotification(
      id: id++,
      title: isBn ? '✅ নিষিদ্ধ সময় শেষ' : '✅ Forbidden time has ended',
      body: isBn
          ? 'সূর্যাস্ত হয়েছে। মাগরিবের ওয়াক্ত হয়ে গেছে।'
          : 'The sun has set. It is now Maghrib time.',
      scheduledTime: times.maghrib,
    );

    // ── সেহরি শেষ হওয়ার আগাম সতর্কতা (৩০ মিনিট আগে) ──
    final sehriWarning = times.fajr.subtract(const Duration(minutes: 30));
    await _scheduleNotification(
      id: id++,
      title: isBn ? '🍽️ সেহরির সময় শেষ হতে ৩০ মিনিট বাকি' : '🍽️ 30 minutes left for Sehri',
      body: isBn
          ? 'সেহরির শেষ সময়: ${_fmt(times.fajr)}। তাড়াতাড়ি সেহরি করুন।'
          : 'Sehri ends at: ${_fmt(times.fajr)}. Please hurry.',
      scheduledTime: sehriWarning,
    );

    // ── সেহরি শেষ (ফজরের ওয়াক্ত শুরু) ──
    await _scheduleNotification(
      id: id++,
      title: isBn ? '⏰ সাহরি শেষ' : '⏰ Sehri has ended',
      body: isBn
          ? 'সাহরির সময় শেষ! এখন রোজা শুরু করার সময়।'
          : 'Sehri time has ended! It is now time to start the fast.',
      scheduledTime: times.fajr,
    );

    // ── ইফতার (মাগরিব) ──
    await _scheduleNotification(
      id: id++,
      title: isBn ? '🌙 ইফতারের সময়' : '🌙 Iftar time',
      body: isBn
          ? 'মাগরিবের ওয়াক্ত হয়েছে। ইফতার করুন।'
          : 'It is now Maghrib time. Please break your fast.',
      scheduledTime: times.maghrib,
    );

    // ── তাহাজ্জুদ: এশা থেকে ফজর পর্যন্ত মোট সময়ের ২/৩ পার হলে শুরু ──
    final ishaTime = times.isha;
    final fajrNext = times.fajr.isBefore(ishaTime)
        ? times.fajr.add(const Duration(days: 1))
        : times.fajr;
    final totalNightMinutes = fajrNext.difference(ishaTime).inMinutes;
    final tahajjudStart = ishaTime.add(Duration(minutes: (totalNightMinutes * 2 ~/ 3)));
    await _scheduleNotification(
      id: id++,
      title: isBn ? '🌙 তাহাজ্জুদের সময় শুরু' : '🌙 Tahajjud time has started',
      body: isBn
          ? 'এখন রাতের শেষ তৃতীয়াংশ। তাহাজ্জুদ নামাজ পড়ুন — দোয়া কবুলের সর্বোত্তম সময়।'
          : 'It is now the last third of the night. Pray Tahajjud — the best time for dua to be accepted.',
      scheduledTime: tahajjudStart,
    );

    return id;
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    // এখানে ইচ্ছাকৃতভাবে কাস্টম RawResourceAndroidNotificationSound
    // ব্যবহার করা হয়নি — এই প্রজেক্টে android/app/src/main/res/raw/
    // ফোল্ডারে কোনো সাউন্ড ফাইল নেই, কাস্টম সাউন্ড রেফার করলে সেই
    // ফাইল না পেলে notification নিঃশব্দে ব্যর্থ হতে পারে। null মানে
    // সিস্টেমের ডিফল্ট notification সাউন্ড ব্যবহার হবে, যেটা সবসময়
    // নিরাপদে কাজ করে। কাস্টম আজানের টোন (mp3) যোগ করতে চাইলে সেটা
    // android/app/src/main/res/raw/notification.mp3 (শুধু ছোট হাতের
    // অক্ষর, এক্সটেনশন ছাড়া নাম android resource আইডি হিসেবে ব্যবহার
    // হবে) হিসেবে রেখে RawResourceAndroidNotificationSound('notification')
    // আবার বসিয়ে দেওয়া যাবে।
    final androidDetails = AndroidNotificationDetails(
      'moni_prayer_channel',
      'MONI PRAYER',
      channelDescription: 'নামাজের সময় ও অনুস্মারক',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      category: AndroidNotificationCategory.alarm,
      // lock screen-এ (ফোন বন্ধ/lock থাকা অবস্থায়) পুরো বিষয়বস্তু
      // সহ দেখানোর জন্য — private/secret দিলে lock screen-এ টাইটেল/
      // বডি লুকিয়ে "একটা notification আছে" মতো দেখাত।
      visibility: NotificationVisibility.public,
      // fullScreenIntent সাধারণত অ্যালার্ম/কল-এর মতো একদম স্ক্রিনের
      // উপর পপ-আপ করে দেখানোর জন্য — ফোন lock করা থাকলেও উপরে ভেসে
      // উঠবে (স্ক্রিনশটে যেমন "সাহরি শেষ" ডায়ালগ-বক্স আকারে ভেসে
      // উঠেছে সেরকম আচরণের কাছাকাছি)।
      fullScreenIntent: true,
      ticker: title,
    );

    final details = NotificationDetails(android: androidDetails);

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
