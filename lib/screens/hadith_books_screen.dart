import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/hadith_books_data.dart';
import '../data/hadith_chapters_data.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/hadith_prefs.dart';
import '../widgets/hadith_last_read_card.dart';
import 'hadith_book_detail_screen.dart';
import 'hadith_chapter_screen.dart';

/// হাদিসের বইয়ের তালিকা — ডেটা আসে lib/data/hadith_books_data.dart থেকে।
/// সবার উপরে "সর্বশেষ পঠিত অবস্থান" কার্ড — ট্যাপ করলে সরাসরি ঐ বই-অধ্যায়ের
/// ঐ হাদিসে চলে যায় (কোরআনের মতো)।
class HadithBooksScreen extends StatefulWidget {
  final AppLanguage lang;
  const HadithBooksScreen({super.key, required this.lang});

  @override
  State<HadithBooksScreen> createState() => _HadithBooksScreenState();
}

class _HadithBooksScreenState extends State<HadithBooksScreen> {
  HadithBook? _lastBook;
  HadithChapter? _lastChapter;
  int? _lastNumber;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final lr = await HadithPrefs.getBooksLastRead();
    if (!mounted) return;
    if (lr == null) {
      setState(() => _lastBook = null);
      return;
    }
    final bookIdx = kHadithBooks.indexWhere((b) => b.id == lr['book']);
    if (bookIdx < 0) {
      setState(() => _lastBook = null);
      return;
    }
    final book = kHadithBooks[bookIdx];
    final chapters = kHadithChapters[book.id] ?? const <HadithChapter>[];
    final chIdx = chapters.indexWhere((c) => c.number == lr['chapter']);
    setState(() {
      _lastBook = book;
      _lastChapter = chIdx >= 0 ? chapters[chIdx] : null;
      _lastNumber = lr['number'] as int;
    });
  }

  // ফেরার পর কার্ড আপডেট — push await করে তারপর রিলোড
  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadLastRead();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isBn = lang.isBn;
    final hasLast = _lastBook != null && _lastChapter != null && _lastNumber != null;
    final extra = hasLast ? 1 : 0;

    return Scaffold(
      appBar: AppBar(title: Text(isBn ? 'হাদিসের বই' : 'Hadith Books')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        itemCount: kHadithBooks.length + extra,
        itemBuilder: (_, i) {
          if (hasLast && i == 0) {
            final book = _lastBook!;
            final ch = _lastChapter!;
            return HadithLastReadCard(
              isBn: isBn,
              title: '${book.name} (${lang.toLocalNum(_lastNumber!)})',
              subtitle: ch.name,
              trailing: HexBadge(text: book.badge, color: book.color, size: 42),
              onTap: () => _push(HadithChapterScreen(
                book: book,
                chapter: ch,
                lang: lang,
                jumpToNumber: _lastNumber,
              )),
            );
          }
          final book = kHadithBooks[i - extra];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BookCard(
              book: book,
              lang: lang,
              onTap: () => _push(HadithBookDetailScreen(book: book, lang: lang)),
            ),
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final HadithBook book;
  final AppLanguage lang;
  final VoidCallback onTap;
  const _BookCard({required this.book, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider10),
            ),
            child: Row(
              children: [
                HexBadge(text: book.badge, color: book.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.toLocalNum(book.count),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang.isBn ? 'হাদিস' : 'Hadith',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// গোলাকার কোণওয়ালা রঙিন হেক্সাগন ব্যাজ (ভেতরে বইয়ের সংক্ষিপ্ত নাম)
class HexBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  const HexBadge({super.key, required this.text, required this.color, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexPainter(color),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: text.length >= 3 ? size * 0.30 : size * 0.38,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color color;
  _HexPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 3; // কোণ গোল করার স্ট্রোকের জায়গা রাখা
    final c = Offset(size.width / 2, size.height / 2);
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (60 * i - 90) * math.pi / 180; // পয়েন্টি-টপ হেক্সাগন
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) => old.color != color;
}
