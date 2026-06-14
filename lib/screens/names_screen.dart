import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

class NamesScreen extends StatefulWidget {
  final AppLanguage lang;
  const NamesScreen({super.key, required this.lang});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  int? _playingGroupIndex;

  // ayat.json এর audio গুলো group অনুযায়ী (part_0 থেকে part_18)
  // group index 0 = bismillah (part_0), 1 = group 1 (part_1), ...
  // কিন্তু আমাদের groups শুরু হয় index 0 থেকে → audio হবে part_1 থেকে part_19
  // ayat.json এ id=1 = bismillah (part_0), id=2 = group 1 (part_1) ...
  // আমাদের _groups[0] = group 1 → audio = part_1

  final List<Map<String, dynamic>> _groups = [
    {'audio': 'part_1', 'names': [
      {'arabic': 'اللَّهُ', 'bangla': 'আল্লাহ্'},
      {'arabic': 'الرَّحْمٰنُ', 'bangla': 'আর-রাহমান'},
      {'arabic': 'الرَّحِيْمُ', 'bangla': 'আর-রাহীম'},
    ]},
    {'audio': 'part_2', 'names': [
      {'arabic': 'الْمَلِكُ', 'bangla': 'আল-মালিক'},
      {'arabic': 'الْقُدُّوْسُ', 'bangla': 'আল-কুদ্দুস'},
      {'arabic': 'السَّلاَمُ', 'bangla': 'আস-সালাম'},
      {'arabic': 'الْمُؤْمِنُ', 'bangla': 'আল-মুমিন'},
      {'arabic': 'الْمُهَيْمِنُ', 'bangla': 'আল-মুহাইমিন'},
      {'arabic': 'الْعَزِيْزُ', 'bangla': 'আল-আযীয'},
      {'arabic': 'الْجَبَّارُ', 'bangla': 'আল-জাব্বার'},
      {'arabic': 'الْمُتَكَبِّرُ', 'bangla': 'আল-মুতাকাব্বির'},
    ]},
    {'audio': 'part_3', 'names': [
      {'arabic': 'الْخَالِقُ', 'bangla': 'আল-খালিক'},
      {'arabic': 'الْبَارِئُ', 'bangla': 'আল-বারি'},
      {'arabic': 'الْمُصَوِّرُ', 'bangla': 'আল-মুসাওয়্যির'},
      {'arabic': 'الْغَفَّارُ', 'bangla': 'আল-গাফ্ফার'},
      {'arabic': 'الْقَهَّارُ', 'bangla': 'আল-কাহহার'},
    ]},
    {'audio': 'part_4', 'names': [
      {'arabic': 'الْوَهَّابُ', 'bangla': 'আল-ওয়াহহাব'},
      {'arabic': 'الرَّزَّاقُ', 'bangla': 'আর-রাযযাক'},
      {'arabic': 'الْفَتَّاحُ', 'bangla': 'আল-ফাত্তাহ'},
      {'arabic': 'الْعَلِيْمُ', 'bangla': 'আল-আলীম'},
    ]},
    {'audio': 'part_5', 'names': [
      {'arabic': 'الْقَابِضُ', 'bangla': 'আল-কাবিদ'},
      {'arabic': 'الْبَاسِطُ', 'bangla': 'আল-বাসিত'},
      {'arabic': 'الْخَافِضُ', 'bangla': 'আল-খাফিদ'},
      {'arabic': 'الرَّافِعُ', 'bangla': 'আর-রাফি'},
      {'arabic': 'الْمُعِزُّ', 'bangla': 'আল-মুইয্য'},
      {'arabic': 'الْمُذِلُّ', 'bangla': 'আল-মুযিল'},
      {'arabic': 'السَّمِيْعُ', 'bangla': 'আস-সামী'},
      {'arabic': 'الْبَصِيْرُ', 'bangla': 'আল-বাসীর'},
    ]},
    {'audio': 'part_6', 'names': [
      {'arabic': 'الْحَكَمُ', 'bangla': 'আল-হাকাম'},
      {'arabic': 'الْعَدْلُ', 'bangla': 'আল-আদল'},
      {'arabic': 'اللَّطِيْفُ', 'bangla': 'আল-লাতীফ'},
      {'arabic': 'الْخَبِيْرُ', 'bangla': 'আল-খাবীর'},
    ]},
    {'audio': 'part_7', 'names': [
      {'arabic': 'الْحَلِيْمُ', 'bangla': 'আল-হালীম'},
      {'arabic': 'الْعَظِيْمُ', 'bangla': 'আল-আযীম'},
      {'arabic': 'الْغَفُوْرُ', 'bangla': 'আল-গাফুর'},
      {'arabic': 'الشَّكُوْرُ', 'bangla': 'আশ-শাকুর'},
      {'arabic': 'الْعَلِيُّ', 'bangla': 'আল-আলী'},
      {'arabic': 'الْكَبِيْرُ', 'bangla': 'আল-কাবীর'},
    ]},
    {'audio': 'part_8', 'names': [
      {'arabic': 'الْحَفِيْظُ', 'bangla': 'আল-হাফীয'},
      {'arabic': 'الْمُقِيْتُ', 'bangla': 'আল-মুকীত'},
      {'arabic': 'الْحَسِيْبُ', 'bangla': 'আল-হাসীব'},
      {'arabic': 'الْجَلِيْلُ', 'bangla': 'আল-জালীল'},
      {'arabic': 'الْكَرِيْمُ', 'bangla': 'আল-কারীম'},
    ]},
    {'audio': 'part_9', 'names': [
      {'arabic': 'الرَّقِيْبُ', 'bangla': 'আর-রাকীব'},
      {'arabic': 'الْمُجِيْبُ', 'bangla': 'আল-মুজীব'},
      {'arabic': 'الْوَاسِعُ', 'bangla': 'আল-ওয়াসি'},
      {'arabic': 'الْحَكِيْمُ', 'bangla': 'আল-হাকীম'},
    ]},
    {'audio': 'part_10', 'names': [
      {'arabic': 'الْوَدُوْدُ', 'bangla': 'আল-ওয়াদুদ'},
      {'arabic': 'الْمَجِيْدُ', 'bangla': 'আল-মাজীদ'},
      {'arabic': 'الْبَاعِثُ', 'bangla': 'আল-বাইস'},
      {'arabic': 'الشَّهِيْدُ', 'bangla': 'আশ-শাহীদ'},
    ]},
    {'audio': 'part_11', 'names': [
      {'arabic': 'الْحَقُّ', 'bangla': 'আল-হাক্ক'},
      {'arabic': 'الْوَكِيْلُ', 'bangla': 'আল-ওয়াকীল'},
      {'arabic': 'الْقَوِيُّ', 'bangla': 'আল-কাওয়ী'},
      {'arabic': 'الْمَتِيْنُ', 'bangla': 'আল-মাতীন'},
    ]},
    {'audio': 'part_12', 'names': [
      {'arabic': 'الْوَلِيُّ', 'bangla': 'আল-ওয়ালী'},
      {'arabic': 'الْحَمِيْدُ', 'bangla': 'আল-হামীদ'},
      {'arabic': 'الْمُحْصِي', 'bangla': 'আল-মুহসী'},
      {'arabic': 'الْمُبْدِئُ', 'bangla': 'আল-মুবদি'},
      {'arabic': 'الْمُعِيْدُ', 'bangla': 'আল-মুঈদ'},
      {'arabic': 'الْمُحْيِ', 'bangla': 'আল-মুহয়ী'},
      {'arabic': 'الْمُمِيْتُ', 'bangla': 'আল-মুমীত'},
      {'arabic': 'الْحَيُّ', 'bangla': 'আল-হাইয়্য'},
      {'arabic': 'الْقَيُّوْمُ', 'bangla': 'আল-কাইয়্যুম'},
    ]},
    {'audio': 'part_13', 'names': [
      {'arabic': 'الْوَاجِدُ', 'bangla': 'আল-ওয়াজিদ'},
      {'arabic': 'الْمَاجِدُ', 'bangla': 'আল-মাজিদ'},
      {'arabic': 'الْوَاحِدُ', 'bangla': 'আল-ওয়াহিদ'},
      {'arabic': 'الْاَحَدُ', 'bangla': 'আল-আহাদ'},
      {'arabic': 'الصَّمَدُ', 'bangla': 'আস-সামাদ'},
      {'arabic': 'الْقَادِرُ', 'bangla': 'আল-কাদির'},
      {'arabic': 'الْمُقْتَدِرُ', 'bangla': 'আল-মুকতাদির'},
    ]},
    {'audio': 'part_14', 'names': [
      {'arabic': 'الْمُقَدِّمُ', 'bangla': 'আল-মুকাদ্দিম'},
      {'arabic': 'الْمُؤَخِّرُ', 'bangla': 'আল-মুআখখির'},
      {'arabic': 'الْاَوَّلُ', 'bangla': 'আল-আওয়্যাল'},
      {'arabic': 'الْاَخِرُ', 'bangla': 'আল-আখির'},
      {'arabic': 'الظَّاهِرُ', 'bangla': 'আয-যাহির'},
      {'arabic': 'الْبَاطِنُ', 'bangla': 'আল-বাতিন'},
    ]},
    {'audio': 'part_15', 'names': [
      {'arabic': 'الْوَالِي', 'bangla': 'আল-ওয়ালী'},
      {'arabic': 'الْمُتَعَالِي', 'bangla': 'আল-মুতাআলী'},
      {'arabic': 'الْبَرُّ', 'bangla': 'আল-বার্র'},
      {'arabic': 'التَّوَّابُ', 'bangla': 'আত-তাওয়্যাব'},
      {'arabic': 'الْمُنْتَقِمُ', 'bangla': 'আল-মুনতাকিম'},
      {'arabic': 'الْعَفُوُّ', 'bangla': 'আল-আফুও'},
      {'arabic': 'الرَّؤُوْفُ', 'bangla': 'আর-রাউফ'},
    ]},
    {'audio': 'part_16', 'names': [
      {'arabic': 'مَالِكُ الْمُلْكِ', 'bangla': 'মালিকুল মুলক'},
      {'arabic': 'ذُوْ الْجَلاَلِ وَالْاِكْرَامِ', 'bangla': 'যুল জালালি ওয়াল ইকরাম'},
    ]},
    {'audio': 'part_17', 'names': [
      {'arabic': 'الْمُقْسِطُ', 'bangla': 'আল-মুকসিত'},
      {'arabic': 'الْجَامِعُ', 'bangla': 'আল-জামি'},
      {'arabic': 'الْغَنِيُّ', 'bangla': 'আল-গানী'},
      {'arabic': 'الْمُغْنِي', 'bangla': 'আল-মুগনী'},
      {'arabic': 'الْمَانِعُ', 'bangla': 'আল-মানি'},
      {'arabic': 'الضَّآرُّ', 'bangla': 'আদ-দার্র'},
      {'arabic': 'النَّافِعُ', 'bangla': 'আন-নাফি'},
    ]},
    {'audio': 'part_18', 'names': [
      {'arabic': 'النُّوْرُ', 'bangla': 'আন-নুর'},
      {'arabic': 'الْهَادِيْ', 'bangla': 'আল-হাদী'},
      {'arabic': 'الْبَدِيْعُ', 'bangla': 'আল-বাদী'},
      {'arabic': 'الْبَاقِي', 'bangla': 'আল-বাকী'},
      {'arabic': 'الْوَارِثُ', 'bangla': 'আল-ওয়ারিস'},
      {'arabic': 'الرَّشِيْدُ', 'bangla': 'আর-রাশীদ'},
      {'arabic': 'الصَّبُوْرُ', 'bangla': 'আস-সাবুর'},
    ]},
  ];

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted && _isPlaying) {
        setState(() {
          _isPlaying = false;
          _playingGroupIndex = null;
        });
      }
    });
  }

  Future<void> _playAudio(String audioName) async {
    await _player.stop();
    await _player.play(AssetSource('audio/$audioName.mp3'));
  }

  void _playGroup(int groupIndex) async {
    if (_isPlaying && _playingGroupIndex == groupIndex) {
      await _player.stop();
      setState(() {
        _isPlaying = false;
        _playingGroupIndex = null;
      });
      return;
    }
    final audioName = _groups[groupIndex]['audio'] as String;
    setState(() {
      _isPlaying = true;
      _playingGroupIndex = groupIndex;
    });
    await _playAudio(audioName);
  }

  void _playAll() async {
    if (_isPlaying && _playingGroupIndex == null) {
      await _player.stop();
      setState(() {
        _isPlaying = false;
      });
      return;
    }
    // সব audio একটার পর একটা play করা জটিল
    // তাই "সব" বলতে part_0 (bismillah) থেকে শুরু করব
    setState(() {
      _isPlaying = true;
      _playingGroupIndex = null;
    });
    await _playAudio('part_0');
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'আল্লাহর ৯৯ নাম' : '99 Names of Allah'),
        actions: [
          IconButton(
            onPressed: _playAll,
            icon: Icon(
              _isPlaying && _playingGroupIndex == null
                  ? Icons.stop_circle
                  : Icons.play_circle,
              color: AppTheme.gold,
              size: 32,
            ),
            tooltip: isBn ? 'সব নাম চালু/বন্ধ' : 'Play/Stop All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Bismillah
          GestureDetector(
            onTap: () async {
              await _player.stop();
              await _player.play(AssetSource('audio/part_0.mp3'));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: AppTheme.primary.withOpacity(0.2),
              child: const Text(
                'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                style: TextStyle(
                  fontSize: 30,
                  color: AppTheme.gold,
                  fontFamily: 'ScheherazadeNew',
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Fazilat (হাদিস)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.primary.withOpacity(0.1),
            child: Text(
              isBn
                  ? 'হযরত আবু হুরাইরা রাযি. থেকে বর্ণিত — রাসূল ﷺ বলেন: "আল্লাহর ৯৯টি নাম আছে, যে ব্যক্তি উক্ত নামগুলো মুখস্থ রাখবে সে জান্নাতে প্রবেশ করবে।" [তিরমিজী: ৩৫০৭]'
                  : 'Abu Hurairah (R) reported: The Prophet ﷺ said: "Allah has 99 names; whoever learns them will enter Paradise." [Tirmidhi: 3507]',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Playing indicator
          if (_isPlaying && _playingGroupIndex == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: AppTheme.primary.withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volume_up, color: AppTheme.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? 'সব নাম চলছে...' : 'Playing all names...',
                    style: const TextStyle(color: AppTheme.accent, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Names list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _groups.length,
              itemBuilder: (context, groupIndex) {
                final names = _groups[groupIndex]['names'] as List<Map<String, dynamic>>;
                final isGroupPlaying = _isPlaying && _playingGroupIndex == groupIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isGroupPlaying
                        ? AppTheme.primary.withOpacity(0.3)
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isGroupPlaying
                          ? AppTheme.accent
                          : AppTheme.primary.withOpacity(0.3),
                      width: isGroupPlaying ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Arabic text
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          names.map((n) => n['arabic']).join('  '),
                          style: const TextStyle(
                            fontSize: 32,
                            color: AppTheme.textPrimary,
                            height: 2.2,
                            fontFamily: 'ScheherazadeNew',
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      // Bangla pronunciation
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          names.map((n) => n['bangla']).join(' • '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      // Bottom row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              isBn
                                  ? '${names.length} টি নাম'
                                  : '${names.length} names',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _playGroup(groupIndex),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isGroupPlaying
                                      ? AppTheme.missed
                                      : AppTheme.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isGroupPlaying
                                        ? AppTheme.missed
                                        : AppTheme.accent.withOpacity(0.6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGroupPlaying
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isGroupPlaying
                                          ? (isBn ? 'বন্ধ করুন' : 'Stop')
                                          : (isBn ? '🔊 শুনুন' : '🔊 Play'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
