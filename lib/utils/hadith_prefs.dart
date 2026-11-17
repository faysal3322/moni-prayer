import 'package:shared_preferences/shared_preferences.dart';
import '../data/hadith_data.dart';

/// হাদিসের "সর্বশেষ পঠিত অবস্থান" — কোরআনের QuranPrefs-এর মতোই, তবে হাদিসের
/// প্রতিটি অপশনের জন্য আলাদা আলাদা সংরক্ষণ (একটা আরেকটাকে ওভাররাইট করে না):
///   • হাদিসের বই        → বই + অধ্যায় + হাদিস নম্বর
///   • বিষয়ভিত্তিক হাদিস → হাদিসের পরিচয়-কী (key) + তালিকার ইনডেক্স
class HadithPrefs {
  HadithPrefs._();

  // ── হাদিসের বই ──
  static const _kBooksBook = 'hadith_books_last_book';
  static const _kBooksChapter = 'hadith_books_last_chapter';
  static const _kBooksNumber = 'hadith_books_last_number';

  static Future<void> setBooksLastRead(
      String bookId, int chapter, int number) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBooksBook, bookId);
    await p.setInt(_kBooksChapter, chapter);
    await p.setInt(_kBooksNumber, number);
  }

  /// {'book': String, 'chapter': int, 'number': int} — কিছু পড়া না হলে null
  static Future<Map<String, dynamic>?> getBooksLastRead() async {
    final p = await SharedPreferences.getInstance();
    final book = p.getString(_kBooksBook);
    final chapter = p.getInt(_kBooksChapter);
    final number = p.getInt(_kBooksNumber);
    if (book == null || chapter == null || number == null) return null;
    return {'book': book, 'chapter': chapter, 'number': number};
  }

  // ── বিষয়ভিত্তিক হাদিস ──
  static const _kTopicKey = 'hadith_topic_last_key';
  static const _kTopicIndex = 'hadith_topic_last_index';

  /// হাদিসের পরিচয়-কী: তালিকায় নতুন হাদিস যোগ/সরানোর পরও যেন সঠিক হাদিস
  /// খুঁজে পাওয়া যায় (শুধু ইনডেক্সের উপর নির্ভর করা হয়নি)।
  static String topicKey(Hadith h) {
    final t = h.bangla.trim();
    final head = t.length > 40 ? t.substring(0, 40) : t;
    return '${h.category.trim()}|${h.reference.trim()}|$head';
  }

  static Future<void> setTopicLastRead(Hadith h, int index) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTopicKey, topicKey(h));
    await p.setInt(_kTopicIndex, index);
  }

  /// সংরক্ষিত হাদিসটি [list]-এর কোন ইনডেক্সে আছে — না পাওয়া গেলে null।
  static Future<int?> getTopicLastReadIndex(List<Hadith> list) async {
    if (list.isEmpty) return null;
    final p = await SharedPreferences.getInstance();
    final key = p.getString(_kTopicKey);
    final saved = p.getInt(_kTopicIndex);
    if (key == null) return null;
    final found = list.indexWhere((h) => topicKey(h) == key);
    if (found >= 0) return found;
    if (saved != null && saved >= 0 && saved < list.length) return saved;
    return null;
  }
}
