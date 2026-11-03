import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/prayer_time_helper.dart';
import '../widgets/nafl_cards.dart';
import 'prayer_schedule_tab.dart';

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
  int _tabIndex = 0; // ০ = নামাজের সময়সূচী (ডিফল্ট), ১ = নফল নামাজ

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

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'নামাজ' : 'Prayer'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    _tabBtn(0, '🕒', isBn ? 'নামাজের সময়সূচী' : 'Prayer Times'),
                    _tabBtn(1, '⭐', isBn ? 'নফল নামাজ' : 'Nafl Prayer'),
                  ]),
                ),
                Expanded(
                  child: _tabIndex == 0 && pt != null
                      ? PrayerScheduleTab(lang: widget.lang, times: pt)
                      : _buildPrayerTab(isBn, pt, ishraqStart, ishraqEnd,
                          chashtStart, chashtEnd, tahaqqudStart, tahaqqudEnd),
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
        'time': isBn ? 'রমাদানের শেষ ১০ রাত (বিজোড়)' : 'Last 10 nights of Ramadan (odd)',
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
        nflSectionHeader('⭐', isBn ? 'নফল সালাতের সময় ও ফজিলত' : 'Nafl Prayer Times & Virtues', AppTheme.gold),
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
        nflSectionHeader('⛔', isBn ? 'নামাজের নিষিদ্ধ সময়' : 'Forbidden Prayer Times', AppTheme.missed),
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
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
              style: TextStyle(color: AppTheme.readable(color), fontSize: 17, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.access_time, size: 15, color: AppTheme.soft),
          const SizedBox(width: 6),
          Expanded(child: Text(time,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.format_list_numbered, size: 15, color: AppTheme.soft),
          const SizedBox(width: 6),
          Text(rakaat, style: TextStyle(color: AppTheme.readable(color), fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text(desc,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
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
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(time,
            style: const TextStyle(color: AppTheme.missed, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(desc,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

