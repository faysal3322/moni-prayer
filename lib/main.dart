import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_language.dart';
import 'utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await NotificationHelper.init();
  await NotificationHelper.requestPermission();
  await NotificationHelper.schedulePrayerNotifications();

  final prefs = await SharedPreferences.getInstance();
  final String lang = prefs.getString('language') ?? 'bn';
  final String userName = prefs.getString('user_name') ?? 'FAYSAL';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const SplashScreen(),
    );
  }
}
