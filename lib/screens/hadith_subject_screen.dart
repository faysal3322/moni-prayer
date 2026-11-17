import 'package:flutter/material.dart';
import '../data/hadith_data.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/hadith_prefs.dart';
import '../widgets/anchored_list.dart';
import '../widgets/hadith_last_read_card.dart';

/// বিষয়ভিত্তিক হাদিস স্ক্রিন — ডেটা আসে lib/data/hadith_data.dart থেকে।
/// সার্চ বক্স + "সর্বশেষ পঠিত অবস্থান" কার্ড + ক্যাটাগরি ফিল্টার + কার্ড লিস্ট।
/// নতুন ডেটা যোগ করলে এই ফাইলে কিছু বদলাতে হবে না।
/// কার্ডে ট্যাপ করলে লিস্ট সরাসরি ঐ হাদিসে চলে যায় (কোরআনের মতো)।
class HadithSubjectScreen extends StatefulWidget {
  final AppLanguage lang;
  const HadithSubjectScreen({super.key, required this.lang});

  @override
  State<HadithSubjectScreen> createState() => _HadithSubjectScreenState();
}

class _HadithSubjectScreenState extends State<HadithSubjectScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String? _category;

  // সর্বশেষ পঠিত হাদিসের ইনডেক্স (kHadithList-এ) — না থাকলে null
  int? _lastIndex;
  // লিস্ট যে হাদিস থেকে শুরু হবে; _epoch বদলালে লিস্ট নতুন করে সেই জায়গায় সাজে
  int _startIndex = 0;
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final idx = await HadithPrefs.getTopicLastReadIndex(kHadithList);
    if (mounted) setState(() => _lastIndex = idx);
  }

  void _jumpToLastRead() {
    final idx = _lastIndex;
    if (idx == null) return;
    FocusScope.of(context).unfocus();
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _category = null;
      _startIndex = idx;
      _epoch++;
    });
  }

  // স্ক্রল থামলে উপরে দৃশ্যমান হাদিসটি "সর্বশেষ পঠিত" হিসেবে সেভ
  void _onTopChanged(List<Hadith> items, int i) {
    if (i < 0 || i >= items.length) return;
    final h = items[i];
    final full = kHadithList.indexOf(h);
    final idx = full < 0 ? i : full;
    HadithPrefs.setTopicLastRead(h, idx);
    if (mounted) setState(() => _lastIndex = idx);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final set = <String>{};
    for (final h in kHadithList) {
      if (h.category.trim().isNotEmpty) set.add(h.category.trim());
    }
    return set.toList();
  }

  List<Hadith> get _filtered {
    final q = _query.trim().toLowerCase();
    return kHadithList.where((h) {
      if (_category != null && h.category.trim() != _category) return false;
      if (q.isEmpty) return true;
      return h.bangla.toLowerCase().contains(q) ||
          h.reference.toLowerCase().contains(q) ||
          h.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    final items = _filtered;
    final cats = _categories;

    return Scaffold(
      appBar: AppBar(title: Text(isBn ? 'বিষয়ভিত্তিক হাদিস' : 'Hadith by Topic')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _query = v;
                _startIndex = 0;
              }),
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: isBn ? 'হাদিস খুঁজুন...' : 'Search hadith...',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
              ),
            ),
          ),
          // "সর্বশেষ পঠিত অবস্থান" — সার্চ/ফিল্টার চলাকালীন দেখানো হয় না
          if (_lastIndex != null && _query.trim().isEmpty && _category == null)
            Builder(builder: (_) {
              final h = kHadithList[_lastIndex!];
              return HadithLastReadCard(
                isBn: isBn,
                title: h.category.trim().isNotEmpty ? h.category.trim() : h.reference,
                subtitle: h.bangla.replaceAll('\n', ' '),
                onTap: _jumpToLastRead,
              );
            }),
          if (cats.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip(isBn ? 'সব' : 'All', _category == null, () => setState(() {
                        _category = null;
                        _startIndex = 0;
                      })),
                  for (final c in cats)
                    _chip(c, _category == c, () => setState(() {
                          _category = c;
                          _startIndex = 0;
                        })),
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? _emptyState(isBn)
                : AnchoredList(
                    // ফিল্টার/সার্চ বদলালে বা কার্ড থেকে জাম্প করলে লিস্ট নতুন করে সাজে
                    key: ValueKey('$_epoch|$_category|$_query'),
                    startIndex: _startIndex,
                    horizontalPadding: 16,
                    topPadding: 8,
                    bottomPadding: 24,
                    itemCount: items.length,
                    onTopIndexChanged: (i) => _onTopChanged(items, i),
                    itemBuilder: (_, i) => _HadithCard(hadith: items[i], isBn: isBn),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppTheme.accent : AppTheme.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isBn) {
    final noData = kHadithList.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(noData ? Icons.menu_book_outlined : Icons.search_off, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              noData
                  ? (isBn ? 'এখনো কোনো হাদিস যোগ করা হয়নি' : 'No hadith added yet')
                  : (isBn ? 'কিছু পাওয়া যায়নি' : 'Nothing found'),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final Hadith hadith;
  final bool isBn;
  const _HadithCard({required this.hadith, required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hadith.category.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(hadith.category,
                  style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          Text(hadith.bangla,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.6)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bookmark_outline, size: 16, color: AppTheme.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(hadith.reference,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
