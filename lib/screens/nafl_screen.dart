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

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    final pt = _prayerTimes;

    final ishraqStart = pt?.sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = pt?.sunrise.add(const Duration(minutes: 45));
    final chashtStart = pt?.sunrise.add(const Duration(minutes: 45));
    final chashtEnd = pt?.dhuhr.subtract(const Duration(minutes: 10));
    final tahaqqudStart = _sunnahTimes?.lastThirdOfTheNight;
    final tahaqqudEnd = pt?.fajr;

    final now = DateTime.now();
    final h = _hijriDay(now);

    final nafls = [
      {
        'icon': '🌙',
        'name': isBn ? 'তাহাজ্জুদ' : 'Tahajjud',
        'time': tahaqqudStart != null && tahaqqudEnd != null
            ? '${_fmt(tahaqqudStart)} - ${_fmt(tahaqqudEnd)}'
            : isBn ? 'রাতের শেষ তৃতীয়াংশ' : 'Last third of night',
        'rakaat': isBn ? '২ - ১২ রাকাত' : '2 - 12 rakats',
        'desc': isBn
            ? 'ফরজ নামাজের পর সর্বশ্রেষ্ঠ নামাজ। ইশার পর ঘুমিয়ে শেষ রাতে উঠে পড়া উত্তম।'
            : 'Best prayer after Fard. Sleep after Isha and wake up in last third of night.',
        'color': const Color(0xFF7C4DFF),
      },
      {
        'icon': '🌅',
        'name': isBn ? 'ইশরাক' : 'Ishraq',
        'time': ishraqStart != null && ishraqEnd != null
            ? '${_fmt(ishraqStart)} - ${_fmt(ishraqEnd)}'
            : isBn ? 'সূর্যোদয়ের ১৫-৪৫ মিনিট পর' : '15-45 min after sunrise',
        'rakaat': isBn ? '২ - ৪ রাকাত' : '2 - 4 rakats',
        'desc': isBn
            ? 'ফজর জামাতে পড়ে সূর্যোদয় পর্যন্ত বসে থেকে পড়লে এক হজ্জ ও উমরার সওয়াব পাওয়া যায়।'
            : 'Pray Fajr in congregation, sit until sunrise, then pray 2 rakats for Hajj & Umrah reward.',
        'color': const Color(0xFFFF8F00),
      },
      {
        'icon': '☀️',
        'name': isBn ? 'দুহা/চাশত' : 'Duha/Chasht',
        'time': chashtStart != null && chashtEnd != null
            ? '${_fmt(chashtStart)} - ${_fmt(chashtEnd)}'
            : isBn ? 'সূর্যোদয়ের ৪৫ মিনিট পর থেকে যোহরের আগে' : '45 min after sunrise to before Dhuhr',
        'rakaat': isBn ? '২ - ১২ রাকাত' : '2 - 12 rakats',
        'desc': isBn
            ? 'রাসূল (সা.) বলেছেন: প্রতিদিন সদকার বিনিময়ে দুহার দুই রাকাত যথেষ্ট। (মুসলিম)'
            : 'The Prophet (S) said: 2 rakats of Duha is sufficient for daily charity. (Muslim)',
        'color': const Color(0xFFFDD835),
      },
      {
        'icon': '🕌',
        'name': isBn ? 'জাওয়াল' : 'Zawal',
        'time': pt != null
            ? '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}'
            : isBn ? 'যোহরের ঠিক আগে' : 'Just before Dhuhr',
        'rakaat': isBn ? '২ - ৪ রাকাত' : '2 - 4 rakats',
        'desc': isBn
            ? 'সূর্য ঢলার সাথে সাথে পড়া হয়। দিনের বেলার তাহাজ্জুদ বলা হয়। এ সময় আল্লাহর দরজা খুলে যায়।'
            : 'Prayed when sun starts to decline. Called daytime Tahajjud. Allah opens doors of mercy.',
        'color': const Color(0xFF66BB6A),
      },
      {
        'icon': '🌆',
        'name': isBn ? 'আওওয়াবিন' : 'Awwabin',
        'time': pt != null
            ? '${_fmt(pt.maghrib)} - ${_fmt(pt.isha)}'
            : isBn ? 'মাগরিবের পর ইশার আগে' : 'Between Maghrib and Isha',
        'rakaat': isBn ? '৬ - ২০ রাকাত' : '6 - 20 rakats',
        'desc': isBn
            ? 'মাগরিবের ফরজ ও সুন্নতের পর পড়তে হয়। যে ব্যক্তি ৬ রাকাত পড়বে তার ৫০ বছরের গুনাহ মাফ হবে।'
            : 'Prayed after Maghrib Fard and Sunnah. 6 rakats forgives 50 years of sins.',
        'color': const Color(0xFF26A69A),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'নামাজ ও রোজার তথ্য' : 'Prayer & Fasting Info'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // নফল নামাজ section
                _sectionHeader('⭐', isBn ? 'নফল সালাতের সময় ও ফজিলত' : 'Nafl Prayer Times & Virtues', AppTheme.gold),
                const SizedBox(height: 12),

                ...nafls.map((n) => _NaflCard(
                  icon: n['icon'] as String,
                  name: n['name'] as String,
                  time: n['time'] as String,
                  rakaat: n['rakaat'] as String,
                  desc: n['desc'] as String,
                  color: n['color'] as Color,
                )),

                const SizedBox(height: 20),

                // নামাজের নিষিদ্ধ সময়
                _sectionHeader('⛔', isBn ? 'নামাজের নিষিদ্ধ সময়' : 'Forbidden Prayer Times', AppTheme.missed),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.missed.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn
                            ? 'এই সময়গুলোতে নফল নামাজ পড়া নিষেধ। তবে সূর্যাস্তের সময় সেইদিনের আসর পড়া যাবে।'
                            : 'Nafl prayers are forbidden at these times. However, that day\'s Asr can be prayed at sunset.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      if (pt != null) ...[
                        _ForbiddenTimeCard(
                          title: isBn ? '১. সূর্যোদয়কালীন' : '1. At Sunrise',
                          time: '${_fmt(pt.sunrise)} - ${_fmt(pt.sunrise.add(const Duration(minutes: 15)))}',
                          desc: isBn ? 'সূর্যোদয়ের পর ১৫ মিনিট পর্যন্ত' : 'For 15 minutes after sunrise',
                        ),
                        const SizedBox(height: 10),
                        _ForbiddenTimeCard(
                          title: isBn ? '২. দ্বিপ্রহরে (যাওয়াল)' : '2. At Noon (Zawal)',
                          time: '${_fmt(pt.dhuhr.subtract(const Duration(minutes: 5)))} - ${_fmt(pt.dhuhr)}',
                          desc: isBn ? 'সূর্য মাথার উপরে থাকার সময় (প্রায় ৫ মিনিট)' : 'When sun is at zenith (approx 5 min)',
                        ),
                        const SizedBox(height: 10),
                        _ForbiddenTimeCard(
                          title: isBn ? '৩. সূর্যাস্তকালীন' : '3. At Sunset',
                          time: '${_fmt(pt.maghrib.subtract(const Duration(minutes: 15)))} - ${_fmt(pt.maghrib)}',
                          desc: isBn ? 'সূর্যাস্তের আগে ১৫ মিনিট' : '15 minutes before sunset',
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // আইয়ামে বিজ section
                _sectionHeader('🌙', isBn ? 'আইয়ামে বিজের রোজা' : 'Ayyam al-Beed Fasting', AppTheme.gold),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn
                            ? 'প্রতি হিজরি মাসের ১৩, ১৪ ও ১৫ তারিখ এই রোজা রাখতে হয়।'
                            : 'Fast on 13th, 14th & 15th of every Hijri month.',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBn
                            ? '"রাসূল (সা.) আমাকে তিনটি বিষয়ে অসিয়ত করেছেন: প্রতি মাসের তিন রোজা, চাশতের নামাজ এবং ঘুমানোর আগে বিতর।" — (বুখারী, মুসলিম)'
                            : '"The Prophet (S) advised me three things: three fasts every month, Chasht prayer, and Witr before sleep." — (Bukhari, Muslim)',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isBn
                            ? '"এটি সারা বছর রোজা রাখার সমতুল্য।" — হাদিস'
                            : '"It equals fasting the whole year." — Hadith',
                        style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: h >= 13 && h <= 15
                              ? AppTheme.gold.withOpacity(0.2)
                              : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: h >= 13 && h <= 15 ? AppTheme.gold : AppTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            h >= 13 && h <= 15 ? Icons.notifications_active : Icons.calendar_today,
                            color: h >= 13 && h <= 15 ? AppTheme.gold : AppTheme.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            h >= 13 && h <= 15
                                ? (isBn ? '🎉 আজ আইয়ামে বিজের রোজার দিন! রোজা রাখুন।' : '🎉 Today is Ayyam al-Beed! Please fast.')
                                : h < 13
                                    ? (isBn ? 'আইয়ামে বিজ শুরু হতে ${13 - h} দিন বাকি' : '${13 - h} days until Ayyam al-Beed')
                                    : (isBn ? 'এই মাসের আইয়ামে বিজ শেষ হয়েছে' : 'Ayyam al-Beed ended this month'),
                            style: TextStyle(
                              color: h >= 13 && h <= 15 ? AppTheme.gold : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: h >= 13 && h <= 15 ? FontWeight.bold : FontWeight.normal,
                            ),
                          )),
                        ]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // অন্যান্য নফল রোজা
                _sectionHeader('🌿', isBn ? 'অন্যান্য গুরুত্বপূর্ণ নফল রোজা' : 'Other Important Nafl Fasts', AppTheme.accent),
                const SizedBox(height: 12),

                _OtherFastCard(
                  icon: '📅',
                  title: isBn ? 'প্রতি সোম ও বৃহস্পতিবার' : 'Every Monday & Thursday',
                  desc: isBn
                      ? 'নবীজি (সা.) এই দুই দিন রোজা রাখতেন। বলেছেন: এই দিনে আমলনামা আল্লাহর কাছে পেশ করা হয়।'
                      : 'The Prophet fasted these days. "Deeds are presented to Allah on these days."',
                ),
                _OtherFastCard(
                  icon: '🌟',
                  title: isBn ? 'আশুরার রোজা (১০ মুহাররম)' : 'Ashura Fast (10 Muharram)',
                  desc: isBn
                      ? 'নবীজি (সা.) বলেছেন: আশুরার রোজায় আগের এক বছরের গুনাহ মাফ হয়। ৯ ও ১০ বা ১০ ও ১১ মুহাররম।'
                      : 'Prophet said: Ashura fast expiates sins of previous year. Fast 9th & 10th or 10th & 11th Muharram.',
                ),
                _OtherFastCard(
                  icon: '🏆',
                  title: isBn ? 'আরাফার রোজা (৯ জিলহজ)' : 'Arafah Fast (9 Dhul Hijjah)',
                  desc: isBn
                      ? 'নবীজি (সা.) বলেছেন: আরাফার রোজায় আগের ও পরের এক বছরের গুনাহ মাফ হয়। হাজীদের জন্য নয়।'
                      : 'Prophet said: Arafah fast expiates sins of previous and next year. Not for pilgrims.',
                ),
                _OtherFastCard(
                  icon: '🌙',
                  title: isBn ? 'শাওয়ালের ৬ রোজা' : '6 Fasts of Shawwal',
                  desc: isBn
                      ? 'রমজানের পর শাওয়াল মাসে ৬টি রোজা রাখলে সারা বছর রোজা রাখার সওয়াব পাওয়া যায়।'
                      : 'Fasting 6 days in Shawwal after Ramadan equals fasting the whole year.',
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  int _hijriDay(DateTime date) {
    try {
      final jd = _gregorianToJulian(date.year, date.month, date.day);
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

  int _gregorianToJulian(int year, int month, int day) {
    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    return day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  Widget _sectionHeader(String icon, String title, Color color) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
    ]);
  }
}

// ═══════════════════════════════════════════
class _NaflCard extends StatelessWidget {
  final String icon, name, time, rakaat, desc;
  final Color color;

  const _NaflCard({
    required this.icon, required this.name, required this.time,
    required this.rakaat, required this.desc, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Text(time, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.format_list_numbered, size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Text(rakaat, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _ForbiddenTimeCard extends StatelessWidget {
  final String title, time, desc;

  const _ForbiddenTimeCard({required this.title, required this.time, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.missed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.missed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: AppTheme.missed, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _OtherFastCard extends StatelessWidget {
  final String icon, title, desc;

  const _OtherFastCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
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
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.gold, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
            ],
          )),
        ],
      ),
    );
  }
}
