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
  int _tabIndex = 0; // 0 = নামাজ, 1 = রোজা

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
      final l3 = l2 - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
          ((j) ~/ 16) * ((15238 * j) ~/ 43) + 29;
      final m = (24 * l3) ~/ 709;
      return l3 - (709 * m) ~/ 24;
    } catch (_) { return 0; }
  }

  int _gjToJul(int y, int m, int d) {
    int a = (14 - m) ~/ 12;
    int yr = y + 4800 - a;
    int mo = m + 12 * a - 3;
    return d + (153 * mo + 2) ~/ 5 + 365 * yr + yr ~/ 4 - yr ~/ 100 + yr ~/ 400 - 32045;
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
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : Column(
              children: [
                // Tab selector
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mosque, color: _tabIndex == 0 ? Colors.white : AppTheme.textSecondary, size: 18),
                              const SizedBox(width: 6),
                              Text(isBn ? 'নফল নামাজ' : 'Nafl Prayer',
                                style: TextStyle(
                                  color: _tabIndex == 0 ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      )),
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.brightness_3, color: _tabIndex == 1 ? Colors.white : AppTheme.textSecondary, size: 18),
                              const SizedBox(width: 6),
                              Text(isBn ? 'নফল রোজা' : 'Nafl Fasting',
                                style: TextStyle(
                                  color: _tabIndex == 1 ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),

                Expanded(
                  child: _tabIndex == 0
                      ? _buildPrayerTab(isBn, pt, ishraqStart, ishraqEnd, chashtStart, chashtEnd, tahaqqudStart, tahaqqudEnd)
                      : _buildFastingTab(isBn, h),
                ),
              ],
            ),
    );
  }

  Widget _buildPrayerTab(bool isBn, PrayerTimes? pt,
      DateTime? ishraqStart, DateTime? ishraqEnd,
      DateTime? chashtStart, DateTime? chashtEnd,
      DateTime? tahaqqudStart, DateTime? tahaqqudEnd) {

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // নফল নামাজ কী
        _sectionHeader('📖', isBn ? 'নফল নামাজ কী?' : 'What is Nafl Prayer?', AppTheme.gold),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Text(
            isBn
                ? 'ফরজ, ওয়াজিব ও সুন্নতে মুআক্কাদা নামাজ ছাড়া অতিরিক্ত ইবাদতের উদ্দেশ্যে যে নামাজ আদায় করা হয় তাকে নফল নামাজ বলা হয়। নফল নামাজ আল্লাহর নৈকট্য অর্জন, গুনাহ মাফ এবং বেশি সওয়াব লাভের অন্যতম মাধ্যম।'
                : 'Prayers performed beyond Fard, Wajib and Sunnah Muakkadah are called Nafl prayers. They are a means to gain closeness to Allah, forgiveness of sins, and extra rewards.',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6),
          ),
        ),

        const SizedBox(height: 16),
        _sectionHeader('⭐', isBn ? 'গুরুত্বপূর্ণ নফল নামাজ' : 'Important Nafl Prayers', AppTheme.gold),
        const SizedBox(height: 10),

        // নির্দিষ্ট সময়ের নফল নামাজ
        _NaflCard(icon: '🌙', name: isBn ? 'তাহাজ্জুদ' : 'Tahajjud',
          time: tahaqqudStart != null && tahaqqudEnd != null ? '${_fmt(tahaqqudStart)} - ${_fmt(tahaqqudEnd)}' : isBn ? 'রাতের শেষ তৃতীয়াংশ' : 'Last third of night',
          rakaat: isBn ? '২ - ১২ রাকাত' : '2-12 rakats',
          desc: isBn ? '"ফরজ নামাজের পর সর্বোত্তম নামাজ হলো রাতের তাহাজ্জুদ।" — সহিহ মুসলিম\nএশার পর ঘুমিয়ে উঠে শেষ রাতে পড়া উত্তম।' : '"Best prayer after Fard is night Tahajjud." — Sahih Muslim\nSleep after Isha and wake up in last third.',
          color: const Color(0xFF7C4DFF)),

        _NaflCard(icon: '🌅', name: isBn ? 'ইশরাক' : 'Ishraq',
          time: ishraqStart != null && ishraqEnd != null ? '${_fmt(ishraqStart)} - ${_fmt(ishraqEnd)}' : isBn ? 'সূর্যোদয়ের ১৫-২০ মিনিট পর' : '15-20 min after sunrise',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'ফজর জামাতে পড়ে সূর্যোদয় পর্যন্ত বসে জিকির করে পড়লে হজ্জ ও উমরার সওয়াব পাওয়া যায়।' : 'Pray Fajr in congregation, sit in dhikr until sunrise, then pray — reward equals Hajj & Umrah.',
          color: const Color(0xFFFF8F00)),

        _NaflCard(icon: '☀️', name: isBn ? 'দুহা / চাশত' : 'Duha / Chasht',
          time: chashtStart != null && chashtEnd != null ? '${_fmt(chashtStart)} - ${_fmt(chashtEnd)}' : isBn ? 'সকাল থেকে দুপুরের আগে' : 'Morning to before noon',
          rakaat: isBn ? '২ - ১২ রাকাত' : '2-12 rakats',
          desc: isBn ? 'রিজিক বৃদ্ধি ও বরকতের আমল। রাসূল ﷺ নিয়মিত উৎসাহ দিয়েছেন। প্রতিদিনের সদকার বিনিময়।' : 'For increase in sustenance and blessings. Prophet encouraged regularly. Equivalent of daily charity.',
          color: const Color(0xFFFDD835)),

        _NaflCard(icon: '🕌', name: isBn ? 'জাওয়াল' : 'Zawal',
          time: pt != null ? '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}' : isBn ? 'যোহরের ঠিক আগে' : 'Just before Dhuhr',
          rakaat: isBn ? '২ - ৪ রাকাত' : '2-4 rakats',
          desc: isBn ? 'সূর্য ঢলার সময় পড়া হয়। দিনের তাহাজ্জুদ বলা হয়। এ সময় আল্লাহর রহমতের দরজা খোলে।' : 'Prayed when sun declines. Called daytime Tahajjud. Doors of mercy open at this time.',
          color: const Color(0xFF66BB6A)),

        _NaflCard(icon: '🌆', name: isBn ? 'আওয়াবিন' : 'Awwabin',
          time: pt != null ? '${_fmt(pt.maghrib)} - ${_fmt(pt.isha)}' : isBn ? 'মাগরিব ও এশার মাঝে' : 'Between Maghrib & Isha',
          rakaat: isBn ? '৬ রাকাত (সর্বোচ্চ ২০)' : '6 rakats (max 20)',
          desc: isBn ? '৬ রাকাত পড়লে ১২ বছরের ইবাদতের সওয়াব ও গুনাহ মাফের আশা করা হয়।' : '6 rakats brings reward equal to 12 years of worship and hope for forgiveness.',
          color: const Color(0xFF26A69A)),

        _NaflCard(icon: '💧', name: isBn ? 'তাহিয়্যাতুল ওযু' : 'Tahiyyatul Wudu',
          time: isBn ? 'অজুর পরপরই' : 'Right after Wudu',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'অজুর পর পড়লে জান্নাতের সুসংবাদ এসেছে। অজুর কৃতজ্ঞতা প্রকাশ পায়।' : 'Glad tidings of Jannah for praying after Wudu. Expression of gratitude.',
          color: const Color(0xFF29B6F6)),

        _NaflCard(icon: '🏛️', name: isBn ? 'তাহিয়্যাতুল মসজিদ' : 'Tahiyyatul Masjid',
          time: isBn ? 'মসজিদে প্রবেশের পর বসার আগে' : 'After entering mosque, before sitting',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'মসজিদে প্রবেশ করলে বসার আগে ২ রাকাত পড়া সুন্নত। মসজিদের সম্মান প্রদর্শন।' : 'Sunnah to pray 2 rakats before sitting in mosque. Shows respect for the mosque.',
          color: const Color(0xFF66BB6A)),

        _NaflCard(icon: '😢', name: isBn ? 'সালাতুত তাওবা' : 'Salatul Tawbah',
          time: isBn ? 'গুনাহ হয়ে গেলে যেকোনো সময়' : 'Anytime after committing a sin',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'গুনাহ হলে ২ রাকাত পড়ে আন্তরিক তাওবা করলে আল্লাহ ক্ষমা করেন।' : 'After a sin, pray 2 rakats and make sincere repentance — Allah forgives.',
          color: const Color(0xFFEF5350)),

        _NaflCard(icon: '🤲', name: isBn ? 'সালাতুল হাজত' : 'Salatul Hajat',
          time: isBn ? 'কোনো প্রয়োজনে' : 'When in need',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'কোনো প্রয়োজন বা সমস্যা সমাধানের জন্য পড়া হয়। আল্লাহর সাহায্য চাওয়ার পদ্ধতি।' : 'Prayed for any need or problem. A way to seek Allah\'s help.',
          color: const Color(0xFF7E57C2)),

        _NaflCard(icon: '🎉', name: isBn ? 'সালাতুশ শোকর' : 'Salatus Shukr',
          time: isBn ? 'কোনো নেয়ামত বা সুখবরে' : 'Upon receiving a blessing',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'কোনো নেয়ামত বা সুখবর পেলে আল্লাহর প্রতি কৃতজ্ঞতা প্রকাশে পড়া হয়।' : 'Prayed to express gratitude to Allah upon receiving a blessing or good news.',
          color: const Color(0xFFFFB300)),

        _NaflCard(icon: '🤔', name: isBn ? 'সালাতুল ইস্তিখারা' : 'Salatul Istikhara',
          time: isBn ? 'গুরুত্বপূর্ণ সিদ্ধান্তের আগে' : 'Before important decisions',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'গুরুত্বপূর্ণ সিদ্ধান্ত নেওয়ার আগে পড়া হয়। সঠিক পথের জন্য আল্লাহর কাছে সাহায্য চাওয়া।' : 'Prayed before important decisions. Seeking Allah\'s guidance for the right path.',
          color: const Color(0xFF26C6DA)),

        _NaflCard(icon: '📿', name: isBn ? 'সালাতুত তাসবীহ' : 'Salatus Tasbeeh',
          time: isBn ? 'যেকোনো সময় (নিষিদ্ধ সময় ছাড়া)' : 'Anytime (except forbidden times)',
          rakaat: isBn ? '৪ রাকাত' : '4 rakats',
          desc: isBn ? 'বিশেষ তাসবীহসহ আদায়। প্রতি রাকাতে ৭৫ বার করে মোট ৩০০ বার তাসবীহ পড়তে হয়। গুনাহ মাফের গুরুত্বপূর্ণ আমল।' : 'With special tasbeeh. 75 times per rakat, total 300. Important deed for forgiveness of sins.',
          color: const Color(0xFFEC407A)),

        _NaflCard(icon: '🌧️', name: isBn ? 'সালাতুল ইস্তিস্কা' : 'Salatul Istisqa',
          time: isBn ? 'খরার সময়' : 'During drought',
          rakaat: isBn ? '২ রাকাত' : '2 rakats',
          desc: isBn ? 'খরা বা অনাবৃষ্টির সময় বৃষ্টির জন্য দোয়া স্বরূপ পড়া হয়।' : 'Prayed during drought or lack of rain as a supplication for rain.',
          color: const Color(0xFF29B6F6)),

        _NaflCard(icon: '🌑', name: isBn ? 'কুসুফ ও খুসুফ' : 'Kusuf & Khusuf',
          time: isBn ? 'সূর্য/চন্দ্রগ্রহণের সময়' : 'During solar/lunar eclipse',
          rakaat: isBn ? '২ রাকাত (দীর্ঘ)' : '2 long rakats',
          desc: isBn ? 'সূর্যগ্রহণে কুসুফ এবং চন্দ্রগ্রহণে খুসুফের নামাজ পড়া হয়। আল্লাহর নিদর্শনের সময় ইবাদত।' : 'Kusuf for solar eclipse, Khusuf for lunar eclipse. Worship at the time of Allah\'s signs.',
          color: const Color(0xFF78909C)),

        _NaflCard(icon: '🌙', name: isBn ? 'শবে কদরের নামাজ' : 'Laylatul Qadr Prayer',
          time: isBn ? 'রমজানের শেষ ১০ রাত (বিজোড়)' : 'Last 10 nights of Ramadan (odd)',
          rakaat: isBn ? 'যত বেশি পারা যায়' : 'As many as possible',
          desc: isBn ? 'শবে কদর হাজার মাসের চেয়ে উত্তম। বিশেষ দোয়া: اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي' : 'Laylatul Qadr is better than 1000 months. Special dua: "Allahumma innaka \'afuwwun tuhibbul \'afwa fa\'fu \'anni"',
          color: const Color(0xFF7C4DFF)),

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isBn ? 'এই সময়গুলোতে নফল নামাজ পড়া যাবে না:' : 'Nafl prayers are forbidden at these times:',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
              const SizedBox(height: 12),
              _ForbiddenRow(isBn ? '১. সূর্যোদয়ের সময়' : '1. At Sunrise',
                pt != null ? '${_fmt(pt.sunrise)} - ${_fmt(pt.sunrise.add(const Duration(minutes: 15)))}' : '--',
                isBn ? 'সূর্যোদয়ের ১৫ মিনিট পর্যন্ত' : 'For 15 min after sunrise'),
              _ForbiddenRow(isBn ? '২. সূর্য ঠিক মাথার ওপরে' : '2. Sun at zenith',
                pt != null ? '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}' : '--',
                isBn ? 'দ্বিপ্রহর (প্রায় ৫ মিনিট)' : 'Noon (approx 5 min)'),
              _ForbiddenRow(isBn ? '৩. সূর্যাস্তের সময়' : '3. At Sunset',
                pt != null ? '${_fmt(pt.maghrib.subtract(const Duration(minutes: 15)))} - ${_fmt(pt.maghrib)}' : '--',
                isBn ? 'সূর্যাস্তের ১৫ মিনিট আগে' : '15 min before sunset'),
              _ForbiddenRow(isBn ? '৪. ফজরের পর থেকে সূর্যোদয় পর্যন্ত' : '4. After Fajr until sunrise',
                pt != null ? '${_fmt(pt.fajr)} - ${_fmt(pt.sunrise)}' : '--',
                isBn ? 'ফজরের ফরজের পর থেকে' : 'After Fajr Fard'),
              _ForbiddenRow(isBn ? '৫. আসরের পর থেকে সূর্যাস্ত পর্যন্ত' : '5. After Asr until sunset',
                pt != null ? '${_fmt(pt.asr)} - ${_fmt(pt.maghrib)}' : '--',
                isBn ? 'আসরের ফরজের পর থেকে' : 'After Asr Fard'),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFastingTab(bool isBn, int hijriDay) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _sectionHeader('🌙', isBn ? 'নফল রোজা কী?' : 'What is Nafl Fasting?', AppTheme.gold),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
          child: Text(
            isBn ? 'রমজানের ফরজ রোজা ছাড়া অতিরিক্ত ইবাদতের উদ্দেশ্যে যে রোজা রাখা হয় তাকে নফল রোজা বলে। এটি আল্লাহর নৈকট্য অর্জন ও গুনাহ মাফের বিশেষ আমল।'
                : 'Fasts beyond obligatory Ramadan fasting are called Nafl fasts. They are special deeds for gaining closeness to Allah and forgiveness of sins.',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6)),
        ),

        const SizedBox(height: 16),
        _sectionHeader('✅', isBn ? 'গুরুত্বপূর্ণ নফল রোজা' : 'Important Nafl Fasts', AppTheme.completed),
        const SizedBox(height: 10),

        _FastCard(icon: '🌟', title: isBn ? 'আইয়ামে বিজ (প্রতি মাসে ৩ দিন)' : 'Ayyam al-Beed (3 days/month)',
          dates: isBn ? 'প্রতি হিজরি মাসের ১৩, ১৪ ও ১৫ তারিখ' : '13th, 14th & 15th of every Hijri month',
          desc: isBn ? '"রাসূল ﷺ আমাকে তিনটি বিষয়ে অসিয়ত করেছেন: প্রতি মাসের তিন রোজা..." — বুখারী\nফজিলত: পুরো মাস রোজার সওয়াব।' : '"The Prophet advised me three things: three fasts every month..." — Bukhari\nVirtue: Equal to fasting the whole month.',
          color: AppTheme.gold,
          alert: hijriDay >= 13 && hijriDay <= 15 ? (isBn ? '🎉 আজ আইয়ামে বিজের রোজার দিন!' : '🎉 Today is Ayyam al-Beed!') : null),

        _FastCard(icon: '🏆', title: isBn ? 'শাওয়ালের ৬ রোজা' : '6 Fasts of Shawwal',
          dates: isBn ? 'শাওয়াল মাসে যেকোনো ৬ দিন' : 'Any 6 days in Shawwal month',
          desc: isBn ? '"যে ব্যক্তি রমজানের রোজা রাখল, তারপর শাওয়ালে ৬টি রোজা রাখল, সে যেন সারা বছর রোজা রাখল।" — সহিহ মুসলিম' : '"Whoever fasts Ramadan then follows it with 6 Shawwal — it is as if he fasted the whole year." — Sahih Muslim',
          color: const Color(0xFF66BB6A)),

        _FastCard(icon: '🕋', title: isBn ? 'আরাফার রোজা (৯ জিলহজ)' : 'Arafah Fast (9 Dhul Hijjah)',
          dates: isBn ? 'জিলহজ মাসের ৯ তারিখ' : '9th of Dhul Hijjah',
          desc: isBn ? '"আরাফার দিনের রোজায় আগের ও পরের এক বছরের গুনাহ মাফ করা হয়।" — সহিহ মুসলিম\n⚠️ হাজীদের জন্য নয়।' : '"Arafah fast expiates sins of previous and next year." — Sahih Muslim\n⚠️ Not for pilgrims.',
          color: const Color(0xFFFF8F00)),

        _FastCard(icon: '📅', title: isBn ? 'আশুরার রোজা (১০ মুহাররম)' : 'Ashura Fast (10 Muharram)',
          dates: isBn ? '৯+১০ অথবা ১০+১১ মুহাররম' : '9+10 or 10+11 Muharram',
          desc: isBn ? '"আশুরার রোজায় আগের এক বছরের গুনাহ মাফ হয়।" — সহিহ মুসলিম\nইহুদিদের বিরোধিতায় ৯ বা ১১ তারিখ মিলিয়ে রাখা উত্তম।' : '"Ashura fast expiates sins of previous year." — Sahih Muslim\nBest to add 9th or 11th to differ from Jews.',
          color: const Color(0xFF26A69A)),

        _FastCard(icon: '📅', title: isBn ? 'সোমবার ও বৃহস্পতিবার' : 'Monday & Thursday',
          dates: isBn ? 'প্রতি সপ্তাহের সোমবার ও বৃহস্পতিবার' : 'Every Monday and Thursday',
          desc: isBn ? '"এই দুই দিনে আমল আল্লাহর কাছে পেশ করা হয়, আমি চাই আমার আমল পেশের সময় আমি রোজাদার থাকি।" — নবীজি ﷺ' : '"Deeds are presented to Allah on these days. I love my deeds to be presented while I am fasting." — Prophet ﷺ',
          color: const Color(0xFF7C4DFF)),

        _FastCard(icon: '🌙', title: isBn ? 'শা\'বান মাসের রোজা' : 'Sha\'ban Month Fasts',
          dates: isBn ? 'শা\'বান মাসের প্রথমার্ধ' : 'First half of Sha\'ban',
          desc: isBn ? 'রাসূল ﷺ শা\'বান মাসে বেশি নফল রোজা রাখতেন। রমজানের পূর্ব প্রস্তুতি হিসেবে গুরুত্বপূর্ণ।' : 'Prophet ﷺ used to fast frequently in Sha\'ban. Important as preparation before Ramadan.',
          color: const Color(0xFFEC407A)),

        _FastCard(icon: '📿', title: isBn ? 'যিলহজের প্রথম ১০ দিন' : 'First 10 Days of Dhul Hijjah',
          dates: isBn ? 'যিলহজ ১-৯ তারিখ (১০ তারিখ ঈদ)' : 'Dhul Hijjah 1-9 (10th is Eid)',
          desc: isBn ? '"এই দিনগুলোতে নেক আমল আল্লাহর কাছে সবচেয়ে প্রিয়।" — বুখারী\nযিলহজের প্রথম ১০ দিন সর্বোত্তম দিন।' : '"Good deeds in these days are most beloved to Allah." — Bukhari\nBest days of the year.',
          color: const Color(0xFFFFB300)),

        _FastCard(icon: '🔄', title: isBn ? 'দাউদ (আ.)-এর রোজা' : 'Fast of Dawud (AS)',
          dates: isBn ? 'একদিন রোজা, একদিন বিরতি' : 'Fast one day, skip one day',
          desc: isBn ? '"আল্লাহর কাছে সবচেয়ে পছন্দের রোজা হলো দাউদ (আ.)-এর রোজা — একদিন রাখতেন একদিন ছাড়তেন।" — বুখারী' : '"Most beloved fast to Allah is that of Dawud — he fasted one day and broke fast next day." — Bukhari',
          color: const Color(0xFF29B6F6)),

        const SizedBox(height: 16),
        _sectionHeader('❌', isBn ? 'নিষিদ্ধ রোজা' : 'Forbidden Fasts', AppTheme.missed),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.missed.withOpacity(0.4))),
          child: Column(
            children: [
              _ProhibitedRow('❌', isBn ? 'ঈদুল ফিতর ও ঈদুল আযহার দিন' : 'Eid al-Fitr & Eid al-Adha',
                isBn ? 'এই দুই দিন রোজা রাখা হারাম।' : 'Fasting on these two days is Haram.'),
              _ProhibitedRow('❌', isBn ? 'আইয়ামে তাশরীক (১১, ১২, ১৩ যিলহজ)' : 'Ayyam al-Tashriq (11-13 Dhul Hijjah)',
                isBn ? 'এই তিন দিন খাওয়া-দাওয়া ও জিকিরের দিন।' : 'Three days of eating, drinking and dhikr.'),
              _ProhibitedRow('❌', isBn ? 'বিরতিহীন রোজা (সাওমে বিসাল)' : 'Continuous Fasting (Sawm al-Wisal)',
                isBn ? 'ইফতার ও সেহরি ছাড়া টানা রোজা নিষিদ্ধ।' : 'Fasting continuously without iftar/sehri is forbidden.'),
              _ProhibitedRow('❌', isBn ? 'শুধু শুক্রবার রোজা' : 'Only Friday Fast',
                isBn ? 'বৃহস্পতি বা শনিবার ছাড়া শুধু শুক্রবার রোজা নিরুৎসাহিত।' : 'Friday fast alone (without Thursday or Saturday) is discouraged.'),
              _ProhibitedRow('❌', isBn ? 'শুধু শনিবার রোজা' : 'Only Saturday Fast',
                isBn ? 'ফরজ ছাড়া শুধু শনিবার নির্দিষ্ট করা মাকরূহ।' : 'Specifying Saturday alone for fasting is Makruh.'),
              _ProhibitedRow('❌', isBn ? 'সারা বছর প্রতিদিন রোজা' : 'Fasting every day all year',
                isBn ? 'প্রতিদিন রোজা রাখা নিষেধ।' : 'Fasting every single day is forbidden.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ═══ Widgets ════════════════════════════════

class _NaflCard extends StatelessWidget {
  final String icon, name, time, rakaat, desc;
  final Color color;
  const _NaflCard({required this.icon, required this.name, required this.time,
    required this.rakaat, required this.desc, required this.color});

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
          Expanded(child: Text(name, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.access_time, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(child: Text(time, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.format_list_numbered, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Text(rakaat, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}

class _FastCard extends StatelessWidget {
  final String icon, title, dates, desc;
  final Color color;
  final String? alert;
  const _FastCard({required this.icon, required this.title, required this.dates,
    required this.desc, required this.color, this.alert});

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
          Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(child: Text(dates, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        if (alert != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(alert!, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
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
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(time, style: const TextStyle(color: AppTheme.missed, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
          Text(title, style: const TextStyle(color: AppTheme.missed, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }
}

Widget _sectionHeader(String icon, String title, Color color) {
  return Row(children: [
    Text(icon, style: const TextStyle(fontSize: 22)),
    const SizedBox(width: 10),
    Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold))),
  ]);
}
