import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<List<double>> _getCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLat = prefs.getDouble('lat');
    final savedLng = prefs.getDouble('lng');
    if (savedLat != null && savedLng != null) {
      return [savedLat, savedLng];
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return [defaultLat, defaultLng];
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return [defaultLat, defaultLng];
      }
      if (permission == LocationPermission.deniedForever) return [defaultLat, defaultLng];
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      await prefs.setDouble('lat', position.latitude);
      await prefs.setDouble('lng', position.longitude);
      return [position.latitude, position.longitude];
    } catch (_) {
      return [defaultLat, defaultLng];
    }
  }

  static Future<void> refreshLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lat');
    await prefs.remove('lng');
    await _getCoordinates();
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
