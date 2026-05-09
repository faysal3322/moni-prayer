import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

class DuaScreen extends StatefulWidget {
  final AppLanguage lang;
  const DuaScreen({super.key, required this.lang});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'দোয়া' : 'Dua'),
      ),
      body: Column(
        children: [
          // ৩টি Tab
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                _tabBtn(0, '🤲', isBn ? 'দোয়া' : 'Duas', isBn),
                _tabBtn(1, '⏰', isBn ? 'দোয়ার সময়' : 'Dua Times', isBn),
                _tabBtn(2, '📍', isBn ? 'দোয়ার স্থান' : 'Dua Places', isBn),
              ],
            ),
          ),

          Expanded(
            child: _tabIndex == 0
                ? _DuaListTab(isBn: isBn)
                : _tabIndex == 1
                    ? _DuaTimeTab(isBn: isBn)
                    : _DuaPlaceTab(isBn: isBn),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(int index, String icon, String label, bool isBn) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11, fontWeight: FontWeight.bold,
              ), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 1: দোয়া সমূহ
class _DuaListTab extends StatefulWidget {
  final bool isBn;
  const _DuaListTab({required this.isBn});

  @override
  State<_DuaListTab> createState() => _DuaListTabState();
}

class _DuaListTabState extends State<_DuaListTab> {
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _categories = [
    {'icon': '🌅', 'bn': 'দৈনন্দিন', 'en': 'Daily'},
    {'icon': '🕌', 'bn': 'নামাজ', 'en': 'Prayer'},
    {'icon': '🍽️', 'bn': 'খাবার', 'en': 'Food'},
    {'icon': '🏠', 'bn': 'ঘর', 'en': 'Home'},
    {'icon': '🚗', 'bn': 'যাতায়াত', 'en': 'Travel'},
    {'icon': '😢', 'bn': 'বিপদ', 'en': 'Hardship'},
    {'icon': '🤲', 'bn': 'বিশেষ', 'en': 'Special'},
  ];

  final List<List<Map<String, dynamic>>> _duas = [
    // দৈনন্দিন
    [
      {'title_bn': 'সকালের দোয়া', 'title_en': 'Morning Dua',
        'arabic': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        'bangla': 'আসবাহনা ওয়া আসবাহাল মুলকু লিল্লাহ, ওয়াল হামদু লিল্লাহ, লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু লা শারিকা লাহু',
        'meaning': 'আমরা সকালে উপনীত হয়েছি এবং সমগ্র রাজত্ব আল্লাহর। সমস্ত প্রশংসা আল্লাহর। আল্লাহ ছাড়া কোনো ইলাহ নেই, তিনি একক, তাঁর কোনো অংশীদার নেই।',
        'ref': 'মুসলিম'},
      {'title_bn': 'সন্ধ্যার দোয়া', 'title_en': 'Evening Dua',
        'arabic': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        'bangla': 'আমসাইনা ওয়া আমসাল মুলকু লিল্লাহ, ওয়াল হামদু লিল্লাহ, লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু লা শারিকা লাহু',
        'meaning': 'আমরা সন্ধ্যায় উপনীত হয়েছি এবং সমগ্র রাজত্ব আল্লাহর।',
        'ref': 'মুসলিম'},
      {'title_bn': 'ঘুমানোর দোয়া', 'title_en': 'Before Sleep',
        'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        'bangla': 'বিসমিকাল্লাহুম্মা আমুতু ওয়া আহইয়া',
        'meaning': 'হে আল্লাহ! তোমার নামে মরি এবং বাঁচি।',
        'ref': 'বুখারী'},
      {'title_bn': 'ঘুম থেকে উঠার দোয়া', 'title_en': 'After Waking Up',
        'arabic': 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        'bangla': 'আলহামদুলিল্লাহিল্লাযী আহইয়ানা বা\'দা মা আমাতানা ওয়া ইলাইহিন নুশুর',
        'meaning': 'সকল প্রশংসা আল্লাহর, যিনি আমাদের মৃত্যুর পর জীবন দান করেছেন এবং তাঁর কাছেই পুনরুত্থান।',
        'ref': 'বুখারী'},
      {'title_bn': 'আয়াতুল কুরসি', 'title_en': 'Ayatul Kursi',
        'arabic': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
        'bangla': 'আল্লাহু লা ইলাহা ইল্লা হুওয়াল হাইয়্যুল কাইয়্যুম, লা তা\'খুযুহু সিনাতুওঁ ওয়ালা নাওম...',
        'meaning': 'আল্লাহ, তিনি ছাড়া কোনো ইলাহ নেই। তিনি চিরঞ্জীব, সর্বসত্তার ধারক। তাঁকে তন্দ্রাও স্পর্শ করে না, নিদ্রাও নয়।',
        'ref': 'কুরআন ২:২৫৫'},
    ],
    // নামাজের দোয়া
    [
      {'title_bn': 'নামাজ শুরুর দোয়া (সানা)', 'title_en': 'Opening Dua (Thana)',
        'arabic': 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَٰهَ غَيْرُكَ',
        'bangla': 'সুবহানাকাল্লাহুম্মা ওয়া বিহামদিকা ওয়া তাবারাকাসমুকা ওয়া তা\'আলা জাদ্দুকা ওয়া লা ইলাহা গাইরুক',
        'meaning': 'হে আল্লাহ! তুমি পবিত্র এবং তোমার প্রশংসা করছি, তোমার নাম বরকতময়, তোমার মর্যাদা অতি উচ্চ এবং তুমি ছাড়া কোনো ইলাহ নেই।',
        'ref': 'তিরমিযী'},
      {'title_bn': 'রুকুর তাসবীহ', 'title_en': 'Tasbih in Ruku',
        'arabic': 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
        'bangla': 'সুবহানা রাব্বিয়াল আযীম',
        'meaning': 'আমার মহান প্রভু পবিত্র।',
        'ref': 'মুসলিম'},
      {'title_bn': 'সিজদার তাসবীহ', 'title_en': 'Tasbih in Sujud',
        'arabic': 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
        'bangla': 'সুবহানা রাব্বিয়াল আ\'লা',
        'meaning': 'আমার সর্বোচ্চ প্রভু পবিত্র।',
        'ref': 'মুসলিম'},
      {'title_bn': 'তাশাহহুদ', 'title_en': 'Tashahhud',
        'arabic': 'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ',
        'bangla': 'আত্তাহিয়্যাতু লিল্লাহি ওয়াস সালাওয়াতু ওয়াত তায়্যিবাত, আস-সালামু আলাইকা আইয়্যুহান নাবিয়্যু...',
        'meaning': 'সকল সম্মান, সকল নামাজ ও সকল পবিত্র বিষয় আল্লাহর জন্য। হে নবী! আপনার উপর শান্তি, আল্লাহর রহমত ও বরকত বর্ষিত হোক।',
        'ref': 'বুখারী, মুসলিম'},
      {'title_bn': 'দরূদ ইবরাহীম', 'title_en': 'Darud Ibrahim',
        'arabic': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ',
        'bangla': 'আল্লাহুম্মা সাল্লি আলা মুহাম্মাদিও ওয়া আলা আলি মুহাম্মাদ, কামা সাল্লাইতা আলা ইবরাহীমা ওয়া আলা আলি ইবরাহীম',
        'meaning': 'হে আল্লাহ! মুহাম্মদ ও তার পরিবারের উপর রহমত বর্ষণ করো, যেমন তুমি ইবরাহীম ও তার পরিবারের উপর করেছো।',
        'ref': 'বুখারী, মুসলিম'},
      {'title_bn': 'নামাজের শেষ দোয়া', 'title_en': 'Final Dua in Prayer',
        'arabic': 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، وَمِنْ عَذَابِ جَهَنَّمَ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ',
        'bangla': 'আল্লাহুম্মা ইন্নী আউযু বিকা মিন আযাবিল কাবর, ওয়া মিন আযাবি জাহান্নাম, ওয়া মিন ফিতনাতিল মাহইয়া ওয়াল মামাত',
        'meaning': 'হে আল্লাহ! আমি তোমার কাছে কবরের আযাব, জাহান্নামের আযাব এবং জীবন-মৃত্যুর ফিতনা থেকে আশ্রয় চাই।',
        'ref': 'বুখারী, মুসলিম'},
    ],
    // খাবারের দোয়া
    [
      {'title_bn': 'খাওয়ার আগে', 'title_en': 'Before Eating',
        'arabic': 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        'bangla': 'বিসমিল্লাহি ওয়া আলা বারাকাতিল্লাহ',
        'meaning': 'আল্লাহর নামে এবং আল্লাহর বরকতের সাথে (শুরু করছি)।',
        'ref': 'আবু দাউদ'},
      {'title_bn': 'খাওয়ার পরে', 'title_en': 'After Eating',
        'arabic': 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
        'bangla': 'আলহামদুলিল্লাহিল্লাযী আত\'আমানা ওয়া সাকানা ওয়া জা\'আলানা মুসলিমীন',
        'meaning': 'সকল প্রশংসা আল্লাহর, যিনি আমাদের খাইয়েছেন, পান করিয়েছেন এবং আমাদের মুসলিম করেছেন।',
        'ref': 'আবু দাউদ, তিরমিযী'},
      {'title_bn': 'ভুলে বিসমিল্লাহ না বললে', 'title_en': 'Forgot Bismillah',
        'arabic': 'بِسْمِ اللَّهِ أَوَّلَهُ وَآخِرَهُ',
        'bangla': 'বিসমিল্লাহি আওয়ালাহু ওয়া আখিরাহু',
        'meaning': 'আল্লাহর নামে শুরুতে এবং শেষে।',
        'ref': 'আবু দাউদ'},
    ],
    // ঘরের দোয়া
    [
      {'title_bn': 'ঘরে প্রবেশের দোয়া', 'title_en': 'Entering Home',
        'arabic': 'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
        'bangla': 'বিসমিল্লাহি ওয়ালাজনা ওয়া বিসমিল্লাহি খারাজনা ওয়া আলাল্লাহি রাব্বিনা তাওয়াক্কালনা',
        'meaning': 'আল্লাহর নামে প্রবেশ করলাম, আল্লাহর নামে বের হবো এবং আমাদের প্রভু আল্লাহর উপর ভরসা করলাম।',
        'ref': 'আবু দাউদ'},
      {'title_bn': 'ঘর থেকে বের হওয়ার দোয়া', 'title_en': 'Leaving Home',
        'arabic': 'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        'bangla': 'বিসমিল্লাহ, তাওয়াক্কালতু আলাল্লাহ, ওয়া লা হাওলা ওয়া লা কুওয়াতা ইল্লা বিল্লাহ',
        'meaning': 'আল্লাহর নামে, আল্লাহর উপর ভরসা করলাম, আল্লাহ ছাড়া কোনো শক্তি ও ক্ষমতা নেই।',
        'ref': 'আবু দাউদ, তিরমিযী'},
      {'title_bn': 'টয়লেটে প্রবেশের দোয়া', 'title_en': 'Entering Toilet',
        'arabic': 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
        'bangla': 'আল্লাহুম্মা ইন্নী আউযু বিকা মিনাল খুবুসি ওয়াল খাবায়িস',
        'meaning': 'হে আল্লাহ! আমি তোমার কাছে পুরুষ ও মহিলা শয়তান থেকে আশ্রয় চাই।',
        'ref': 'বুখারী, মুসলিম'},
      {'title_bn': 'টয়লেট থেকে বের হওয়ার দোয়া', 'title_en': 'Leaving Toilet',
        'arabic': 'غُفْرَانَكَ',
        'bangla': 'গুফরানাক',
        'meaning': 'হে আল্লাহ! তোমার কাছে ক্ষমা চাই।',
        'ref': 'আবু দাউদ, তিরমিযী'},
      {'title_bn': 'মসজিদে প্রবেশের দোয়া', 'title_en': 'Entering Mosque',
        'arabic': 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        'bangla': 'আল্লাহুম্মাফতাহলী আবওয়াবা রাহমাতিক',
        'meaning': 'হে আল্লাহ! আমার জন্য তোমার রহমতের দরজাগুলো খুলে দাও।',
        'ref': 'মুসলিম'},
      {'title_bn': 'মসজিদ থেকে বের হওয়ার দোয়া', 'title_en': 'Leaving Mosque',
        'arabic': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
        'bangla': 'আল্লাহুম্মা ইন্নী আসআলুকা মিন ফাদলিক',
        'meaning': 'হে আল্লাহ! আমি তোমার কাছে তোমার অনুগ্রহ চাই।',
        'ref': 'মুসলিম'},
    ],
    // যাতায়াতের দোয়া
    [
      {'title_bn': 'যানবাহনে ওঠার দোয়া', 'title_en': 'Riding a Vehicle',
        'arabic': 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُونَ',
        'bangla': 'সুবহানাল্লাযী সাখখারা লানা হাযা ওয়া মা কুন্না লাহু মুকরিনীন, ওয়া ইন্না ইলা রাব্বিনা লামুনকালিবুন',
        'meaning': 'পবিত্র তিনি যিনি এটাকে আমাদের অধীন করে দিয়েছেন, আমরা এটাকে বশীভূত করতে সক্ষম ছিলাম না। নিশ্চয়ই আমরা আমাদের প্রভুর কাছে ফিরে যাবো।',
        'ref': 'কুরআন ৪৩:১৩-১৪'},
      {'title_bn': 'সফরের দোয়া', 'title_en': 'Dua for Journey',
        'arabic': 'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَٰذَا الْبِرَّ وَالتَّقْوَى',
        'bangla': 'আল্লাহুম্মা ইন্না নাসআলুকা ফী সাফারিনা হাযাল বিররা ওয়াত তাকওয়া',
        'meaning': 'হে আল্লাহ! আমরা এই সফরে তোমার কাছে নেকী ও তাকওয়া চাই।',
        'ref': 'মুসলিম'},
      {'title_bn': 'সফর থেকে ফেরার দোয়া', 'title_en': 'Returning from Journey',
        'arabic': 'آيِبُونَ، تَائِبُونَ، عَابِدُونَ، لِرَبِّنَا حَامِدُونَ',
        'bangla': 'আয়িবুন, তায়িবুন, আবিদুন, লিরাব্বিনা হামিদুন',
        'meaning': 'আমরা ফিরে আসছি, তাওবা করছি, ইবাদত করছি, আমাদের প্রভুর প্রশংসা করছি।',
        'ref': 'মুসলিম'},
    ],
    // বিপদের দোয়া
    [
      {'title_bn': 'বিপদে দোয়া', 'title_en': 'Dua in Hardship',
        'arabic': 'إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ',
        'bangla': 'ইন্না লিল্লাহি ওয়া ইন্না ইলাইহি রাজিউন',
        'meaning': 'নিশ্চয়ই আমরা আল্লাহর এবং তাঁর কাছেই ফিরে যাবো।',
        'ref': 'কুরআন ২:১৫৬'},
      {'title_bn': 'দুশ্চিন্তার দোয়া', 'title_en': 'Dua for Anxiety',
        'arabic': 'اللَّهُمَّ إِنِّي عَبْدُكَ، ابْنُ عَبْدِكَ، ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ',
        'bangla': 'আল্লাহুম্মা ইন্নী আবদুকা, ইবনু আবদিকা, ইবনু আমাতিকা, নাসিয়াতী বিয়াদিকা',
        'meaning': 'হে আল্লাহ! আমি তোমার বান্দা, তোমার বান্দার সন্তান, তোমার বান্দির সন্তান। আমার ভাগ্য তোমার হাতে।',
        'ref': 'আহমদ'},
      {'title_bn': 'অসুস্থতার দোয়া', 'title_en': 'Dua for Illness',
        'arabic': 'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَاسَ، اشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ',
        'bangla': 'আল্লাহুম্মা রাব্বান নাস, আযহিবিল বাস, ইশফি আনতাশ শাফী, লা শিফায়া ইল্লা শিফাউক',
        'meaning': 'হে আল্লাহ! মানুষের প্রভু! কষ্ট দূর করো, আরোগ্য দাও — তুমিই আরোগ্যদাতা, তোমার আরোগ্য ছাড়া কোনো আরোগ্য নেই।',
        'ref': 'বুখারী, মুসলিম'},
      {'title_bn': 'ভয়ের দোয়া', 'title_en': 'Dua for Fear',
        'arabic': 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
        'bangla': 'হাসবুনাল্লাহু ওয়া নি\'মাল ওয়াকীল',
        'meaning': 'আল্লাহই আমাদের জন্য যথেষ্ট এবং তিনি কতই না উত্তম কর্মবিধায়ক।',
        'ref': 'কুরআন ৩:১৭৩'},
      {'title_bn': 'ঋণ থেকে মুক্তির দোয়া', 'title_en': 'Dua to Pay Off Debt',
        'arabic': 'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
        'bangla': 'আল্লাহুম্মাকফিনী বিহালালিকা আন হারামিক, ওয়া আগনিনী বিফাদলিকা আম্মান সিওয়াক',
        'meaning': 'হে আল্লাহ! তোমার হালাল দিয়ে আমাকে হারাম থেকে বাঁচাও এবং তোমার অনুগ্রহ দিয়ে তোমা ছাড়া সকলের মুখাপেক্ষিতা থেকে মুক্ত করো।',
        'ref': 'তিরমিযী'},
    ],
    // বিশেষ দোয়া
    [
      {'title_bn': 'ইস্তিগফার', 'title_en': 'Istighfar',
        'arabic': 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
        'bangla': 'আস্তাগফিরুল্লাহাল আযীমাল্লাযী লা ইলাহা ইল্লা হুওয়াল হাইয়্যুল কাইয়্যুমু ওয়া আতুবু ইলাইহ',
        'meaning': 'আমি মহান আল্লাহর কাছে ক্ষমা চাই, যিনি ছাড়া কোনো ইলাহ নেই, যিনি চিরজীবী ও সর্বসত্তার ধারক, এবং আমি তাঁর কাছে তাওবা করছি।',
        'ref': 'তিরমিযী'},
      {'title_bn': 'সাইয়েদুল ইস্তিগফার', 'title_en': 'Sayyidul Istighfar',
        'arabic': 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ',
        'bangla': 'আল্লাহুম্মা আনতা রাব্বী লা ইলাহা ইল্লা আনত, খালাকতানী ওয়া আনা আবদুক...',
        'meaning': 'হে আল্লাহ! তুমি আমার প্রভু, তুমি ছাড়া কোনো ইলাহ নেই। তুমি আমাকে সৃষ্টি করেছো এবং আমি তোমার বান্দা।',
        'ref': 'বুখারী'},
      {'title_bn': 'দরূদ শরীফ', 'title_en': 'Darud Sharif',
        'arabic': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
        'bangla': 'আল্লাহুম্মা সাল্লি আলা মুহাম্মাদিও ওয়া আলা আলি মুহাম্মাদ',
        'meaning': 'হে আল্লাহ! মুহাম্মদ ও তাঁর পরিবারের উপর রহমত বর্ষণ করো।',
        'ref': 'বুখারী, মুসলিম'},
      {'title_bn': 'শবে কদরের দোয়া', 'title_en': 'Laylatul Qadr Dua',
        'arabic': 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
        'bangla': 'আল্লাহুম্মা ইন্নাকা আফুওয়্যুন তুহিব্বুল আফওয়া ফা\'ফু আন্নী',
        'meaning': 'হে আল্লাহ! তুমি ক্ষমাশীল, ক্ষমা ভালোবাসো, তাই আমাকে ক্ষমা করো।',
        'ref': 'তিরমিযী'},
      {'title_bn': 'লা হাওলা ওয়ালা কুওয়াতা', 'title_en': 'Hawqala',
        'arabic': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
        'bangla': 'লা হাওলা ওয়ালা কুওয়াতা ইল্লা বিল্লাহিল আলিয়্যিল আযীম',
        'meaning': 'মহান উচ্চ আল্লাহর সাহায্য ছাড়া কোনো শক্তি ও ক্ষমতা নেই।',
        'ref': 'বুখারী'},
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBn;
    return Column(
      children: [
        // Category scroll
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = _selectedCategory == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppTheme.accent : Colors.white12),
                  ),
                  child: Row(children: [
                    Text(cat['icon'] as String, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(isBn ? cat['bn'] as String : cat['en'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              );
            },
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _duas[_selectedCategory].length,
            itemBuilder: (_, i) => _DuaCard(dua: _duas[_selectedCategory][i], isBn: isBn),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// Tab 2: দোয়ার সময় (placeholder)
class _DuaTimeTab extends StatelessWidget {
  final bool isBn;
  const _DuaTimeTab({required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏰', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            isBn ? 'দোয়ার সময়\nশীঘ্রই আসছে...' : 'Dua Times\nComing soon...',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 3: দোয়ার স্থান (placeholder)
class _DuaPlaceTab extends StatelessWidget {
  final bool isBn;
  const _DuaPlaceTab({required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📍', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            isBn ? 'দোয়ার স্থান\nশীঘ্রই আসছে...' : 'Dua Places\nComing soon...',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _DuaCard extends StatefulWidget {
  final Map<String, dynamic> dua;
  final bool isBn;
  const _DuaCard({required this.dua, required this.isBn});

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dua = widget.dua;
    final isBn = widget.isBn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(_expanded ? 0.2 : 0.1),
                borderRadius: _expanded
                    ? const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))
                    : BorderRadius.circular(14),
              ),
              child: Row(children: [
                Expanded(child: Text(
                  isBn ? dua['title_bn'] as String : dua['title_en'] as String,
                  style: const TextStyle(color: AppTheme.gold, fontSize: 15, fontWeight: FontWeight.bold),
                )),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.gold, size: 20),
              ]),
            ),
          ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Arabic
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      dua['arabic'] as String,
                      style: const TextStyle(fontSize: 22, color: AppTheme.textPrimary, height: 2.0),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bangla pronunciation
                  Text(dua['bangla'] as String,
                    style: const TextStyle(color: AppTheme.accent, fontSize: 14, height: 1.6, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 4),
                  // Meaning
                  Text(isBn ? 'অর্থ: ' : 'Meaning: ',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(dua['meaning'] as String,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
                  const SizedBox(height: 10),
                  // Ref + Copy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('📖 ${dua['ref']}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: dua['arabic'] as String));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isBn ? 'আরবি কপি হয়েছে' : 'Arabic copied'),
                            backgroundColor: AppTheme.completed,
                            duration: const Duration(seconds: 2),
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.copy, color: AppTheme.accent, size: 14),
                            SizedBox(width: 4),
                            Text('কপি', style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
