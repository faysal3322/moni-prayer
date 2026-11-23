import 'package:flutter/material.dart';

import '../data/umrah_data.dart';
import '../utils/app_language.dart';
import '../utils/app_theme.dart';
import '../utils/umrah_progress.dart';
import '../widgets/umrah_widgets.dart';
import 'umrah_step_screen.dart';

/// ওমরাহ ট্র্যাকার: বর্তমান অগ্রগতি + ১২ ধাপের ভ্রমণসূচী।
class UmrahTrackerScreen extends StatelessWidget {
  final AppLanguage lang;
  const UmrahTrackerScreen({super.key, required this.lang});

  UmrahProgress get _p => UmrahProgress.instance;
  bool get _bn => lang.isBn;
  String _t(String bn, String en) => _bn ? bn : en;
  String _n(int v) => lang.toLocalNum(v);

  void _open(BuildContext context, int i) {
    if (_p.isStepLocked(i)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_t('আগের ধাপগুলো সম্পন্ন করুন', 'Finish the previous steps first')),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }
    _p.start();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UmrahStepScreen(lang: lang, index: i)),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('নতুন করে শুরু করবেন?', 'Start over?')),
        content: Text(_t(
          'সব ধাপ, টিক এবং তাওয়াফ ও সাঈর গণনা মুছে প্রথম থেকে শুরু হবে।',
          'All steps, ticks and tawaf / sa\'i counts will be reset.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.confirm),
          ),
        ],
      ),
    );
    if (ok == true) _p.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _p,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(_t('ওমরাহ ট্র্যাকার', 'Umrah Tracker')),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: _t('নতুন করে শুরু', 'Start over'),
              icon: const Icon(Icons.restart_alt),
              onPressed: () => _confirmReset(context),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _sectionHeader(_t('বর্তমান অগ্রগতি', 'Current progress')),
            _p.allDone ? _doneCard() : _currentCard(context),
            _sectionHeader(_t('ভ্রমণসূচী', 'Itinerary')),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 16, 32),
              child: Column(
                children: [
                  for (int i = 0; i < UmrahData.steps.length; i++)
                    _timelineRow(context, i),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _currentCard(BuildContext context) {
    final i = _p.current;
    final s = UmrahData.steps[i];
    final pct = (_p.fraction * 100).round();
    final started = _p.checkedCount(s) > 0 || _p.counterOf(s.counter) > 0 && s.counter != UmrahCounter.none;

    return Container(
      width: double.infinity,
      color: AppTheme.cardBg,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _t('ধাপ ${_n(i + 1)} (${_n(UmrahData.steps.length)} এর মধ্যে)',
                      'Step ${i + 1} of ${UmrahData.steps.length}'),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _badge(_t('চলমান', 'In progress')),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _p.fraction,
                    strokeWidth: 10,
                    backgroundColor: AppTheme.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(kUmrahGreen),
                  ),
                ),
                Text(
                  '${_n(pct)}%',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _bn ? s.title : s.titleEn,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 20),
          UmrahPrimaryButton(
            label: started
                ? _t('চালিয়ে যান', 'Continue')
                : _t('ধাপটি শুরু করুন', 'Start this step'),
            onPressed: () => _open(context, i),
          ),
        ],
      ),
    );
  }

  /// ১২ ধাপ শেষ — আগের "আলহামদুলিল্লাহ" ধাপের লেখা
  Widget _doneCard() {
    return Container(
      width: double.infinity,
      color: AppTheme.cardBg,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('🌟', style: TextStyle(fontSize: 44))),
          const SizedBox(height: 8),
          Center(
            child: Text(
              UmrahData.doneTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final t in UmrahData.donePoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 20, color: kUmrahGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.5,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          for (final id in UmrahData.doneDuaIds)
            if (UmrahData.duaById(id) != null)
              UmrahDuaCard(dua: UmrahData.duaById(id)!, lang: lang),
        ],
      ),
    );
  }

  Widget _badge(String text, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: kUmrahGreen.withOpacity(filled ? 0.25 : 0.10),
        border: Border.all(color: kUmrahGreen.withOpacity(0.7)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kUmrahGreen,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _timelineRow(BuildContext context, int i) {
    final s = UmrahData.steps[i];
    final done = _p.isStepDone(i);
    final cur = _p.isStepCurrent(i);
    final last = i == UmrahData.steps.length - 1;

    final statusText = done
        ? _t('সম্পন্ন', 'Done')
        : cur
            ? _t('চলমান', 'In progress')
            : _t('অপেক্ষমান', 'Waiting');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // বাঁ পাশের গোল ও রেখা
          SizedBox(
            width: 44,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? kUmrahGreen : Colors.transparent,
                    border: Border.all(
                      color: (done || cur) ? kUmrahGreen : AppTheme.divider24,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : cur
                          ? const Icon(Icons.arrow_forward,
                              color: kUmrahGreen, size: 20)
                          : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: done ? kUmrahGreen : AppTheme.divider24,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _open(context, i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    color: cur
                        ? kUmrahGreen.withOpacity(AppTheme.isDark ? 0.14 : 0.08)
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cur ? kUmrahGreen : AppTheme.divider,
                      width: cur ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_n(i + 1)}. ${_bn ? s.title : s.titleEn}',
                          style: TextStyle(
                            color: cur ? kUmrahGreen : AppTheme.textPrimary,
                            fontSize: 16.5,
                            fontWeight: cur ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: (done || cur)
                              ? kUmrahGreen
                              : AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (cur) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward,
                            size: 18, color: kUmrahGreen),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
