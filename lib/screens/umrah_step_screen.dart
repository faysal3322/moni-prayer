import 'package:flutter/material.dart';

import '../data/umrah_data.dart';
import '../utils/app_language.dart';
import '../utils/app_theme.dart';
import '../utils/umrah_progress.dart';
import '../widgets/umrah_widgets.dart';

/// একটি ধাপের পাতা: প্রতিটি কাজের আগে গোল টিক-বক্স। সব টিক হলে "পরের ধাপ" বাটন চালু হয়।
class UmrahStepScreen extends StatefulWidget {
  final AppLanguage lang;
  final int index;
  const UmrahStepScreen({super.key, required this.lang, required this.index});

  @override
  State<UmrahStepScreen> createState() => _UmrahStepScreenState();
}

class _UmrahStepScreenState extends State<UmrahStepScreen> {
  final UmrahProgress _p = UmrahProgress.instance;
  final ScrollController _scroll = ScrollController();

  bool get _bn => widget.lang.isBn;
  String _t(String bn, String en) => _bn ? bn : en;
  String _n(int v) => widget.lang.toLocalNum(v);

  UmrahStep get _s => UmrahData.steps[widget.index];
  bool get _isLast => widget.index == UmrahData.steps.length - 1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _next() {
    _p.completeStep(widget.index);
    if (_isLast) {
      Navigator.pop(context);
    } else {
      // পরের ধাপে সরাসরি চলে যাবে (পেছনে ট্র্যাকার থাকবে)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UmrahStepScreen(lang: widget.lang, index: widget.index + 1),
        ),
      );
    }
  }

  void _showProhibitions() {
    final txt = TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6);
    Widget group(String title, Color c, IconData ic, List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          umrahSectionLabel(title, c),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(ic, size: 18, color: c),
                  const SizedBox(width: 8),
                  Expanded(child: Text(it, style: txt)),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('ইহরাম অবস্থার নিষেধাজ্ঞা', 'Restrictions during Ihram'),
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            group(_t('নিষিদ্ধ', 'Not allowed'), AppTheme.missed, Icons.block,
                UmrahData.prohibited),
            if (_p.female)
              group(_t('নারীদের জন্য', 'For women'), const Color(0xFFEC407A),
                  Icons.block, UmrahData.prohibitedWomen),
            group(_t('বৈধ', 'Allowed'), AppTheme.completed,
                Icons.check_circle_outline, UmrahData.allowed),
            Text(
              UmrahData.prohibitedNote,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _p,
      builder: (context, _) {
        final s = _s;
        final done = _p.isStepDone(widget.index);
        final ready = _p.isStepReady(s);
        final checked = _p.checkedCount(s);
        final total = s.totalItems;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(
              _t('ধাপ ${_n(widget.index + 1)}: ${s.title}',
                  'Step ${widget.index + 1}: ${s.titleEn}'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kUmrahGreen),
                  color: kUmrahGreen.withOpacity(done ? 0.25 : 0.08),
                ),
                child: Text(
                  done ? _t('সম্পন্ন', 'Done') : _t('চলমান', 'In progress'),
                  style: const TextStyle(
                    color: kUmrahGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  children: [
                    if (s.ihramBanner) _banner(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Text(s.emoji, style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.subtitle,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          UmrahGenderChips(lang: widget.lang),
                        ],
                      ),
                    ),
                    if (s.counter != UmrahCounter.none)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: UmrahCounterCard(
                            kind: s.counter, lang: widget.lang),
                      ),
                    _checklist(s),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _extras(s),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _bottomBar(s, done, ready, checked, total),
            ],
          ),
        );
      },
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      color: kUmrahGreen.withOpacity(AppTheme.isDark ? 0.18 : 0.12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: kUmrahGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(
                    'আপনি ইহরামের অবস্থায় আছেন। তাওয়াফ শুরু করার জন্য কাবাপ্রাঙ্গণে না পৌঁছানো পর্যন্ত ঘনঘন তালবিয়া পাঠ করতে থাকুন।',
                    'You are in the state of Ihram. Keep reciting the Talbiyah often until you reach the Kaaba to begin Tawaf.',
                  ),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _showProhibitions,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _t('নিষিদ্ধ কাজগুলো দেখে নিন', 'See restrictions'),
                    style: const TextStyle(
                      color: kUmrahGreen,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kUmrahGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// টিক-বক্সসহ সেকশন তালিকা
  Widget _checklist(UmrahStep s) {
    int flat = 0;
    final children = <Widget>[];
    for (final sec in s.sections) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
          child: Text(
            sec.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      for (final item in sec.items) {
        final idx = flat++;
        final on = _p.isChecked(s.id, idx);
        children.add(_checkRow(s.id, idx, item, on));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _checkRow(String stepId, int idx, String text, bool on) {
    return InkWell(
      onTap: () => _p.toggle(stepId, idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? kUmrahGreen : Colors.transparent,
                border: Border.all(
                  color: on ? kUmrahGreen : AppTheme.divider24,
                  width: 2,
                ),
              ),
              child: on
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: on ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontSize: 15.5,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// নারীদের নির্দেশনা, সতর্কতা ও দোয়া
  Widget _extras(UmrahStep s) {
    final body = TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 14.5,
      height: 1.65,
    );
    Widget bullets(List<String> list, Color dot) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final w in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: dot, fontSize: 16)),
                    Expanded(child: Text(w, style: body)),
                  ],
                ),
              ),
          ],
        );

    const pink = Color(0xFFEC407A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        if (_p.female && s.womenPoints.isNotEmpty)
          umrahBox(
            fill: pink.withOpacity(AppTheme.isDark ? 0.10 : 0.07),
            border: pink.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                umrahSectionLabel(
                    _t('👩 নারীদের জন্য বিশেষ নির্দেশনা', '👩 For women'), pink),
                bullets(s.womenPoints, pink),
              ],
            ),
          ),
        if (s.warnings.isNotEmpty)
          umrahBox(
            fill: AppTheme.missed.withOpacity(AppTheme.isDark ? 0.10 : 0.06),
            border: AppTheme.missed.withOpacity(0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                umrahSectionLabel(
                    _t('⚠️ সতর্কতা', '⚠️ Be careful'), AppTheme.missed),
                bullets(s.warnings, AppTheme.missed),
              ],
            ),
          ),
        if (s.duaIds.isNotEmpty) ...[
          umrahSectionLabel(
              _t('🤲 এই ধাপের দোয়া', '🤲 Duas for this step'), AppTheme.gold),
          for (final id in s.duaIds)
            if (UmrahData.duaById(id) != null)
              UmrahDuaCard(dua: UmrahData.duaById(id)!, lang: widget.lang),
        ],
      ],
    );
  }

  Widget _bottomBar(UmrahStep s, bool done, bool ready, int checked, int total) {
    final canGo = done || ready;
    final nextTitle =
        _isLast ? null : UmrahData.steps[widget.index + 1].title;

    String label;
    if (_isLast) {
      label = _t('ওমরাহ সম্পন্ন করুন', 'Complete Umrah');
    } else {
      label = _t('পরবর্তী ধাপ: $nextTitle', 'Next: ${UmrahData.steps[widget.index + 1].titleEn}');
    }

    String? hint;
    if (!canGo) {
      if (checked < total) {
        hint = _t(
          'সব কাজে টিক দিন (${_n(checked)}/${_n(total)})',
          'Tick every item ($checked/$total)',
        );
      } else {
        hint = _t('আগে ৭ চক্কর গণনা শেষ করুন', 'Finish counting all 7 rounds first');
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  hint,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            UmrahPrimaryButton(
              label: label,
              onPressed: canGo ? _next : null,
              icon: _isLast ? Icons.check : Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}
