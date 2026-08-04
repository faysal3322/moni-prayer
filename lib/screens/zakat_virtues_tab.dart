import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

/// যাকাতের ফযীলত ও গুরুত্ব সম্পর্কিত তথ্য — ইসলামের তৃতীয় স্তম্ভ হিসেবে
/// যাকাতের মর্যাদা, নিসাব, এবং সম্পর্কিত গুরুত্বপূর্ণ বিধান।
class ZakatVirtuesTab extends StatelessWidget {
  final AppLanguage lang;
  const ZakatVirtuesTab({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isBn = lang.isBn;

    final points = isBn
        ? [
            {
              'icon': '🕋',
              'title': 'ইসলামের তৃতীয় স্তম্ভ',
              'body':
                  'যাকাত ইসলামের পাঁচটি স্তম্ভের একটি — যাদের সম্পদ নিসাব পরিমাণে পৌঁছেছে এবং এক বছর তাদের অধীনে ছিল, তাদের জন্য এটি ফরজ।',
            },
            {
              'icon': '🌟',
              'title': 'সম্পদের পরিশুদ্ধতা',
              'body':
                  'যাকাত অর্থ হলো হালাল উপার্জনকে "পরিশুদ্ধ করা"। প্রতি বছর মজুদকৃত স্বর্ণ, রৌপ্য ও সঞ্চয়ের ২.৫% দান করার মাধ্যমে সম্পদ পবিত্র হয়।',
            },
            {
              'icon': '⚖️',
              'title': 'গরিবের অধিকার',
              'body':
                  'শাইখ সালিহ বিন ফাওযান বলেন: "যাকাত হলো ধনীদের উপর গরিবদের একটি প্রাপ্য অধিকার।" এটি দয়া নয়, বরং একটি ন্যায্য পাওনা।',
            },
            {
              'icon': '📖',
              'title': 'কুরআনের নির্দেশনা',
              'body':
                  'কুরআনে বহু জায়গায় নামাজের সাথে যাকাতের কথা একসাথে উল্লেখ হয়েছে, যা এর গুরুত্ব বোঝায়। "আর তোমরা নামাজ কায়েম কর ও যাকাত আদায় কর" — বহু আয়াতে এই নির্দেশ এসেছে।',
            },
            {
              'icon': '🚫',
              'title': 'অবৈধ উপার্জন গৃহীত হয় না',
              'body':
                  'নবী ﷺ বলেছেন: "আল্লাহ পবিত্র ও উত্তম এবং তিনি পবিত্র ও উত্তম জিনিসই পছন্দ করেন।" তাই যাকাত অবশ্যই হালাল উপার্জন থেকে দিতে হবে।',
            },
            {
              'icon': '💰',
              'title': 'নিসাবের পরিমাণ',
              'body':
                  'সোনা: ৮৫ গ্রাম। রূপা: ৫৯৫ গ্রাম। নগদ অর্থের ক্ষেত্রে রৌপ্যের নিসাব-মূল্য ব্যবহার করা উত্তম (গরিবদের জন্য বেশি উপকারী), কারণ এটি সাধারণত কম হয়।',
            },
            {
              'icon': '🏠',
              'title': 'কীসের উপর যাকাত নেই',
              'body':
                  'ব্যক্তিগত ব্যবহারের গাড়ি, বাড়ি, হীরা বা অন্যান্য গহনার উপর যাকাত নেই। তবে ভাড়া বা বিনিয়োগ থেকে অর্জিত লাভের উপর যাকাত দিতে হয়।',
            },
            {
              'icon': '🌙',
              'title': 'বার্ষিক হিসাব',
              'body':
                  'যাকাত বছরে একবার দিতে হয়, যখন সম্পদ নিসাব পরিমাণে এক (চন্দ্র) বছর ধরে বজায় থাকে। মাসিক বেতনভোগীরা যেদিন সঞ্চয় নিসাবে পৌঁছায় সেদিন থেকে বছর গণনা শুরু করতে পারেন।',
            },
            {
              'icon': '🕌',
              'title': 'ঘুমানোর আগে সূরা মুলক',
              'body':
                  'যদিও যাকাতের সাথে সরাসরি সম্পর্কিত নয়, তবে নিয়মিত আমল হিসেবে ঘুমানোর আগে সূরা মুলক পাঠ করা কবরের আযাব থেকে রক্ষাকারী বলে হাদীসে এসেছে।',
            },
          ]
        : [
            {
              'icon': '🕋',
              'title': 'The Third Pillar of Islam',
              'body':
                  'Zakat is one of the five pillars of Islam — obligatory for those whose wealth has reached the nisab threshold and remained in their possession for a full year.',
            },
            {
              'icon': '🌟',
              'title': 'Purification of Wealth',
              'body':
                  'Zakat means to "purify" one\'s lawful earnings. By giving 2.5% of stored gold, silver, and savings each year, wealth is purified.',
            },
            {
              'icon': '⚖️',
              'title': 'A Right of the Poor',
              'body':
                  'Shaykh Salih al-Fawzan said: "Zakat is a due right of the poor upon the wealthy." It is not charity out of kindness, but a rightful due.',
            },
            {
              'icon': '📖',
              'title': 'Quranic Command',
              'body':
                  'The Quran repeatedly mentions zakat alongside prayer, emphasizing its importance: "And establish prayer and give zakat" appears in numerous verses.',
            },
            {
              'icon': '🚫',
              'title': 'Unlawful Earnings Not Accepted',
              'body':
                  'The Prophet ﷺ said: "Allah is pure and accepts only that which is pure." Zakat must therefore come from lawful earnings.',
            },
            {
              'icon': '💰',
              'title': 'Nisab Threshold',
              'body':
                  'Gold: 85 grams. Silver: 595 grams. For cash, using the silver-based nisab is preferred (more beneficial to the poor) as it is typically lower.',
            },
            {
              'icon': '🏠',
              'title': 'What is Exempt',
              'body':
                  'Personal-use cars, homes, diamonds, or jewelry are exempt from zakat. However, profits from rent or investments are subject to zakat.',
            },
            {
              'icon': '🌙',
              'title': 'Annual Calculation',
              'body':
                  'Zakat is due once a year, when wealth remains at or above nisab for a full lunar year. Salaried individuals may start counting from when savings first reach nisab.',
            },
            {
              'icon': '🕌',
              'title': 'Surah Al-Mulk Before Sleep',
              'body':
                  'While not directly related to zakat, reciting Surah Al-Mulk before sleeping is mentioned in hadith as protection from the punishment of the grave.',
            },
          ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      itemCount: points.length,
      itemBuilder: (context, index) {
        final p = points[index];
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
              Text(p['icon']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['title']!,
                      style: const TextStyle(color: AppTheme.gold, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['body']!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
