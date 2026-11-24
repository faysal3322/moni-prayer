import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// ফোনের Music/Umrah MP3 ফোল্ডার থেকে ওমরাহ ধাপের অডিও খুঁজে বের করে।
///
/// ফোল্ডারের গঠন (ফাইল ম্যানেজারে যেমন আছে):
///   /storage/emulated/0/Music/Recitations/Umrah MP3/1 Starting your Journey/*.mp3
///   /storage/emulated/0/Music/Recitations/Umrah MP3/2 Putting on Ehram/*.mp3 ...
/// ফোল্ডারের নামের শুরুর সংখ্যা = ধাপ নম্বর। অডিও অ্যাপের ভেতরে নেই,
/// তাই অ্যাপের সাইজ বাড়ে না।
class UmrahAudioHelper {
  UmrahAudioHelper._();

  static const String rootPath = '/storage/emulated/0/Music/Recitations/Umrah MP3';

  /// যেসব ধাপে (ধাপ নম্বর) অডিও দেখাবে। নতুন ধাপের অডিও চালু করতে
  /// শুধু এখানে নম্বর যোগ করুন, যেমন {1, 2, 3}।
  static const Set<int> enabledSteps = {1};

  static const List<String> _exts = [
    '.mp3', '.m4a', '.aac', '.wav', '.ogg', '.opus', '.flac',
  ];

  static Future<bool> hasPermission() async {
    try {
      return await Permission.manageExternalStorage.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final st = await Permission.manageExternalStorage.request();
      return st.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// ধাপ নম্বরের (১, ২, ...) ফোল্ডার; না থাকলে null
  static Future<Directory?> folderForStep(int stepNo) async {
    final root = Directory(rootPath);
    try {
      if (!await root.exists()) return null;
      await for (final e in root.list(followLinks: false)) {
        if (e is! Directory) continue;
        final name = e.path.split('/').last;
        final m = RegExp(r'^\s*(\d+)').firstMatch(name);
        if (m != null && int.parse(m.group(1)!) == stepNo) return e;
      }
    } catch (_) {}
    return null;
  }

  /// ধাপের অডিও ফাইল (নামের ক্রম অনুযায়ী)
  static Future<List<File>> filesForStep(int stepNo) async {
    final dir = await folderForStep(stepNo);
    if (dir == null) return [];
    final out = <File>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        if (e is! File) continue;
        final low = e.path.toLowerCase();
        if (_exts.any(low.endsWith)) out.add(e);
      }
    } catch (_) {}
    out.sort((a, b) => _natural(a.path.split('/').last, b.path.split('/').last));
    return out;
  }

  /// "2 abc" < "10 abc" ধরনের স্বাভাবিক ক্রম
  static int _natural(String a, String b) {
    final re = RegExp(r'(\d+)|(\D+)');
    final x = re.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
    final y = re.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
    for (int i = 0; i < x.length && i < y.length; i++) {
      final nx = int.tryParse(x[i]);
      final ny = int.tryParse(y[i]);
      final c = (nx != null && ny != null) ? nx.compareTo(ny) : x[i].compareTo(y[i]);
      if (c != 0) return c;
    }
    return x.length.compareTo(y.length);
  }

  /// ফাইলের নাম থেকে সুন্দর শিরোনাম (এক্সটেনশন বাদ)
  static String titleOf(File f) {
    var n = f.path.split('/').last;
    final dot = n.lastIndexOf('.');
    if (dot > 0) n = n.substring(0, dot);
    return n.replaceAll('_', ' ').trim();
  }
}
