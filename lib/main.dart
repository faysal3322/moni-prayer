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

/// বর্তমানে টপ-এ কোন রুট আছে তা ট্র্যাক করে, যাতে কুরআন সূরা-বিস্তারিত
/// স্ক্রিন নিজেই খোলা থাকা অবস্থায় persistent ব্যানার লুকিয়ে রাখা যায় —
/// ওই স্ক্রিনের নিজস্ব প্লে/পজ/পরের-আয়াত কন্ট্রোল থাকে, তাই ব্যানার
/// দেখালে সেগুলো ঢেকে ফেলে (আগে এই সমস্যাটাই হচ্ছিল)।
class _QuranScreenRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final ValueNotifier<bool> isQuranScreenOnTop = ValueNotifier(false);

  void _update(Route<dynamic>? route) {
    isQuranScreenOnTop.value = route?.settings.name == kSurahDetailRouteName;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }
}

class _MoniPrayerAppState extends State<MoniPrayerApp> {
  late String _lang;
  late String _userName;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _QuranScreenRouteObserver _routeObserver = _QuranScreenRouteObserver();

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

  /// "এখন তেলাওয়াত হচ্ছে" ব্যানারের বই-আইকনে চাপলে কল হয় — root navigator
  /// দিয়ে সরাসরি সেই সূরার সেই আয়াতে (কুরআন টেক্সট পেজে) খুলে দেয়,
  /// ব্যবহারকারী তখন অ্যাপের যে-কোনো স্ক্রিনেই থাকুক না কেন।
  void _openNowPlayingInQuranScreen(QuranNowPlaying info) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(MaterialPageRoute(
      settings: const RouteSettings(name: kSurahDetailRouteName),
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
      navigatorObservers: [_routeObserver],
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
      // দেখা যাবে। ব্যানারের যেকোনো জায়গায় (বই-আইকন সহ) চাপলে সরাসরি
      // চলমান আয়াতের টেক্সট পেজে চলে যায় — আলাদা মিনি-প্লেয়ার শিট আর
      // খোলা হয় না, কারণ সেটা একটা বাড়তি ধাপ তৈরি করছিল। কুরআন
      // সূরা-বিস্তারিত স্ক্রিন নিজেই খোলা থাকলে ব্যানার দেখানো হয় না,
      // কারণ ওই স্ক্রিনের নিজস্ব প্লে-বার এমনিতেই দেখা যায়।
      //
      // ব্যানারটা স্ক্রিনের একদম নিচে (Align bottomCenter) বসানো হতো
      // আগে, যেটা প্রতিটা স্ক্রিনের নিজস্ব bottomNavigationBar-এর ওপর
      // দিয়ে বসে গিয়ে সেটাকে ঢেকে ফেলছিল (bottomNavigationBar আসলে
      // এই Stack-এর নিচে, HomeScreen-এর নিজস্ব Scaffold-এর অংশ, তাই
      // top-level Stack-এ Align bottomCenter করলে সেটাই সবার উপরে
      // বসে যায়)। এখন নিচে একটা fixed padding দিয়ে ব্যানারটাকে
      // bottom nav bar-এর উচ্চতার (কমপক্ষে) উপরে তুলে দেওয়া হচ্ছে।
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            ValueListenableBuilder<bool>(
              valueListenable: _routeObserver.isQuranScreenOnTop,
              builder: (context, isOnQuranScreen, _) {
                if (isOnQuranScreen) return const SizedBox.shrink();
                return ValueListenableBuilder<QuranNowPlaying?>(
                  valueListenable: QuranAudioHelper.nowPlaying,
                  builder: (context, info, _) {
                    if (info == null) return const SizedBox.shrink();
                    return _NowPlayingBanner(
                      info: info,
                      isBn: _lang == 'bn',
                      onTap: () => _openNowPlayingInQuranScreen(info),
                      onPause: () => QuranAudioHelper.pause(),
                      onResume: () => QuranAudioHelper.resume(),
                    );
                  },
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
///
/// পুরো ব্যানারেই (প্লে/পজ বাটন ছাড়া) ট্যাপ করলে সরাসরি কুরআন টেক্সট
/// পেজে, চলমান আয়াতে চলে যায় — [onTap] কল হয়।
///
/// প্রতিটা স্ক্রিনের নিজস্ব bottomNavigationBar (HomeScreen-এ NavigationBar)
/// থাকে সেই স্ক্রিনের নিজের Scaffold-এর ভেতরে, কিন্তু এই ব্যানারটা
/// top-level MaterialApp.builder-এর Stack-এ বসানো, যেটা সব Scaffold-এর
/// উপরে থাকে। তাই আগে এটাকে স্ক্রিনের একদম নিচে (bottomCenter) বসালে
/// সেটা bottomNavigationBar-এর উপর দিয়ে বসে সেটাকে ঢেকে ফেলছিল। এখন
/// [kBottomNavBarHeight] পরিমাণ বাড়তি bottom padding দিয়ে ব্যানারটাকে
/// bottom nav bar-এর উপরে তুলে দেওয়া হয়েছে, যাতে দুটোই একসাথে দেখা যায়।
class _NowPlayingBanner extends StatelessWidget {
  /// Material 3 এর ডিফল্ট NavigationBar-এর উচ্চতা (৮০) — HomeScreen-এর
  /// bottomNavigationBar-এর সাথে মিলিয়ে রাখা হয়েছে, যাতে ব্যানারটা
  /// ঠিক তার উপরেই বসে, না বেশি উঁচুতে না ওভারল্যাপ করে।
  static const double kBottomNavBarHeight = 80;

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
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: kBottomNavBarHeight + 8,
          ),
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
                    const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // "key" না দিলেও Text স্বয়ংক্রিয়ভাবে rebuild হবে যখনই
                        // ValueListenableBuilder নতুন QuranNowPlaying পাবে —
                        // অর্থাৎ আয়াত নম্বর পাল্টালেই এই লেখা আপডেট হয়ে
                        // যাবে (আয়াত ১ → ২ → ৩ ... একের পর এক)।
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
                    // প্লে/পজ বাটনটা নিজস্ব InkWell দিয়ে ব্যানারের বাকি
                    // অংশের ট্যাপ থেকে আলাদা রাখা হয়েছে, যাতে এতে চাপলে
                    // পেজ পাল্টে না গিয়ে শুধু প্লে/পজ হয়।
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
