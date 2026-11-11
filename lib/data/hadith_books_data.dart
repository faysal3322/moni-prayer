import 'package:flutter/material.dart';

/// হাদিসের বইয়ের তালিকা — এই ফাইলে শুধু বইয়ের তথ্য থাকে।
///
/// নতুন বই যোগ করতে [kHadithBooks]-এ একটা `HadithBook(...)` লাইন বসান।
/// প্রতিটি বইয়ের `id` আলাদা ও ইংরেজি অক্ষরে হতে হবে — পরে হাদিসের ডেটা
/// এই `id` দিয়েই বইয়ের সাথে জোড়া লাগবে।
/// হাদিস শুধু বাংলায় রাখা হবে (আরবি নয়), যাতে অ্যাপের সাইজ কম থাকে।
class HadithBook {
  /// ইউনিক আইডি (যেমন: bukhari)
  final String id;

  /// হেক্সাগনের ভেতরের ছোট লেখা (যেমন: B, AD, 40)
  final String badge;

  /// বইয়ের নাম
  final String name;

  /// লেখক / সংকলক
  final String author;

  /// মোট হাদিস সংখ্যা (বই খুললে আসল সংখ্যা এখান থেকেই দেখাবে)
  final int count;

  /// হেক্সাগনের রঙ
  final Color color;

  const HadithBook({
    required this.id,
    required this.badge,
    required this.name,
    required this.author,
    required this.count,
    required this.color,
  });
}

/// স্ক্রিনশটের ক্রমে সাজানো (১ → ২৫)
const List<HadithBook> kHadithBooks = [
  // ── স্ক্রিনশট ১ ──
  HadithBook(id: 'bukhari', badge: 'B', name: 'সহীহ বুখারী', author: 'ইমাম বুখারি', count: 7563, color: Color(0xFF84B96B)),
  HadithBook(id: 'muslim', badge: 'M', name: 'সহীহ মুসলিম', author: 'ইমাম মুসলিম', count: 7547, color: Color(0xFF4B8FBF)),
  HadithBook(id: 'nasai', badge: 'N', name: 'সুনানে আন-নাসায়ী', author: 'ইমাম নাসায়ী', count: 5758, color: Color(0xFF5BB3DE)),
  HadithBook(id: 'abu_dawud', badge: 'AD', name: 'সুনানে আবূ দাউদ', author: 'ইমাম আবু দাউদ', count: 5274, color: Color(0xFF8847A8)),
  HadithBook(id: 'tirmidhi', badge: 'T', name: 'জামে‘ আত-তিরমিযী', author: 'ইমাম তিরমিজি', count: 3956, color: Color(0xFF4F6EDB)),
  HadithBook(id: 'ibn_majah', badge: 'IM', name: 'সুনানে ইবনে মাজাহ', author: 'ইমাম ইবনে মাজাহ', count: 4341, color: Color(0xFFDB6B3B)),
  HadithBook(id: 'muwatta', badge: 'MI', name: 'মুয়াত্তা ইমাম মালিক', author: 'ইমাম মালিক', count: 1830, color: Color(0xFF7FB3E8)),

  // ── স্ক্রিনশট ২ ──
  HadithBook(id: 'riyadus_salihin', badge: 'RS', name: 'রিয়াদুস সালেহীন', author: 'ইমাম নববী', count: 1905, color: Color(0xFFD95A8E)),
  HadithBook(id: 'bulugul_maram', badge: 'BM', name: 'বুলুগুল মারাম', author: 'ইবনে হাজার আসকালানী', count: 1568, color: Color(0xFFEFA582)),
  HadithBook(id: 'lulu_marjan', badge: 'LM', name: "আল-লু'লু ওয়াল মারজান", author: 'আল্লামা ফুয়াদ আল বাকী', count: 1906, color: Color(0xFFC3DC4B)),
  HadithBook(id: 'hadith_sambhar', badge: 'HS', name: 'হাদীস সম্ভার', author: 'আব্দুল হামিদ ফাইযি', count: 2013, color: Color(0xFF6BB5A8)),
  HadithBook(id: 'silsila_sahiha', badge: 'SS', name: 'সিলসিলা সহিহা', author: 'আল্লামা নাসিরুদ্দিন আলবানী', count: 60, color: Color(0xFFE2B73E)),
  HadithBook(id: 'jal_joif', badge: 'JH', name: 'জাল ও যঈফ হাদীস সিরিজ', author: 'আল্লামা নাসিরুদ্দিন আলবানী', count: 102, color: Color(0xFFE29C9C)),
  HadithBook(id: 'mishkat', badge: 'MM', name: 'মিশকাতুল মাসাবীহ', author: 'আল্লামা খতীব তাবরেযী', count: 6294, color: Color(0xFF616161)),

  // ── স্ক্রিনশট ৩ ──
  HadithBook(id: 'nawawi_40', badge: '40', name: 'আন্-নওয়াবীর চল্লিশ হাদীস', author: 'ইমাম নববী', count: 42, color: Color(0xFF8E866B)),
  HadithBook(id: 'adabul_mufrad', badge: 'AM', name: 'আল-আদাবুল মুফরাদ', author: 'ইমাম বুখারি', count: 1336, color: Color(0xFF3A8672)),
  HadithBook(id: 'juz_rafayen', badge: 'JR', name: "জুজ'উল রাফায়েল ইয়াদাইন", author: 'ইমাম বুখারি', count: 48, color: Color(0xFF74CDE0)),
  HadithBook(id: 'hadith_qudsi', badge: 'HK', name: 'সহীহ হাদীসে কুদসী', author: 'আল্লামা নাসিরুদ্দিন আলবানী', count: 163, color: Color(0xFF58B974)),
  HadithBook(id: 'susabyasto_100', badge: '100', name: '১০০ সুসাব্যস্ত হাদীস', author: 'সঙ্কলিত হাদীস', count: 101, color: Color(0xFF3F51B5)),
  HadithBook(id: 'mishkat_joif', badge: 'MJ', name: 'মিশকাতে যঈফ হাদীস', author: 'মুযাফফার বিন মুহসিন', count: 106, color: Color(0xFFC5305E)),
  HadithBook(id: 'shamayel', badge: 'ST', name: 'শামায়েলে তিরমিযি', author: 'ইমাম তিরমিজি', count: 322, color: Color(0xFFDD5F55)),

  // ── স্ক্রিনশট ৪ ──
  HadithBook(id: 'targib_tahrib', badge: 'TW', name: 'সহীহ আত-তারগিব ওয়াত তাহরিব', author: 'আল্লামা নাসিরুদ্দিন আলবানী', count: 200, color: Color(0xFFC678D9)),
  HadithBook(id: 'fazayel_amal', badge: 'FA', name: 'সহিহ ফাযায়েলে আমল', author: 'আহসানুল্লাহ বিন সানাউল্লাহ', count: 151, color: Color(0xFF607D8B)),
  HadithBook(id: 'upodesh', badge: 'UP', name: 'উপদেশ', author: 'আব্দুর রাজ্জাক বিন ইউসুফ', count: 234, color: Color(0xFF66AD5E)),
  HadithBook(id: 'ramadan_joif', badge: 'RH', name: 'রমজানের দুর্বল হাদিস', author: 'সানাউল্লাহ নজির আহমদ', count: 36, color: Color(0xFF7B4535)),
];
