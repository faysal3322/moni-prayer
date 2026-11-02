import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/nafl_cards.dart';

class NaflAmalTab extends StatelessWidget {
  final bool isBn;
  const NaflAmalTab({super.key, required this.isBn});

  // ══════════════════════════════════════════
  // নফল/সুন্নত আমল (দোয়া পেজের একটি ট্যাব)
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> amals = [
      // দৈনন্দিন আমল
      {
        'category': isBn ? '🌅 দৈনন্দিন আমল' : '🌅 Daily Amal',
        'color': const Color(0xFF7C4DFF),
        'items': [
          {'num': '১', 'title': isBn ? 'ওযুর পর কালেমা শাহাদত' : 'Shahadah after Wudu', 'desc': isBn ? 'প্রত্যেক ওযুর পর কালেমা শাহাদত পাঠ করুন — এতে জান্নাতের ৮টি দরজার যেকোনো দরজা দিয়ে প্রবেশ করতে পারবেন।\n"আশহাদু আল্লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু..." — সহিহ মুসলিম ২৩৪' : 'After every Wudu recite Shahadah — all 8 gates of Jannah open for you. — Sahih Muslim 234'},
          {'num': '২', 'title': isBn ? 'ফরজ নামাজের পর আয়াতুল কুরসি' : 'Ayatul Kursi after Fard', 'desc': isBn ? 'প্রত্যেক ফরজ সালাত শেষে আয়াতুল কুরসি পাঠ করুন — এতে মৃত্যুর সাথে সাথে জান্নাতে যেতে পারবেন।\n— সহিহ নাসাই, সিলসিলাহ সহিহাহ ৯৭২' : 'Recite Ayatul Kursi after every Fard prayer — you will enter Jannah upon death. — Nasai 972'},
          {'num': '৩', 'title': isBn ? 'ফরজ নামাজের পর তাসবীহ' : 'Tasbih after Fard', 'desc': isBn ? 'প্রত্যেক ফরজ সালাত শেষে ৩৩ বার সুবহানাল্লাহ, ৩৩ বার আলহামদুলিল্লাহ, ৩৩ বার আল্লাহু আকবার এবং ১ বার লা ইলাহা ইল্লাল্লাহু... পাঠ করুন — অতীতের সব পাপ ক্ষমা হয়ে যাবে।\n— সহিহ মুসলিম ১২২৮' : '33x Subhanallah, 33x Alhamdulillah, 33x Allahu Akbar after every Fard — all past sins forgiven. — Muslim 1228'},
          {'num': '৪', 'title': isBn ? 'প্রতিরাতে সূরা মুলক' : 'Surah Mulk every night', 'desc': isBn ? 'প্রতিরাতে সূরা মুলক পাঠ করুন — কবরের শাস্তি থেকে মুক্তি পাবেন।\n— সহিহ নাসাই, সহিহ তারগিব, হাকিম ৩৮৩৯' : 'Recite Surah Mulk every night — protection from punishment of the grave. — Nasai, Hakim 3839'},
          {'num': '৫', 'title': isBn ? 'সকাল-সন্ধ্যায় ১০ বার দরূদ' : '10x Darud morning & evening', 'desc': isBn ? 'সকালে ১০ বার ও সন্ধ্যায় ১০ বার রাসূল ﷺ-এর উপর দরূদ পড়ুন — নিশ্চিত রাসূলের শাফাআত পাবেন।\n— তিবরানি, সহিহ তারগিব ৬৫৬' : '10x Darud in morning & evening — guaranteed intercession of the Prophet. — Tabarani 656'},
          {'num': '৬', 'title': isBn ? 'সুবহানাল্লাহিল আযীম ওয়া বিহামদিহি' : 'Subhanallahil Azim', 'desc': isBn ? 'সকালে ও বিকালে ১০০ বার পড়লে সৃষ্টিকুলের সমস্ত মানুষ থেকে বেশি মর্যাদা পাবেন।\n"যে এটি পড়ে তার জন্য জান্নাতে একটি খেজুরগাছ রোপণ করা হয়।" — তিরমিযী ৩৪৬৪' : '100x morning & evening — higher status than all creation. Tree planted in Jannah. — Tirmidhi 3464'},
          {'num': '৭', 'title': isBn ? 'সুবহানাল্লাহি ওয়া বিহামদিহি ১০০ বার' : 'Subhanallahi wa bihamdih 100x', 'desc': isBn ? 'সকালে ও সন্ধ্যায় ১০০ বার পড়লে কিয়ামতের দিন তার চেয়ে বেশি সওয়াব আর কারো হবে না।\n— সহিহ মুসলিম ২৬৯২' : '100x morning & evening — no one will have more reward on Judgment Day. — Muslim 2692'},
          {'num': '৮', 'title': isBn ? 'বাজারে প্রবেশের দোয়া' : 'Dua entering market', 'desc': isBn ? 'বাজারে প্রবেশ করে "লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু..." পড়লে — ১০ লক্ষ পুণ্য, ১০ লক্ষ পাপ মোচন, ১০ লক্ষ মর্যাদা বৃদ্ধি এবং জান্নাতে একটি গৃহ নির্মাণ।\n— তিরমিযী ৩৪২৮' : 'Recite "La ilaha illallahu wahdahu..." entering market — 1 million good deeds, sins erased, house in Jannah. — Tirmidhi 3428'},
          {'num': '৯', 'title': isBn ? 'বাড়িতে সালাম দিয়ে প্রবেশ' : 'Enter home with Salam', 'desc': isBn ? 'বাড়িতে সালাম দিয়ে প্রবেশ করুন — আল্লাহ নিজ জিম্মাদারিতে আপনাকে জান্নাতে প্রবেশ করাবেন।\n— ইবনু হিব্বান ৪৯৯, সহিহ তারগিব ৩১৬' : 'Enter home with Salam — Allah guarantees your entry to Jannah. — Ibn Hibban 499'},
          {'num': '১০', 'title': isBn ? 'জামাতে প্রথম তাকবীরে ৪০ দিন' : '40 days with first Takbir', 'desc': isBn ? 'জামাতে ইমামের প্রথম তাকবীরের সাথে ৪০ দিন সালাত আদায় করুন — জাহান্নাম থেকে মুক্তি পাবেন।\n— তিরমিযী, সিলসিলাহ সহিহাহ ৭৪৭' : 'Pray 40 days with first Takbir in congregation — freed from Hellfire. — Tirmidhi 747'},
        ],
      },
      // সুন্নত আমল
      {
        'category': isBn ? '📿 সুন্নত আমল (নবীজির অভ্যাস)' : '📿 Sunnah Amal',
        'color': const Color(0xFF26A69A),
        'items': [
          {'num': '১', 'title': isBn ? 'মিসওয়াক করা' : 'Using Miswak', 'desc': isBn ? 'ওযুর পূর্বে মিসওয়াক করার অভ্যাস করুন। নবীজি ﷺ প্রতিটি নামাজের আগে মিসওয়াক করতেন।' : 'Use Miswak before Wudu. The Prophet used it before every prayer.'},
          {'num': '২', 'title': isBn ? 'ঘুমানোর আগে আমল' : 'Before sleep Amal', 'desc': isBn ? 'ঘুমানোর আগে: সূরা মুলক, আয়াতুল কুরসি, সূরা ইখলাস/ফালাক/নাস (৩ বার দম), ঘুমের দোয়া, সূরা কাফিরুন পড়ে ডান কাত হয়ে শোবেন।' : 'Before sleep: Surah Mulk, Ayatul Kursi, 3 Quls (x3 blow), sleep dua, Surah Kafirun — sleep on right side.'},
          {'num': '৩', 'title': isBn ? 'রাতে অযু অবস্থায় ঘুমানো' : 'Sleep in state of Wudu', 'desc': isBn ? 'রাতে অযু অবস্থায় ঘুমান — ফেরেশতারা তার জন্য রাত্রি পর্যন্ত মাগফেরাত কামনা করে।\n— ফাতহুল বারি ১১/১১০' : 'Sleep in state of Wudu — angels seek forgiveness for you all night. — Fathul Bari 11/110'},
          {'num': '৪', 'title': isBn ? 'বৃষ্টিতে ভেজা' : 'Getting wet in rain', 'desc': isBn ? 'মাঝে মাঝে বৃষ্টিতে ভেজা নবীজির সুন্নত।\n— সহিহ মুসলিম ৮৯৮' : 'Getting wet in rain is Sunnah of the Prophet. — Sahih Muslim 898'},
          {'num': '৫', 'title': isBn ? 'বৃষ্টির সময় দোয়া করা' : 'Dua during rain', 'desc': isBn ? 'বৃষ্টির সময় দোয়া করা — এই সময়ের দোয়া কবুল হয়।\n— সহিহ বুখারী ১০৩২' : 'Make dua during rain — duas are accepted at this time. — Sahih Bukhari 1032'},
          {'num': '৬', 'title': isBn ? 'খুশিতে সিজদায় লুটিয়ে পড়া' : 'Sajdah of gratitude', 'desc': isBn ? 'খুব খুশি হলে সিজদায় লুটিয়ে পড়া নবীজির সুন্নত।\n— মুখতাসার যাদুল মাআদ ১/২৭' : 'Prostrating when extremely happy is Sunnah. — Mukhtasar Zadul Maad 1/27'},
          {'num': '৭', 'title': isBn ? 'ধোঁয়া ওঠা গরম খাবার না খাওয়া' : 'Not eating steaming hot food', 'desc': isBn ? 'ধোঁয়া ওঠা গরম খাবার ঠাণ্ডা না হওয়া পর্যন্ত না খাওয়া।\n— বায়হাকি ৪২৮' : 'Do not eat food until the steam has settled. — Bayhaqi 428'},
          {'num': '৮', 'title': isBn ? 'নফল নামাজ ঘরে পড়া' : 'Nafl prayer at home', 'desc': isBn ? 'নফল ও সুন্নত নামাজ ঘরে পড়া উত্তম।\n— সহিহ বুখারী ৭৩১' : 'It is better to pray Nafl and Sunnah at home. — Sahih Bukhari 731'},
          {'num': '৯', 'title': isBn ? 'মাঝে মাঝে খালি পায়ে হাঁটা' : 'Walk barefoot sometimes', 'desc': isBn ? 'মাঝে মাঝে খালি পায়ে হাঁটা নবীজির সুন্নত।\n— সুনানে আবু দাউদ ৪১৬০' : 'Walking barefoot sometimes is Sunnah. — Abu Dawud 4160'},
          {'num': '১০', 'title': isBn ? 'বাসা ছেড়ে ও ফিরে ২ রাকাত' : '2 rakats leaving & returning home', 'desc': isBn ? 'বাসা থেকে বের হওয়ার সময় এবং ফিরে এসে ২ রাকাত নামাজ আদায় করা।\n— মুসনাদে বাজ্জার ৮৫৬৭' : 'Pray 2 rakats when leaving home and when returning. — Musnad Bazzar 8567'},
          {'num': '১১', 'title': isBn ? 'আত্মীয়তার সম্পর্ক রক্ষা করা' : 'Maintaining family ties', 'desc': isBn ? 'আত্মীয়তার সম্পর্ক রক্ষা করলে রিজিক বাড়ে ও হায়াত দীর্ঘ হয়।\n— বুখারী, মুসলিম' : 'Maintaining family ties increases provision and extends lifespan. — Bukhari, Muslim'},
        ],
      },
      // জুমার আমল
      {
        'category': isBn ? '🕌 জুমার দিনের আমল' : '🕌 Friday Amal',
        'color': AppTheme.accent,
        'items': [
          {'num': '১', 'title': isBn ? 'ভোরে আগে উঠা' : 'Wake up early', 'desc': isBn ? 'জুমার দিন আলস্য ত্যাগ করে ভোরে আগে আগে ঘুম থেকে ওঠা।' : 'Wake up early on Friday, leaving laziness aside.'},
          {'num': '২', 'title': isBn ? 'ফজর জামাতে আদায়' : 'Fajr in congregation', 'desc': isBn ? 'জুমার দিনের ফজর জামাতে পড়া সবচেয়ে বেশি মর্যাদাপূর্ণ।' : 'Friday Fajr in congregation is most virtuous.'},
          {'num': '৩', 'title': isBn ? 'গোসল ও পরিচ্ছন্নতা' : 'Ghusl & cleanliness', 'desc': isBn ? 'জুমার নামাজের আগে সুন্দরভাবে গোসল করা ও শরীর পরিচ্ছন্ন করা মুস্তাহাব।' : 'Taking Ghusl and cleaning oneself before Jumu\'ah is mustahab.'},
          {'num': '৪', 'title': isBn ? 'উত্তম পোশাক পরা' : 'Wear best clothes', 'desc': isBn ? 'জুমার দিন নিজের কাছে থাকা সবচেয়ে সুন্দর ও পরিচ্ছন্ন পোশাকটি পরিধান করা সুন্নাহ।' : 'Wearing your best clothes on Friday is Sunnah.'},
          {'num': '৫', 'title': isBn ? 'বেশি বেশি দরূদ পাঠ' : 'Abundant Darud', 'desc': isBn ? 'জুমার দিন ও রাত (বৃহস্পতিবার দিবাগত রাত) থেকে সূর্যাস্ত পর্যন্ত নবী ﷺ-এর প্রতি অধিক দরূদ পাঠ করার বিশেষ গুরুত্ব আছে।' : 'Abundant Darud on Friday from Thursday night until sunset has special virtue.'},
          {'num': '৬', 'title': isBn ? 'আগে আগে মসজিদে যাওয়া' : 'Go to mosque early', 'desc': isBn ? 'যে ব্যক্তি যত দ্রুত মসজিদে প্রবেশ করবেন, আল্লাহর কাছে তার মর্যাদা তত বেশি।' : 'The earlier you enter the mosque, the greater your reward with Allah.'},
          {'num': '৭', 'title': isBn ? 'পায়ে হেঁটে মসজিদে যাওয়া' : 'Walk to mosque', 'desc': isBn ? 'সম্ভব হলে পায়ে হেঁটে মসজিদে যাওয়া সওয়াবের কাজ।' : 'Walking to the mosque earns extra reward.'},
          {'num': '৮', 'title': isBn ? 'সূরা কাহাফ তেলাওয়াত' : 'Recite Surah Kahaf', 'desc': isBn ? 'জুমার দিনে সূরা কাহাফ তেলাওয়াত করলে কিয়ামতে নূরের আলো হবে ও দাজ্জালের ফেতনা থেকে রক্ষা পাবে।' : 'Reciting Surah Kahaf on Friday brings Noor on Judgment Day and protection from Dajjal.'},
          {'num': '৯', 'title': isBn ? 'আসরের পর দোয়ায় মশগুল থাকা' : 'Dua after Asr', 'desc': isBn ? 'জুমার দিন আসরের পর থেকে মাগরিব পর্যন্ত দোয়ায় মশগুল থাকা — এই সময়ে দোয়া কবুলের সম্ভাবনা সবচেয়ে বেশি।' : 'Stay in dua from Asr to Maghrib on Friday — highest chance of acceptance.'},
          {'num': '১০', 'title': isBn ? 'ভিন্ন পথে ফিরে আসা' : 'Return by different route', 'desc': isBn ? 'মসজিদে যাওয়ার সময় যে রাস্তা ব্যবহার করা হয়েছে, ফেরার সময় অন্য রাস্তায় আসা উত্তম।' : 'Return from mosque by a different route than you came.'},
        ],
      },
      // ছোট কিন্তু ফজিলতপূর্ণ আমল
      {
        'category': isBn ? '💎 ছোট কিন্তু ফজিলতপূর্ণ আমল' : '💎 Small but Virtuous Amal',
        'color': const Color(0xFFFF8F00),
        'items': [
          {'num': '১', 'title': isBn ? 'প্রতিটি ভালো কাজ বিসমিল্লাহ দিয়ে শুরু' : 'Start every good deed with Bismillah', 'desc': isBn ? 'প্রতিটি ভালো কাজ ডান দিক দিয়ে বিসমিল্লাহ বলে শুরু করুন।' : 'Begin every good deed from the right side saying Bismillah.'},
          {'num': '২', 'title': isBn ? 'জানা না থাকলে স্বীকার করা' : 'Admit when you don\'t know', 'desc': isBn ? 'কোনো কিছু জানা না থাকলে স্বীকার করুন যে আমি জানি না।\n— বায়হাকি ১৭৫৯৫' : 'If you don\'t know something, admit it. — Bayhaqi 17595'},
          {'num': '৩', 'title': isBn ? 'বিপদে আকাশের দিকে তাকানো' : 'Look to sky in hardship', 'desc': isBn ? 'মাঝে মাঝে বিপদে আকাশের দিকে মাথা তুলে কষ্টগুলো আল্লাহকে বলুন।\n— সহিহ মুসলিম ২৫৩১' : 'In hardship, look up to the sky and share your pain with Allah. — Muslim 2531'},
          {'num': '৪', 'title': isBn ? 'খাবার পরে দোয়া পড়া' : 'Dua after eating', 'desc': isBn ? 'খাওয়া শেষে আলহামদুলিল্লাহ পড়ুন। দুধ পান করলে পড়ুন: "আল্লাহুম্মা বারিক লানা ফিহি ওয়াযিদনা মিনহু।"' : 'After eating say Alhamdulillah. After drinking milk: "Allahumma barik lana fihi wa zidna minhu."'},
          {'num': '৫', 'title': isBn ? 'করজে হাসানা দেওয়া' : 'Interest-free loan', 'desc': isBn ? 'সুদবিহীন ঋণ (করজে হাসানা) দেওয়া অত্যন্ত সওয়াবের কাজ।\n— সহিহ মুসলিম ২৫৮০' : 'Giving interest-free loans is highly virtuous. — Sahih Muslim 2580'},
          {'num': '৬', 'title': isBn ? 'মানুষের মাঝে বিবাদ মিটিয়ে দেওয়া' : 'Resolve disputes', 'desc': isBn ? 'মানুষের মাঝে বিবাদ মিটিয়ে দেওয়া সদকার সমতুল্য।\n— মুসনাদে আহমদ ২৭৫০৮' : 'Resolving disputes between people equals charity. — Musnad Ahmad 27508'},
          {'num': '৭', 'title': isBn ? 'পেট ভরে না খাওয়া' : 'Don\'t eat to full', 'desc': isBn ? 'পেটের তিনভাগের এক ভাগ খালি রেখে খাওয়া শেষ করুন। নবীজির সুন্নত।\n— তিরমিযী ১৮১৮' : 'Leave one-third of stomach empty — Sunnah of the Prophet. — Tirmidhi 1818'},
          {'num': '৮', 'title': isBn ? 'দান-সদকা করা' : 'Give charity', 'desc': isBn ? 'প্রতিমাসে আয়ের একটা অংশ এতিম, গরিব-দুখী, বিধবা ও দুস্থদের মাঝে দান করুন — আল্লাহর কাছে জিহাদকারীর সমতুল্য হবেন।\n— সহিহ বুখারী ৬০০৭' : 'Monthly give some income to orphans, widows, poor — equal to a Mujahid in Allah\'s sight. — Bukhari 6007'},
          {'num': '৯', 'title': isBn ? 'সন্তান জন্মের পর আজান' : 'Adhan after birth', 'desc': isBn ? 'সন্তান জন্ম হওয়ার পর ডান কানে আজান দেওয়া সুন্নত।\n— আবু রাফি (রা.) বর্ণিত' : 'Giving Adhan in the right ear of newborn is Sunnah. — Abu Rafi (ra.)'},
          {'num': '১০', 'title': isBn ? 'ঘুমের মধ্যে খারাপ স্বপ্ন দেখলে' : 'When seeing bad dream', 'desc': isBn ? 'খারাপ স্বপ্ন দেখলে উঠে বামপাশে তিনবার থুথু ফেলুন এবং "আউযুবিল্লাহি মিনাশ শাইত্বানির রজিম" পড়ুন।\n— সহিহ মুসলিম' : 'Upon bad dream: spit left 3 times, recite "Audhu billahi minash shaytanir rajim." — Muslim'},
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: amals.length,
      itemBuilder: (context, categoryIndex) {
        final category = amals[categoryIndex];
        final color = category['color'] as Color;
        final items = category['items'] as List<Map<String, dynamic>>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                category['category'] as String,
                style: TextStyle(
                    color: AppTheme.readable(color), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => AmalCard(
                  num: item['num'] as String,
                  title: item['title'] as String,
                  desc: item['desc'] as String,
                  color: AppTheme.readable(color),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
