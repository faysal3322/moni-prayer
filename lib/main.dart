import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/surah_detail_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_language.dart';
import 'utils/quran_audio_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final String lang = prefs.getString('language') ?? 'bn';
  final String userName = prefs.getString('user_name') ?? 'FAYSAL';

  // Create the Recitations folder right away so it exists on the device
  // as soon as the app is installed and opened — even before the user
  // plays or downloads any Quran audio. This lets the user manually copy
  // recitation files into it via a file manager.
  // Runs in the background; doesn't block app startup if it's slow.
  QuranAudioHelper.ensureAudioDirExists();

  runApp(MoniPrayerApp(initialLang: lang, userName: userName));
}

class MoniPrayerApp extends StatefulWidget {
  final String initialLang;
  final String userName;
  const MoniPrayerApp({super.key, required this.initialLang, required this.userName});

  static _MoniPrayerAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MoniPrayerAppState>();

  @override
  State<MoniPrayerApp> createState() => _MoniPrayerAppState();
}

class _MoniPrayerAppState extends State<MoniPrayerApp> {
  late String _lang;
  late String _userName;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _lang = widget.initialLang;
    _userName = widget.userName;
  }

  void setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _lang = lang);
  }

  void setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() => _userName = name);
  }

  String get language => _lang;
  String get userName => _userName;

  /// "এখন তেলাওয়াত হচ্ছে" ব্যানারে চাপলে কল হয় — root navigator দিয়ে
  /// সরাসরি সেই সূরার সেই আয়াতে খুলে দেয়, ব্যবহারকারী তখন অ্যাপের
  /// যে-কোনো স্ক্রিনেই থাকুক না কেন।
  void _openNowPlaying(QuranNowPlaying info) {
    _navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => SurahDetailScreen(
        lang: AppLanguage(_lang),
        sura: info.sura,
        jumpToAyaNumber: info.ayaNumber,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'MONI PRAYER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: Locale(_lang),
      supportedLocales: const [Locale('bn'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // প্রতিটা স্ক্রিনের উপরে একটা persistent "এখন তেলাওয়াত হচ্ছে" ব্যানার
      // overlay করা হচ্ছে — কুরআন স্ক্রিন থেকে অন্য কোথাও চলে গেলেও এটা
      // দেখা যাবে, এবং চাপলে সরাসরি চলমান আয়াতে ফিরিয়ে নিয়ে যাবে।
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            ValueListenableBuilder<QuranNowPlaying?>(
              valueListenable: QuranAudioHelper.nowPlaying,
              builder: (context, info, _) {
                if (info == null) return const SizedBox.shrink();
                return _NowPlayingBanner(
                  info: info,
                  isBn: _lang == 'bn',
                  onTap: () => _openNowPlaying(info),
                  onPause: () => QuranAudioHelper.pause(),
                  onResume: () => QuranAudioHelper.resume(),
                );
              },
            ),
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// অ্যাপের যেকোনো স্ক্রিনের নিচে ভাসমান "এখন তেলাওয়াত হচ্ছে" ব্যানার।
/// SafeArea-এর নিচে বসানো থাকে যাতে কোনো স্ক্রিনের নিজস্ব bottom bar/nav-এর
/// সাথে ওভারল্যাপ না করে এবং সব ডিভাইসে দৃশ্যমান থাকে।
class _NowPlayingBanner extends StatelessWidget {
  final QuranNowPlaying info;
  final bool isBn;
  final VoidCallback onTap;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _NowPlayingBanner({
    required this.info,
    required this.isBn,
    required this.onTap,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = info.ayaNumber != null
        ? '${isBn ? 'আয়াত' : 'Aya'} ${info.ayaNumber}'
        : (isBn ? 'বিসমিল্লাহ' : 'Bismillah');
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Material(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(14),
            elevation: 6,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${isBn ? 'তেলাওয়াত হচ্ছে' : 'Playing'}: ${info.suraName} — $subtitle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: info.isPaused ? onResume : onPause,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.4)),
                        ),
                        child: Icon(
                          info.isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
