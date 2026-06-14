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
  int? _playingGroupIndex;   // কোন group repeat হচ্ছে
  int _allPlayIndex = 0;     // "সব চালু" এ কোন group চলছে
  bool _isPlayingAll = false; // সব একসাথে চলছে কিনা

  // ayat.json থেকে আরবি লেখা হুবহু নেওয়া হয়েছে
  final List<Map<String, dynamic>> _groups = [
    {
      'audio': 'part_1',
      'arabic': 'هُوَ اللهُ الَّذِيْ لَاۤ  اِلٰهَ  اِلَّا  هُوَ   الرَّحْمٰنُ   الرَّحِيْمُ',
      'names': [
        {'bangla': 'আল্লাহ্'},
        {'bangla': 'আর-রাহমান'},
        {'bangla': 'আর-রাহীম'},
      ]
    },
    {
      'audio': 'part_2',
      'arabic': 'اَلْمَلِكُ     الْقُدُّوْسُ     السَّلاَمُ    الْمُؤْمِنُ     الْمُهَيْمِنُ     الْعَزِيْزُ    الْجَبَّارُ     الْمُتَكَبِّرُ',
      'names': [
        {'bangla': 'আল-মালিক'},
        {'bangla': 'আল-কুদ্দুস'},
        {'bangla': 'আস-সালাম'},
        {'bangla': 'আল-মুমিন'},
        {'bangla': 'আল-মুহাইমিন'},
        {'bangla': 'আল-আযীয'},
        {'bangla': 'আল-জাব্বার'},
        {'bangla': 'আল-মুতাকাব্বির'},
      ]
    },
    {
      'audio': 'part_3',
      'arabic': 'اَلْخَالِقُ     الْبَارِئُ      الْمُصَوِّرُ    الْغَفَّارُ      الْقَهَّارُ',
      'names': [
        {'bangla': 'আল-খালিক'},
        {'bangla': 'আল-বারি'},
        {'bangla': 'আল-মুসাওয়্যির'},
        {'bangla': 'আল-গাফ্ফার'},
        {'bangla': 'আল-কাহহার'},
      ]
    },
    {
      'audio': 'part_4',
      'arabic': 'اَلْوَهَّابُ     الرَّزَّاقُ   الْفَتَّاحُ     الْعَلِيْمُ',
      'names': [
        {'bangla': 'আল-ওয়াহহাব'},
        {'bangla': 'আর-রাযযাক'},
        {'bangla': 'আল-ফাত্তাহ'},
        {'bangla': 'আল-আলীম'},
      ]
    },
    {
      'audio': 'part_5',
      'arabic': 'اَلْقَا بِضُ      الْبَاسِطُ     الْخَافِضُ     الرَّافِعُ     الْمُعِزُّ     الْمُذِلُّ       السَّمِيْعُ     الْبَصِيْرُ',
      'names': [
        {'bangla': 'আল-কাবিদ'},
        {'bangla': 'আল-বাসিত'},
        {'bangla': 'আল-খাফিদ'},
        {'bangla': 'আর-রাফি'},
        {'bangla': 'আল-মুইয্য'},
        {'bangla': 'আল-মুযিল'},
        {'bangla': 'আস-সামী'},
        {'bangla': 'আল-বাসীর'},
      ]
    },
    {
      'audio': 'part_6',
      'arabic': 'اَلْحَكَمُ      الْعَدْلُ       اللَّطِيْفُ      الْخَبِيْرُ',
      'names': [
        {'bangla': 'আল-হাকাম'},
        {'bangla': 'আল-আদল'},
        {'bangla': 'আল-লাতীফ'},
        {'bangla': 'আল-খাবীর'},
      ]
    },
    {
      'audio': 'part_7',
      'arabic': 'اَلْحَلِيْمُ      الْعَظِيْمُ     الْغَفُوْرُ      الشَّكُوْرُ      الْعَلِيُّ      الْكَبِيْرُ',
      'names': [
        {'bangla': 'আল-হালীম'},
        {'bangla': 'আল-আযীম'},
        {'bangla': 'আল-গাফুর'},
        {'bangla': 'আশ-শাকুর'},
        {'bangla': 'আল-আলী'},
        {'bangla': 'আল-কাবীর'},
      ]
    },
    {
      'audio': 'part_8',
      'arabic': 'اَلْحَفِيْظُ     الْمُقِيْتُ     الْحَسِيْبُ     الْجَلِيْلُ     الْكَرِيْمُ',
      'names': [
        {'bangla': 'আল-হাফীয'},
        {'bangla': 'আল-মুকীত'},
        {'bangla': 'আল-হাসীব'},
        {'bangla': 'আল-জালীল'},
        {'bangla': 'আল-কারীম'},
      ]
    },
    {
      'audio': 'part_9',
      'arabic': 'اَلرَّقِيْبُ    الْمُجِيْبُ     الْوَاسِعُ     الْحَكِيْمُ',
      'names': [
        {'bangla': 'আর-রাকীব'},
        {'bangla': 'আল-মুজীব'},
        {'bangla': 'আল-ওয়াসি'},
        {'bangla': 'আল-হাকীম'},
      ]
    },
    {
      'audio': 'part_10',
      'arabic': 'اَلْوَدُوْدُ     الْمَجِيْدُ     الْبَاعِثُ     الشّهِيْدُ',
      'names': [
        {'bangla': 'আল-ওয়াদুদ'},
        {'bangla': 'আল-মাজীদ'},
        {'bangla': 'আল-বাইস'},
        {'bangla': 'আশ-শাহীদ'},
      ]
    },
    {
      'audio': 'part_11',
      'arabic': 'اَلْحَقُّ     الْوَكِيْلُ    الْقَوِيُّ     الْمَتِيْنُ',
      'names': [
        {'bangla': 'আল-হাক্ক'},
        {'bangla': 'আল-ওয়াকীল'},
        {'bangla': 'আল-কাওয়ী'},
        {'bangla': 'আল-মাতীন'},
      ]
    },
    {
      'audio': 'part_12',
      'arabic': 'اَلْوَلِيُّ      الْحَمِيْدُ     الْمُحْصِي      الْمُبْدِئُ     الْمُعِيْدُ    الْمُحْيِ    الْمُمِيْتُ     الْحَيُّ    الْقَيُّوْمُ',
      'names': [
        {'bangla': 'আল-ওয়ালী'},
        {'bangla': 'আল-হামীদ'},
        {'bangla': 'আল-মুহসী'},
        {'bangla': 'আল-মুবদি'},
        {'bangla': 'আল-মুঈদ'},
        {'bangla': 'আল-মুহয়ী'},
        {'bangla': 'আল-মুমীত'},
        {'bangla': 'আল-হাইয়্য'},
        {'bangla': 'আল-কাইয়্যুম'},
      ]
    },
    {
      'audio': 'part_13',
      'arabic': 'اَلْوَاجِدُ الْمَاجِدُ   الْوَاحِدُ  الْاَحَدُ  الصَّمَدُ    الْقَادِرُ    الْمُقْتَدِرُ',
      'names': [
        {'bangla': 'আল-ওয়াজিদ'},
        {'bangla': 'আল-মাজিদ'},
        {'bangla': 'আল-ওয়াহিদ'},
        {'bangla': 'আল-আহাদ'},
        {'bangla': 'আস-সামাদ'},
        {'bangla': 'আল-কাদির'},
        {'bangla': 'আল-মুকতাদির'},
      ]
    },
    {
      'audio': 'part_14',
      'arabic': 'اَلْمُقَدِّمُ    الْمُؤَخِّرُ    الْاَ وَّلُ   الْاَخِرُ    الظَّاهِرُ   الْبَاطِنُ',
      'names': [
        {'bangla': 'আল-মুকাদ্দিম'},
        {'bangla': 'আল-মুআখখির'},
        {'bangla': 'আল-আওয়্যাল'},
        {'bangla': 'আল-আখির'},
        {'bangla': 'আয-যাহির'},
        {'bangla': 'আল-বাতিন'},
      ]
    },
    {
      'audio': 'part_15',
      'arabic': 'اَلْوَالِي الْمُتَعَالِي الْبَرُّ التَّوَّابُ الْمُنْتَقِمُ الْعَفُوُّ الرَّؤُوْفُ',
      'names': [
        {'bangla': 'আল-ওয়ালী'},
        {'bangla': 'আল-মুতাআলী'},
        {'bangla': 'আল-বার্র'},
        {'bangla': 'আত-তাওয়্যাব'},
        {'bangla': 'আল-মুনতাকিম'},
        {'bangla': 'আল-আফুও'},
        {'bangla': 'আর-রাউফ'},
      ]
    },
    {
      'audio': 'part_16',
      'arabic': 'مَالِكُ   الْمُلْكِ   ذُوْ الْجَلاَلِ  وَالْاِ كْرَامِ',
      'names': [
        {'bangla': 'মালিকুল মুলক'},
        {'bangla': 'যুল জালালি ওয়াল ইকরাম'},
      ]
    },
    {
      'audio': 'part_17',
      'arabic': 'اَلْمُقْسِطُ   الْجَامِعُ     الْغَنِيُّ    الْمُغْنِي    الْمَانِعُ    الضَّآرُّ    النَّافِعُ',
      'names': [
        {'bangla': 'আল-মুকসিত'},
        {'bangla': 'আল-জামি'},
        {'bangla': 'আল-গানী'},
        {'bangla': 'আল-মুগনী'},
        {'bangla': 'আল-মানি'},
        {'bangla': 'আদ-দার্র'},
        {'bangla': 'আন-নাফি'},
      ]
    },
    {
      'audio': 'part_18',
      'arabic': 'اَلنُّوْرُ    الْهَادِيْ    الْبَدِيْعُ    الْبَاقِي      الْوَارِثُ    الرَّشِيْدُ   الصَّبُوْرُ',
      'names': [
        {'bangla': 'আন-নুর'},
        {'bangla': 'আল-হাদী'},
        {'bangla': 'আল-বাদী'},
        {'bangla': 'আল-বাকী'},
        {'bangla': 'আল-ওয়ারিস'},
        {'bangla': 'আর-রাশীদ'},
        {'bangla': 'আস-সাবুর'},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    // audio শেষ হলে
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      if (_isPlayingAll) {
        // সব চালু মোড — পরবর্তী group এ যাও
        _playNextAll();
      } else if (_playingGroupIndex != null) {
        // repeat মোড — একই group আবার চালাও
        _repeatCurrentGroup();
      }
    });
  }

  // ══ Group repeat ══
  void _playGroup(int groupIndex) async {
    if (_playingGroupIndex == groupIndex && _isPlaying) {
      // চলছে → বন্ধ করো
      await _player.stop();
      setState(() {
        _isPlaying = false;
        _isPlayingAll = false;
        _playingGroupIndex = null;
      });
      return;
    }
    await _player.stop();
    setState(() {
      _isPlaying = true;
      _isPlayingAll = false;
      _playingGroupIndex = groupIndex;
    });
    await _player.play(AssetSource('audio/${_groups[groupIndex]['audio']}.mp3'));
  }

  void _repeatCurrentGroup() async {
    if (_playingGroupIndex == null || !_isPlaying) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_isPlaying) return;
    await _player.play(AssetSource('audio/${_groups[_playingGroupIndex!]['audio']}.mp3'));
  }

  // ══ সব একসাথে চালু ══
  void _togglePlayAll() async {
    if (_isPlayingAll) {
      // চলছে → বন্ধ করো
      await _player.stop();
      setState(() {
        _isPlaying = false;
        _isPlayingAll = false;
        _playingGroupIndex = null;
        _allPlayIndex = 0;
      });
      return;
    }
    await _player.stop();
    setState(() {
      _isPlaying = true;
      _isPlayingAll = true;
      _playingGroupIndex = null;
      _allPlayIndex = 0;
    });
    // bismillah দিয়ে শুরু
    await _player.play(AssetSource('audio/part_0.mp3'));
  }

  void _playNextAll() async {
    if (!_isPlayingAll) return;
    // part_0 (bismillah) শেষ হলে group 0 থেকে শুরু
    // তারপর group 0, 1, 2 ... শেষ পর্যন্ত
    if (_allPlayIndex < _groups.length) {
      final audio = _groups[_allPlayIndex]['audio'] as String;
      setState(() {});
      _allPlayIndex++;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || !_isPlayingAll) return;
      await _player.play(AssetSource('audio/$audio.mp3'));
    } else {
      // সব শেষ — শুরু থেকে আবার
      setState(() {
        _allPlayIndex = 0;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || !_isPlayingAll) return;
      await _player.play(AssetSource('audio/part_0.mp3'));
    }
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
            onPressed: _togglePlayAll,
            icon: Icon(
              _isPlayingAll ? Icons.stop_circle : Icons.play_circle,
              color: AppTheme.gold,
              size: 32,
            ),
            tooltip: isBn ? 'সব নাম চালু/বন্ধ' : 'Play/Stop All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Bismillah — tap করলে part_0 play হয়
          GestureDetector(
            onTap: () async {
              await _player.stop();
              setState(() {
                _isPlaying = true;
                _isPlayingAll = false;
                _playingGroupIndex = -1; // bismillah
              });
              await _player.play(AssetSource('audio/part_0.mp3'));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: AppTheme.primary.withOpacity(0.2),
              child: const Text(
                'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
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

          // হাদিস
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.primary.withOpacity(0.1),
            child: Text(
              isBn
                  ? 'রাসূল ﷺ বলেন: "আল্লাহর ৯৯টি নাম আছে, যে ব্যক্তি উক্ত নামগুলো মুখস্থ রাখবে সে জান্নাতে প্রবেশ করবে।" [তিরমিজী: ৩৫০৭]'
                  : 'Prophet ﷺ said: "Allah has 99 names; whoever learns them will enter Paradise." [Tirmidhi: 3507]',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // সব চালু indicator
          if (_isPlayingAll)
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
                final group = _groups[groupIndex];
                final names = group['names'] as List<Map<String, dynamic>>;
                final arabic = group['arabic'] as String;
                final isGroupPlaying =
                    _isPlaying && _playingGroupIndex == groupIndex;

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
                      // আরবি লেখা — ayat.json থেকে হুবহু
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          arabic,
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
                      // বাংলা উচ্চারণ
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
                            // Repeat বাটন
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
                                          : Icons.repeat,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isGroupPlaying
                                          ? (isBn ? 'বন্ধ করুন' : 'Stop')
                                          : (isBn ? '🔁 রিপিট' : '🔁 Repeat'),
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
