import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/umrah_data.dart';

/// ওমরাহ ট্র্যাকারের অগ্রগতি (SharedPreferences-এ সেভ হয়)।
///
/// - [current]   : বর্তমান ধাপের ইনডেক্স (০–১১); সব ধাপ শেষ হলে ১২
/// - [checks]    : টিক দেওয়া আইটেম ("stepId:index")
/// - [tawaf]/[sai]: চক্কর গণনা (০–৭)
class UmrahProgress extends ChangeNotifier {
  UmrahProgress._();
  static final UmrahProgress instance = UmrahProgress._();

  static const _kStarted = 'umrah_started';
  static const _kCurrent = 'umrah_cur';
  static const _kChecks = 'umrah_checks';
  static const _kTawaf = 'umrah_tawaf';
  static const _kSai = 'umrah_sai';
  static const _kFemale = 'umrah_female';

  bool loaded = false;
  bool started = false;
  int current = 0;
  int tawaf = 0;
  int sai = 0;
  bool female = false;
  final Set<String> checks = {};

  int get total => UmrahData.steps.length;
  bool get allDone => current >= total;

  int _cl(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    started = p.getBool(_kStarted) ?? false;
    current = _cl(p.getInt(_kCurrent) ?? 0, 0, total);
    tawaf = _cl(p.getInt(_kTawaf) ?? 0, 0, 7);
    sai = _cl(p.getInt(_kSai) ?? 0, 0, 7);
    female = p.getBool(_kFemale) ?? false;
    checks
      ..clear()
      ..addAll(p.getStringList(_kChecks) ?? const []);
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kStarted, started);
    await p.setInt(_kCurrent, current);
    await p.setInt(_kTawaf, tawaf);
    await p.setInt(_kSai, sai);
    await p.setBool(_kFemale, female);
    await p.setStringList(_kChecks, checks.toList());
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  // ── ধাপের অবস্থা ──
  bool isStepDone(int i) => i < current;
  bool isStepCurrent(int i) => i == current;
  bool isStepLocked(int i) => i > current;

  bool isChecked(String stepId, int idx) => checks.contains('$stepId:$idx');

  int checkedCount(UmrahStep s) {
    int n = 0;
    for (int i = 0; i < s.totalItems; i++) {
      if (isChecked(s.id, i)) n++;
    }
    return n;
  }

  int counterOf(UmrahCounter c) =>
      c == UmrahCounter.tawaf ? tawaf : (c == UmrahCounter.sai ? sai : 7);

  /// ধাপের সব টিক ও (থাকলে) ৭ চক্কর শেষ কি না
  bool isStepReady(UmrahStep s) =>
      checkedCount(s) >= s.totalItems && counterOf(s.counter) >= 7;

  /// ০.০ – ১.০ : সম্পন্ন ধাপ + বর্তমান ধাপের আংশিক অগ্রগতি
  double get fraction {
    if (allDone) return 1.0;
    final s = UmrahData.steps[current];
    final items = s.totalItems + (s.counter == UmrahCounter.none ? 0 : 1);
    final done = checkedCount(s) +
        (s.counter == UmrahCounter.none
            ? 0
            : (counterOf(s.counter) >= 7 ? 1 : 0));
    final part = items == 0 ? 0.0 : done / items;
    return (current + part) / total;
  }

  // ── কাজ ──
  void start() {
    started = true;
    _commit();
  }

  void toggle(String stepId, int idx) {
    final k = '$stepId:$idx';
    if (!checks.remove(k)) checks.add(k);
    _commit();
  }

  /// ধাপ [i] সম্পন্ন — পরের ধাপ খুলে যাবে
  void completeStep(int i) {
    if (i >= current) current = _cl(i + 1, 0, total);
    started = true;
    _commit();
  }

  void setCounter(UmrahCounter c, int v) {
    if (c == UmrahCounter.tawaf) tawaf = _cl(v, 0, 7);
    if (c == UmrahCounter.sai) sai = _cl(v, 0, 7);
    _commit();
  }

  void setFemale(bool v) {
    female = v;
    _commit();
  }

  void reset() {
    started = false;
    current = 0;
    tawaf = 0;
    sai = 0;
    checks.clear();
    _commit();
  }
}
