import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/zakat_helper.dart';

/// বছরভিত্তিক যাকাত রেকর্ড — প্রতিটা বছরে কত যাকাত প্রদেয় হয়েছিল এবং
/// এখন পর্যন্ত কত প্রদান করা হয়েছে তা ট্র্যাক করা যায়। সম্পূর্ণ প্রদান
/// হয়ে গেলে সবুজ, বাকি থাকলে হলুদ/লাল ব্যাজ দেখায়।
class ZakatYearlyRecordTab extends StatefulWidget {
  final AppLanguage lang;
  const ZakatYearlyRecordTab({super.key, required this.lang});

  @override
  State<ZakatYearlyRecordTab> createState() => _ZakatYearlyRecordTabState();
}

class _ZakatYearlyRecordTabState extends State<ZakatYearlyRecordTab> {
  List<ZakatRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await ZakatHelper.getAllRecords();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  String _fmtAmount(double v) {
    final rounded = (v * 100).round() / 100;
    final s = rounded == rounded.roundToDouble() ? rounded.toInt().toString() : rounded.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    final negative = intPart.startsWith('-');
    final digits = negative ? intPart.substring(1) : intPart;
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final formattedInt = (negative ? '-' : '') + buffer.toString();
    return parts.length > 1 ? '$formattedInt.${parts[1]}' : formattedInt;
  }

  void _showEntrySheet({ZakatRecord? existing}) {
    final isBn = widget.lang.isBn;
    final yearController = TextEditingController(text: existing?.year ?? '');
    final payableController = TextEditingController(
      text: existing != null && existing.payable != 0 ? _plainNum(existing.payable) : '',
    );
    final paidController = TextEditingController(
      text: existing != null && existing.paid != 0 ? _plainNum(existing.paid) : '',
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    String? errorText;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? (isBn ? 'নতুন বছরের হিসাব যোগ করুন' : 'Add Yearly Record')
                          : (isBn ? 'হিসাব সম্পাদনা করুন' : 'Edit Record'),
                      style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: yearController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: isBn ? 'বছর (হিজরি বা ইংরেজি)' : 'Year (Hijri or English)',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: payableController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: isBn ? 'মোট প্রদেয় যাকাত' : 'Total Payable Zakat',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: paidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: isBn ? 'এ পর্যন্ত প্রদান করা হয়েছে' : 'Paid So Far',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: isBn ? 'নোট (ঐচ্ছিক)' : 'Note (optional)',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!, style: const TextStyle(color: AppTheme.missed, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final year = yearController.text.trim();
                          if (year.isEmpty) {
                            setSheetState(() => errorText = isBn ? 'বছর লিখুন' : 'Enter a year');
                            return;
                          }
                          final payable = double.tryParse(payableController.text.trim()) ?? 0.0;
                          final paid = double.tryParse(paidController.text.trim()) ?? 0.0;
                          await ZakatHelper.upsertRecord(ZakatRecord(
                            year: year,
                            payable: payable,
                            paid: paid,
                            note: noteController.text.trim(),
                            dateAdded: existing?.dateAdded ?? DateTime.now().toIso8601String(),
                          ));
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          _load();
                        },
                        child: Text(isBn ? 'সংরক্ষণ করুন' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _plainNum(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  Future<void> _confirmDelete(ZakatRecord record) async {
    final isBn = widget.lang.isBn;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(isBn ? 'মুছে ফেলবেন?' : 'Delete this record?', style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          isBn ? '${record.year} সালের হিসাব মুছে যাবে।' : 'The record for ${record.year} will be deleted.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(isBn ? 'মুছুন' : 'Delete', style: const TextStyle(color: AppTheme.missed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ZakatHelper.deleteRecord(record.year);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isBn
                      ? 'এখনো কোনো বছরের হিসাব যোগ করা হয়নি। নিচের + বাটনে চেপে যোগ করুন।'
                      : 'No yearly records yet. Tap + below to add one.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final r = _records[index];
                final due = (r.payable - r.paid).clamp(0.0, double.infinity);
                final isComplete = due <= 0 && r.payable > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isComplete ? AppTheme.completed.withOpacity(0.5) : AppTheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBn ? '${r.year} সাল' : 'Year ${r.year}',
                            style: const TextStyle(color: AppTheme.gold, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                                onPressed: () => _showEntrySheet(existing: r),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.missed),
                                onPressed: () => _confirmDelete(r),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _statColumn(isBn ? 'প্রদেয়' : 'Payable', _fmtAmount(r.payable), AppTheme.textPrimary),
                          ),
                          Expanded(
                            child: _statColumn(isBn ? 'প্রদান করা হয়েছে' : 'Paid', _fmtAmount(r.paid), AppTheme.completed),
                          ),
                          Expanded(
                            child: _statColumn(
                              isBn ? 'বাকি' : 'Remaining',
                              _fmtAmount(due),
                              due > 0 ? AppTheme.missed : AppTheme.completed,
                            ),
                          ),
                        ],
                      ),
                      if (r.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(r.note, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                      ],
                      if (isComplete) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppTheme.completed),
                            const SizedBox(width: 4),
                            Text(
                              isBn ? 'সম্পূর্ণ পরিশোধিত' : 'Fully Paid',
                              style: const TextStyle(color: AppTheme.completed, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntrySheet(),
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
