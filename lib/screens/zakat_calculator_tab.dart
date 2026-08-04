import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/zakat_helper.dart';

/// যাকাত ক্যালকুলেটর — নগদ টাকা, সোনা (গ্রাম + প্রতি গ্রাম দর), রূপা
/// (গ্রাম + প্রতি গ্রাম দর) ও দায়/ঋণ ইনপুট নিয়ে মোট সম্পদ বের করে, তারপর
/// নিসাব (সোনা ৮৫ গ্রাম বা রূপা ৫৯৫ গ্রাম-ভিত্তিক বাজারমূল্য) এর সাথে
/// তুলনা করে ২.৫% যাকাত হিসাব করে।
///
/// রেফারেন্স: উলামাদের অভিমত অনুযায়ী (ইবনু বায, আল-লাজনাহ আদ-দাইমাহ)
/// নগদ টাকার নিসাব সোনা ও রূপার নিসাবের মধ্যে যেটির মূল্য কম, সেটি
/// ধরাই গরীবদের জন্য বেশি উপকারী — তাই ডিফল্ট নিসাব-ভিত্তি রূপা
/// (সাধারণত রূপার নিসাব-মূল্য সোনার চেয়ে কম হয়)।
class ZakatCalculatorTab extends StatefulWidget {
  final AppLanguage lang;
  const ZakatCalculatorTab({super.key, required this.lang});

  @override
  State<ZakatCalculatorTab> createState() => _ZakatCalculatorTabState();
}

class _ZakatCalculatorTabState extends State<ZakatCalculatorTab> {
  final _cashController = TextEditingController();
  final _goldGramsController = TextEditingController();
  final _goldPriceController = TextEditingController();
  final _silverGramsController = TextEditingController();
  final _silverPriceController = TextEditingController();
  final _liabilitiesController = TextEditingController();
  final _goldNisabPriceController = TextEditingController();
  final _silverNisabPriceController = TextEditingController();

  String _nisabBasis = 'silver'; // 'gold' | 'silver'
  bool _loading = true;

  static const double goldNisabGrams = 85.0;
  static const double silverNisabGrams = 595.0;
  static const double zakatRate = 0.025;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _goldGramsController.dispose();
    _goldPriceController.dispose();
    _silverGramsController.dispose();
    _silverPriceController.dispose();
    _liabilitiesController.dispose();
    _goldNisabPriceController.dispose();
    _silverNisabPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final saved = await ZakatHelper.getLastCalculatorInputs();
    _cashController.text = _fmtInput(saved['cash']);
    _goldGramsController.text = _fmtInput(saved['goldGrams']);
    _goldPriceController.text = _fmtInput(saved['goldPricePerGram']);
    _silverGramsController.text = _fmtInput(saved['silverGrams']);
    _silverPriceController.text = _fmtInput(saved['silverPricePerGram']);
    _liabilitiesController.text = _fmtInput(saved['liabilities']);
    _goldNisabPriceController.text = _fmtInput(saved['goldNisabPrice']);
    _silverNisabPriceController.text = _fmtInput(saved['silverNisabPrice']);
    _nisabBasis = saved['nisabBasis'] as String? ?? 'silver';
    if (mounted) setState(() => _loading = false);
  }

  String _fmtInput(dynamic v) {
    final d = (v as num?)?.toDouble() ?? 0.0;
    if (d == 0.0) return '';
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  Future<void> _saveInputs() async {
    await ZakatHelper.saveCalculatorInputs(
      cash: _parse(_cashController),
      goldGrams: _parse(_goldGramsController),
      goldPricePerGram: _parse(_goldPriceController),
      silverGrams: _parse(_silverGramsController),
      silverPricePerGram: _parse(_silverPriceController),
      liabilities: _parse(_liabilitiesController),
      nisabBasis: _nisabBasis,
      silverNisabPrice: _parse(_silverNisabPriceController),
      goldNisabPrice: _parse(_goldNisabPriceController),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    final cash = _parse(_cashController);
    final goldValue = _parse(_goldGramsController) * _parse(_goldPriceController);
    final silverValue = _parse(_silverGramsController) * _parse(_silverPriceController);
    final liabilities = _parse(_liabilitiesController);
    final totalAssets = cash + goldValue + silverValue;
    final netAssets = (totalAssets - liabilities).clamp(0.0, double.infinity);

    final goldNisabPrice = _parse(_goldNisabPriceController);
    final silverNisabPrice = _parse(_silverNisabPriceController);
    final goldNisabValue = goldNisabPrice * goldNisabGrams;
    final silverNisabValue = silverNisabPrice * silverNisabGrams;

    double nisabValue;
    String nisabLabel;
    if (_nisabBasis == 'gold') {
      nisabValue = goldNisabValue;
      nisabLabel = isBn ? 'সোনার নিসাব (৮৫ গ্রাম)' : 'Gold Nisab (85g)';
    } else {
      nisabValue = silverNisabValue;
      nisabLabel = isBn ? 'রূপার নিসাব (৫৯৫ গ্রাম)' : 'Silver Nisab (595g)';
    }

    final isEligible = nisabValue > 0 && netAssets >= nisabValue;
    final zakatDue = isEligible ? netAssets * zakatRate : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(isBn ? 'নগদ অর্থ ও সঞ্চয়' : 'Cash & Savings'),
          _amountField(_cashController, isBn ? 'নগদ + ব্যাংক সঞ্চয়' : 'Cash + Bank Savings'),
          const SizedBox(height: 18),
          _sectionTitle(isBn ? 'সোনা' : 'Gold'),
          Row(
            children: [
              Expanded(child: _amountField(_goldGramsController, isBn ? 'পরিমাণ (গ্রাম)' : 'Weight (grams)')),
              const SizedBox(width: 10),
              Expanded(child: _amountField(_goldPriceController, isBn ? 'প্রতি গ্রাম দর' : 'Price/gram')),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle(isBn ? 'রূপা' : 'Silver'),
          Row(
            children: [
              Expanded(child: _amountField(_silverGramsController, isBn ? 'পরিমাণ (গ্রাম)' : 'Weight (grams)')),
              const SizedBox(width: 10),
              Expanded(child: _amountField(_silverPriceController, isBn ? 'প্রতি গ্রাম দর' : 'Price/gram')),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle(isBn ? 'দায়/ঋণ (বাদ যাবে)' : 'Liabilities/Debt (deducted)'),
          _amountField(_liabilitiesController, isBn ? 'তাৎক্ষণিক পরিশোধযোগ্য ঋণ' : 'Immediate payable debt'),
          const SizedBox(height: 18),
          _sectionTitle(isBn ? 'নিসাব হিসাবের ভিত্তি' : 'Nisab Basis'),
          Text(
            isBn
                ? 'উলামাদের মতে, নগদ টাকার ক্ষেত্রে সোনা ও রূপার নিসাবের মধ্যে যেটির মূল্য কম, সেটি ধরাই গরীবদের জন্য বেশি উপকারী। তাই সাধারণত রূপা-ভিত্তিক নিসাব ব্যবহার করা হয়।'
                : 'Scholars recommend using whichever nisab (gold or silver) has the lower value, as it benefits the poor more. Silver-based nisab is commonly used.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppTheme.gold,
                  title: Text(isBn ? 'রূপা' : 'Silver', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  value: 'silver',
                  groupValue: _nisabBasis,
                  onChanged: (v) => setState(() => _nisabBasis = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppTheme.gold,
                  title: Text(isBn ? 'সোনা' : 'Gold', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  value: 'gold',
                  groupValue: _nisabBasis,
                  onChanged: (v) => setState(() => _nisabBasis = v!),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _amountField(
                  _silverNisabPriceController,
                  isBn ? 'রূপার বাজারদর (প্রতি গ্রাম)' : 'Silver market price/gram',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _amountField(
                  _goldNisabPriceController,
                  isBn ? 'সোনার বাজারদর (প্রতি গ্রাম)' : 'Gold market price/gram',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () async {
              setState(() {});
              await _saveInputs();
            },
            icon: const Icon(Icons.calculate_outlined),
            label: Text(isBn ? 'হিসাব করুন' : 'Calculate'),
          ),
          const SizedBox(height: 20),
          _resultCard(
            isBn: isBn,
            totalAssets: totalAssets,
            liabilities: liabilities,
            netAssets: netAssets,
            nisabLabel: nisabLabel,
            nisabValue: nisabValue,
            isEligible: isEligible,
            zakatDue: zakatDue,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );

  Widget _amountField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppTheme.textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          filled: true,
          fillColor: AppTheme.cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
          ),
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
    );
  }

  Widget _resultCard({
    required bool isBn,
    required double totalAssets,
    required double liabilities,
    required double netAssets,
    required String nisabLabel,
    required double nisabValue,
    required bool isEligible,
    required double zakatDue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEligible ? AppTheme.gold.withOpacity(0.1) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isEligible ? AppTheme.gold.withOpacity(0.6) : AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultRow(isBn ? 'মোট সম্পদ' : 'Total Assets', totalAssets),
          _resultRow(isBn ? 'দায়/ঋণ (বাদ)' : 'Liabilities (deducted)', -liabilities),
          const Divider(color: Colors.white24),
          _resultRow(isBn ? 'নিট সম্পদ' : 'Net Assets', netAssets, bold: true),
          const SizedBox(height: 6),
          _resultRow(nisabLabel, nisabValue),
          const SizedBox(height: 12),
          if (nisabValue <= 0)
            Text(
              isBn
                  ? 'নিসাব হিসাবের জন্য উপরে বাজারদর দিন।'
                  : 'Please enter the market price above to calculate nisab.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            )
          else if (!isEligible)
            Text(
              isBn
                  ? 'আপনার নিট সম্পদ নিসাব পরিমাণের কম — যাকাত ফরজ নয়।'
                  : 'Your net assets are below the nisab — Zakat is not obligatory.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
            )
          else ...[
            Text(
              isBn ? 'প্রদেয় যাকাত (২.৫%)' : 'Zakat Due (2.5%)',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _fmtAmount(zakatDue),
              style: const TextStyle(color: AppTheme.gold, fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _fmtAmount(value),
            style: TextStyle(
              color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double v) {
    final rounded = (v * 100).round() / 100;
    final s = rounded == rounded.roundToDouble() ? rounded.toInt().toString() : rounded.toStringAsFixed(2);
    // হাজার বিভাজক (,) যোগ করা — বাংলা/ইংরেজি উভয় ভাষাতেই সংখ্যার
    // পঠনযোগ্যতা বাড়ানোর জন্য একই পশ্চিমা কমা-বিভাজন ব্যবহার করা হচ্ছে,
    // যেহেতু ব্যবহারকারীর মুদ্রা/লোকেল সুনির্দিষ্ট নয়।
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
}
