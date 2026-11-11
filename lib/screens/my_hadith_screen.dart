import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

/// আমার হাদিস — ব্যবহারকারীর সংরক্ষিত/পছন্দের হাদিস (পরে যোগ হবে)।
class MyHadithScreen extends StatelessWidget {
  final AppLanguage lang;
  const MyHadithScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    return Scaffold(
      appBar: AppBar(title: Text(isBn ? 'আমার হাদিস' : 'My Hadith')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 12),
              Text(
                isBn ? 'এখনো কোনো হাদিস সংরক্ষণ করা হয়নি' : 'No saved hadith yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
