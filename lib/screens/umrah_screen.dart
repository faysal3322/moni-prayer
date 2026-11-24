import 'package:flutter/material.dart';

import '../data/umrah_data.dart';
import '../utils/app_language.dart';
import '../utils/app_theme.dart';
import '../utils/umrah_progress.dart';
import '../widgets/umrah_widgets.dart';
import 'umrah_resources_screen.dart';
import 'umrah_tracker_screen.dart';

/// হোমের "ওমরাহ" ক্যাটাগরির প্রবেশ পাতা।
///
/// "উমরাহ শুরু করুন" → [UmrahTrackerScreen] (১২ ধাপের ট্র্যাকার) → [UmrahStepScreen] (টিক-বক্সসহ ধাপ)।
/// দোয়া / ভুল হলে / তথ্য → [UmrahResourcesScreen]।
/// সব তথ্য lib/data/umrah_data.dart-এ — সেখানে বদলালেই এখানে বদলে যাবে।
class UmrahScreen extends StatefulWidget {
  final AppLanguage lang;
  const UmrahScreen({super.key, required this.lang});

  @override
  State<UmrahScreen> createState() => _UmrahScreenState();
}

class _UmrahScreenState extends State<UmrahScreen> {
  final UmrahProgress _p = UmrahProgress.instance;

  bool get _bn => widget.lang.isBn;
  String _t(String bn, String en) => _bn ? bn : en;

  @override
  void initState() {
    super.initState();
    _p.load();
  }

  void _openTracker() {
    _p.start();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UmrahTrackerScreen(lang: widget.lang)),
    );
  }

  void _openResources(int tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UmrahResourcesScreen(lang: widget.lang, initialTab: tab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('ওমরাহ', 'Umrah'))),
      body: AnimatedBuilder(
        animation: _p,
        builder: (context, _) {
          final inProgress = _p.started && (_p.current > 0 || _p.checks.isNotEmpty);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _welcomeCard(),
              Row(
                children: [
                  Text(
                    _t('আপনি:', 'You are:'),
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 10),
                  UmrahGenderChips(lang: widget.lang),
                ],
              ),
              const SizedBox(height: 16),
              UmrahPrimaryButton(
                label: _p.allDone
                    ? _t('ট্র্যাকার দেখুন', 'View tracker')
                    : inProgress
                        ? _t('উমরাহ চালিয়ে যান', 'Continue Umrah')
                        : _t('উমরাহ শুরু করুন', 'Start Umrah'),
                onPressed: _openTracker,
              ),
              const SizedBox(height: 22),
              _linkTile('🤲', _t('দোয়াসমূহ', 'Duas'),
                  _t('আরবি, উচ্চারণ ও অর্থসহ', 'Arabic, transliteration & meaning'),
                  () => _openResources(0)),
              _linkTile('⚠️', _t('ভুল হলে করণীয়', 'If something goes wrong'),
                  _t('সাধারণ সমস্যা ও সমাধান', 'Common problems & solutions'),
                  () => _openResources(1)),
              _linkTile('ℹ️', _t('তথ্য, ফজিলত ও মীকাত', 'Info, virtues & miqat'),
                  _t('ওমরাহর বিধান ও মীকাতসমূহ', 'Rulings and miqat points'),
                  () => _openResources(2)),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(AppTheme.isDark ? 0.55 : 0.95),
            const Color(0xFF0D2E10),
          ],
        ),
        border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Text('🕋', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            UmrahData.welcome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.heroGold,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            UmrahData.welcomeSub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.heroText,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(String emoji, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Text(emoji, style: const TextStyle(fontSize: 26)),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(sub,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
        trailing: Icon(Icons.chevron_right, color: AppTheme.soft),
      ),
    );
  }
}
