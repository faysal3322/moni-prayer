/// হাদিস সংগ্রহ — এই ফাইলে শুধু ডেটা থাকে।
///
/// নতুন হাদিস যোগ করতে নিচের [kHadithList]-এ একটা `Hadith(...)` লাইন
/// বসিয়ে দিলেই হবে — স্ক্রিন নিজে থেকেই দেখাবে, সার্চও কাজ করবে।
/// আরবি টেক্সট না থাকলে `arabic` বাদ দিতে পারেন।
///
/// উদাহরণ:
/// ```dart
/// Hadith(
///   category: 'নিয়ত',
///   arabic: '...',
///   bangla: '...',
///   reference: 'সহিহ বুখারি: ১',
/// ),
/// ```
class Hadith {
  /// বিষয় / ক্যাটাগরি (যেমন: নিয়ত, নামাজ, আখলাক)
  final String category;

  /// আরবি মূল টেক্সট (ঐচ্ছিক)
  final String arabic;

  /// বাংলা অনুবাদ
  final String bangla;

  /// সূত্র (কিতাবের নাম ও নম্বর)
  final String reference;

  const Hadith({
    required this.category,
    this.arabic = '',
    required this.bangla,
    required this.reference,
  });
}

/// ⚠️ নিচের একটা হাদিস শুধু নমুনা হিসেবে রাখা — মুছে দিয়ে নিজের ডেটা বসাতে পারেন।
const List<Hadith> kHadithList = [
  Hadith(
    category: 'নিয়ত',
    arabic: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
    bangla: 'নিশ্চয়ই সকল আমল নিয়তের উপর নির্ভরশীল।',
    reference: 'সহিহ বুখারি: ১, সহিহ মুসলিম: ১৯০৭',
  ),
];
