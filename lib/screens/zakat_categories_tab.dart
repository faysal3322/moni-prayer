import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

/// যাকাত বন্টনের ৮টা খাত — সূরা আত-তাওবা ৯:৬০ অনুযায়ী। প্রতিটা খাতের
/// সংক্ষিপ্ত ব্যাখ্যাসহ। তথ্যসূত্র: ব্যবহারকারীর দেওয়া রেফারেন্স নোট
/// (শাইখ সালিহ আল-ফাওযান ও অন্যান্য ফাতাওয়া সংকলন অবলম্বনে)।
class ZakatCategoriesTab extends StatelessWidget {
  final AppLanguage lang;
  const ZakatCategoriesTab({super.key, required this.lang});

  static const _categories = [
    {
      'icon': '🤲',
      'title_bn': 'গরীব (ফুক্বারা)',
      'title_en': 'The Poor (Fuqara)',
      'desc_bn': 'যাদের কাছে নিজের ও পরিবারের মৌলিক প্রয়োজন মেটানোর মতো যথেষ্ট সম্পদ নেই।',
      'desc_en': 'Those who lack sufficient means to meet their basic needs.',
    },
    {
      'icon': '🏚️',
      'title_bn': 'অভাবী (মাসাকীন)',
      'title_en': 'The Needy (Masakin)',
      'desc_bn': 'গরীবের চেয়ে কিছুটা ভালো অবস্থানে থাকলেও যাদের প্রয়োজন পূরণ হয় না।',
      'desc_en': 'Those in a slightly better position than the poor, but whose needs still go unmet.',
    },
    {
      'icon': '📋',
      'title_bn': 'যাকাত সংগ্রহকারী কর্মচারী',
      'title_en': 'Zakat Administrators',
      'desc_bn': 'যারা যাকাত সংগ্রহ ও বন্টনের কাজে নিযুক্ত, তাদের পারিশ্রমিকের জন্য।',
      'desc_en': 'Those employed to collect and distribute zakat, for their compensation.',
    },
    {
      'icon': '💚',
      'title_bn': 'অন্তর আকৃষ্টকরণ',
      'title_en': 'Reconciling Hearts',
      'desc_bn': 'ইসলামের প্রতি আগ্রহী বা নবপ্রবেশকারীদের অন্তরকে ইসলামের প্রতি আকৃষ্ট করার জন্য।',
      'desc_en': 'To attract the hearts of those inclined towards or new to Islam.',
    },
    {
      'icon': '⛓️',
      'title_bn': 'ক্রীতদাস মুক্তকরণ',
      'title_en': 'Freeing Captives',
      'desc_bn': 'দাসত্ব বা বন্দিদশা থেকে মুক্ত করার জন্য ব্যয় করা যায়।',
      'desc_en': 'To free slaves or captives from bondage.',
    },
    {
      'icon': '💳',
      'title_bn': 'ঋণগ্রস্তদের সাহায্য',
      'title_en': 'Those in Debt',
      'desc_bn': 'প্রকৃতপক্ষে ঋণগ্রস্ত ব্যক্তিদের ঋণ পরিশোধে সহায়তার জন্য।',
      'desc_en': 'To assist those genuinely burdened by debt.',
    },
    {
      'icon': '🛡️',
      'title_bn': 'আল্লাহর রাস্তায়',
      'title_en': 'In the Cause of Allah',
      'desc_bn': 'মুসলিম রাষ্ট্রের সরকারি সেনাবাহিনী ও জিহাদের প্রস্তুতির জন্য।',
      'desc_en': 'For the official military of a Muslim state and preparation for jihad.',
    },
    {
      'icon': '🧳',
      'title_bn': 'মুসাফির/পথিক',
      'title_en': 'The Wayfarer',
      'desc_bn': 'যে ব্যক্তি সম্পদশালী হলেও ভ্রমণে অর্থসংকটে পড়ে নিজ গন্তব্যে পৌঁছাতে অক্ষম।',
      'desc_en': 'A traveler stranded and unable to reach their destination, even if wealthy at home.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
          ),
          child: Text(
            isBn
                ? 'আল্লাহ তাআলা বলেন: "নিশ্চয়ই সাদাক্বাত (যাকাত) শুধু ফকির, মিসকিন এবং তা সংগ্রহের জন্য নিযুক্ত কর্মচারীদের জন্য, আর যাদের অন্তর ইসলামের প্রতি আকৃষ্ট হয়ে আছে তাদের জন্য; এবং দাস আজাদ করার জন্য, ঋণগ্রস্তদের জন্য, আল্লাহর রাস্তায় ব্যয় করার জন্য এবং মুসাফিরের জন্য — এটি আল্লাহর পক্ষ থেকে ফরজ বিধান। আর আল্লাহ মহাজ্ঞানী, প্রজ্ঞাময়।" (সূরা আত-তাওবা ৯:৬০)'
                : '"As-sadaqat (zakat) are only for the poor, the needy, those employed to collect them, those whose hearts are to be reconciled, for freeing captives, for those in debt, for the cause of Allah, and for the wayfarer — an obligation from Allah. Allah is All-Knowing, All-Wise." (Surah At-Tawbah 9:60)',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ),
        ..._categories.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final cat = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Text('$i', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cat['icon']} ${isBn ? cat['title_bn'] : cat['title_en']}',
                        style: const TextStyle(color: AppTheme.gold, fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn ? cat['desc_bn']! : cat['desc_en']!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.missed.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.missed.withOpacity(0.3)),
          ),
          child: Text(
            isBn
                ? '⚠️ যাকাত পিতামাতা, দাদা-দাদি, সন্তান বা নাতি-নাতনিকে দেওয়া যাবে না — তাদের ভরণপোষণ এমনিতেই ফরজ দায়িত্ব। তবে দরিদ্র ভাই-বোন, চাচা-খালাকে যাকাত দেওয়া জায়েজ ও অতিরিক্ত সওয়াবের কাজ (আত্মীয়তা রক্ষা + দান — দুই সওয়াব)।'
                : "⚠️ Zakat cannot be given to parents, grandparents, children, or grandchildren — supporting them is already an obligatory duty. However, giving zakat to poor siblings, uncles, or aunts is permissible and earns double reward (maintaining family ties + charity).",
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, height: 1.5),
          ),
        ),
      ],
    );
  }
}
