import 'package:flutter/material.dart';

import '../data/umrah_data.dart';
import '../utils/app_language.dart';
import '../utils/app_theme.dart';
import '../widgets/umrah_widgets.dart';

/// ওমরাহর রেফারেন্স পাতা: দোয়া · ভুল হলে · তথ্য (আগের ট্যাবগুলোর লেখা অপরিবর্তিত)।
class UmrahResourcesScreen extends StatefulWidget {
  final AppLanguage lang;
  final int initialTab;
  const UmrahResourcesScreen({super.key, required this.lang, this.initialTab = 0});

  @override
  State<UmrahResourcesScreen> createState() => _UmrahResourcesScreenState();
}

class _UmrahResourcesScreenState extends State<UmrahResourcesScreen> {
  String _query = '';

  bool get _bn => widget.lang.isBn;
  String _t(String bn, String en) => _bn ? bn : en;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t('ওমরাহ গাইড', 'Umrah Guide')),
          bottom: TabBar(
            indicatorColor: AppTheme.accent,
            tabs: [
              Tab(text: _t('🤲 দোয়া', '🤲 Duas')),
              Tab(text: _t('⚠️ ভুল হলে', '⚠️ Mistakes')),
              Tab(text: _t('ℹ️ তথ্য', 'ℹ️ Info')),
            ],
          ),
        ),
        body: TabBarView(
          children: [_duaTab(), _problemTab(), _infoTab()],
        ),
      ),
    );
  }

  Widget _box({required Widget child, Color? border, Color? fill}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? AppTheme.divider),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _duaTab() {
    final q = _query.trim();
    final list = UmrahData.duas.where((d) {
      if (q.isEmpty) return true;
      return d.title.contains(q) ||
          d.translit.contains(q) ||
          d.meaning.contains(q) ||
          d.note.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: _t('দোয়া খুঁজুন…', 'Search duas…'),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppTheme.fieldFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                _t('কোনো দোয়া পাওয়া যায়নি', 'No duas found'),
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        for (final d in list) UmrahDuaCard(dua: d, lang: widget.lang),
      ],
    );
  }

  Widget _problemTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _box(
          fill: AppTheme.pending.withOpacity(0.08),
          border: AppTheme.pending.withOpacity(0.4),
          child: Text(
            _t(
              'সমস্যায় পড়লে ঘাবড়াবেন না। নিচে সাধারণ সমস্যার সমাধান আছে। জটিল বা মাযহাবভেদে ভিন্ন মাসয়ালায় আপনার গ্রুপ-আলেম বা নির্ভরযোগ্য আলেমের পরামর্শ নিন।',
              'Don\'t panic. Common problems and what to do are below. For complex or school-dependent rulings, ask a reliable scholar.',
            ),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ),
        for (final p in UmrahData.problems)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(
                  p.question,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                children: [
                  Text(
                    p.answer,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _infoTab() {
    final txt = TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 14,
      height: 1.7,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(
                _t('🌟 ওমরাহর ফজিলত', 'Virtues of Umrah'),
                AppTheme.gold,
              ),
              for (final v in UmrahData.virtues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(v, style: txt),
                ),
            ],
          ),
        ),
        _box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(
                _t('📋 ওমরাহর কাজ ও বিধান', 'Rulings'),
                AppTheme.gold,
              ),
              Text(UmrahData.rulingNote, style: txt),
              const SizedBox(height: 8),
              Text(UmrahData.hajjSeasonNote, style: txt),
            ],
          ),
        ),
        _box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(_t('📍 মীকাতসমূহ', 'Miqat points'), AppTheme.gold),
              for (final m in UmrahData.miqats)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m[0],
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        m[1],
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(UmrahData.miqatNote, style: txt),
            ],
          ),
        ),
        _box(
          child: Text(
            _t(
              'সূত্র: কুরআন ও সহিহ হাদিস এবং একাধিক নির্ভরযোগ্য বাংলা ওমরাহ গাইড থেকে সংকলিত। কোথাও মতভেদ থাকলে সুন্নাহসম্মত ও সহজ মতটি দেখানো হয়েছে; নিজের মাযহাব বা আলেমের নির্দেশনা অনুসরণ করুন।',
              'Compiled from the Quran, authentic hadith and several Bengali Umrah guides. Where scholars differ, follow your own school or scholar.',
            ),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
