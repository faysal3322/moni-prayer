import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';

class NamesScreen extends StatefulWidget {
  final AppLanguage lang;
  const NamesScreen({super.key, required this.lang});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  int? _playingGroupIndex;
  int _currentNameIndex = 0;
  bool _ttsReady = false;

  final List<Map<String, dynamic>> _groups = [
    {'names': [
      {'arabic': 'اللَّهُ', 'bangla': 'আল্লাহ্'},
      {'arabic': 'الرَّحْمَٰنُ', 'bangla': 'আর-রাহমান'},
      {'arabic': 'الرَّحِيمُ', 'bangla': 'আর-রাহীম'},
    ]},
    {'names': [
      {'arabic': 'الْمَلِكُ', 'bangla': 'আল-মালিক'},
      {'arabic': 'الْقُدُّوسُ', 'bangla': 'আল-কুদ্দুস'},
      {'arabic': 'السَّلَامُ', 'bangla': 'আস-সালাম'},
      {'arabic': 'الْمُؤْمِنُ', 'bangla': 'আল-মুমিন'},
      {'arabic': 'الْمُهَيْمِنُ', 'bangla': 'আল-মুহাইমিন'},
      {'arabic': 'الْعَزِيزُ', 'bangla': 'আল-আযীয'},
      {'arabic': 'الْجَبَّارُ', 'bangla': 'আল-জাব্বার'},
      {'arabic': 'الْمُتَكَبِّرُ', 'bangla': 'আল-মুতাকাব্বির'},
    ]},
    {'names': [
      {'arabic': 'الْخَالِقُ', 'bangla': 'আল-খালিক'},
      {'arabic': 'الْبَارِئُ', 'bangla': 'আল-বারি'},
      {'arabic': 'الْمُصَوِّرُ', 'bangla': 'আল-মুসাওয়্যির'},
      {'arabic': 'الْغَفَّارُ', 'bangla': 'আল-গাফ্ফার'},
      {'arabic': 'الْقَهَّارُ', 'bangla': 'আল-কাহহার'},
    ]},
    {'names': [
      {'arabic': 'الْوَهَّابُ', 'bangla': 'আল-ওয়াহহাব'},
      {'arabic': 'الرَّزَّاقُ', 'bangla': 'আর-রাযযাক'},
      {'arabic': 'الْفَتَّاحُ', 'bangla': 'আল-ফাত্তাহ'},
      {'arabic': 'الْعَلِيمُ', 'bangla': 'আল-আলীম'},
    ]},
    {'names': [
      {'arabic': 'الْقَابِضُ', 'bangla': 'আল-কাবিদ'},
      {'arabic': 'الْبَاسِطُ', 'bangla': 'আল-বাসিত'},
      {'arabic': 'الْخَافِضُ', 'bangla': 'আল-খাফিদ'},
      {'arabic': 'الرَّافِعُ', 'bangla': 'আর-রাফি'},
      {'arabic': 'الْمُعِزُّ', 'bangla': 'আল-মুইয্য'},
      {'arabic': 'الْمُذِلُّ', 'bangla': 'আল-মুযিল'},
      {'arabic': 'السَّمِيعُ', 'bangla': 'আস-সামী'},
      {'arabic': 'الْبَصِيرُ', 'bangla': 'আল-বাসীর'},
    ]},
    {'names': [
      {'arabic': 'الْحَكَمُ', 'bangla': 'আল-হাকাম'},
      {'arabic': 'الْعَدْلُ', 'bangla': 'আল-আদল'},
      {'arabic': 'اللَّطِيفُ', 'bangla': 'আল-লাতীফ'},
      {'arabic': 'الْخَبِيرُ', 'bangla': 'আল-খাবীর'},
    ]},
    {'names': [
      {'arabic': 'الْحَلِيمُ', 'bangla': 'আল-হালীম'},
      {'arabic': 'الْعَظِيمُ', 'bangla': 'আল-আযীম'},
      {'arabic': 'الْغَفُورُ', 'bangla': 'আল-গাফুর'},
      {'arabic': 'الشَّكُورُ', 'bangla': 'আশ-শাকুর'},
      {'arabic': 'الْعَلِيُّ', 'bangla': 'আল-আলী'},
      {'arabic': 'الْكَبِيرُ', 'bangla': 'আল-কাবীর'},
    ]},
    {'names': [
      {'arabic': 'الْحَفِيظُ', 'bangla': 'আল-হাফীয'},
      {'arabic': 'الْمُقِيتُ', 'bangla': 'আল-মুকীত'},
      {'arabic': 'الْحَسِيبُ', 'bangla': 'আল-হাসীব'},
      {'arabic': 'الْجَلِيلُ', 'bangla': 'আল-জালীল'},
      {'arabic': 'الْكَرِيمُ', 'bangla': 'আল-কারীম'},
    ]},
    {'names': [
      {'arabic': 'الرَّقِيبُ', 'bangla': 'আর-রাকীব'},
      {'arabic': 'الْمُجِيبُ', 'bangla': 'আল-মুজীব'},
      {'arabic': 'الْوَاسِعُ', 'bangla': 'আল-ওয়াসি'},
      {'arabic': 'الْحَكِيمُ', 'bangla': 'আল-হাকীম'},
    ]},
    {'names': [
      {'arabic': 'الْوَدُودُ', 'bangla': 'আল-ওয়াদুদ'},
      {'arabic': 'الْمَجِيدُ', 'bangla': 'আল-মাজীদ'},
      {'arabic': 'الْبَاعِثُ', 'bangla': 'আল-বাইস'},
      {'arabic': 'الشَّهِيدُ', 'bangla': 'আশ-শাহীদ'},
    ]},
    {'names': [
      {'arabic': 'الْحَقُّ', 'bangla': 'আল-হাক্ক'},
      {'arabic': 'الْوَكِيلُ', 'bangla': 'আল-ওয়াকীল'},
      {'arabic': 'الْقَوِيُّ', 'bangla': 'আল-কাওয়ী'},
      {'arabic': 'الْمَتِينُ', 'bangla': 'আল-মাতীন'},
    ]},
    {'names': [
      {'arabic': 'الْوَلِيُّ', 'bangla': 'আল-ওয়ালী'},
      {'arabic': 'الْحَمِيدُ', 'bangla': 'আল-হামীদ'},
      {'arabic': 'الْمُحْصِي', 'bangla': 'আল-মুহসী'},
      {'arabic': 'الْمُبْدِئُ', 'bangla': 'আল-মুবদি'},
      {'arabic': 'الْمُعِيدُ', 'bangla': 'আল-মুঈদ'},
      {'arabic': 'الْمُحْيِي', 'bangla': 'আল-মুহয়ী'},
      {'arabic': 'الْمُمِيتُ', 'bangla': 'আল-মুমীত'},
      {'arabic': 'الْحَيُّ', 'bangla': 'আল-হাইয়্যু'},
      {'arabic': 'الْقَيُّومُ', 'bangla': 'আল-কাইয়্যুম'},
    ]},
    {'names': [
      {'arabic': 'الْوَاجِدُ', 'bangla': 'আল-ওয়াজিদ'},
      {'arabic': 'الْمَاجِدُ', 'bangla': 'আল-মাজিদ'},
      {'arabic': 'الْوَاحِدُ', 'bangla': 'আল-ওয়াহিদ'},
      {'arabic': 'الْأَحَدُ', 'bangla': 'আল-আহাদ'},
      {'arabic': 'الصَّمَدُ', 'bangla': 'আস-সামাদ'},
      {'arabic': 'الْقَادِرُ', 'bangla': 'আল-কাদির'},
      {'arabic': 'الْمُقْتَدِرُ', 'bangla': 'আল-মুকতাদির'},
    ]},
    {'names': [
      {'arabic': 'الْمُقَدِّمُ', 'bangla': 'আল-মুকাদ্দিম'},
      {'arabic': 'الْمُؤَخِّرُ', 'bangla': 'আল-মুআখখির'},
      {'arabic': 'الْأَوَّلُ', 'bangla': 'আল-আওয়াল'},
      {'arabic': 'الْآخِرُ', 'bangla': 'আল-আখির'},
      {'arabic': 'الظَّاهِرُ', 'bangla': 'আয-যাহির'},
      {'arabic': 'الْبَاطِنُ', 'bangla': 'আল-বাতিন'},
    ]},
    {'names': [
      {'arabic': 'الْوَالِي', 'bangla': 'আল-ওয়ালী'},
      {'arabic': 'الْمُتَعَالِي', 'bangla': 'আল-মুতাআলী'},
      {'arabic': 'الْبَرُّ', 'bangla': 'আল-বার্র'},
      {'arabic': 'التَّوَّابُ', 'bangla': 'আত-তাওয়্যাব'},
      {'arabic': 'الْمُنْتَقِمُ', 'bangla': 'আল-মুনতাকিম'},
      {'arabic': 'الْعَفُوُّ', 'bangla': 'আল-আফুওয়্যু'},
      {'arabic': 'الرَّءُوفُ', 'bangla': 'আর-রাউফ'},
    ]},
    {'names': [
      {'arabic': 'مَالِكُ الْمُلْكِ', 'bangla': 'মালিকুল মুলক'},
      {'arabic': 'ذُو الْجَلَالِ وَالْإِكْرَامِ', 'bangla': 'যুল জালালি ওয়াল ইকরাম'},
    ]},
    {'names': [
      {'arabic': 'الْمُقْسِطُ', 'bangla': 'আল-মুকসিত'},
      {'arabic': 'الْجَامِعُ', 'bangla': 'আল-জামি'},
      {'arabic': 'الْغَنِيُّ', 'bangla': 'আল-গানী'},
      {'arabic': 'الْمُغْنِي', 'bangla': 'আল-মুগনী'},
      {'arabic': 'الْمَانِعُ', 'bangla': 'আল-মানি'},
      {'arabic': 'الضَّارُّ', 'bangla': 'আদ-দার্র'},
      {'arabic': 'النَّافِعُ', 'bangla': 'আন-নাফি'},
    ]},
    {'names': [
      {'arabic': 'النُّورُ', 'bangla': 'আন-নূর'},
      {'arabic': 'الْهَادِي', 'bangla': 'আল-হাদী'},
      {'arabic': 'الْبَدِيعُ', 'bangla': 'আল-বাদী'},
      {'arabic': 'الْبَاقِي', 'bangla': 'আল-বাকী'},
      {'arabic': 'الْوَارِثُ', 'bangla': 'আল-ওয়ারিস'},
      {'arabic': 'الرَّشِيدُ', 'bangla': 'আর-রাশীদ'},
      {'arabic': 'الصَّبُورُ', 'bangla': 'আস-সাবুর'},
    ]},
  ];

  List<Map<String, dynamic>> get _allNames =>
      _groups.expand((g) => g['names'] as List<Map<String, dynamic>>).toList();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.4);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (!mounted) return;
        if (_isPlaying) {
          if (_playingGroupIndex != null) {
            _playNextInGroup();
          } else {
            _playNextAll();
          }
        }
      });

      if (mounted) setState(() => _ttsReady = true);
    } catch (e) {
      if (mounted) setState(() => _ttsReady = false);
    }
  }

  Future<void> _speakName(String arabic) async {
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _tts.speak(arabic);
  }

  void _playAll() async {
    if (_isPlaying && _playingGroupIndex == null) {
      await _tts.stop();
      setState(() {
        _isPlaying = false;
        _currentNameIndex = 0;
      });
      return;
    }
    setState(() {
      _isPlaying = true;
      _playingGroupIndex = null;
      _currentNameIndex = 0;
    });
    await _speakName(_allNames[0]['arabic']);
  }

  void _playNextAll() async {
    _currentNameIndex++;
    if (_currentNameIndex < _allNames.length) {
      await _speakName(_allNames[_currentNameIndex]['arabic']);
    } else {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentNameIndex = 0;
        });
      }
    }
  }

  void _playGroup(int groupIndex) async {
    if (_isPlaying && _playingGroupIndex == groupIndex) {
      await _tts.stop();
      setState(() {
        _isPlaying = false;
        _playingGroupIndex = null;
        _currentNameIndex = 0;
      });
      return;
    }
    setState(() {
      _isPlaying = true;
      _playingGroupIndex = groupIndex;
      _currentNameIndex = 0;
    });
    final names = _groups[groupIndex]['names'] as List<Map<String, dynamic>>;
    await _speakName(names[0]['arabic']);
  }

  void _playNextInGroup() async {
    if (_playingGroupIndex == null) return;
    final names = _groups[_playingGroupIndex!]['names'] as List<Map<String, dynamic>>;
    _currentNameIndex++;
    if (_currentNameIndex < names.length) {
      await _speakName(names[_currentNameIndex]['arabic']);
    } else {
      // unlimited repeat — go back to first
      _currentNameIndex = 0;
      await Future.delayed(const Duration(milliseconds: 600));
      if (_isPlaying && _playingGroupIndex != null) {
        await _speakName(names[0]['arabic']);
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
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
            onPressed: _ttsReady ? _playAll : null,
            icon: Icon(
              _isPlaying && _playingGroupIndex == null
                  ? Icons.stop_circle
                  : Icons.play_circle,
              color: _ttsReady ? AppTheme.gold : AppTheme.textSecondary,
              size: 32,
            ),
            tooltip: isBn ? 'সব নাম চালু/বন্ধ' : 'Play/Stop All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Bismillah
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppTheme.primary.withOpacity(0.2),
            child: const Text(
              'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: TextStyle(fontSize: 22, color: AppTheme.gold),
              textAlign: TextAlign.center,
            ),
          ),

          // TTS warning
          if (!_ttsReady)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppTheme.pending.withOpacity(0.15),
              child: Text(
                isBn
                    ? '⚠️ সাউন্ডের জন্য ডিভাইসে আরবি ভাষা install করুন:\nSettings → General Management → Language → Add Language → Arabic'
                    : '⚠️ For sound, install Arabic language:\nSettings → General Management → Language → Add Language → Arabic',
                style: const TextStyle(color: AppTheme.pending, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),

          // Playing all indicator
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
                            fontFamily: 'Amiri',
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              isBn ? '${names.length} টি নাম' : '${names.length} names',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            // Repeat button
                            GestureDetector(
                              onTap: _ttsReady ? () => _playGroup(groupIndex) : null,
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
                                      isGroupPlaying ? Icons.stop : Icons.repeat,
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
