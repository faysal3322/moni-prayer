import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/quran_audio_helper.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ফিক্স: অ্যাপ ইন্সটল/প্রথম চালু করার সাথে সাথেই
    // /storage/emulated/0/Music/Recitations/... ফোল্ডার তৈরি হওয়ার
    // কথা ছিল, কিন্তু main()-এ (UI তৈরি হওয়ার আগে) কল করলে এর ভেতরের
    // পারমিশন-রিকোয়েস্ট নিঃশব্দে ব্যর্থ হয়ে যেত। এখানে (splash screen
    // দেখানোর সময়, UI ইতিমধ্যে প্রস্তুত) কল করলে পারমিশন ডায়ালগ/সেটিংস
    // স্ক্রিন ঠিকভাবে খোলে ও কাজ করে।
    QuranAudioHelper.ensureAudioDirExists();
    // একই কারণে (UI প্রস্তুত হওয়ার পরে পারমিশন-রিকোয়েস্ট নির্ভরযোগ্যভাবে
    // কাজ করে) — "নিজের দোয়া/অডিও" ফোল্ডারও এখানেই আগেভাগে তৈরি করা
    // হচ্ছে, যাতে ব্যবহারকারী চাইলে অ্যাপ খোলার পরপরই ফাইল ম্যানেজার
    // দিয়ে সরাসরি Music/Recitations/custom-duas/ ফোল্ডারে mp3 রেখে
    // দিতে পারেন, app-এর "+" বাটন ব্যবহার না করেও।
    QuranAudioHelper.ensureCustomDuaDirExists();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🕌',
                  style: TextStyle(fontSize: 60),
                ),
              ),
            ).animate().scale(duration: 600.ms),
            const SizedBox(height: 24),
            const Text(
              'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: TextStyle(fontSize: 22, color: AppTheme.gold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
            const SizedBox(height: 16),
            const Text(
              'MONI PRAYER',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.gold,
                letterSpacing: 4,
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
            const SizedBox(height: 8),
            const Text(
              'ইসলামিক প্রার্থনা ট্র্যাকার',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 2,
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
