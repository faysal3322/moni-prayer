import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// অধ্যায়ের ভেতরের হাদিস লোডার।
///
/// হাদিস থাকে `assets/hadith/<বইয়ের id>/<অধ্যায় নম্বর>.json` ফাইলে।
/// যেমন: assets/hadith/bukhari/1.json  (সহীহ বুখারী, ১ নম্বর অধ্যায়)
/// অধ্যায় খুললে শুধু সেই ফাইলটাই লোড হয়, তাই অ্যাপ ভারী হয় না।
/// ফাইল না থাকলে [load] `null` দেয় — স্ক্রিন তখন "শীঘ্রই যোগ হবে" দেখায়।
///
/// JSON ফরম্যাট:
/// {
///   "chapter": 1,
///   "hadiths": [
///     {
///       "number": 1,                       // হাদিস নম্বর
///       "number_to": 2,                    // ঐচ্ছিক — দুই হাদিস একসাথে থাকলে শেষ নম্বর (১৯২৫ - ১৯২৬)
///       "narrator": "উমার ইবনুল খাত্তাব (রাঃ)",  // "থেকে বর্ণিত:" স্ক্রিন নিজে বসায়
///       "text": ["প্রথম অনুচ্ছেদ", "দ্বিতীয় অনুচ্ছেদ"],  // প্রতিটি অনুচ্ছেদ আলাদা
///       "footnote": "(৫৪, ২৫২৯ ...)",      // না থাকলে null
///       "grade": "সহিহ হাদিস",
///       "heading": {                       // এই হাদিসের আগে অধ্যায়-শিরোনাম থাকলে
///         "no": 1,                         // ১/১, ১/২ ...
///         "title": "শিরোনাম",               // ফাঁকা হতে পারে
///         "note": "আয়াতের অনুবাদ ..."       // না থাকলে null
///       }
///     }
///   ]
/// }
class HadithHeading {
  final int no;
  final String title;
  final String? note;
  const HadithHeading({required this.no, required this.title, this.note});
}

class HadithEntry {
  final int number;

  /// দুটি হাদিস একসাথে একটি কার্ডে থাকলে শেষ হাদিসের নম্বর, নাহলে null
  final int? numberTo;
  final String narrator;
  final List<String> paragraphs;
  final String? footnote;
  final String grade;
  final HadithHeading? heading;

  const HadithEntry({
    required this.number,
    this.numberTo,
    required this.narrator,
    required this.paragraphs,
    this.footnote,
    this.grade = 'সহিহ হাদিস',
    this.heading,
  });

  factory HadithEntry.fromJson(Map<String, dynamic> j) {
    final h = j['heading'];
    final fn = (j['footnote'] as String?)?.trim();
    return HadithEntry(
      number: j['number'] as int,
      numberTo: j['number_to'] as int?,
      narrator: (j['narrator'] as String?) ?? '',
      paragraphs: ((j['text'] as List?) ?? const []).map((e) => e.toString()).toList(),
      footnote: (fn == null || fn.isEmpty) ? null : fn,
      grade: (j['grade'] as String?) ?? 'সহিহ হাদিস',
      heading: h is Map
          ? HadithHeading(
              no: h['no'] as int,
              title: (h['title'] as String?) ?? '',
              note: (h['note'] as String?),
            )
          : null,
    );
  }
}

class HadithContent {
  static final Map<String, List<HadithEntry>?> _cache = {};

  /// অধ্যায়ের হাদিস লোড করে। ফাইল না থাকলে বা ফাঁকা হলে `null`।
  static Future<List<HadithEntry>?> load(String bookId, int chapterNo) async {
    final key = '$bookId/$chapterNo';
    if (_cache.containsKey(key)) return _cache[key];
    List<HadithEntry>? result;
    try {
      final raw = await rootBundle.loadString('assets/hadith/$key.json');
      final map = json.decode(raw) as Map<String, dynamic>;
      final list = ((map['hadiths'] as List?) ?? const [])
          .map((e) => HadithEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      result = list.isEmpty ? null : list;
    } catch (_) {
      result = null; // ফাইল নেই
    }
    _cache[key] = result;
    return result;
  }
}
