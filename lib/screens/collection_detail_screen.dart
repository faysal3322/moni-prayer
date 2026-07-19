import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/quran_database_helper.dart';
import '../utils/quran_collections_helper.dart';
import '../utils/quran_prefs.dart';

class CollectionDetailScreen extends StatefulWidget {
  final AppLanguage lang;
  final int collectionId;
  final String collectionName;
  const CollectionDetailScreen({
    super.key,
    required this.lang,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  List<Map<String, dynamic>> _items = []; // collection_items rows (id, sura, aya, sort_order)
  Map<int, Map<String, dynamic>> _ayaCache = {}; // item id -> {arabic, bangla, translit, suraName}
  List<Map<String, dynamic>> _chapters = [];
  bool _loading = true;
  late String _title;

  bool _showArabic = true;
  bool _showBangla = false;
  bool _showTransliteration = true;
  double _fontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _title = widget.collectionName;
    _load();
  }

  Future<void> _load() async {
    final items = await QuranCollectionsHelper.getCollectionItems(widget.collectionId);
    final chapters = await QuranDatabaseHelper.getChapters();
    final showArabic = await QuranPrefs.getShowArabic();
    final showBangla = await QuranPrefs.getShowBangla();
    final showTranslit = await QuranPrefs.getShowTransliteration();
    final fontSize = await QuranPrefs.getFontSize();

    final cache = <int, Map<String, dynamic>>{};
    final suraNameMap = {
      for (final c in chapters) (c['sura'] as int): (c['name_transliteration'] as String? ?? ''),
    };

    for (final item in items) {
      final itemId = item['id'] as int;
      final sura = item['sura'] as int;
      final aya = item['aya'] as int;
      final arabicRow = await QuranDatabaseHelper.getSingleAya(sura, aya);
      final banglaRow = await QuranDatabaseHelper.getSingleAyaBangla(sura, aya);
      final translitRow = await QuranDatabaseHelper.getSingleAyaTransliteration(sura, aya);
      cache[itemId] = {
        'arabic': arabicRow?['text'] as String? ?? '',
        'bangla': banglaRow?['text'] as String? ?? '',
        'translit': translitRow?['text'] as String? ?? '',
        'suraName': suraNameMap[sura] ?? '',
      };
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _chapters = chapters;
      _ayaCache = cache;
      _showArabic = showArabic;
      _showBangla = showBangla;
      _showTransliteration = showTranslit;
      _fontSize = fontSize;
      _loading = false;
    });
  }

  Future<void> _renameCollection() async {
    final isBn = widget.lang.isBn;
    final controller = TextEditingController(text: _title);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(isBn ? 'নাম পরিবর্তন' : 'Rename', style: const TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
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
            child: Text(isBn ? 'সেভ' : 'Save', style: const TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await QuranCollectionsHelper.renameCollection(widget.collectionId, newName);
      setState(() => _title = newName);
    }
  }

  void _showAddVerseSheet() {
    final isBn = widget.lang.isBn;
    int? selectedSura;
    final ayaController = TextEditingController();
    String? errorText;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'আয়াত যোগ করুন' : 'Add a Verse',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  // সূরা নির্বাচন
                  DropdownButtonFormField<int>(
                    value: selectedSura,
                    dropdownColor: AppTheme.cardBg,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isBn ? 'সূরা নির্বাচন করুন' : 'Select Surah',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.accent),
                      ),
                    ),
                    items: _chapters.map((c) {
                      final sura = c['sura'] as int;
                      final name = c['name_transliteration'] as String? ?? '';
                      return DropdownMenuItem(value: sura, child: Text('${widget.lang.toLocalNum(sura)}. $name'));
                    }).toList(),
                    onChanged: (value) => setSheetState(() => selectedSura = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ayaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: isBn ? 'আয়াত নম্বর' : 'Verse Number',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      errorText: errorText,
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final ayaNum = int.tryParse(ayaController.text.trim());
                        if (selectedSura == null) {
                          setSheetState(() => errorText = isBn ? 'সূরা নির্বাচন করুন' : 'Select a surah');
                          return;
                        }
                        if (ayaNum == null || ayaNum < 1) {
                          setSheetState(() => errorText = isBn ? 'সঠিক আয়াত নম্বর দিন' : 'Enter a valid verse number');
                          return;
                        }
                        final chapter = _chapters.firstWhere((c) => c['sura'] == selectedSura);
                        final maxAya = chapter['ayas_count'] as int? ?? 0;
                        if (ayaNum > maxAya) {
                          setSheetState(() => errorText = isBn
                              ? 'এই সূরায় সর্বোচ্চ ${widget.lang.toLocalNum(maxAya)} আয়াত আছে'
                              : 'This surah has only $maxAya verses');
                          return;
                        }
                        await QuranCollectionsHelper.addItem(widget.collectionId, selectedSura!, ayaNum);
                        if (context.mounted) Navigator.pop(sheetContext);
                        _load();
                      },
                      child: Text(
                        isBn ? 'যোগ করুন' : 'Add',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeItem(int itemId) async {
    await QuranCollectionsHelper.removeItem(itemId);
    _load();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    final orderedIds = _items.map((e) => e['id'] as int).toList();
    await QuranCollectionsHelper.reorderItems(orderedIds);
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isBn ? 'নাম পরিবর্তন' : 'Rename',
            onPressed: _renameCollection,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVerseSheet,
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isBn
                          ? 'এখনো কোনো আয়াত যোগ করা হয়নি।\n+ বাটনে চেপে আয়াত যোগ করুন।'
                          : 'No verses added yet.\nTap + to add a verse.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  itemCount: _items.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final itemId = item['id'] as int;
                    final sura = item['sura'] as int;
                    final aya = item['aya'] as int;
                    final cached = _ayaCache[itemId] ?? {};

                    return Container(
                      key: ValueKey(itemId),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${cached['suraName'] ?? ''} • ${isBn ? "আয়াত" : "Verse"} ${widget.lang.toLocalNum(aya)}',
                                  style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                                onPressed: () => _removeItem(itemId),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.drag_handle, color: AppTheme.textSecondary, size: 20),
                            ],
                          ),
                          if (_showArabic) ...[
                            const SizedBox(height: 10),
                            Text(
                              cached['arabic'] as String? ?? '',
                              style: TextStyle(
                                fontSize: _fontSize,
                                color: AppTheme.textPrimary,
                                fontFamily: 'ScheherazadeNew',
                                height: 2.0,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                          if (_showBangla && (cached['bangla'] as String? ?? '').isNotEmpty) ...[
                            const Divider(color: Colors.white12, height: 20),
                            Text(
                              cached['bangla'] as String,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.6),
                            ),
                          ],
                          if (_showTransliteration && (cached['translit'] as String? ?? '').isNotEmpty) ...[
                            const Divider(color: Colors.white12, height: 20),
                            Text(
                              cached['translit'] as String,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
