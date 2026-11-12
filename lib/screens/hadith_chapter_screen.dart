import 'package:flutter/material.dart';
import '../data/hadith_books_data.dart';
import '../data/hadith_chapters_data.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

/// একটি অধ্যায়ের ভেতরের পাতা — এখন শুধু কাঠামো।
/// অধ্যায়ের ভেতরে কী দেখাবে সেটা পরে এখানে যোগ হবে।
class HadithChapterScreen extends StatelessWidget {
  final HadithBook book;
  final HadithChapter chapter;
  final AppLanguage lang;
  const HadithChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    return Scaffold(
      appBar: AppBar(title: Text(chapter.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(book.name,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                '${isBn ? 'অধ্যায়' : 'Chapter'} ${lang.toLocalNum(chapter.number)}',
                style: TextStyle(color: AppTheme.gold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(chapter.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '${isBn ? 'হাদিসের রেঞ্জ' : 'Hadith range'}: '
                '${lang.toLocalNum(chapter.from)} - ${lang.toLocalNum(chapter.to)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
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
