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

  /// ব্যানারের মূল অংশে চাপলে কল হয় — একটা বিস্তারিত মিনি-প্লেয়ার
  /// bottom sheet খোলে (progress bar, play/pause), কুরআন টেক্সট পেজে না
  /// গিয়েই। প্লেয়ার নিজেই "কুরআনে দেখুন" বাটন দিয়ে টেক্সট পেজেও যেতে দেয়।
  void _openExpandedPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ExpandedQuranPlayer(
        isBn: _lang == 'bn',
        onOpenInQuranScreen: (info) {
          Navigator.pop(sheetContext);
          _openNowPlayingInQuranScreen(info);
        },
      ),
    );
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
      // দেখা যাবে। ব্যানারে চাপলে বিস্তারিত মিনি-প্লেয়ার খোলে, আর বই-আইকনে
      // চাপলে সরাসরি চলমান আয়াতের টেক্সট পেজে চলে যায়। কুরআন
      // সূরা-বিস্তারিত স্ক্রিন নিজেই খোলা থাকলে ব্যানার দেখানো হয় না,
      // কারণ ওই স্ক্রিনের নিজস্ব প্লে-বার এমনিতেই দেখা যায়।
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
                    return Builder(
                      builder: (bannerContext) => _NowPlayingBanner(
                        info: info,
                        isBn: _lang == 'bn',
                        onTap: () => _openExpandedPlayer(bannerContext),
                        onOpenInQuranScreen: () => _openNowPlayingInQuranScreen(info),
                        onPause: () => QuranAudioHelper.pause(),
                        onResume: () => QuranAudioHelper.resume(),
                      ),
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
/// SafeArea-এর নিচে বসানো থাকে যাতে কোনো স্ক্রিনের নিজস্ব bottom bar/nav-এর
/// সাথে ওভারল্যাপ না করে এবং সব ডিভাইসে দৃশ্যমান থাকে।
class _NowPlayingBanner extends StatelessWidget {
  final QuranNowPlaying info;
  final bool isBn;
  final VoidCallback onTap;
  final VoidCallback onOpenInQuranScreen;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _NowPlayingBanner({
    required this.info,
    required this.isBn,
    required this.onTap,
    required this.onOpenInQuranScreen,
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
                    // বই-আইকনে আলাদাভাবে চাপলে সরাসরি কুরআন টেক্সট পেজে
                    // (চলমান আয়াতে) চলে যায় — ব্যানারের বাকি অংশে চাপলে
                    // বিস্তারিত মিনি-প্লেয়ার খোলে।
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onOpenInQuranScreen,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
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

/// পূর্ণাঙ্গ, বিস্তারিত মিনি-প্লেয়ার — ব্যানারে চাপলে bottom sheet হিসেবে
/// খোলে। progress bar, play/pause, এবং কুরআন টেক্সট পেজে যাওয়ার শর্টকাট
/// দেখায়। Previous/Next/Sleep-timer-এর মতো আয়াত-নির্ভর নিয়ন্ত্রণ এখানে
/// রাখা হয়নি, কারণ সেগুলোর জন্য কুরআন টেক্সট স্ক্রিনের নিজস্ব অবস্থা
/// (কোন আয়াত, কোন সূরা তালিকা) দরকার — সেটা এখান থেকে নিরাপদে দখল করা
/// সম্ভব না; বদলে "কুরআনে দেখুন" বাটন দিয়ে সরাসরি সেখানে পাঠানো হয়।
class _ExpandedQuranPlayer extends StatefulWidget {
  final bool isBn;
  final void Function(QuranNowPlaying info) onOpenInQuranScreen;
  const _ExpandedQuranPlayer({required this.isBn, required this.onOpenInQuranScreen});

  @override
  State<_ExpandedQuranPlayer> createState() => _ExpandedQuranPlayerState();
}

class _ExpandedQuranPlayerState extends State<_ExpandedQuranPlayer> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Material(
          color: AppTheme.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ValueListenableBuilder<QuranNowPlaying?>(
              valueListenable: QuranAudioHelper.nowPlaying,
              builder: (context, info, _) {
                if (info == null) {
                  // প্লেব্যাক ইতিমধ্যে থেমে গেছে (উদাহরণ: শেষ সূরা শেষ হয়ে
                  // গেছে) — শিট বন্ধ করে দেওয়া হচ্ছে।
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  });
                  return const SizedBox(height: 100);
                }
                final subtitle = info.ayaNumber != null
                    ? '${widget.isBn ? 'আয়াত' : 'Aya'} ${info.ayaNumber}'
                    : (widget.isBn ? 'বিসমিল্লাহ' : 'Bismillah');
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 48),
                    const SizedBox(height: 14),
                    Text(
                      info.suraName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _PlayerProgressBar(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.gold.withOpacity(0.15),
                            border: Border.all(color: AppTheme.gold, width: 1.6),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: info.isPaused
                                  ? () => QuranAudioHelper.resume()
                                  : () => QuranAudioHelper.pause(),
                              child: Icon(
                                info.isPaused ? Icons.play_arrow : Icons.pause,
                                color: AppTheme.gold,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onOpenInQuranScreen(info),
                        icon: const Icon(Icons.menu_book_outlined, color: AppTheme.gold),
                        label: Text(
                          widget.isBn ? 'কুরআনে দেখুন' : 'Open in Quran',
                          style: const TextStyle(color: AppTheme.gold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.gold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// audio_service প্লেয়ারের positionStream শুনে একটা লাইভ progress bar
/// দেখায় — সময়ও (mm:ss / mm:ss) দেখায়।
class _PlayerProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stream = QuranAudioHelper.positionStream;
    if (stream == null) {
      return const SizedBox(height: 24);
    }
    return StreamBuilder<Duration>(
      stream: stream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = QuranAudioHelper.currentDuration ?? Duration.zero;
        final total = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
        final progress = (position.inMilliseconds / total).clamp(0.0, 1.0);
        String fmt(Duration d) {
          final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
          final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
          return '$m:$s';
        }

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppTheme.gold,
                inactiveTrackColor: AppTheme.gold.withOpacity(0.2),
                thumbColor: AppTheme.gold,
              ),
              child: Slider(
                value: progress,
                onChanged: duration.inMilliseconds > 0
                    ? (v) {
                        QuranAudioHelper.seekTo(
                          Duration(milliseconds: (v * total).round()),
                        );
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmt(position), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(fmt(duration), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
