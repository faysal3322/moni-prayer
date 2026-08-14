import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import '../utils/quran_collections_helper.dart';
import '../utils/quran_prefs.dart';
import 'surah_detail_screen.dart';
import 'juz_detail_screen.dart';
import 'collection_detail_screen.dart';
import 'quran_settings_screen.dart';
import 'bangla_quran_screen.dart';

class QuranScreen extends StatefulWidget {
  final AppLanguage lang;
  const QuranScreen({super.key, required this.lang});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'কোরআন' : 'Quran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: isBn ? 'কোরআন সেটিংস' : 'Quran Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => QuranSettingsScreen(lang: widget.lang),
              ));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.gold,
          // ফিক্স: নতুন "বাংলা কোরআন" ট্যাব যোগ হওয়ায় এখন মোট ৪টা ট্যাব —
          // ছোট স্ক্রিনে ৪টা ট্যাব-লেবেল ঠাসাঠাসি হয়ে যেতে পারে, তাই
          // isScrollable: true দেওয়া হলো যাতে প্রতিটা ট্যাব নিজের
          // স্বাভাবিক প্রস্থ পায় এবং প্রয়োজনে পাশে স্ক্রল করা যায়।
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: isBn ? 'সূরা' : 'Sura'),
            Tab(text: isBn ? 'পারা' : 'Para'),
            Tab(text: isBn ? 'আমার কোরআন' : 'My Quran'),
            Tab(text: isBn ? 'বাংলা কোরআন' : 'Bangla Quran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SuraTab(lang: widget.lang),
          _ParaTab(lang: widget.lang),
          _MyQuranTab(lang: widget.lang),
          BanglaQuranTab(lang: widget.lang),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// সূরা ট্যাব — ১১৪টা সূরার তালিকা (আগের QuranScreen-এর মূল লজিক)
// ═══════════════════════════════════════════
class _SuraTab extends StatefulWidget {
  final AppLanguage lang;
  const _SuraTab({required this.lang});

  @override
  State<_SuraTab> createState() => _SuraTabState();
}

class _SuraTabState extends State<_SuraTab> {
  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();
  // "সর্বশেষ পঠিত অবস্থান" — সূরা নম্বর, আয়াত নম্বর, এবং সূরার নাম
  // (কার্ডে দেখানোর জন্য)। কোনো ডেটা না থাকলে null।
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _loadLastRead();
  }

  /// এই ট্যাব আবার visible/rebuild হলে (যেমন সূরা পড়ে ফিরে এলে) সর্বশেষ
  /// পঠিত অবস্থান নতুন করে লোড করা হয়, যাতে কার্ডটা আপ-টু-ডেট থাকে।
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final lastRead = await QuranPrefs.getLastRead();
    if (lastRead == null || !mounted) {
      if (mounted) setState(() => _lastRead = null);
      return;
    }
    final chapter = await QuranDatabaseHelper.getChapter(lastRead['sura']!);
    if (!mounted) return;
    setState(() {
      _lastRead = {
        'sura': lastRead['sura'],
        'aya': lastRead['aya'],
        'name': chapter?['name_transliteration'] ?? '',
        'nameArabic': chapter?['name_arabic'] ?? '',
      };
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await QuranDatabaseHelper.getChapters();
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _filtered = chapters;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filtered = _chapters;
      } else {
        final q = query.trim().toLowerCase();
        _filtered = _chapters.where((c) {
          final translit = (c['name_transliteration'] as String? ?? '').toLowerCase();
          final suraNum = (c['sura'] ?? '').toString();
          return translit.contains(q) || suraNum == q;
        }).toList();
      }
    });
  }

  String _typeLabel(String? type, bool isBn) {
    if (type == 'Meccan') return isBn ? 'মক্কী' : 'Meccan';
    if (type == 'Medinan') return isBn ? 'মাদানী' : 'Medinan';
    return type ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: isBn ? 'সূরা খুঁজুন...' : 'Search Surah...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accent),
              ),
            ),
          ),
        ),
        // "সর্বশেষ পঠিত অবস্থান" কার্ড — সার্চ চলাকালীন (যখন তালিকা
        // ফিল্টার করা থাকে) দেখানো হয় না, শুধু পুরো সূরা তালিকা দেখা
        // অবস্থায় সবার উপরে দেখানো হয়।
        if (_lastRead != null && _searchController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  settings: const RouteSettings(name: kSurahDetailRouteName),
                  builder: (_) => SurahDetailScreen(
                    lang: widget.lang,
                    sura: _lastRead!['sura'] as int,
                    jumpToAyaNumber: _lastRead!['aya'] as int,
                  ),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark, color: AppTheme.gold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'সর্বশেষ পঠিত অবস্থান' : 'Last read position',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_lastRead!['name']} (${widget.lang.toLocalNum(_lastRead!['aya'] as int)})',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _lastRead!['nameArabic'] as String? ?? '',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 20,
                        fontFamily: 'ScheherazadeNew',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
              : _error.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          isBn
                              ? 'কোরআন ডাটাবেজ লোড করা যায়নি।\n$_error'
                              : 'Could not load Quran database.\n$_error',
                          style: const TextStyle(color: AppTheme.missed, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            isBn ? 'কোনো সূরা পাওয়া যায়নি' : 'No surah found',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final c = _filtered[index];
                            final suraNum = c['sura'] as int;
                            final nameArabic = c['name_arabic'] as String? ?? '';
                            final nameTranslit = c['name_transliteration'] as String? ?? '';
                            final ayasCount = c['ayas_count'] as int? ?? 0;
                            final type = c['type'] as String?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.gold.withOpacity(0.6)),
                                  ),
                                  child: Text(
                                    widget.lang.toLocalNum(suraNum),
                                    style: const TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  nameTranslit,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_typeLabel(type, isBn)} • ${widget.lang.toLocalNum(ayasCount)} ${isBn ? "আয়াত" : "verses"}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                trailing: Text(
                                  nameArabic,
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 22,
                                    fontFamily: 'ScheherazadeNew',
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    settings: const RouteSettings(name: kSurahDetailRouteName),
                                    builder: (_) => SurahDetailScreen(lang: widget.lang, sura: suraNum),
                                  ));
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// পারা ট্যাব — ১ থেকে ৩০ পারার তালিকা
// ═══════════════════════════════════════════
class _ParaTab extends StatefulWidget {
  final AppLanguage lang;
  const _ParaTab({required this.lang});

  @override
  State<_ParaTab> createState() => _ParaTabState();
}

class _ParaTabState extends State<_ParaTab> {
  List<Map<String, dynamic>> _juzList = [];
  Map<int, String> _suraNames = {};
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final juzList = await QuranDatabaseHelper.getJuzList();
      final chapters = await QuranDatabaseHelper.getChapters();
      if (!mounted) return;
      setState(() {
        _juzList = juzList;
        _suraNames = {
          for (final c in chapters) (c['sura'] as int): (c['name_transliteration'] as String? ?? ''),
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isBn ? 'পারার তালিকা লোড করা যায়নি।\n$_error' : 'Could not load Para list.\n$_error',
            style: const TextStyle(color: AppTheme.missed, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _juzList.length,
      itemBuilder: (context, index) {
        final juz = _juzList[index];
        final juzNumber = juz['id'] as int;
        final startSura = juz['sura'] as int;
        final startAya = juz['aya'] as int;
        final suraName = _suraNames[startSura] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold.withOpacity(0.6)),
              ),
              child: Text(
                widget.lang.toLocalNum(juzNumber),
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            title: Text(
              isBn ? 'পারা $juzNumber' : 'Juz $juzNumber',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              '$suraName • ${isBn ? "আয়াত" : "Verse"} ${widget.lang.toLocalNum(startAya)} ${isBn ? "থেকে শুরু" : "onwards"}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => JuzDetailScreen(lang: widget.lang, juzNumber: juzNumber),
              ));
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// আমার কোরআন ট্যাব — ব্যবহারকারীর নিজস্ব আয়াত কালেকশন
// ═══════════════════════════════════════════
class _MyQuranTab extends StatefulWidget {
  final AppLanguage lang;
  const _MyQuranTab({required this.lang});

  @override
  State<_MyQuranTab> createState() => _MyQuranTabState();
}

class _MyQuranTabState extends State<_MyQuranTab> {
  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final collections = await QuranCollectionsHelper.getCollections();
    if (!mounted) return;
    setState(() {
      _collections = collections;
      _loading = false;
    });
  }

  Future<void> _createCollection() async {
    final isBn = widget.lang.isBn;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          isBn ? 'নতুন কালেকশন' : 'New Collection',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: isBn ? 'যেমন: ৩৩ আয়াত' : 'e.g. 33 Verses',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(isBn ? 'তৈরি করুন' : 'Create', style: const TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await QuranCollectionsHelper.createCollection(name);
      _load();
    }
  }

  Future<void> _deleteCollection(int id) async {
    final isBn = widget.lang.isBn;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(isBn ? 'কালেকশন মুছবেন?' : 'Delete collection?', style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          isBn ? 'এই কালেকশনের সব আয়াত মুছে যাবে।' : 'All verses in this collection will be removed.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isBn ? 'মুছুন' : 'Delete', style: const TextStyle(color: AppTheme.missed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await QuranCollectionsHelper.deleteCollection(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCollection,
        backgroundColor: AppTheme.gold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          isBn ? 'নতুন কালেকশন' : 'New Collection',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _collections.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isBn
                          ? 'এখনো কোনো কালেকশন নেই।\nনিচের বাটনে চেপে একটি তৈরি করুন — যেমন "৩৩ আয়াত"।'
                          : 'No collections yet.\nTap below to create one — e.g. "33 Verses".',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final col = _collections[index];
                    final id = col['id'] as int;
                    final name = col['name'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: const Icon(Icons.bookmark_border, color: AppTheme.gold),
                        title: Text(
                          name,
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary, size: 20),
                          onPressed: () => _deleteCollection(id),
                        ),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CollectionDetailScreen(
                              lang: widget.lang,
                              collectionId: id,
                              collectionName: name,
                            ),
                          ));
                          _load(); // নাম পরিবর্তিত হয়ে থাকতে পারে
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
