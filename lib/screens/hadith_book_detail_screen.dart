import 'package:flutter/material.dart';
import '../data/hadith_books_data.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import 'hadith_books_screen.dart' show HexBadge;

/// একটি বইয়ের ভেতরের পাতা — এখন শুধু কাঠামো।
/// বইয়ের অধ্যায়/হাদিসের তালিকা পরে এখানে যোগ হবে।
class HadithBookDetailScreen extends StatelessWidget {
  final HadithBook book;
  final AppLanguage lang;
  const HadithBookDetailScreen({super.key, required this.book, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HexBadge(text: book.badge, color: book.color, size: 84),
              const SizedBox(height: 16),
              Text(book.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(book.author,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 6),
              Text('${lang.toLocalNum(book.count)} ${isBn ? 'হাদিস' : 'Hadith'}',
                  style: TextStyle(color: AppTheme.gold, fontSize: 14)),
              const SizedBox(height: 24),
              Text(
                isBn ? 'হাদিস শীঘ্রই যোগ করা হবে' : 'Hadith will be added soon',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
