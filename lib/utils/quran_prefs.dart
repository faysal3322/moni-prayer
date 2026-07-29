import 'package:shared_preferences/shared_preferences.dart';

/// Stores user preferences for the Quran section only.
/// Completely separate keys from other app settings — no collision risk.
class QuranPrefs {
  static const _keyShowArabic = 'quran_show_arabic';
  static const _keyShowBangla = 'quran_show_bangla';
  static const _keyShowTransliteration = 'quran_show_transliteration';
  static const _keyFontSize = 'quran_font_size';
  static const _keyViewMode = 'quran_view_mode'; // 'list' or 'page'
  static const _keyPlaybackSpeed = 'quran_playback_speed';

  // Default: Arabic on, English transliteration off, Bangla text off
  // (ব্যবহারকারীর অনুরোধে ইংরেজি উচ্চারণ এখন ডিফল্টে বন্ধ থাকে — আগে
  // এটা ভুলবশত ডিফল্টে চালু ছিল)।
  static Future<bool> getShowArabic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowArabic) ?? true;
  }

  static Future<void> setShowArabic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowArabic, value);
  }

  static Future<bool> getShowBangla() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowBangla) ?? false;
  }

  static Future<void> setShowBangla(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowBangla, value);
  }

  static Future<bool> getShowTransliteration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowTransliteration) ?? false;
  }

  static Future<void> setShowTransliteration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTransliteration, value);
  }

  /// Font size scale for Arabic text, in logical pixels (base size).
  /// Range: 18 (small) .. 40 (large). Default 24.
  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? 24.0;
  }

  static Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, value);
  }

  /// 'list' (card-by-card, with translation) or 'page' (mushaf-style flowing Arabic).
  static Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyViewMode) ?? 'list';
  }

  static Future<void> setViewMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyViewMode, value);
  }

  /// তেলাওয়াতের গতি (1.0 = স্বাভাবিক)। ডিফল্ট 1.0।
  static Future<double> getPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyPlaybackSpeed) ?? 1.0;
  }

  static Future<void> setPlaybackSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPlaybackSpeed, value);
  }
}
