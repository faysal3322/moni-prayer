import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_prefs.dart';
import '../utils/quran_audio_helper.dart';
import '../utils/quran_database_helper.dart';

class QuranSettingsScreen extends StatefulWidget {
  final AppLanguage lang;
  const QuranSettingsScreen({super.key, required this.lang});

  @override
  State<QuranSettingsScreen> createState() => _QuranSettingsScreenState();
}

class _QuranSettingsScreenState extends State<QuranSettingsScreen> {
  bool _showArabic = true;
  bool _showBangla = false;
  bool _showTransliteration = false;
  double _fontSize = 28.0;
  bool _loading = true;

  // "সম্পূর্ণ কোরআন অফলাইন ডাউনলোড করুন" চলাকালীন ব্যবহারকারীকে ডায়ালগ
  // থেকে "বাতিল" চাপার সুযোগ দেওয়ার জন্য — true থাকলে downloadAllSurahs
  // পরের সূরায় যাওয়ার আগে থেমে যায়।
  bool _downloadCancelled = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final arabic = await QuranPrefs.getShowArabic();
    final bangla = await QuranPrefs.getShowBangla();
    final translit = await QuranPrefs.getShowTransliteration();
    final fontSize = await QuranPrefs.getFontSize();
    if (!mounted) return;
    setState(() {
      _showArabic = arabic;
      _showBangla = bangla;
      _showTransliteration = translit;
      _fontSize = fontSize;
      _loading = false;
    });
  }

  Future<void> _toggleArabic(bool value) async {
    if (!value && !_showBangla && !_showTransliteration) {
      _showWarning();
      return;
    }
    setState(() => _showArabic = value);
    await QuranPrefs.setShowArabic(value);
  }

  Future<void> _toggleBangla(bool value) async {
    if (!value && !_showArabic && !_showTransliteration) {
      _showWarning();
      return;
    }
    setState(() => _showBangla = value);
    await QuranPrefs.setShowBangla(value);
  }

  Future<void> _toggleTransliteration(bool value) async {
    if (!value && !_showArabic && !_showBangla) {
      _showWarning();
      return;
    }
    setState(() => _showTransliteration = value);
    await QuranPrefs.setShowTransliteration(value);
  }

  void _showWarning() {
    final isBn = widget.lang.isBn;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBn
            ? 'অন্তত একটি ভাষা চালু রাখতে হবে'
            : 'At least one language must stay on'),
        backgroundColor: AppTheme.cardBg,
      ),
    );
  }

  Future<void> _onFontSizeChanged(double value) async {
    setState(() => _fontSize = value);
    await QuranPrefs.setFontSize(value);
  }

  /// "সম্পূর্ণ কোরআন অফলাইন ডাউনলোড করুন" চাপলে কল হয় — একটা প্রোগ্রেস
  /// ডায়ালগ দেখিয়ে ব্যাকগ্রাউন্ডে ১ থেকে ১১৪ পর্যন্ত সব সূরা একে একে
  /// ডাউনলোড করে। আগে থেকেই ডাউনলোড করা সূরাগুলো QuranAudioHelper নিজে
  /// থেকেই স্কিপ করে দেয়, তাই দ্বিতীয়বার চাপলে শুধু বাকি থাকা সূরাগুলোই
  /// ডাউনলোড হবে।
  Future<void> _startDownloadAll() async {
    final isBn = widget.lang.isBn;
    _downloadCancelled = false;

    final progress = ValueNotifier<({int completed, int total, int currentSura})>(
      (completed: 0, total: 114, currentSura: 1),
    );

    // ডায়ালগটা একটা StatefulBuilder-বিহীন ValueListenableBuilder দিয়ে
    // বানানো হয়েছে, যাতে প্রতিটা সূরা শেষ হওয়ার সাথে সাথে UI রিবিল্ড
    // হয়ে যায় — কিন্তু পুরো স্ক্রিন না, শুধু ডায়ালগের ভেতরের টেক্সট/বার।
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ValueListenableBuilder(
        valueListenable: progress,
        builder: (context, value, _) {
          final ratio = value.total == 0 ? 0.0 : value.completed / value.total;
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            title: Text(
              isBn ? 'ডাউনলোড হচ্ছে...' : 'Downloading...',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn
                      ? 'সূরা ${value.currentSura} (${value.completed}/${value.total})'
                      : 'Surah ${value.currentSura} (${value.completed}/${value.total})',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _downloadCancelled = true;
                  Navigator.pop(dialogContext);
                },
                child: Text(isBn ? 'বাতিল' : 'Cancel'),
              ),
            ],
          );
        },
      ),
    );

    List<int> failed = [];
    try {
      failed = await QuranAudioHelper.downloadAllSurahs(
        getAllSurahAudio: QuranDatabaseHelper.getAllSurahAudio,
        shouldContinue: () => !_downloadCancelled,
        onProgress: (completed, total, currentSura) {
          progress.value = (completed: completed, total: total, currentSura: currentSura);
        },
      );
    } finally {
      // ডাউনলোড শেষ হোক বা ব্যর্থ হোক, ডায়ালগ খোলা থাকলে বন্ধ করে দেওয়া
      // হচ্ছে (ব্যবহারকারী নিজে "বাতিল" চেপে আগেই বন্ধ করে দিলে
      // Navigator.pop আবার কল করা এড়াতে mounted/canPop চেক করা হচ্ছে)।
      if (mounted && Navigator.of(context, rootNavigator: false).canPop() && !_downloadCancelled) {
        Navigator.of(context).pop();
      }
    }

    if (!mounted) return;

    if (_downloadCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'ডাউনলোড বাতিল করা হয়েছে' : 'Download cancelled'),
          backgroundColor: AppTheme.cardBg,
        ),
      );
      return;
    }

    if (failed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn
              ? 'সম্পূর্ণ কোরআন অফলাইনের জন্য ডাউনলোড হয়ে গেছে'
              : 'Full Quran downloaded for offline use'),
          backgroundColor: AppTheme.cardBg,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn
              ? '${failed.length}টি সূরা ডাউনলোড ব্যর্থ হয়েছে (ইন্টারনেট চেক করে আবার চেষ্টা করুন)'
              : '${failed.length} surah(s) failed to download (check your internet and try again)'),
          backgroundColor: AppTheme.cardBg,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'কোরআন সেটিংস' : 'Quran Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionLabel(text: isBn ? 'ভাষা' : 'Language'),
                const SizedBox(height: 8),
                Text(
                  isBn
                      ? 'পড়ার সময় স্ক্রিনে কোন ভাষা দেখতে চান তা বেছে নিন। একাধিক ভাষা একসাথে চালু রাখা যাবে।'
                      : 'Choose which languages appear while reading. Multiple can be on at once.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 12),

                _LanguageToggleTile(
                  title: isBn ? 'আরবি (মূল কোরআন)' : 'Arabic (Original)',
                  value: _showArabic,
                  onChanged: _toggleArabic,
                ),
                _LanguageToggleTile(
                  title: isBn ? 'বাংলা অনুবাদ' : 'Bangla Translation',
                  value: _showBangla,
                  onChanged: _toggleBangla,
                ),
                _LanguageToggleTile(
                  title: isBn ? 'ইংরেজি উচ্চারণ' : 'English Transliteration',
                  value: _showTransliteration,
                  onChanged: _toggleTransliteration,
                ),

                const SizedBox(height: 24),
                _SectionLabel(text: isBn ? 'ফন্ট সাইজ' : 'Font Size'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'بِسْمِ اللَّهِ',
                        style: TextStyle(
                          fontSize: _fontSize,
                          color: AppTheme.gold,
                          fontFamily: 'ScheherazadeNew',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.text_decrease, color: AppTheme.textSecondary, size: 18),
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min: 18,
                              max: 40,
                              divisions: 11,
                              activeColor: AppTheme.gold,
                              onChanged: _onFontSizeChanged,
                            ),
                          ),
                          const Icon(Icons.text_increase, color: AppTheme.textSecondary, size: 22),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionLabel(text: isBn ? 'অডিও' : 'Audio'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.download_outlined, color: AppTheme.gold),
                    title: Text(
                      isBn ? 'সম্পূর্ণ কোরআন অফলাইন ডাউনলোড করুন' : 'Download full Quran for offline',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isBn ? 'সব ১১৪টি সূরার তেলাওয়াত একসাথে ডাউনলোড করুন' : 'Download all 114 surahs at once',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    onTap: _startDownloadAll,
                  ),
                ),

                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.cleaning_services_outlined, color: AppTheme.gold),
                    title: Text(
                      isBn ? 'অডিও ক্যাশ পরিষ্কার করুন' : 'Clear audio cache',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isBn
                          ? 'অডিও থেমে যাওয়া বা কাটা কাটা লাগলে ব্যবহার করুন — সব ডাউনলোড করা তেলাওয়াত মুছে আবার নতুন করে ডাউনলোড হবে'
                          : 'Use if audio cuts off or sounds wrong — deletes downloaded recitations so they re-download fresh',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: AppTheme.cardBg,
                          title: Text(
                            isBn ? 'অডিও ক্যাশ পরিষ্কার করবেন?' : 'Clear audio cache?',
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                          content: Text(
                            isBn
                                ? 'ডাউনলোড করা সব সূরার তেলাওয়াত মুছে ফেলা হবে। পরের বার প্লে করার সময় ইন্টারনেট থেকে আবার ডাউনলোড হবে।'
                                : 'All downloaded surah recitations will be deleted. They will re-download from the internet next time you play them.',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: Text(isBn ? 'বাতিল' : 'Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: Text(isBn ? 'পরিষ্কার করুন' : 'Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await QuranAudioHelper.clearAllDownloadedAudio();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBn ? 'অডিও ক্যাশ পরিষ্কার হয়েছে' : 'Audio cache cleared'),
                            backgroundColor: AppTheme.cardBg,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.gold,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _LanguageToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LanguageToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        value: value,
        activeColor: AppTheme.gold,
        onChanged: onChanged,
      ),
    );
  }
}
