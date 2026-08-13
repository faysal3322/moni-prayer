import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// একটা নির্দিষ্ট বছরের (হিজরি বছর অনুযায়ী, যেমন "১৪৪৭") যাকাত রেকর্ড —
/// সেই বছরের হিসাব করা প্রদেয় (payable) যাকাত ও ব্যবহারকারী কত প্রদান
/// (paid) করেছেন তা এখানে থাকে। ব্যবহারকারী চাইলে নোট/মন্তব্যও রাখতে পারেন।
class ZakatRecord {
  final String year; // যেমন "1447" (হিজরি) — ফ্রি-টেক্সট রাখা হয়েছে, যাতে
  // ব্যবহারকারী চাইলে ইংরেজি সাল (যেমন "2025") ব্যবহার করলেও কাজ করে
  final double payable; // ঐ বছরের হিসাব করা মোট প্রদেয় যাকাত
  final double paid; // এখন পর্যন্ত প্রদান করা মোট পরিমাণ
  final String note;
  final String dateAdded; // ISO 8601 — কবে এন্ট্রি যোগ হয়েছে

  ZakatRecord({
    required this.year,
    required this.payable,
    required this.paid,
    this.note = '',
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'payable': payable,
        'paid': paid,
        'note': note,
        'dateAdded': dateAdded,
      };

  factory ZakatRecord.fromJson(Map<String, dynamic> json) => ZakatRecord(
        year: json['year'] as String,
        payable: (json['payable'] as num).toDouble(),
        paid: (json['paid'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        dateAdded: json['dateAdded'] as String,
      );

  ZakatRecord copyWith({
    String? year,
    double? payable,
    double? paid,
    String? note,
  }) =>
      ZakatRecord(
        year: year ?? this.year,
        payable: payable ?? this.payable,
        paid: paid ?? this.paid,
        note: note ?? this.note,
        dateAdded: dateAdded,
      );
}

/// যাকাত সেকশনের ডেটা (বছরভিত্তিক রেকর্ড + ক্যালকুলেটরের শেষ ব্যবহৃত
/// মান) সংরক্ষণ করে। আলাদা sqflite ডাটাবেসের বদলে SharedPreferences-এ
/// একটা JSON list হিসেবে রাখা হচ্ছে — ডেটার পরিমাণ ছোট (প্রতি বছর
/// একটা এন্ট্রি) বলে এটাই সহজ ও যথেষ্ট, এবং backup/restore-এর অংশ
/// হিসেবে অন্য SharedPreferences ভিত্তিক সেটিংসের মতোই সহজে যোগ করা
/// যায়।
class ZakatHelper {
  static const _keyRecords = 'zakat_records';
  static const _keyLastCash = 'zakat_last_cash';
  static const _keyLastGoldGrams = 'zakat_last_gold_grams';
  static const _keyLastGoldPricePerGram = 'zakat_last_gold_price_per_gram';
  static const _keyLastSilverGrams = 'zakat_last_silver_grams';
  static const _keyLastSilverPricePerGram = 'zakat_last_silver_price_per_gram';
  static const _keyLastLiabilities = 'zakat_last_liabilities';
  static const _keyLastNisabBasis = 'zakat_last_nisab_basis'; // 'gold' | 'silver'
  static const _keyLastSilverNisabPrice = 'zakat_last_silver_nisab_price'; // নিসাব হিসাবের জন্য রূপার বাজারদর (প্রতি গ্রাম)
  static const _keyLastGoldNisabPrice = 'zakat_last_gold_nisab_price'; // নিসাব হিসাবের জন্য সোনার বাজারদর (প্রতি গ্রাম)
  // রেফারেন্স "যাকাত হিসাব" অ্যাপের ডিজাইন অনুসরণ করে যোগ করা অতিরিক্ত
  // সম্পদ/দায়ের ঘর — এগুলো নগদ/সোনা/রূপার বাইরের অন্যান্য যাকাতযোগ্য
  // সম্পদ ও ব্যক্তিগত দায় হিসাবের জন্য।
  static const _keyLastProvidentFund = 'zakat_last_provident_fund'; // প্রভিডেন্ট ফান্ড, শেয়ার, বন্ড, বীমা, সঞ্চয়পত্র
  static const _keyLastGoodsStock = 'zakat_last_goods_stock'; // জমাকৃত পণ্য বা মালামাল
  static const _keyLastReceivables = 'zakat_last_receivables'; // পাওনা, ধার প্রদান, অগ্রিম
  static const _keyLastOtherAssets = 'zakat_last_other_assets'; // অন্যান্য সম্পদ
  static const _keyLastBankLoan = 'zakat_last_bank_loan'; // ব্যাংক/এনজিও ঋণ
  static const _keyLastOtherLiabilities = 'zakat_last_other_liabilities'; // অন্যান্য দায় সমূহ

  // ═══ বছরভিত্তিক রেকর্ড ═══

  static Future<List<ZakatRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRecords);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ZakatRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.year.compareTo(a.year)); // নতুন বছর আগে
  }

  static Future<void> _saveAll(List<ZakatRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRecords, raw);
  }

  /// নতুন একটা বছরের রেকর্ড যোগ করে বা (একই year থাকলে) প্রতিস্থাপন করে।
  static Future<void> upsertRecord(ZakatRecord record) async {
    final records = await getAllRecords();
    final idx = records.indexWhere((r) => r.year == record.year);
    if (idx >= 0) {
      records[idx] = record;
    } else {
      records.add(record);
    }
    await _saveAll(records);
  }

  static Future<void> deleteRecord(String year) async {
    final records = await getAllRecords();
    records.removeWhere((r) => r.year == year);
    await _saveAll(records);
  }

  // ═══ ক্যালকুলেটরের শেষ ব্যবহৃত মান (পরের বার খুললে আগের ইনপুট মনে রাখার জন্য) ═══

  static Future<Map<String, dynamic>> getLastCalculatorInputs() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'cash': prefs.getDouble(_keyLastCash) ?? 0.0,
      'goldGrams': prefs.getDouble(_keyLastGoldGrams) ?? 0.0,
      'goldPricePerGram': prefs.getDouble(_keyLastGoldPricePerGram) ?? 0.0,
      'silverGrams': prefs.getDouble(_keyLastSilverGrams) ?? 0.0,
      'silverPricePerGram': prefs.getDouble(_keyLastSilverPricePerGram) ?? 0.0,
      'liabilities': prefs.getDouble(_keyLastLiabilities) ?? 0.0,
      'nisabBasis': prefs.getString(_keyLastNisabBasis) ?? 'silver',
      'silverNisabPrice': prefs.getDouble(_keyLastSilverNisabPrice) ?? 0.0,
      'goldNisabPrice': prefs.getDouble(_keyLastGoldNisabPrice) ?? 0.0,
      'providentFund': prefs.getDouble(_keyLastProvidentFund) ?? 0.0,
      'goodsStock': prefs.getDouble(_keyLastGoodsStock) ?? 0.0,
      'receivables': prefs.getDouble(_keyLastReceivables) ?? 0.0,
      'otherAssets': prefs.getDouble(_keyLastOtherAssets) ?? 0.0,
      'bankLoan': prefs.getDouble(_keyLastBankLoan) ?? 0.0,
      'otherLiabilities': prefs.getDouble(_keyLastOtherLiabilities) ?? 0.0,
    };
  }

  static Future<void> saveCalculatorInputs({
    required double cash,
    required double goldGrams,
    required double goldPricePerGram,
    required double silverGrams,
    required double silverPricePerGram,
    required double liabilities,
    required String nisabBasis,
    required double silverNisabPrice,
    required double goldNisabPrice,
    double providentFund = 0.0,
    double goodsStock = 0.0,
    double receivables = 0.0,
    double otherAssets = 0.0,
    double bankLoan = 0.0,
    double otherLiabilities = 0.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLastCash, cash);
    await prefs.setDouble(_keyLastGoldGrams, goldGrams);
    await prefs.setDouble(_keyLastGoldPricePerGram, goldPricePerGram);
    await prefs.setDouble(_keyLastSilverGrams, silverGrams);
    await prefs.setDouble(_keyLastSilverPricePerGram, silverPricePerGram);
    await prefs.setDouble(_keyLastLiabilities, liabilities);
    await prefs.setString(_keyLastNisabBasis, nisabBasis);
    await prefs.setDouble(_keyLastSilverNisabPrice, silverNisabPrice);
    await prefs.setDouble(_keyLastGoldNisabPrice, goldNisabPrice);
    await prefs.setDouble(_keyLastProvidentFund, providentFund);
    await prefs.setDouble(_keyLastGoodsStock, goodsStock);
    await prefs.setDouble(_keyLastReceivables, receivables);
    await prefs.setDouble(_keyLastOtherAssets, otherAssets);
    await prefs.setDouble(_keyLastBankLoan, bankLoan);
    await prefs.setDouble(_keyLastOtherLiabilities, otherLiabilities);
  }

  // ═══ ব্যাকআপ/রিস্টোর ═══

  /// ব্যাকআপের জন্য যাকাত সেকশনের সব ডেটা (বছরভিত্তিক রেকর্ড +
  /// ক্যালকুলেটরের শেষ ইনপুট) একসাথে বের করে আনে।
  static Future<Map<String, dynamic>> exportData() async {
    final records = await getAllRecords();
    final calcInputs = await getLastCalculatorInputs();
    return {
      'records': records.map((r) => r.toJson()).toList(),
      'calculator_inputs': calcInputs,
    };
  }

  /// ব্যাকআপ থেকে যাকাত সেকশনের ডেটা পুনরুদ্ধার করে।
  static Future<void> importData(Map<String, dynamic> data) async {
    if (data['records'] != null) {
      final records = (data['records'] as List)
          .map((e) => ZakatRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      await _saveAll(records);
    }
    if (data['calculator_inputs'] != null) {
      final c = Map<String, dynamic>.from(data['calculator_inputs'] as Map);
      await saveCalculatorInputs(
        cash: (c['cash'] as num?)?.toDouble() ?? 0.0,
        goldGrams: (c['goldGrams'] as num?)?.toDouble() ?? 0.0,
        goldPricePerGram: (c['goldPricePerGram'] as num?)?.toDouble() ?? 0.0,
        silverGrams: (c['silverGrams'] as num?)?.toDouble() ?? 0.0,
        silverPricePerGram: (c['silverPricePerGram'] as num?)?.toDouble() ?? 0.0,
        liabilities: (c['liabilities'] as num?)?.toDouble() ?? 0.0,
        nisabBasis: c['nisabBasis'] as String? ?? 'silver',
        silverNisabPrice: (c['silverNisabPrice'] as num?)?.toDouble() ?? 0.0,
        goldNisabPrice: (c['goldNisabPrice'] as num?)?.toDouble() ?? 0.0,
        providentFund: (c['providentFund'] as num?)?.toDouble() ?? 0.0,
        goodsStock: (c['goodsStock'] as num?)?.toDouble() ?? 0.0,
        receivables: (c['receivables'] as num?)?.toDouble() ?? 0.0,
        otherAssets: (c['otherAssets'] as num?)?.toDouble() ?? 0.0,
        bankLoan: (c['bankLoan'] as num?)?.toDouble() ?? 0.0,
        otherLiabilities: (c['otherLiabilities'] as num?)?.toDouble() ?? 0.0,
      );
    }
  }
}
