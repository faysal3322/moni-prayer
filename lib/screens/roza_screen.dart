import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../widgets/nafl_cards.dart';

/// হোমের "রোজা" ক্যাটাগরি — নফল রোজার ফজিলত ও নিষিদ্ধ রোজা।
class RozaScreen extends StatelessWidget {
  final AppLanguage lang;
  const RozaScreen({super.key, required this.lang});

  int _hijriDay(DateTime date) {
    try {
      final jd = _gjToJul(date.year, date.month, date.day);
      final l = jd - 1948440 + 10632;
      final n = (l - 1) ~/ 10631;
      final l2 = l - 10631 * n + 354;
      final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
          ((l2) ~/ 5670) * ((43 * l2) ~/ 15238);
      final l3 = l2 -
          ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
          ((j) ~/ 16) * ((15238 * j) ~/ 43) +
          29;
      final m = (24 * l3) ~/ 709;
      return l3 - (709 * m) ~/ 24;
    } catch (_) {
      return 0;
    }
  }

  int _gjToJul(int y, int m, int d) {
    int a = (14 - m) ~/ 12;
    int yr = y + 4800 - a;
    int mo = m + 12 * a - 3;
    return d +
        (153 * mo + 2) ~/ 5 +
        365 * yr +
        yr ~/ 4 -
        yr ~/ 100 +
        yr ~/ 400 -
        32045;
  }

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    return Scaffold(
      appBar: AppBar(title: Text(isBn ? 'রোজা' : 'Fasting')),
      body: _buildFastingTab(isBn, _hijriDay(DateTime.now())),
    );
  }

  // ══════════════════════════════════════════
  // নফল রোজার তথ্য
  Widget _buildFastingTab(bool isBn, int hijriDay) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        nflSectionHeader('🌙', isBn ? 'নফল রোজার ফজিলত' : 'Nafl Fasting Virtues', AppTheme.gold),
        const SizedBox(height: 10),
        FastCard(icon: '🌟', title: isBn ? 'আইয়ামে বিজ (প্রতি মাসে ৩ দিন)' : 'Ayyam al-Beed',
          dates: isBn ? 'প্রতি হিজরি মাসের ১৩, ১৪ ও ১৫ তারিখ' : '13th, 14th & 15th Hijri',
          desc: isBn ? '"রাসূল ﷺ প্রতি মাসের তিন রোজার অসিয়ত করেছেন।" — বুখারী\nফজিলত: পুরো মাস রোজার সওয়াব।' : '"The Prophet advised three fasts every month." — Bukhari',
          color: AppTheme.gold,
          alert: hijriDay >= 13 && hijriDay <= 15 ? (isBn ? '🎉 আজ আইয়ামে বিজের রোজার দিন!' : '🎉 Today is Ayyam al-Beed!') : null),
        FastCard(icon: '🏆', title: isBn ? 'শাওয়ালের ৬ রোজা' : '6 Fasts of Shawwal',
          dates: isBn ? 'শাওয়াল মাসে যেকোনো ৬ দিন' : 'Any 6 days in Shawwal',
          desc: isBn ? '"রমাদানের পর শাওয়ালে ৬টি রোজা রাখলে সারা বছর রোজা রাখার সওয়াব।" — সহিহ মুসলিম' : '"Fasting 6 days in Shawwal after Ramadan equals fasting the whole year." — Sahih Muslim',
          color: const Color(0xFF66BB6A)),
        FastCard(icon: '🕋', title: isBn ? 'আরাফার রোজা (৯ জুলহিজ্জাহ)' : 'Arafah Fast',
          dates: isBn ? 'জুলহিজ্জাহ মাসের ৯ তারিখ' : '9th of Dhul Hijjah',
          desc: isBn ? '"আরাফার রোজায় আগের ও পরের এক বছরের গুনাহ মাফ।" — সহিহ মুসলিম\n⚠️ হাজীদের জন্য নয়।' : '"Arafah fast expiates sins of previous and next year." — Sahih Muslim\n⚠️ Not for pilgrims.',
          color: const Color(0xFFFF8F00)),
        FastCard(icon: '📅', title: isBn ? 'আশুরার রোজা (১০ মুহাররম)' : 'Ashura Fast',
          dates: isBn ? '৯+১০ অথবা ১০+১১ মুহাররম' : '9+10 or 10+11 Muharram',
          desc: isBn ? '"আশুরার রোজায় আগের এক বছরের গুনাহ মাফ হয়।" — সহিহ মুসলিম' : '"Ashura fast expiates sins of previous year." — Sahih Muslim',
          color: const Color(0xFF26A69A)),
        FastCard(icon: '📅', title: isBn ? 'সোমবার ও বৃহস্পতিবার' : 'Monday & Thursday',
          dates: isBn ? 'প্রতি সপ্তাহের সোমবার ও বৃহস্পতিবার' : 'Every Monday and Thursday',
          desc: isBn ? '"এই দুই দিনে আমল আল্লাহর কাছে পেশ করা হয়।" — তিরমিযী' : '"Deeds are presented to Allah on these days." — Tirmidhi',
          color: const Color(0xFF7C4DFF)),
        FastCard(icon: '🌙', title: isBn ? 'শা’বান মাসের রোজা' : 'Sha\'ban Fasts',
          dates: isBn ? 'শা’বান মাসের প্রথমার্ধ' : 'First half of Sha\'ban',
          desc: isBn ? 'রাসূল ﷺ শা’বান মাসে বেশি নফল রোজা রাখতেন। রমাদানের পূর্ব প্রস্তুতি।' : 'Prophet ﷺ fasted frequently in Sha\'ban. Preparation before Ramadan.',
          color: const Color(0xFFEC407A)),
        FastCard(icon: '📿', title: isBn ? 'জুলহিজ্জাহর প্রথম ৯ দিন' : 'First 9 Days of Dhul Hijjah',
          dates: isBn ? 'জুলহিজ্জাহ ১-৯ তারিখ' : 'Dhul Hijjah 1-9',
          desc: isBn ? '"এই দিনগুলোতে নেক আমল আল্লাহর কাছে সবচেয়ে প্রিয়।" — বুখারী' : '"Good deeds in these days are most beloved to Allah." — Bukhari',
          color: const Color(0xFFFFB300)),
        FastCard(icon: '🔄', title: isBn ? 'দাউদ (আ.)-এর রোজা' : 'Fast of Dawud (AS)',
          dates: isBn ? 'একদিন রোজা, একদিন বিরতি' : 'Fast one day, skip one day',
          desc: isBn ? '"আল্লাহর কাছে সবচেয়ে পছন্দের রোজা হলো দাউদ (আ.)-এর রোজা।" — বুখারী' : '"Most beloved fast to Allah is that of Dawud." — Bukhari',
          color: const Color(0xFF29B6F6)),
        const SizedBox(height: 16),
        nflSectionHeader('❌', isBn ? 'নিষিদ্ধ রোজা' : 'Forbidden Fasts', AppTheme.missed),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
          ),
          child: Column(children: [
            ProhibitedRow('❌', isBn ? 'ঈদুল ফিতর ও ঈদুল আযহার দিন' : 'Eid al-Fitr & Eid al-Adha',
              isBn ? 'এই দুই দিন রোজা রাখা হারাম।' : 'Fasting on these two days is Haram.'),
            ProhibitedRow('❌', isBn ? 'আইয়ামে তাশরীক (১১, ১২, ১৩ জুলহিজ্জাহ)' : 'Ayyam al-Tashriq',
              isBn ? 'এই তিন দিন খাওয়া-দাওয়া ও জিকিরের দিন।' : 'Three days of eating, drinking and dhikr.'),
            ProhibitedRow('❌', isBn ? 'বিরতিহীন রোজা (সাওমে বিসাল)' : 'Continuous Fasting',
              isBn ? 'ইফতার ও সেহরি ছাড়া টানা রোজা নিষিদ্ধ।' : 'Fasting without iftar/sehri is forbidden.'),
            ProhibitedRow('❌', isBn ? 'শুধু শুক্রবার রোজা' : 'Only Friday Fast',
              isBn ? 'বৃহস্পতি বা শনিবার ছাড়া শুধু শুক্রবার রোজা নিরুৎসাহিত।' : 'Friday fast alone is discouraged.'),
            ProhibitedRow('❌', isBn ? 'সারা বছর প্রতিদিন রোজা' : 'Fasting every day all year',
              isBn ? 'প্রতিদিন রোজা রাখা নিষেধ।' : 'Fasting every single day is forbidden.'),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
