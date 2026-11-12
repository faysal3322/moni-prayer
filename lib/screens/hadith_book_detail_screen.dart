import 'package:flutter/material.dart';
import '../data/hadith_books_data.dart';
import '../data/hadith_chapters_data.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import 'hadith_books_screen.dart' show HexBadge;
import 'hadith_chapter_screen.dart';

/// একটি বইয়ের ভেতরের পাতা — অধ্যায়ের তালিকা + অধ্যায় সার্চ।
/// অধ্যায়ের ডেটা lib/data/hadith_chapters_data.dart-এ থাকে।
/// যে বইয়ের অধ্যায় এখনো যোগ হয়নি সেটায় "শীঘ্রই যোগ হবে" দেখাবে।
class HadithBookDetailScreen extends StatefulWidget {
  final HadithBook book;
  final AppLanguage lang;
  const HadithBookDetailScreen({super.key, required this.book, required this.lang});

  @override
  State<HadithBookDetailScreen> createState() => _HadithBookDetailScreenState();
}

class _HadithBookDetailScreenState extends State<HadithBookDetailScreen> {
  static const Color _headerGreen = Color(0xFF428C6F);
  static const Color _badgeGreen = Color(0xFF4FA383);

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HadithChapter> get _all => kHadithChapters[widget.book.id] ?? const [];

  List<HadithChapter> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _all;
    return _all.where((c) {
      // নাম অথবা অধ্যায় নম্বর (বাংলা/ইংরেজি অংক) দিয়ে খোঁজা যাবে
      return c.name.contains(q) ||
          c.number.toString() == q ||
          widget.lang.toLocalNum(c.number) == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isBn = lang.isBn;
    final book = widget.book;
    final items = _filtered;

    return Scaffold(
      backgroundColor: _headerGreen,
      appBar: AppBar(
        backgroundColor: _headerGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 76,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              '${lang.toLocalNum(book.count)}${isBn ? 'টি হাদিস' : ' Hadith'}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _all.isEmpty ? _comingSoon(isBn) : _chapterList(isBn, items),
      ),
    );
  }

  Widget _chapterList(bool isBn, List<HadithChapter> items) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: isBn ? 'অধ্যায় সার্চ করুন' : 'Search chapter',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              suffixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(isBn ? 'কিছু পাওয়া যায়নি' : 'Nothing found',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _chapterCard(items[i], isBn),
                ),
        ),
      ],
    );
  }

  Widget _chapterCard(HadithChapter ch, bool isBn) {
    final lang = widget.lang;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HadithChapterScreen(
                book: widget.book,
                chapter: ch,
                lang: lang,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                HexBadge(text: lang.toLocalNum(ch.number), color: _badgeGreen),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch.name,
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${isBn ? 'হাদিসের রেঞ্জ' : 'Hadith range'}: '
                        '${lang.toLocalNum(ch.from)} - ${lang.toLocalNum(ch.to)}',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _comingSoon(bool isBn) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HexBadge(text: widget.book.badge, color: widget.book.color, size: 84),
            const SizedBox(height: 16),
            Text(widget.book.author,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            Text(
              isBn ? 'অধ্যায় শীঘ্রই যোগ করা হবে' : 'Chapters will be added soon',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
