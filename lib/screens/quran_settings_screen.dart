import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_prefs.dart';
import '../utils/quran_audio_helper.dart';

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
                      isBn ? 'শীঘ্রই আসছে' : 'Coming soon',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isBn
                              ? 'অডিও ডাউনলোড ফিচার শীঘ্রই যুক্ত হবে'
                              : 'Audio download feature coming soon'),
                          backgroundColor: AppTheme.cardBg,
                        ),
                      );
                    },
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
