import 'package:shared_preferences/shared_preferences.dart';

/// ১২ ঘণ্টা (am/pm সহ) নাকি ২৪ ঘণ্টা ফরম্যাটে সময় দেখানো হবে — এই
/// পছন্দটা অ্যাপ জুড়ে (ক্লক কার্ড, নামাজের সময়, হোমস্ক্রিন widget)
/// ব্যবহারের জন্য একটা সাধারণ in-memory holder। main() এ অ্যাপ শুরু
/// হওয়ার সময় synchronously লোড হয়, আর Settings screen থেকে বদলালে
/// সাথে সাথে আপডেট হয় — তাই প্রতিটা format কল আলাদা করে async prefs
/// read করার দরকার নেই।
class TimeFormatPrefs {
  static bool use24Hour = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    use24Hour = prefs.getBool('time_format_24h') ?? false;
  }

  static Future<void> setUse24Hour(bool value) async {
    use24Hour = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('time_format_24h', value);
  }
}
