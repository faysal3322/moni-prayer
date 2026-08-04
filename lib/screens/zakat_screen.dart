import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import 'zakat_calculator_tab.dart';
import 'zakat_yearly_record_tab.dart';
import 'zakat_categories_tab.dart';
import 'zakat_virtues_tab.dart';

/// যাকাত সেকশনের মূল স্ক্রিন — ৪টা ট্যাব:
/// ১. ক্যালকুলেটর (নগদ, সোনা, রূপা, দায় ইনপুট নিয়ে যাকাত হিসাব)
/// ২. বছরভিত্তিক হিসাব (প্রতি বছর কত প্রদেয় হলো, কত প্রদান করা হলো)
/// ৩. বন্টনের খাত (৮টা খাত, সূরা তাওবা ৯:৬০ অনুযায়ী)
/// ৪. ফযীলত (যাকাতের গুরুত্ব ও ফযীলত সংক্রান্ত তথ্য)
class ZakatScreen extends StatefulWidget {
  final AppLanguage lang;
  const ZakatScreen({super.key, required this.lang});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> with SingleTickerProviderStateMixin {
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
        title: Text(isBn ? 'যাকাত' : 'Zakat'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.gold,
          tabs: [
            Tab(text: isBn ? 'ক্যালকুলেটর' : 'Calculator'),
            Tab(text: isBn ? 'বছরভিত্তিক হিসাব' : 'Yearly Record'),
            Tab(text: isBn ? 'বন্টনের খাত' : 'Categories'),
            Tab(text: isBn ? 'ফযীলত' : 'Virtues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ZakatCalculatorTab(lang: widget.lang),
          ZakatYearlyRecordTab(lang: widget.lang),
          ZakatCategoriesTab(lang: widget.lang),
          ZakatVirtuesTab(lang: widget.lang),
        ],
      ),
    );
  }
}
