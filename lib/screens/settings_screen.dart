import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/app_language.dart';
import '../utils/database_helper.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  final AppLanguage lang;
  final VoidCallback onChanged;
  const SettingsScreen({super.key, required this.lang, required this.onChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  String _currentLang = 'bn';
  int _hijriAdjust = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLang = prefs.getString('language') ?? 'bn';
      _nameCtrl.text = prefs.getString('user_name') ?? 'FAYSAL';
      _hijriAdjust = prefs.getInt('hijri_adjust') ?? 0;
    });
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    MoniPrayerApp.of(context)?.setUserName(name);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.lang.isBn ? 'নাম সেভ হয়েছে' : 'Name saved'),
      backgroundColor: AppTheme.completed));
  }

  void _setLang(String lang) {
    MoniPrayerApp.of(context)?.setLanguage(lang);
    setState(() => _currentLang = lang);
    widget.onChanged();
  }

  Future<void> _setHijriAdjust(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hijri_adjust', val);
    setState(() => _hijriAdjust = val);
    widget.onChanged();
  }

  Future<void> _backup() async {
    try {
      final data = await DatabaseHelper.exportAllData();
      final prefs = await SharedPreferences.getInstance();
      data['user_name'] = prefs.getString('user_name') ?? 'FAYSAL';
      data['language'] = prefs.getString('language') ?? 'bn';
      final now = DateTime.now();
      final fileName = 'moni_prayer_backup_${now.year}_${now.month.toString().padLeft(2,'0')}_${now.day.toString().padLeft(2,'0')}.json';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonEncode(data));
      await Share.shareXFiles([XFile(file.path)], subject: 'MONI PRAYER Backup');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppTheme.missed));
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(widget.lang.restore, style: const TextStyle(color: AppTheme.gold)),
        content: Text(widget.lang.backupWarning, style: const TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(widget.lang.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(widget.lang.confirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null) return;
      final file = File(result.files.single.path!);
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await DatabaseHelper.importAllData(json);
      final prefs = await SharedPreferences.getInstance();
      if (json['user_name'] != null) await prefs.setString('user_name', json['user_name']);
      if (json['language'] != null) await prefs.setString('language', json['language']);
      widget.onChanged();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.lang.isBn ? 'রিস্টোর সম্পন্ন' : 'Restore complete'),
        backgroundColor: AppTheme.completed));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppTheme.missed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isBn = lang.isBn;

    return Scaffold(
      appBar: AppBar(title: Text(lang.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User name
          _sectionTitle(lang.userName),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'FAYSAL',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true, fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            )),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _saveName, child: Text(lang.save)),
          ]),

          const SizedBox(height: 24),

          // Language
          _sectionTitle(lang.language),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _LangBtn(label: lang.bangla, selected: _currentLang == 'bn', onTap: () => _setLang('bn'))),
            const SizedBox(width: 12),
            Expanded(child: _LangBtn(label: lang.english, selected: _currentLang == 'en', onTap: () => _setLang('en'))),
          ]),

          const SizedBox(height: 24),

          // Hijri Adjust
          _sectionTitle(isBn ? 'হিজরি তারিখ সংশোধন' : 'Hijri Date Adjustment'),
          const SizedBox(height: 4),
          Text(
            isBn ? 'চাঁদ দেখার উপর নির্ভর করে ±১ দিন পরিবর্তন করুন' : 'Adjust ±1 day based on moon sighting',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // -1 button
                GestureDetector(
                  onTap: () => _setHijriAdjust(_hijriAdjust > -1 ? _hijriAdjust - 1 : -1),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _hijriAdjust == -1 ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: const Center(child: Text('-1', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(width: 16),
                // 0 button
                GestureDetector(
                  onTap: () => _setHijriAdjust(0),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _hijriAdjust == 0 ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: Center(child: Text(isBn ? '০' : '0', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(width: 16),
                // +1 button
                GestureDetector(
                  onTap: () => _setHijriAdjust(_hijriAdjust < 1 ? _hijriAdjust + 1 : 1),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _hijriAdjust == 1 ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: const Center(child: Text('+1', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  _hijriAdjust == 0
                      ? (isBn ? 'স্বাভাবিক' : 'Normal')
                      : _hijriAdjust == 1
                          ? (isBn ? '১ দিন এগিয়ে' : '1 day ahead')
                          : (isBn ? '১ দিন পিছিয়ে' : '1 day behind'),
                  style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // Backup & Restore
          _sectionTitle(isBn ? 'ব্যাকআপ ও রিস্টোর' : 'Backup & Restore'),
          const SizedBox(height: 8),
          Text(
            isBn ? 'আপনার সমস্ত ডেটা JSON ফাইলে সেভ করুন বা পুনরুদ্ধার করুন।' : 'Save or restore all your data as a JSON file.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: _backup,
              icon: const Icon(Icons.backup),
              label: Text(lang.backup),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: _restore,
              icon: const Icon(Icons.restore),
              label: Text(lang.restore),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBg, foregroundColor: AppTheme.gold),
            )),
          ]),

          const SizedBox(height: 32),
          const Center(child: Text(
            'MONI PRAYER v1.0.0\nSolo. Simple. Sacred.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15));
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.accent : Colors.white12),
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecondary,
          fontWeight: FontWeight.bold))),
      ),
    );
  }
}
