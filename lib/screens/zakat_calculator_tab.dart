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
  // আনুমানিক রূপার বাজারদর (প্রতি গ্রাম, টাকায়) — শুধু প্রথমবার প্রি-ফিল
  // করার জন্য একটা যুক্তিসঙ্গত সূচনা-বিন্দু, সঠিক/আপডেটেড দর নয়।
  // ব্যবহারকারীকে অবশ্যই বর্তমান বাজারদর দিয়ে এটা যাচাই/হালনাগাদ করে
  // নিতে বলা হচ্ছে (নিচে হেল্পার টেক্সটেও উল্লেখ আছে)।
  static const double _defaultSilverPricePerGram = 150.0;

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
    // ফিক্স: প্রথমবার (কোনো সংরক্ষিত মান না থাকলে) নিসাব-দর ফিল্ড
    // দুটো একদম ফাঁকা থাকত, যার ফলে শুধু নগদ টাকা দিয়ে হিসাব করতে
    // চাইলে নিসাব-মূল্য ০ থেকে যেত এবং কোনো ফলাফল আসত না। এখন প্রথমবার
    // একটা যুক্তিসঙ্গত আনুমানিক রূপার বাজারদর (প্রতি গ্রাম) প্রি-ফিল
    // করে দেওয়া হচ্ছে, যাতে ব্যবহারকারী শুধু নগদ টাকা দিয়েই সাথে সাথে
    // ফলাফল দেখতে পান — চাইলে সাম্প্রতিক বাজারদর দিয়ে এটা বদলে নিতে
    // পারবেন। (এটা একটা মোটামুটি ধারণা মাত্র, নির্ভুল দর নয়।)
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

    // ফিক্স: আগে নিসাব হিসাবের জন্য শুধু নিচের "রূপার/সোনার বাজারদর"
    // ফিল্ড দুটোর মান ব্যবহার হতো। কিন্তু বেশিরভাগ ব্যবহারকারী শুধু
    // "নগদ অর্থ" পূরণ করেই "হিসাব করুন" চাপতেন — এই আলাদা নিসাব-দর
    // ফিল্ড দুটো ফাঁকা রেখে দিতেন (বুঝতে পারতেন না এটাও পূরণ করা লাগবে)।
    // ফলে নিসাব-মূল্য সবসময় ০ হয়ে যেত এবং "নিসাব হিসাবের জন্য বাজারদর
    // দিন" বার্তা ছাড়া কোনো ফলাফলই আসত না, এমনকি বড় অঙ্কের নগদ থাকা
    // সত্ত্বেও।
    //
    // এখন যদি নিসাব-দর ফিল্ড ফাঁকা থাকে, উপরের সোনা/রূপা সেকশনে
    // ব্যবহারকারী যে প্রতি-গ্রাম দর দিয়েছেন (থাকলে) সেটাই fallback
    // হিসেবে ব্যবহার করা হচ্ছে — যেহেতু বাস্তবে এটা একই বাজারদর হওয়ার
    // কথা, দুইবার একই তথ্য চাওয়ার দরকার নেই।
    final effectiveGoldNisabPrice = goldNisabPrice > 0 ? goldNisabPrice : _parse(_goldPriceController);
    final effectiveSilverNisabPrice = silverNisabPrice > 0 ? silverNisabPrice : _parse(_silverPriceController);
    final goldNisabValue = effectiveGoldNisabPrice * goldNisabGrams;
    final silverNisabValue = effectiveSilverNisabPrice * silverNisabGrams;

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
          // ═══ উপরে নিসাবের পরিমাণ + নিসাব-ভিত্তি নির্বাচন — একসাথে
          // একটাই জায়গায়, যাতে ব্যবহারকারী শুরুতেই পুরো নিসাব-সংক্রান্ত
          // সব তথ্য ও ইনপুট একবারে দেখে/পূরণ করে ফেলতে পারেন। ═══
          _nisabReferenceCard(isBn),
          const SizedBox(height: 10),
          _nisabBasisCard(isBn),
          const SizedBox(height: 18),
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

  /// উপরে দেখানো নিসাবের রেফারেন্স তথ্য — সোনা ৮৫ গ্রাম (≈৭.৫ তোলা) ও
  /// রূপা ৫৯৫ গ্রাম (≈৫২.৫ তোলা)। শুধু তথ্যগত, কোনো ইনপুট নেই।
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

  /// "নিসাব হিসাবের ভিত্তি" — ব্যাখ্যা, রূপা/সোনা বাছাই ও বাজারদর ইনপুট
  /// একটা কার্ডে একসাথে গুছিয়ে দেখানো হয়েছে, যাতে পুরো ক্যালকুলেটরটা
  /// এলোমেলো না লেগে সুসংগঠিত মনে হয়।
  Widget _nisabBasisCard(bool isBn) {
    return Container(
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
          _resultRow(isBn ? 'নিট সম্পদ' : 'Net Assets', netAssets, bold: true),
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
            const SizedBox(height: 4),
            // ফিক্স: চূড়ান্ত "প্রদেয় যাকাত" সংখ্যাটা আগে সরাসরি একটা
            // প্লেইন Text widget হিসেবে বাম-align হয়ে থাকত (কোনো Row/
            // right-align ছাড়া) — তাই এটা _resultRow-এর মতো সারিবদ্ধ
            // থাকত না, বাম দিকে "ভাসমান" দেখাত। এখন এটাকেও লেবেল-বামে,
            // অংক-ডানে এই একই প্যাটার্নে সাজানো হলো, যাতে পুরো কার্ডের
            // সব সংখ্যা একই উলম্ব রেখায় (ডান কিনারায়) align থাকে।
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.gold, width: 1.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      isBn ? 'প্রদেয় যাকাত (২.৫%)' : 'Zakat Due (2.5%)',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _fmtAmount(zakatDue),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// প্রতিটা হিসাবের সারি — লেবেল বামে, টাকার পরিমাণ ডানে। রেফারেন্স
  /// অ্যাপের মতো হালকা নিচের-বর্ডার দিয়ে প্রতিটা সারি আলাদা করে
  /// দেখানো হচ্ছে, যাতে টেবিলের মতো স্পষ্ট এবং amount সবসময় ডান
  /// কিনারায় align দেখা যায়।
  Widget _resultRow(String label, double value, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtAmount(value),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
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
