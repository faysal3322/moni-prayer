import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'time_format_prefs.dart';

class PrayerTimeHelper {
  static const double defaultLat = 23.8103;
  static const double defaultLng = 90.4125;

  static Future<PrayerTimes> getPrayerTimes({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final coords = await _getCoordinates();
    final myCoordinates = Coordinates(coords[0], coords[1]);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    final dateComponents = DateComponents.from(targetDate);
    return PrayerTimes(myCoordinates, dateComponents, params);
  }

  // ফিক্স: আগে GPS ব্যর্থ হলে (timeout, সাময়িক service glitch, ইত্যাদি)
  // সরাসরি ঢাকার কোঅর্ডিনেট (defaultLat/defaultLng) ব্যবহার হতো — কোনো
  // সতর্কতা বা cache ছাড়াই। ব্যবহারকারী ভেলোরে থেকেও ঢাকার হিসাবে নামাজের
  // সময় পাচ্ছিলেন, যা বাস্তব লোকেশনের সাথে না মিলে বড় গরমিল তৈরি করছিল।
  //
  // এখন crash/timeout হলে সবার আগে শেষবার সফলভাবে পাওয়া GPS লোকেশন
  // (SharedPreferences-এ cache করা) ব্যবহার করা হয় — যেহেতু ব্যবহারকারী
  // সচরাচর একই শহর/এলাকায় থাকেন, এই cache প্রায় সবসময়ই সঠিক এবং
  // ঢাকার ডিফল্টের চেয়ে বহুগুণ নির্ভরযোগ্য। GPS সফল হলে নতুন cache
  // সেভ হয়ে যায়। শুধুমাত্র প্রথমবার (কোনো cache-ই নেই) এবং GPS-ও
  // ব্যর্থ হলে তখনই ঢাকার ডিফল্ট ব্যবহার হয়।
  static Future<List<double>> _getCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLat = prefs.getDouble('lat');
    final cachedLng = prefs.getDouble('lng');

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallback(cachedLat, cachedLng);
      }

      final permission = await ensureLocationPermissionAskedOnce();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return _fallback(cachedLat, cachedLng);
      }

      // ফিক্স ("লোকেশন চালু করুন — No thanks" ডায়ালগ বারবার আসা): geolocator
      // ডিফল্টে Google Play Services (Fused provider) ব্যবহার করে, আর
      // লোকেশন বন্ধ/সীমিত থাকলে Google-এর নিজস্ব "আরও সঠিক লোকেশনের জন্য
      // লোকেশন চালু করুন" সিস্টেম ডায়ালগ (বাটন: No thanks / OK) তুলে ধরে —
      // "No thanks" দিলেও পরের চেষ্টায় আবার আসে। forceAndroidLocationManager:true
      // দিলে Android-এর সাধারণ LocationManager ব্যবহার হয়, যা কখনোই ওই
      // ডায়ালগ দেখায় না; লোকেশন না পেলে শুধু ব্যতিক্রম ছোড়ে, যা নিচের
      // catch চুপচাপ সামলে cache-এ ফিরে যায়।
      // (geolocator ^11-এ এই প্যারামিটারগুলোই সমর্থিত — locationSettings/
      // AndroidSettings ভার্সন ১৩+ এর জন্য এবং আলাদা geolocator_android
      // ইমপোর্ট লাগে, তাই এখানে ব্যবহার করা হয়নি।)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 15),
      );

      // GPS সফল — cache আপডেট করা হচ্ছে পরবর্তী কোনো ব্যর্থতার জন্য
      await prefs.setDouble('lat', position.latitude);
      await prefs.setDouble('lng', position.longitude);

      return [position.latitude, position.longitude];
    } catch (_) {
      return _fallback(cachedLat, cachedLng);
    }
  }

  // ফিক্স (লোকেশন পারমিশন ডায়ালগ বারবার আসা): আগে প্রতিবার লোকেশন দরকার
  // হলে (অ্যাপ খোলা, প্রতি ১৫ মিনিটের টাইমার, অ্যাপে ফিরে আসা, নোটিফিকেশন
  // শিডিউল, নামাজের সময় হিসাব ইত্যাদি) পারমিশন denied থাকলে
  // Geolocator.requestPermission() আবার আবার কল হতো — তাই Android-এর
  // "লোকেশন অনুমতি দিন" ডায়ালগ ব্যবহারকারী "না" বললেও বারবার ফিরে আসত।
  // ব্যবহারকারী লোকেশন না দিতে চাইলে সেটা তাঁর অধিকার — অ্যাপ জোর করবে না।
  //
  // এখন পারমিশন-ডায়ালগ পুরো ইনস্টলে সর্বোচ্চ *একবার* (এবং একবার "না"
  // বললে আর কখনোই স্বয়ংক্রিয়ভাবে না) দেখানো হয়। এর পরে লোকেশন না পেলে
  // অ্যাপ চুপচাপ শেষবারের cache করা লোকেশন (বা ঢাকার ডিফল্ট) দিয়ে চলে।
  // ব্যবহারকারী পরে নিজে চাইলে ফোনের সেটিংস থেকে অনুমতি দিতে পারেন।
  static const String _kAskedPermissionKey = 'location_permission_asked_once';
  static bool _askedThisSession = false;

  static Future<LocationPermission> ensureLocationPermissionAskedOnce() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.denied) return permission;

    // denied অবস্থা: আগে কখনো জিজ্ঞাসা করা হয়েছে কিনা দেখা হচ্ছে।
    if (_askedThisSession) return permission;
    final prefs = await SharedPreferences.getInstance();
    final askedBefore = prefs.getBool(_kAskedPermissionKey) ?? false;
    if (askedBefore) return permission;

    _askedThisSession = true;
    await prefs.setBool(_kAskedPermissionKey, true);
    return await Geolocator.requestPermission();
  }

  // GPS ব্যর্থ হলে: cache থাকলে cache ব্যবহার করা (সঠিক তথ্যের সবচেয়ে
  // কাছাকাছি), না থাকলে (একদম প্রথমবার অ্যাপ ব্যবহারে GPS-ও fail করলে)
  // ঢাকার ডিফল্ট কোঅর্ডিনেট।
  static List<double> _fallback(double? cachedLat, double? cachedLng) {
    if (cachedLat != null && cachedLng != null) {
      return [cachedLat, cachedLng];
    }
    return [defaultLat, defaultLng];
  }

  static Future<void> refreshLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lat');
    await prefs.remove('lng');
  }

  static Map<String, DateTime> getPrayerTimesMap(PrayerTimes times) {
    return {
      'fajr': times.fajr,
      'dhuhr': times.dhuhr,
      'asr': times.asr,
      'maghrib': times.maghrib,
      'isha': times.isha,
    };
  }

  static String? getNextPrayer(PrayerTimes times) {
    final now = DateTime.now();
    final map = getPrayerTimesMap(times);
    for (final entry in map.entries) {
      if (now.isBefore(entry.value)) return entry.key;
    }
    return null;
  }

  static Duration? getTimeToNextPrayer(PrayerTimes times) {
    final now = DateTime.now();
    final map = getPrayerTimesMap(times);
    for (final entry in map.entries) {
      if (now.isBefore(entry.value)) return entry.value.difference(now);
    }
    return null;
  }

  static String formatTime(DateTime time) {
    if (TimeFormatPrefs.use24Hour) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute $period';
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
