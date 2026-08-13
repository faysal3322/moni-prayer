import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/zakat_helper.dart';

/// যাকাত ক্যালকুলেটর — ব্যবহারকারীর দেওয়া রেফারেন্স "যাকাত হিসাব" অ্যাপের
/// ডিজাইন অনুসরণ করে সাজানো: প্রতিটা সম্পদ/দায়ের ঘর একটা আলাদা কার্ডে
/// (বামে লেবেল, ডানে টাকার ইনপুট), "ব্যক্তিগত সম্পদ"/"ব্যক্তিগত দায়"
/// সেকশন হেডার, মাঝে-মাঝে হলুদ ব্যান্ডে উপ-যোগফল, এবং শেষে সবুজ কার্ডে
/// চূড়ান্ত যাকাতের পরিমাণ।
///
/// নিসাব-নির্ভুল হিসাবের জন্য সোনা ও রূপা এখানে গ্রাম + প্রতি-গ্রাম-দর
/// হিসেবে আলাদা রাখা হয়েছে (রেফারেন্স অ্যাপে এটা একটাই "মূল্যমান
/// অলংকার" ঘর ছিল, কিন্তু নিসাবের সাথে তুলনা করতে গ্রাম-পরিমাণ আলাদাভাবে
/// জানা আবশ্যক)।
///
/// রেফারেন্স: উলামাদের অভিমত অনুযায়ী (ইবনু বায, আল-লাজনাহ আদ-দাইমাহ)
/// নগদ টাকার নিসাব সোনা ও রূপার নিসাবের মধ্যে যেটির মূল্য কম, সেটি
/// ধরাই গরীবদের জন্য বেশি উপকারী — তাই ডিফল্ট নিসাব-ভিত্তি রূপা।
class ZakatCalculatorTab extends StatefulWidget {
  final AppLanguage lang;
  const ZakatCalculatorTab({super.key, required this.lang});

  @override
  State<ZakatCalculatorTab> createState() => _ZakatCalculatorTabState();
}

class _ZakatCalculatorTabState extends State<ZakatCalculatorTab> {
  final _goldGramsController = TextEditingController();
  final _goldPriceController = TextEditingController();
  final _silverGramsController = TextEditingController();
  final _silverPriceController = TextEditingController();
  final _cashController = TextEditingController();
  final _providentFundController = TextEditingController();
  final _goodsStockController = TextEditingController();
  final _receivablesController = TextEditingController();
  final _otherAssetsController = TextEditingController();
  final _bankLoanController = TextEditingController();
  final _otherLiabilitiesController = TextEditingController();
  final _goldNisabPriceController = TextEditingController();
  final _silverNisabPriceController = TextEditingController();

  String _nisabBasis = 'silver'; // 'gold' | 'silver'
  bool _loading = true;

  static const double goldNisabGrams = 85.0;
  static const double silverNisabGrams = 595.0;
  static const double zakatRate = 0.025;
  static const double _defaultSilverPricePerGram = 150.0;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _goldGramsController.dispose();
    _goldPriceController.dispose();
    _silverGramsController.dispose();
    _silverPriceController.dispose();
    _cashController.dispose();
    _providentFundController.dispose();
    _goodsStockController.dispose();
    _receivablesController.dispose();
    _otherAssetsController.dispose();
    _bankLoanController.dispose();
    _otherLiabilitiesController.dispose();
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
    _providentFundController.text = _fmtInput(saved['providentFund']);
    _goodsStockController.text = _fmtInput(saved['goodsStock']);
    _receivablesController.text = _fmtInput(saved['receivables']);
    _otherAssetsController.text = _fmtInput(saved['otherAssets']);
    _bankLoanController.text = _fmtInput(saved['bankLoan']);
    _otherLiabilitiesController.text = _fmtInput(saved['otherLiabilities']);
    _goldNisabPriceController.text = _fmtInput(saved['goldNisabPrice']);
    _silverNisabPriceController.text = _fmtInput(saved['silverNisabPrice']);
    _nisabBasis = saved['nisabBasis'] as String? ?? 'silver';
    if (_silverNisabPriceController.text.isEmpty) {
      _silverNisabPriceController.text = _defaultSilverPricePerGram.toString();
    }
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
      liabilities: _parse(_bankLoanController) + _parse(_otherLiabilitiesController),
      nisabBasis: _nisabBasis,
      silverNisabPrice: _parse(_silverNisabPriceController),
      goldNisabPrice: _parse(_goldNisabPriceController),
      providentFund: _parse(_providentFundController),
      goodsStock: _parse(_goodsStockController),
      receivables: _parse(_receivablesController),
      otherAssets: _parse(_otherAssetsController),
      bankLoan: _parse(_bankLoanController),
      otherLiabilities: _parse(_otherLiabilitiesController),
    );
  }

  void _resetAll() {
    setState(() {
      for (final c in [
        _cashController,
        _goldGramsController,
        _goldPriceController,
        _silverGramsController,
        _silverPriceController,
        _providentFundController,
        _goodsStockController,
        _receivablesController,
        _otherAssetsController,
        _bankLoanController,
        _otherLiabilitiesController,
      ]) {
        c.clear();
      }
    });
    _saveInputs();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.lang.isBn;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    final goldValue = _parse(_goldGramsController) * _parse(_goldPriceController);
    final silverValue = _parse(_silverGramsController) * _parse(_silverPriceController);
    final cash = _parse(_cashController);
    final providentFund = _parse(_providentFundController);
    final goodsStock = _parse(_goodsStockController);
    final receivables = _parse(_receivablesController);
    final otherAssets = _parse(_otherAssetsController);

    final totalAssets = goldValue + silverValue + cash + providentFund + goodsStock + receivables + otherAssets;

    final bankLoan = _parse(_bankLoanController);
    final otherLiabilities = _parse(_otherLiabilitiesController);
    final totalLiabilities = bankLoan + otherLiabilities;

    final netAssets = (totalAssets - totalLiabilities).clamp(0.0, double.infinity);

    final goldNisabPrice = _parse(_goldNisabPriceController);
    final silverNisabPrice = _parse(_silverNisabPriceController);
    final effectiveGoldNisabPrice = goldNisabPrice > 0 ? goldNisabPrice : _parse(_goldPriceController);
    final effectiveSilverNisabPrice = silverNisabPrice > 0 ? silverNisabPrice : _parse(_silverPriceController);
    final goldNisabValue = effectiveGoldNisabPrice * goldNisabGrams;
    final silverNisabValue = effectiveSilverNisabPrice * silverNisabGrams;

    final nisabValue = _nisabBasis == 'gold' ? goldNisabValue : silverNisabValue;
    final isEligible = nisabValue > 0 && netAssets >= nisabValue;
    final zakatDue = isEligible ? netAssets * zakatRate : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(isBn ? 'ব্যক্তিগত সম্পদ' : 'Personal Assets'),
          _assetField(_cashController, isBn ? 'নগদ ও ব্যাংকে জমা (মূল্য-টাকা)' : 'Cash & Bank Deposit'),
          _assetField(_goldGramsController, isBn ? 'সোনা — পরিমাণ (গ্রাম)' : 'Gold — Weight (grams)', isMoney: false),
          _assetField(_goldPriceController, isBn ? 'সোনা — প্রতি গ্রাম দর' : 'Gold — Price/gram'),
          _assetField(_silverGramsController, isBn ? 'রূপা — পরিমাণ (গ্রাম)' : 'Silver — Weight (grams)', isMoney: false),
          _assetField(_silverPriceController, isBn ? 'রূপা — প্রতি গ্রাম দর' : 'Silver — Price/gram'),
          _assetField(
            _providentFundController,
            isBn
                ? 'প্রভিডেন্ট ফান্ড, শেয়ার, বন্ড, বীমা, সঞ্চয়পত্র ইত্যাদি (মূল্য-টাকা)'
                : 'Provident Fund, Shares, Bonds, Insurance, Savings Certificates',
          ),
          _assetField(
            _goodsStockController,
            isBn ? 'জমাকৃত পণ্য বা মালামাল ইত্যাদি (মূল্য-টাকা)' : 'Stored Goods / Merchandise',
          ),
          _assetField(
            _receivablesController,
            isBn ? 'পাওনা, ধার প্রদান, অগ্রিম ইত্যাদি' : 'Receivables, Loans Given, Advances',
          ),
          _assetField(_otherAssetsController, isBn ? 'অন্যান্য' : 'Other'),
          _totalBand(isBn ? 'মোট সম্পদ' : 'Total Assets', totalAssets, isBn),
          const SizedBox(height: 16),
          _sectionHeader(isBn ? 'ব্যক্তিগত দায়' : 'Personal Liabilities'),
          _assetField(_bankLoanController, isBn ? 'ব্যাংক/এনজিও ঋণ (টাকা)' : 'Bank/NGO Loan'),
          _assetField(_otherLiabilitiesController, isBn ? 'অন্যান্য দায় সমূহ (টাকা)' : 'Other Liabilities'),
          _totalBand(isBn ? 'মোট দায়' : 'Total Liabilities', totalLiabilities, isBn),
          const SizedBox(height: 16),
          _netAssetsCard(isBn, netAssets),
          const SizedBox(height: 16),
          _nisabBasisCard(isBn),
          const SizedBox(height: 16),
          _finalZakatCard(isBn, nisabValue, isEligible, zakatDue),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _resetAll,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(isBn ? 'রিসেট' : 'Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _nisabReferenceCard(isBn),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0662B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _assetField(TextEditingController controller, String label, {bool isMoney = true}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  label,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.3),
                ),
              ),
            ),
            Container(width: 1, height: 40, color: AppTheme.primary.withOpacity(0.3)),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.background,
                    hintText: isMoney ? (widget.lang.isBn ? 'টাকা' : 'Taka') : (widget.lang.isBn ? 'গ্রাম' : 'grams'),
                    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.normal, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalBand(String label, double value, bool isBn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              '${_fmtAmount(value)} ${isBn ? 'টাকা' : 'Taka'}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _netAssetsCard(bool isBn, double netAssets) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBn ? 'নিট সম্পদের পরিমাণ = (মোট সম্পদ - মোট দায়)' : 'Net Assets = (Total Assets - Total Liabilities)',
              style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${_fmtAmount(netAssets)} ${isBn ? 'টাকা' : 'Taka'}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nisabBasisCard(bool isBn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBn ? 'নিসাব হিসাবের ভিত্তি' : 'Nisab Basis',
              style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              isBn
                  ? 'উলামাদের মতে, নগদ টাকার ক্ষেত্রে সোনা ও রূপার নিসাবের মধ্যে যেটির মূল্য কম, সেটি ধরাই গরীবদের জন্য বেশি উপকারী। তাই সাধারণত রূপা-ভিত্তিক নিসাব ব্যবহার করা হয়। ⚠️ নিচের বাজারদর একটা আনুমানিক মান — যাকাত হিসাবের আগে বর্তমান বাজারদর দিয়ে যাচাই করে নিন।'
                  : 'Scholars recommend using whichever nisab (gold or silver) has the lower value, as it benefits the poor more. Silver-based nisab is commonly used. ⚠️ The price below is an estimate — please verify with current market rates before finalizing your zakat.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
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
                  child: _smallAmountField(
                    _silverNisabPriceController,
                    isBn ? 'রূপার বাজারদর (প্রতি গ্রাম)' : 'Silver market price/gram',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallAmountField(
                    _goldNisabPriceController,
                    isBn ? 'সোনার বাজারদর (প্রতি গ্রাম)' : 'Gold market price/gram',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallAmountField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppTheme.textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          filled: true,
          fillColor: AppTheme.background,
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

  Widget _finalZakatCard(bool isBn, double nisabValue, bool isEligible, double zakatDue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              isBn ? 'এ বছর আপনার মোট যাকাত' : "This Year's Total Zakat",
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${_fmtAmount(zakatDue)} ${isBn ? 'টাকা' : 'Taka'}',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (nisabValue <= 0) ...[
              const SizedBox(height: 8),
              Text(
                isBn ? 'নিসাব হিসাবের জন্য উপরে বাজারদর দিন।' : 'Please enter the market price above to calculate nisab.',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ] else if (!isEligible) ...[
              const SizedBox(height: 8),
              Text(
                isBn
                    ? 'আপনার নিট সম্পদ নিসাব পরিমাণের কম — যাকাত ফরজ নয়।'
                    : 'Your net assets are below the nisab — Zakat is not obligatory.',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nisabReferenceCard(bool isBn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.gold, size: 18),
              const SizedBox(width: 6),
              Text(
                isBn ? 'নিসাবের পরিমাণ' : 'Nisab Amount',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isBn
                ? 'স্বর্ণের নিসাব = ৭.৫০ তোলা (৮৫ গ্রাম)।\nরৌপ্যের নিসাব = ৫২.৫০ তোলা (৫৯৫ গ্রাম)।'
                : 'Gold Nisab = 7.50 tola (85 grams).\nSilver Nisab = 52.50 tola (595 grams).',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            isBn
                ? 'ধরে নেওয়া হয়েছে যে, নিসাব মূল্যের অধিক সম্পদ থাকলেই যাকাত ফরজ হয়।'
                : 'It is assumed that Zakat becomes obligatory once your wealth exceeds the nisab value.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
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
}
