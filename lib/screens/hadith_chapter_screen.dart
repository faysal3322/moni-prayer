import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../data/hadith_books_data.dart';
import '../data/hadith_chapters_data.dart';
import '../data/hadith_content.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import 'hadith_books_screen.dart' show HexBadge;

/// অধ্যায়ের ভেতরের পাতা — অধ্যায়-শিরোনাম কার্ড + হাদিসের কার্ড (শুধু বাংলা অনুবাদ)।
/// হাদিসের ডেটা আসে lib/data/hadith_content.dart-এর মাধ্যমে assets/hadith/... JSON থেকে।
class HadithChapterScreen extends StatefulWidget {
  final HadithBook book;
  final HadithChapter chapter;
  final AppLanguage lang;
  const HadithChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    required this.lang,
  });

  @override
  State<HadithChapterScreen> createState() => _HadithChapterScreenState();
}

class _HadithChapterScreenState extends State<HadithChapterScreen> {
  static const Color _headerGreen = Color(0xFF428C6F);
  static const Color _green = Color(0xFF3F9E78);
  static const Color _pillGreen = Color(0xFF66B592);

  final ScrollController _scroll = ScrollController();
  late final Future<List<HadithEntry>?> _future;
  double _fontSize = 18;

  @override
  void initState() {
    super.initState();
    _future = HadithContent.load(widget.book.id, widget.chapter.number);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _isBn => widget.lang.isBn;

  // ── শেয়ার / কপির টেক্সট ──
  String _plainText(HadithEntry h) {
    final b = StringBuffer()
      ..writeln('${widget.book.name} — ${_isBn ? 'হাদিস' : 'Hadith'}: ${widget.lang.toLocalNum(h.number)}')
      ..writeln(_narratedBy(h))
      ..writeln()
      ..writeln(h.paragraphs.join('\n\n'));
    return b.toString().trim();
  }

  String _narratedBy(HadithEntry h) =>
      _isBn ? '${h.narrator} থেকে বর্ণিত:' : 'Narrated by ${h.narrator}:';

  void _openFontSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isBn ? 'লেখার আকার' : 'Text size',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Slider(
                value: _fontSize,
                min: 14,
                max: 30,
                divisions: 16,
                activeColor: _green,
                label: widget.lang.toLocalNum(_fontSize.round()),
                onChanged: (v) {
                  setSheet(() => _fontSize = v);
                  setState(() {});
                },
              ),
              Text(
                _isBn ? 'এটি একটি নমুনা লেখা — আল্লাহর রাসূল (ﷺ)' : 'Sample text (ﷺ)',
                style: _bodyStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(_isBn ? 'সাহায্য' : 'Help',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          _isBn
              ? '• ডান পাশের তীর বোতাম দিয়ে পাতার শুরু বা শেষে যাওয়া যায়।\n'
                  '• কার্ডের তিন-ডট মেনু থেকে হাদিস কপি বা শেয়ার করা যায়।\n'
                  '• উপরের সেটিংস আইকন থেকে লেখার আকার বদলানো যায়।'
              : '• Use the arrow buttons on the right to jump to the top or bottom.\n'
                  '• Use the three-dot menu on a card to copy or share a hadith.\n'
                  '• Use the settings icon above to change the text size.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isBn ? 'ঠিক আছে' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text(widget.book.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(widget.chapter.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 28),
            onPressed: _openHelp,
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 28),
            onPressed: _openFontSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: FutureBuilder<List<HadithEntry>?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: _green));
              }
              final items = snap.data;
              if (items == null) return _comingSoon();
              return Stack(
                children: [
                  ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (items[i].heading != null) _headingCard(items[i].heading!),
                        _hadithCard(items[i]),
                      ],
                    ),
                  ),
                  _scrollButtons(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── অধ্যায়-শিরোনাম কার্ড (যেমন: ১/১. অধ্যায়ঃ ...) ──
  Widget _headingCard(HadithHeading h) {
    final lang = widget.lang;
    final label =
        '${lang.toLocalNum(widget.chapter.number)}/${lang.toLocalNum(h.no)}. ${_isBn ? 'অধ্যায়ঃ' : 'Chapter:'}';
    final title = h.title.trim();
    final note = h.note?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: label, style: const TextStyle(color: _green)),
              if (title.isNotEmpty) TextSpan(text: ' $title'),
            ]),
            style: _bodyStyle().copyWith(fontWeight: FontWeight.bold, height: 1.7),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: AppTheme.divider, height: 1),
            const SizedBox(height: 14),
            Text(
              note,
              style: _bodyStyle().copyWith(
                  color: AppTheme.textSecondary, fontSize: _fontSize - 1),
            ),
          ],
        ],
      ),
    );
  }

  // ── হাদিসের কার্ড ──
  Widget _hadithCard(HadithEntry h) {
    final lang = widget.lang;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HexBadge(text: widget.book.badge, color: widget.book.color, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.book.name,
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.bold)),
                    Text(
                      '${_isBn ? 'হাদিস' : 'Hadith'}: ${lang.toLocalNum(h.number)}',
                      style: const TextStyle(
                          color: _green, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _pillGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(h.grade,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
                color: AppTheme.cardBg,
                onSelected: (v) async {
                  if (v == 'copy') {
                    await Clipboard.setData(ClipboardData(text: _plainText(h)));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isBn ? 'কপি করা হয়েছে' : 'Copied')),
                    );
                  } else if (v == 'share') {
                    await Share.share(_plainText(h));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'copy',
                      child: Text(_isBn ? 'কপি করুন' : 'Copy',
                          style: TextStyle(color: AppTheme.textPrimary))),
                  PopupMenuItem(
                      value: 'share',
                      child: Text(_isBn ? 'শেয়ার করুন' : 'Share',
                          style: TextStyle(color: AppTheme.textPrimary))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _narratedBy(h),
            style: TextStyle(color: _green, fontSize: _fontSize, height: 1.6),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < h.paragraphs.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == h.paragraphs.length - 1 ? 0 : 10),
              child: Text(h.paragraphs[i], style: _bodyStyle()),
            ),
          if (h.footnote != null) ...[
            const SizedBox(height: 18),
            Divider(color: AppTheme.divider, height: 1),
            const SizedBox(height: 12),
            Text(_isBn ? 'ফুটনোট:' : 'Footnote:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
            const SizedBox(height: 2),
            Text(h.footnote!,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 15, height: 1.6)),
          ],
        ],
      ),
    );
  }

  /// হাদিসের মূল লেখার স্টাইল। ﷺ চিহ্ন ঠিকমতো দেখাতে ScheherazadeNew ফন্ট ফলব্যাক রাখা হয়েছে।
  TextStyle _bodyStyle() => TextStyle(
        color: AppTheme.textPrimary,
        fontSize: _fontSize,
        height: 1.95,
        fontFamilyFallback: const ['ScheherazadeNew'],
      );

  // ── ডান পাশের উপর/নিচে যাওয়ার বোতাম ──
  Widget _scrollButtons() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          width: 52,
          decoration: BoxDecoration(
            color: _green.withOpacity(0.88),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28)),
                onTap: () => _scroll.animateTo(0,
                    duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 12, 0, 4),
                  child: Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 30),
                ),
              ),
              InkWell(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28)),
                onTap: () => _scroll.animateTo(_scroll.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comingSoon() {
    final lang = widget.lang;
    final ch = widget.chapter;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_isBn ? 'অধ্যায়' : 'Chapter'} ${lang.toLocalNum(ch.number)}',
              style: TextStyle(color: AppTheme.gold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(ch.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${_isBn ? 'হাদিসের রেঞ্জ' : 'Hadith range'}: '
              '${lang.toLocalNum(ch.from)} - ${lang.toLocalNum(ch.to)}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(
              _isBn ? 'হাদিস শীঘ্রই যোগ করা হবে' : 'Hadith will be added soon',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
