import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import 'hadith_books_screen.dart';
import 'hadith_subject_screen.dart';
import 'my_hadith_screen.dart';

/// হাদিস ফোল্ডার — প্রথমে তিনটি অপশন:
///   ১. হাদিসের বই   ২. বিষয়ভিত্তিক হাদিস   ৩. আমার হাদিস
class HadithScreen extends StatelessWidget {
  final AppLanguage lang;
  const HadithScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;

    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: Text(isBn ? 'হাদিস' : 'Hadith')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _OptionCard(
            icon: Icons.auto_stories,
            gradient: const [Color(0xFFFF8F00), Color(0xFFE65100)],
            title: isBn ? 'হাদিসের বই' : 'Hadith Books',
            subtitle: isBn ? 'বুখারী, মুসলিম সহ সব কিতাব' : 'Bukhari, Muslim and more',
            onTap: () => open(HadithBooksScreen(lang: lang)),
          ),
          _OptionCard(
            icon: Icons.category,
            gradient: const [Color(0xFF26A69A), Color(0xFF00695C)],
            title: isBn ? 'বিষয়ভিত্তিক হাদিস' : 'Hadith by Topic',
            subtitle: isBn ? 'বিষয় অনুযায়ী হাদিস খুঁজুন' : 'Browse hadith by subject',
            onTap: () => open(HadithSubjectScreen(lang: lang)),
          ),
          _OptionCard(
            icon: Icons.bookmark,
            gradient: const [Color(0xFF7E57C2), Color(0xFF4527A0)],
            title: isBn ? 'আমার হাদিস' : 'My Hadith',
            subtitle: isBn ? 'আপনার সংরক্ষিত হাদিস' : 'Your saved hadith',
            onTap: () => open(MyHadithScreen(lang: lang)),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
