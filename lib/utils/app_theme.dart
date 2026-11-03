import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// অ্যাপের রঙ ও থিম।
///
/// ডার্ক/লাইট মোড সাপোর্টের জন্য যে রঙগুলো মোড অনুযায়ী পাল্টায় সেগুলো এখন
/// `static const`-এর বদলে `static Color get` (getter)। [isDark] ফ্ল্যাগটা
/// main.dart থেকে সেট হয় (সেটিংসে নির্বাচিত মোড অনুযায়ী)। সবুজ/লাল/হলুদ
/// ধরনের স্ট্যাটাস রঙ দুই মোডেই একই থাকে, তাই সেগুলো const-ই আছে।
class AppTheme {
  /// true = ডার্ক মোড (ডিফল্ট — আগের মতোই), false = লাইট মোড
  static bool isDark = true;

  // ── দুই মোডেই একই রঙ ──
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color accent = Color(0xFF4CAF50);
  static const Color missed = Color(0xFFE53935);
  static const Color pending = Color(0xFFFDD835);
  static const Color completed = Color(0xFF43A047);

  // ── সবসময় গাঢ় ব্যাকগ্রাউন্ডের কার্ডের (যেমন হোমের ঘড়ি কার্ড) ভেতরের লেখার রঙ ──
  // ঘড়ি কার্ডের ব্যাকগ্রাউন্ড লাইট মোডেও গাঢ় সবুজ-কালো থাকে, তাই এর ভেতরের
  // লেখা দুই মোডেই উজ্জ্বল (সাদা/সোনালি) থাকতে হবে। এগুলো মোডের সাথে পাল্টায় না।
  static const Color heroText = Color(0xFFEEEEEE);
  static const Color heroGold = Color(0xFFFFD700);

  // ── মোড অনুযায়ী পাল্টায় ──
  /// হলুদ (pending) রঙ — লাইট মোডে সাদা ব্যাকগ্রাউন্ডে পড়া যায় এমন গাঢ় সোনালি
  static Color get pendingText => isDark ? pending : const Color(0xFF9A6B00);
  /// সবুজ ডিফল্ট-মুক্ত টেবিল হেডারের ব্যাকগ্রাউন্ড (লাইট মোডে গাঢ় সবুজ, যাতে সোনালি লেখা ফোটে)
  static Color get tableHeaderBg => isDark ? primary.withOpacity(0.4) : primary;
  static Color get gold => isDark ? const Color(0xFFFFD700) : const Color(0xFFB8860B);
  static Color get background => isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F5F2);
  static Color get surface => isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  static Color get cardBg => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  static Color get textPrimary => isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1B1B1B);
  static Color get textSecondary => isDark ? const Color(0xFF9E9E9E) : const Color(0xFF616161);
  static Color get friday => isDark ? const Color(0xFF1A3A1A) : const Color(0xFFDDEFDD);
  static Color get saturday => isDark ? const Color(0xFF1A2A3A) : const Color(0xFFDCE8F4);

  /// ডিভাইডার/বর্ডারের হালকা রেখা (আগে Colors.white12 / white10 / white24)
  static Color get divider => isDark ? Colors.white12 : Colors.black12;
  static Color get divider10 => isDark ? Colors.white10 : const Color(0x0F000000);
  static Color get divider24 => isDark ? Colors.white24 : Colors.black26;

  /// কার্ডের ভেতরের ছোট আইকন/লেখার নরম রঙ (আগে Colors.white54 / white70)
  static Color get soft => isDark ? Colors.white54 : Colors.black54;
  static Color get softer => isDark ? Colors.white70 : Colors.black87;

  /// টেক্সটফিল্ডের ভেতরের ব্যাকগ্রাউন্ড (আগে Colors.black26)
  static Color get fieldFill => isDark ? Colors.black26 : const Color(0x14000000);

  /// হালকা ওভারলে টিন্টের ভিত্তি রঙ (আগে Colors.white.withOpacity(..))
  static Color get overlay => isDark ? Colors.white : Colors.black;

  /// লেখা/আইকনের রঙ লাইট মোডে সাদা ব্যাকগ্রাউন্ডে পড়ার উপযোগী করে দেয়।
  /// ডার্ক মোডে রঙ অপরিবর্তিত থাকে। উজ্জ্বল রঙ (হলুদ, হালকা সবুজ ইত্যাদি) লাইট
  /// মোডে একই হিউ রেখে গাঢ় করা হয়, যাতে কনট্রাস্ট ভালো থাকে।
  static Color readable(Color c) {
    if (isDark) return c;
    if (c.computeLuminance() <= 0.22) return c;
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * 0.62).clamp(0.0, 0.34)).withSaturation((hsl.saturation).clamp(0.0, 1.0)).toColor();
  }

  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  /// ভাষা অনুযায়ী থিম। [bn] true হলে সব অংক (০-৯ এবং 0-9) BanglaNum (Atma) ফন্টে আসে।
  static ThemeData themeFor(Brightness b, {required bool bn}) => _build(b, bn: bn);

  // BanglaNum কে প্রথম ফন্ট বানানো হয়েছে; ওতে শুধু অংক আর ':' '-' আছে, তাই
  // বাকি সব লেখা পরের ফন্ট (Noto Sans) থেকেই আসে — আগের মতোই।
  static TextStyle? _bnStyle(TextStyle? s) => s == null
      ? null
      : s.copyWith(
          fontFamily: 'BanglaNum',
          fontFamilyFallback: [if (s.fontFamily != null) s.fontFamily!],
        );

  static TextTheme _bnTextTheme(TextTheme t) => TextTheme(
        displayLarge: _bnStyle(t.displayLarge),
        displayMedium: _bnStyle(t.displayMedium),
        displaySmall: _bnStyle(t.displaySmall),
        headlineLarge: _bnStyle(t.headlineLarge),
        headlineMedium: _bnStyle(t.headlineMedium),
        headlineSmall: _bnStyle(t.headlineSmall),
        titleLarge: _bnStyle(t.titleLarge),
        titleMedium: _bnStyle(t.titleMedium),
        titleSmall: _bnStyle(t.titleSmall),
        bodyLarge: _bnStyle(t.bodyLarge),
        bodyMedium: _bnStyle(t.bodyMedium),
        bodySmall: _bnStyle(t.bodySmall),
        labelLarge: _bnStyle(t.labelLarge),
        labelMedium: _bnStyle(t.labelMedium),
        labelSmall: _bnStyle(t.labelSmall),
      );

  static ThemeData _build(Brightness b, {bool bn = false}) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F5F2);
    final sf = dark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
    final card = dark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
    final titleColor = dark ? const Color(0xFFFFD700) : const Color(0xFF8A6508);
    final base = dark ? ThemeData.dark() : ThemeData.light();

    return ThemeData(
      brightness: b,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      canvasColor: bg,
      dividerColor: dark ? Colors.white12 : Colors.black12,
      colorScheme: dark
          ? ColorScheme.dark(primary: primary, secondary: accent, surface: sf, background: bg)
          : ColorScheme.light(primary: primary, secondary: accent, surface: sf, background: bg),
      textTheme: bn
          ? _bnTextTheme(GoogleFonts.notoSansTextTheme(base.textTheme))
          : GoogleFonts.notoSansTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: sf,
        foregroundColor: dark ? Colors.white : const Color(0xFF1B1B1B),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: dark ? 4 : 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: sf,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark ? primary : const Color(0xFFC8E6C9),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
              color: states.contains(WidgetState.selected)
                  ? (dark ? Colors.white : primary)
                  : (dark ? const Color(0xFF9E9E9E) : const Color(0xFF616161)),
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? (dark ? Colors.white : primary)
                  : (dark ? const Color(0xFF9E9E9E) : const Color(0xFF616161)),
            )),
      ),
      dialogTheme: DialogThemeData(backgroundColor: card, surfaceTintColor: Colors.transparent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
