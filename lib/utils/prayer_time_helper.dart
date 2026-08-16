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

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallback(cachedLat, cachedLng);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return _fallback(cachedLat, cachedLng);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
