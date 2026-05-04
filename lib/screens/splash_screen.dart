import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
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
