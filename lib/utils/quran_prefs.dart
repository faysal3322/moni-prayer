import 'package:shared_preferences/shared_preferences.dart';

/// Stores user preferences for the Quran section only.
/// Completely separate keys from other app settings — no collision risk.
class QuranPrefs {
  static const _keyShowArabic = 'quran_show_arabic';
  static const _keyShowBangla = 'quran_show_bangla';
  static const _keyShowTransliteration = 'quran_show_transliteration';
  static const _keyFontSize = 'quran_font_size';

  // Default: Arabic + English transliteration on (Bangla text not available yet)
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
    return prefs.getBool(_keyShowTransliteration) ?? true;
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
}
