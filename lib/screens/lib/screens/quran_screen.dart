import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

class QuranScreen extends StatefulWidget {
  final AppLanguage lang;
  const QuranScreen({super.key, required this.lang});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'কোরআন' : 'Quran'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book, color: AppTheme.gold, size: 64),
              const SizedBox(height: 16),
              Text(
                isBn ? 'কোরআন সেকশন শীঘ্রই আসছে' : 'Quran section coming soon',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isBn
                    ? '১১৪টি সূরার তালিকা এখানে যুক্ত করা হবে।'
                    : 'All 114 Surahs will be added here.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
