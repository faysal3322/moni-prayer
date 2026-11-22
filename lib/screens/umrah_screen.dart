import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/umrah_data.dart';
import '../utils/app_language.dart';
import '../utils/app_theme.dart';

/// হোমের "ওমরাহ" ক্যাটাগরি — ধাপে ধাপে মোয়াল্লেম (গাইড)।
///
/// ৪টি ট্যাব: গাইড (ধাপ ও কাউন্টার), দোয়া, ভুল হলে, তথ্য।
/// অগ্রগতি (ধাপ, তাওয়াফ/সাঈর চক্কর, পুরুষ/নারী) SharedPreferences-এ সেভ হয়।
/// সব তথ্য lib/data/umrah_data.dart-এ — সেখানে বদলালেই এখানে বদলে যাবে।
class UmrahScreen extends StatefulWidget {
  final AppLanguage lang;
  const UmrahScreen({super.key, required this.lang});

  @override
  State<UmrahScreen> createState() => _UmrahScreenState();
}

class _UmrahScreenState extends State<UmrahScreen> {
  static const _kStep = 'umrah_step';
  static const _kTawaf = 'umrah_tawaf';
  static const _kSai = 'umrah_sai';
  static const _kFemale = 'umrah_female';

  int _tab = 0;
  int _step = 0;
  int _tawaf = 0;
  int _sai = 0;
  bool _female = false;
  String _query = '';
  final ScrollController _scroll = ScrollController();

  bool get _bn => widget.lang.isBn;
  String _t(String bn, String en) => _bn ? bn : en;
  String _n(int v) => widget.lang.toLocalNum(v);
  int _cl(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _step = _cl(p.getInt(_kStep) ?? 0, 0, UmrahData.steps.length - 1);
      _tawaf = _cl(p.getInt(_kTawaf) ?? 0, 0, 7);
      _sai = _cl(p.getInt(_kSai) ?? 0, 0, 7);
      _female = p.getBool(_kFemale) ?? false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kStep, _step);
    await p.setInt(_kTawaf, _tawaf);
    await p.setInt(_kSai, _sai);
    await p.setBool(_kFemale, _female);
  }

  void _go(int i) {
    setState(() => _step = _cl(i, 0, UmrahData.steps.length - 1));
    _save();
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('নতুন করে শুরু করবেন?', 'Start over?')),
        content: Text(
          _t(
            'ধাপ, তাওয়াফ ও সাঈর সব গণনা মুছে প্রথম থেকে শুরু হবে।',
            'Your step, tawaf and sa\'i counts will be reset.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.lang.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.lang.confirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _step = 0;
        _tawaf = 0;
        _sai = 0;
      });
      _save();
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('ওমরাহ', 'Umrah')),
        actions: [
          IconButton(
            tooltip: _t('নতুন করে শুরু', 'Start over'),
            icon: const Icon(Icons.restart_alt),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: Column(
        children: [
          _tabBar(),
          Expanded(
            child: _tab == 0
                ? _guideTab()
                : _tab == 1
                ? _duaTab()
                : _tab == 2
                ? _problemTab()
                : _infoTab(),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    final items = [
      ['🧭', _t('গাইড', 'Guide')],
      ['🤲', _t('দোয়া', 'Duas')],
      ['⚠️', _t('ভুল হলে', 'Mistakes')],
      ['ℹ️', _t('তথ্য', 'Info')],
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(items[i][0], style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      items[i][1],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        color: sel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════
  // গাইড ট্যাব
  Widget _guideTab() {
    final steps = UmrahData.steps;
    final s = steps[_step];
    final progress = (_step + 1) / steps.length;

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (_step == 0) _welcomeCard(),
        // অগ্রগতি
        Row(
          children: [
            Text(
              _t(
                'ধাপ ${_n(_step + 1)} / ${_n(steps.length)}',
                'Step ${_step + 1} of ${steps.length}',
              ),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ChoiceChip(
              label: Text(
                _t('পুরুষ', 'Male'),
                style: const TextStyle(fontSize: 12),
              ),
              selected: !_female,
              onSelected: (_) {
                setState(() => _female = false);
                _save();
              },
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: Text(
                _t('নারী', 'Female'),
                style: const TextStyle(fontSize: 12),
              ),
              selected: _female,
              onSelected: (_) {
                setState(() => _female = true);
                _save();
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
          ),
        ),
        const SizedBox(height: 12),
        _stepChips(),
        const SizedBox(height: 14),
        _stepCard(s),
        const SizedBox(height: 4),
        _navButtons(),
      ],
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

  Widget _stepChips() {
    final steps = UmrahData.steps;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = i == _step;
          final done = i < _step;
          return GestureDetector(
            onTap: () => _go(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.primary
                    : done
                    ? AppTheme.primary.withOpacity(0.22)
                    : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: sel ? AppTheme.accent : AppTheme.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    done ? '✅' : steps[i].emoji,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    steps[i].title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                      color: sel ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  Widget _stepCard(UmrahStep s) {
    final bodyStyle = TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 14.5,
      height: 1.65,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // শিরোনাম
        Row(
          children: [
            Text(s.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    s.subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // কাউন্টার
        if (s.counter != UmrahCounter.none) _counterCard(s.counter),

        // এখন কী করবেন
        _box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(
                _t('এখন যা করবেন', 'What to do now'),
                AppTheme.accent,
              ),
              for (int i = 0; i < s.points.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _n(i + 1),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.points[i], style: bodyStyle)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // নারীদের জন্য
        if (_female && s.womenPoints.isNotEmpty)
          _box(
            fill: const Color(0xFFEC407A)
                .withOpacity(AppTheme.isDark ? 0.10 : 0.07),
            border: const Color(0xFFEC407A).withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(
                  _t('👩 নারীদের জন্য বিশেষ নির্দেশনা', '👩 For women'),
                  const Color(0xFFEC407A),
                ),
                for (final w in s.womenPoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: Color(0xFFEC407A),
                            fontSize: 16,
                          ),
                        ),
                        Expanded(child: Text(w, style: bodyStyle)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // সতর্কতা
        if (s.warnings.isNotEmpty)
          _box(
            fill: AppTheme.missed.withOpacity(AppTheme.isDark ? 0.10 : 0.06),
            border: AppTheme.missed.withOpacity(0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(
                  _t('⚠️ সতর্কতা', '⚠️ Be careful'),
                  AppTheme.missed,
                ),
                for (final w in s.warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: AppTheme.missed,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(child: Text(w, style: bodyStyle)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // দোয়া
        if (s.duaIds.isNotEmpty) ...[
          _sectionLabel(
            _t('🤲 এই ধাপের দোয়া', '🤲 Duas for this step'),
            AppTheme.gold,
          ),
          for (final id in s.duaIds)
            if (UmrahData.duaById(id) != null) _duaCard(UmrahData.duaById(id)!),
        ],
      ],
    );
  }

  Widget _navButtons() {
    final last = _step == UmrahData.steps.length - 1;
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _go(_step - 1),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(_t('আগের ধাপ', 'Previous')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: BorderSide(color: AppTheme.divider24),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: last ? _confirmReset : () => _go(_step + 1),
            icon: Icon(
              last ? Icons.restart_alt : Icons.arrow_forward,
              size: 18,
            ),
            label: Text(
              last
                  ? _t('নতুন করে শুরু', 'Start over')
                  : _t('পরের ধাপ', 'Next step'),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // তাওয়াফ / সাঈ কাউন্টার
  Widget _counterCard(UmrahCounter kind) {
    final isTawaf = kind == UmrahCounter.tawaf;
    final count = isTawaf ? _tawaf : _sai;
    final done = count >= 7;
    final next = count + 1;

    String title;
    String hint;
    String? hint2;
    if (isTawaf) {
      title = _t('তাওয়াফ কাউন্টার', 'Tawaf counter');
      if (done) {
        hint = _t(
          'সাত চক্কর পূর্ণ! হাজরে আসওয়াদে আবার ইসতিলাম (অষ্টমবার) করুন, চাদর দিয়ে দুই কাঁধ ঢেকে নিন, তারপর দুই রাকাত নামাজ।',
          'Seven rounds complete! Make istilam once more, cover both shoulders, then pray two rak\'ahs.',
        );
      } else if (count == 0) {
        hint = _t(
          'হাজরে আসওয়াদ বরাবর দাঁড়িয়ে ইসতিলাম করে ১ম চক্কর শুরু করুন। কাবা থাকবে আপনার বামে।',
          'Face the Black Stone, make istilam and begin round 1. The Kaaba stays on your left.',
        );
      } else if (next <= 3) {
        hint = _t(
          '${_n(next)}ম চক্কর: পুরুষরা রমল করুন (কাঁধ হেলিয়ে একটু দ্রুত ছোট পদক্ষেপ)। হাজরে আসওয়াদ বরাবর এলে ইসতিলাম।',
          'Round $next: men do raml (brisk short steps). Istilam at the Black Stone.',
        );
      } else {
        hint = _t(
          '${_n(next)}ম চক্কর: স্বাভাবিক গতিতে হাঁটুন। হাজরে আসওয়াদ বরাবর এলে ইসতিলাম।',
          'Round $next: walk normally. Istilam at the Black Stone.',
        );
      }
      hint2 = done
          ? null
          : _t(
              'রুকনে ইয়ামানী থেকে হাজরে আসওয়াদের মাঝে: “রাব্বানা আতিনা ফিদ দুনইয়া হাসানাহ…”',
              'Between the Yemeni corner and the Black Stone: "Rabbana atina…"',
            );
    } else {
      title = _t('সাঈ কাউন্টার', 'Sa\'i counter');
      final atSafa = count % 2 == 0;
      if (done) {
        hint = _t(
          'সাত চক্কর পূর্ণ — আপনি এখন মারওয়ায়। সাঈ শেষ! এবার হলক/কসর।',
          'Seven laps done — you are at Marwa. Sa\'i complete! Now halq/taqsir.',
        );
      } else if (count == 0) {
        hint = _t(
          'সাফায় যান: “ইন্নাস সাফা ওয়াল মারওয়াতা মিন শা‘আইরিল্লাহ — আবদাউ বিমা বাদাআল্লাহু বিহি”, কিবলামুখী হয়ে তিনবার তাকবীর, দোয়া। তারপর মারওয়ার দিকে ১ম চক্কর শুরু করুন।',
          'Go to Safa, recite the verse, face the Kaaba, takbeer and dua, then start lap 1 toward Marwa.',
        );
      } else {
        hint = _t(
          '${_n(next)}ম চক্কর: ${atSafa ? 'সাফা থেকে মারওয়ার' : 'মারওয়া থেকে সাফার'} দিকে। এখন আপনি ${atSafa ? 'সাফায়' : 'মারওয়ায়'} — কিবলামুখী হয়ে দোয়া করে রওনা হোন।',
          'Lap $next: ${atSafa ? 'Safa → Marwa' : 'Marwa → Safa'}.',
        );
      }
      hint2 = done
          ? null
          : _t(
              'দুই সবুজ বাতির মাঝে পুরুষ দ্রুত চলবেন; নারী স্বাভাবিক গতিতে।',
              'Men move briskly between the green lights; women walk normally.',
            );
    }

    void inc() {
      if (count >= 7) return;
      HapticFeedback.mediumImpact();
      setState(() {
        if (isTawaf) {
          _tawaf++;
        } else {
          _sai++;
        }
      });
      _save();
    }

    void dec() {
      if (count <= 0) return;
      setState(() {
        if (isTawaf) {
          _tawaf--;
        } else {
          _sai--;
        }
      });
      _save();
    }

    void reset() {
      setState(() {
        if (isTawaf) {
          _tawaf = 0;
        } else {
          _sai = 0;
        }
      });
      _save();
    }

    return _box(
      border: AppTheme.gold.withOpacity(0.5),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: inc,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: count / 7,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done ? AppTheme.completed : AppTheme.gold,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _n(count),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/ ${_n(7)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (hint2 != null) ...[
            const SizedBox(height: 6),
            Text(
              hint2,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: _t('একটি পিছনে', 'Undo'),
                onPressed: count > 0 ? dec : null,
                icon: const Icon(Icons.undo),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: done ? null : inc,
                  child: Text(
                    done
                        ? _t('সম্পন্ন ✅', 'Done ✅')
                        : _t(
                            '${_n(next)}ম চক্কর সম্পন্ন (+১)',
                            'Round $next done (+1)',
                          ),
                  ),
                ),
              ),
              IconButton(
                tooltip: _t('আবার ০ থেকে', 'Reset'),
                onPressed: count > 0 ? reset : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // দোয়া কার্ড
  Widget _duaCard(UmrahDua d) {
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.title,
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: '${d.arabic}\n\n${d.translit}\n\n${d.meaning}',
                    ),
                  );
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(_t('কপি হয়েছে', 'Copied')),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppTheme.soft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                d.arabic,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 26,
                  height: 2.0,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            d.translit,
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 14,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            d.meaning,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (d.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.overlay.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                d.note,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // দোয়া ট্যাব (সব দোয়া + সার্চ)
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
        for (final d in list) _duaCard(d),
      ],
    );
  }

  // ══════════════════════════════════════════
  // ভুল হলে ট্যাব
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

  // ══════════════════════════════════════════
  // তথ্য ট্যাব
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
