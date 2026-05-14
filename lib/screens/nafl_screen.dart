import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/prayer_time_helper.dart';

class NaflScreen extends StatefulWidget {
  final AppLanguage lang;
  const NaflScreen({super.key, required this.lang});

  @override
  State<NaflScreen> createState() => _NaflScreenState();
}

class _NaflScreenState extends State<NaflScreen> {
  PrayerTimes? _prayerTimes;
  SunnahTimes? _sunnahTimes;
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final times = await PrayerTimeHelper.getPrayerTimes();
    final sunnah = SunnahTimes(times);
    if (mounted) {
      setState(() {
        _prayerTimes = times;
        _sunnahTimes = sunnah;
        _loading = false;
      });
    }
  }

  String _fmt(DateTime t) => PrayerTimeHelper.formatTime(t);

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
    final isBn = widget.lang.isBn;
    final pt = _prayerTimes;
    final now = DateTime.now();
    final h = _hijriDay(now);

    final ishraqStart = pt?.sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = pt?.sunrise.add(const Duration(minutes: 45));
    final chashtStart = pt?.sunrise.add(const Duration(minutes: 45));
    final chashtEnd = pt?.dhuhr.subtract(const Duration(minutes: 10));
    final tahaqqudStart = _sunnahTimes?.lastThirdOfTheNight;
    final tahaqqudEnd = pt?.fajr;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'নামাজ ও রোজার তথ্য' : 'Prayer & Fasting Info'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : Column(
              children: [
                // ৩টি Tab
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    _tabBtn(0, '🕌', isBn ? 'নফল নামাজ' : 'Nafl Prayer'),
                    _tabBtn(1, '🌙', isBn ? 'নফল রোজা' : 'Nafl Fasting'),
                    _tabBtn(2, '📿', isBn ? 'নফল আমল' : 'Nafl Amal'),
                  ]),
                ),
                Expanded(
                  child: _tabIndex == 0
                      ? _buildPrayerTab(isBn, pt, ishraqStart, ishraqEnd,
                          chashtStart, chashtEnd, tahaqqudStart, tahaqqudEnd)
                      : _tabIndex == 1
                          ? _buildFastingTab(isBn, h)
                          : _buildAmalTab(isBn),
                ),
              ],
            ),
    );
  }

  Widget _tabBtn(int index, String icon, String label) {
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
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // Tab 1: নফল নামাজ
  Widget _buildPrayerTab(
    bool isBn,
    PrayerTimes? pt,
    DateTime? ishraqStart,
    DateTime? ishraqEnd,
    DateTime? chashtStart,
    DateTime? chashtEnd,
    DateTime? tahaqqudStart,
    DateTime? tahaqqudEnd,
  ) {
    final nafls = [
      {
        'icon': '🌙',
        'name': isBn ? 'তাহাজ্জুদ' : 'Tahajjud',
        'time': tahaqqudStart != null && tahaqqudEnd != null
            ? '${_fmt(tahaqqudStart)} - ${_fmt(tahaqqudEnd)}'
            : isBn ? 'রাতের শেষ তৃতীয়াংশ' : 'Last third of night',
        'rakaat': isBn ? '২ - ১২ রাকাত' : '2-12 rakats',
        'desc': isBn
            ? '"ফরজ নামাজের পর সর্বোত্তম নামাজ হলো রাতের তাহাজ্জুদ।" — সহিহ মুসলিম\nএশার পর ঘুমিয়ে উঠে শেষ রাতে পড়া উত্তম।'
            : '"Best prayer after Fard is night Tahajjud." — Sahih Muslim',
        'color': const Color(0xFF7C4DFF),
      },
      {
        'icon': '🌅',
        'name': isBn ? 'ইশরাক' : 'Ishraq',
        'time': ishraqStart != null && ishraqEnd != null
            ? '${_fmt(ishraqStart)} - ${_fmt(ishraqEnd)}'
            : isBn ? 'সূর্যোদয়ের ১৫-২০ মিনিট পর' : '15-20 min after sunrise',
        'rakaat': isBn ? '২ রাকাত' : '2 rakats',
        'desc': isBn
            ? 'ফজর জামাতে পড়ে সূর্যোদয় পর্যন্ত বসে জিকির করে পড়লে হজ্জ ও উমরার সওয়াব পাওয়া যায়।'
            : 'Pray Fajr in congregation, sit in dhikr until sunrise — reward equals Hajj & Umrah.',
        'color': const Color(0xFFFF8F00),
      },
      {
        'icon': '☀️',
        'name': isBn ? 'দুহা / চাশত' : 'Duha / Chasht',
        'time': chashtStart != null && chashtEnd != null
            ? '${_fmt(chashtStart)} - ${_fmt(chashtEnd)}'
            : isBn ? 'সকাল থেকে দুপুরের আগে' : 'Morning to before noon',
        'rakaat': isBn ? '২ - ১২ রাকাত' : '2-12 rakats',
        'desc': isBn
            ? 'রিজিক বৃদ্ধি ও বরকতের আমল। রাসূল ﷺ নিয়মিত উৎসাহ দিয়েছেন। প্রতিদিনের সদকার বিনিময়।'
            : 'For increase in sustenance and blessings.',
        'color': const Color(0xFFFDD835),
      },
      {
        'icon': '🕌',
        'name': isBn ? 'জাওয়াল' : 'Zawal',
        'time': pt != null
            ? '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}'
            : isBn ? 'যোহরের ঠিক আগে' : 'Just before Dhuhr',
        'rakaat': isBn ? '২ - ৪ রাকাত' : '2-4 rakats',
        'desc': isBn
            ? 'সূর্য ঢলার সময় পড়া হয়। দিনের তাহাজ্জুদ বলা হয়।'
            : 'Called daytime Tahajjud.',
        'color': const Color(0xFF66BB6A),
      },
      {
        'icon': '🌆',
        'name': isBn ? 'আওয়াবিন' : 'Awwabin',
        'time': pt != null
            ? '${_fmt(pt.maghrib)} - ${_fmt(pt.isha)}'
            : isBn ? 'মাগরিব ও এশার মাঝে' : 'Between Maghrib & Isha',
        'rakaat': isBn ? '৬ রাকাত (সর্বোচ্চ ২০)' : '6 rakats (max 20)',
        'desc': isBn
            ? '৬ রাকাত পড়লে ১২ বছরের ইবাদতের সওয়াব ও গুনাহ মাফের আশা।'
            : '6 rakats brings reward equal to 12 years of worship.',
        'color': const Color(0xFF26A69A),
      },
      {
        'icon': '💧',
        'name': isBn ? 'তাহিয়্যাতুল ওযু' : 'Tahiyyatul Wudu',
        'time': isBn ? 'অজুর পরপরই' : 'Right after Wudu',
        'rakaat': isBn ? '২ রাকাত' : '2 rakats',
        'desc': isBn
            ? 'অজুর পর পড়লে জান্নাতের সুসংবাদ এসেছে।'
            : 'Glad tidings of Jannah for praying after Wudu.',
        'color': const Color(0xFF29B6F6),
      },
      {
        'icon': '🏛️',
        'name': isBn ? 'তাহিয়্যাতুল মসজিদ' : 'Tahiyyatul Masjid',
        'time': isBn ? 'মসজিদে প্রবেশের পর বসার আগে' : 'Before sitting in mosque',
        'rakaat': isBn ? '২ রাকাত' : '2 rakats',
        'desc': isBn
            ? 'মসজিদে প্রবেশ করলে বসার আগে ২ রাকাত পড়া সুন্নত।'
            : 'Sunnah to pray 2 rakats before sitting in mosque.',
        'color': const Color(0xFF66BB6A),
      },
      {
        'icon': '😢',
        'name': isBn ? 'সালাতুত তাওবা' : 'Salatul Tawbah',
        'time': isBn ? 'গুনাহ হয়ে গেলে' : 'After committing a sin',
        'rakaat': isBn ? '২ রাকাত' : '2 rakats',
        'desc': isBn
            ? 'গুনাহ হলে ২ রাকাত পড়ে আন্তরিক তাওবা করলে আল্লাহ ক্ষমা করেন।'
            : 'Pray 2 rakats and make sincere repentance — Allah forgives.',
        'color': const Color(0xFFEF5350),
      },
      {
        'icon': '🤲',
        'name': isBn ? 'সালাতুল হাজত' : 'Salatul Hajat',
        'time': isBn ? 'কোনো প্রয়োজনে' : 'When in need',
        'rakaat': isBn ? '২ রাকাত' : '2 rakats',
        'desc': isBn
            ? 'কোনো প্রয়োজন বা সমস্যা সমাধানের জন্য পড়া হয়।'
            : 'Prayed for any need or problem.',
        'color': const Color(0xFF7E57C2),
      },
      {
        'icon': '🤔',
        'name': isBn ? 'সালাতুল ইস্তিখারা' : 'Salatul Istikhara',
        'time': isBn ? 'গুরুত্বপূর্ণ সিদ্ধান্তের আগে' : 'Before important decisions',
        'rakaat': isBn ? '২ রাকাত' : '2 rakats',
        'desc': isBn
            ? 'গুরুত্বপূর্ণ সিদ্ধান্ত নেওয়ার আগে পড়া হয়। সঠিক পথের জন্য আল্লাহর সাহায্য চাওয়া।'
            : 'Seeking Allah\'s guidance before important decisions.',
        'color': const Color(0xFF26C6DA),
      },
      {
        'icon': '📿',
        'name': isBn ? 'সালাতুত তাসবীহ' : 'Salatus Tasbeeh',
        'time': isBn ? 'যেকোনো সময় (নিষিদ্ধ সময় ছাড়া)' : 'Anytime (except forbidden)',
        'rakaat': isBn ? '৪ রাকাত' : '4 rakats',
        'desc': isBn
            ? 'প্রতি রাকাতে ৭৫ বার করে মোট ৩০০ বার তাসবীহ পড়তে হয়। গুনাহ মাফের গুরুত্বপূর্ণ আমল।'
            : '75 tasbeeh per rakat, total 300. Important for forgiveness.',
        'color': const Color(0xFFEC407A),
      },
      {
        'icon': '🌙',
        'name': isBn ? 'শবে কদরের নামাজ' : 'Laylatul Qadr Prayer',
        'time': isBn ? 'রমজানের শেষ ১০ রাত (বিজোড়)' : 'Last 10 nights of Ramadan (odd)',
        'rakaat': isBn ? 'যত বেশি পারা যায়' : 'As many as possible',
        'desc': isBn
            ? 'শবে কদর হাজার মাসের চেয়ে উত্তম। বিশেষ দোয়া: اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي'
            : 'Laylatul Qadr is better than 1000 months.',
        'color': const Color(0xFF7C4DFF),
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _sectionHeader('⭐', isBn ? 'নফল সালাতের সময় ও ফজিলত' : 'Nafl Prayer Times & Virtues', AppTheme.gold),
        const SizedBox(height: 10),
        ...nafls.map((n) => _NaflCard(
              icon: n['icon'] as String,
              name: n['name'] as String,
              time: n['time'] as String,
              rakaat: n['rakaat'] as String,
              desc: n['desc'] as String,
              color: n['color'] as Color,
            )),
        const SizedBox(height: 16),
        _sectionHeader('⛔', isBn ? 'নামাজের নিষিদ্ধ সময়' : 'Forbidden Prayer Times', AppTheme.missed),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
          ),
          child: Column(children: [
            Text(
              isBn ? 'এই সময়গুলোতে নফল নামাজ পড়া যাবে না:' : 'Nafl prayers are forbidden at these times:',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (pt != null) ...[
              _ForbiddenRow(isBn ? '১. সূর্যোদয়ের সময়' : '1. At Sunrise',
                  '${_fmt(pt.sunrise)} - ${_fmt(pt.sunrise.add(const Duration(minutes: 15)))}',
                  isBn ? 'সূর্যোদয়ের ১৫ মিনিট পর্যন্ত' : 'For 15 min after sunrise'),
              _ForbiddenRow(isBn ? '২. সূর্য ঠিক মাথার ওপরে' : '2. Sun at zenith',
                  '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}',
                  isBn ? 'দ্বিপ্রহর (প্রায় ৫ মিনিট)' : 'Noon (approx 5 min)'),
              _ForbiddenRow(isBn ? '৩. সূর্যাস্তের সময়' : '3. At Sunset',
                  '${_fmt(pt.maghrib.subtract(const Duration(minutes: 15)))} - ${_fmt(pt.maghrib)}',
                  isBn ? 'সূর্যাস্তের ১৫ মিনিট আগে' : '15 min before sunset'),
              _ForbiddenRow(isBn ? '৪. ফজরের পর থেকে সূর্যোদয় পর্যন্ত' : '4. After Fajr until sunrise',
                  '${_fmt(pt.fajr)} - ${_fmt(pt.sunrise)}',
                  isBn ? 'ফজরের ফরজের পর থেকে' : 'After Fajr Fard'),
              _ForbiddenRow(isBn ? '৫. আসরের পর থেকে সূর্যাস্ত পর্যন্ত' : '5. After Asr until sunset',
                  '${_fmt(pt.asr)} - ${_fmt(pt.maghrib)}',
                  isBn ? 'আসরের ফরজের পর থেকে' : 'After Asr Fard'),
            ],
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ══════════════════════════════════════════
  // Tab 2: নফল রোজা
  Widget _buildFastingTab(bool isBn, int hijriDay) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _sectionHeader('🌙', isBn ? 'নফল রোজার ফজিলত' : 'Nafl Fasting Virtues', AppTheme.gold),
        const SizedBox(height: 10),
        _FastCard(icon: '🌟', title: isBn ? 'আইয়ামে বিজ (প্রতি মাসে ৩ দিন)' : 'Ayyam al-Beed',
          dates: isBn ? 'প্রতি হিজরি মাসের ১৩, ১৪ ও ১৫ তারিখ' : '13th, 14th & 15th Hijri',
          desc: isBn ? '"রাসূল ﷺ প্রতি মাসের তিন রোজার অসিয়ত করেছেন।" — বুখারী\nফজিলত: পুরো মাস রোজার সওয়াব।' : '"The Prophet advised three fasts every month." — Bukhari',
          color: AppTheme.gold,
          alert: hijriDay >= 13 && hijriDay <= 15 ? (isBn ? '🎉 আজ আইয়ামে বিজের রোজার দিন!' : '🎉 Today is Ayyam al-Beed!') : null),
        _FastCard(icon: '🏆', title: isBn ? 'শাওয়ালের ৬ রোজা' : '6 Fasts of Shawwal',
          dates: isBn ? 'শাওয়াল মাসে যেকোনো ৬ দিন' : 'Any 6 days in Shawwal',
          desc: isBn ? '"রমজানের পর শাওয়ালে ৬টি রোজা রাখলে সারা বছর রোজা রাখার সওয়াব।" — সহিহ মুসলিম' : '"Fasting 6 days in Shawwal after Ramadan equals fasting the whole year." — Sahih Muslim',
          color: const Color(0xFF66BB6A)),
        _FastCard(icon: '🕋', title: isBn ? 'আরাফার রোজা (৯ জিলহজ)' : 'Arafah Fast',
          dates: isBn ? 'জিলহজ মাসের ৯ তারিখ' : '9th of Dhul Hijjah',
          desc: isBn ? '"আরাফার রোজায় আগের ও পরের এক বছরের গুনাহ মাফ।" — সহিহ মুসলিম\n⚠️ হাজীদের জন্য নয়।' : '"Arafah fast expiates sins of previous and next year." — Sahih Muslim\n⚠️ Not for pilgrims.',
          color: const Color(0xFFFF8F00)),
        _FastCard(icon: '📅', title: isBn ? 'আশুরার রোজা (১০ মুহাররম)' : 'Ashura Fast',
          dates: isBn ? '৯+১০ অথবা ১০+১১ মুহাররম' : '9+10 or 10+11 Muharram',
          desc: isBn ? '"আশুরার রোজায় আগের এক বছরের গুনাহ মাফ হয়।" — সহিহ মুসলিম' : '"Ashura fast expiates sins of previous year." — Sahih Muslim',
          color: const Color(0xFF26A69A)),
        _FastCard(icon: '📅', title: isBn ? 'সোমবার ও বৃহস্পতিবার' : 'Monday & Thursday',
          dates: isBn ? 'প্রতি সপ্তাহের সোমবার ও বৃহস্পতিবার' : 'Every Monday and Thursday',
          desc: isBn ? '"এই দুই দিনে আমল আল্লাহর কাছে পেশ করা হয়।" — তিরমিযী' : '"Deeds are presented to Allah on these days." — Tirmidhi',
          color: const Color(0xFF7C4DFF)),
        _FastCard(icon: '🌙', title: isBn ? 'শা\'বান মাসের রোজা' : 'Sha\'ban Fasts',
          dates: isBn ? 'শা\'বান মাসের প্রথমার্ধ' : 'First half of Sha\'ban',
          desc: isBn ? 'রাসূল ﷺ শা\'বান মাসে বেশি নফল রোজা রাখতেন। রমজানের পূর্ব প্রস্তুতি।' : 'Prophet ﷺ fasted frequently in Sha\'ban. Preparation before Ramadan.',
          color: const Color(0xFFEC407A)),
        _FastCard(icon: '📿', title: isBn ? 'যিলহজের প্রথম ৯ দিন' : 'First 9 Days of Dhul Hijjah',
          dates: isBn ? 'যিলহজ ১-৯ তারিখ' : 'Dhul Hijjah 1-9',
          desc: isBn ? '"এই দিনগুলোতে নেক আমল আল্লাহর কাছে সবচেয়ে প্রিয়।" — বুখারী' : '"Good deeds in these days are most beloved to Allah." — Bukhari',
          color: const Color(0xFFFFB300)),
        _FastCard(icon: '🔄', title: isBn ? 'দাউদ (আ.)-এর রোজা' : 'Fast of Dawud (AS)',
          dates: isBn ? 'একদিন রোজা, একদিন বিরতি' : 'Fast one day, skip one day',
          desc: isBn ? '"আল্লাহর কাছে সবচেয়ে পছন্দের রোজা হলো দাউদ (আ.)-এর রোজা।" — বুখারী' : '"Most beloved fast to Allah is that of Dawud." — Bukhari',
          color: const Color(0xFF29B6F6)),
        const SizedBox(height: 16),
        _sectionHeader('❌', isBn ? 'নিষিদ্ধ রোজা' : 'Forbidden Fasts', AppTheme.missed),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
          ),
          child: Column(children: [
            _ProhibitedRow('❌', isBn ? 'ঈদুল ফিতর ও ঈদুল আযহার দিন' : 'Eid al-Fitr & Eid al-Adha',
              isBn ? 'এই দুই দিন রোজা রাখা হারাম।' : 'Fasting on these two days is Haram.'),
            _ProhibitedRow('❌', isBn ? 'আইয়ামে তাশরীক (১১, ১২, ১৩ যিলহজ)' : 'Ayyam al-Tashriq',
              isBn ? 'এই তিন দিন খাওয়া-দাওয়া ও জিকিরের দিন।' : 'Three days of eating, drinking and dhikr.'),
            _ProhibitedRow('❌', isBn ? 'বিরতিহীন রোজা (সাওমে বিসাল)' : 'Continuous Fasting',
              isBn ? 'ইফতার ও সেহরি ছাড়া টানা রোজা নিষিদ্ধ।' : 'Fasting without iftar/sehri is forbidden.'),
            _ProhibitedRow('❌', isBn ? 'শুধু শুক্রবার রোজা' : 'Only Friday Fast',
              isBn ? 'বৃহস্পতি বা শনিবার ছাড়া শুধু শুক্রবার রোজা নিরুৎসাহিত।' : 'Friday fast alone is discouraged.'),
            _ProhibitedRow('❌', isBn ? 'সারা বছর প্রতিদিন রোজা' : 'Fasting every day all year',
              isBn ? 'প্রতিদিন রোজা রাখা নিষেধ।' : 'Fasting every single day is forbidden.'),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ══════════════════════════════════════════
  // Tab 3: নফল/সুন্নত আমল
  Widget _buildAmalTab(bool isBn) {
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
                    color: color, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => _AmalCard(
                  num: item['num'] as String,
                  title: item['title'] as String,
                  desc: item['desc'] as String,
                  color: color,
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ══ Widgets ═══════════════════════════════

class _NaflCard extends StatelessWidget {
  final String icon, name, time, rakaat, desc;
  final Color color;
  const _NaflCard({
    required this.icon,
    required this.name,
    required this.time,
    required this.rakaat,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text(name,
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.access_time, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(child: Text(time,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.format_list_numbered, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Text(rakaat, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text(desc,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}

class _FastCard extends StatelessWidget {
  final String icon, title, dates, desc;
  final Color color;
  final String? alert;
  const _FastCard({
    required this.icon,
    required this.title,
    required this.dates,
    required this.desc,
    required this.color,
    this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text(title,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(child: Text(dates,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        Text(desc,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        if (alert != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(alert!,
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }
}

class _ForbiddenRow extends StatelessWidget {
  final String title, time, desc;
  const _ForbiddenRow(this.title, this.time, this.desc);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.missed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.missed.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(time,
            style: const TextStyle(color: AppTheme.missed, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(desc,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

class _ProhibitedRow extends StatelessWidget {
  final String icon, title, desc;
  const _ProhibitedRow(this.icon, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: AppTheme.missed, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(desc,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }
}

class _AmalCard extends StatefulWidget {
  final String num, title, desc;
  final Color color;
  const _AmalCard({
    required this.num,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  State<_AmalCard> createState() => _AmalCardState();
}

class _AmalCardState extends State<_AmalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withOpacity(0.3)),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_expanded ? 0.15 : 0.05),
              borderRadius: _expanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12))
                  : BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(widget.num,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(
                        color: widget.color, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: widget.color,
                size: 20,
              ),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Text(widget.desc,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13, height: 1.6)),
          ),
      ]),
    );
  }
}

Widget _sectionHeader(String icon, String title, Color color) {
  return Row(children: [
    Text(icon, style: const TextStyle(fontSize: 22)),
    const SizedBox(width: 10),
    Expanded(
        child: Text(title,
            style: TextStyle(
                color: color, fontSize: 17, fontWeight: FontWeight.bold))),
  ]);
}
