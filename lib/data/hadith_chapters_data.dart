/// হাদিসের বইয়ের অধ্যায়-তালিকা — এই ফাইলে শুধু অধ্যায়ের তথ্য থাকে।
///
/// [kHadithChapters]-এর key হলো `hadith_books_data.dart`-এর বইয়ের `id`।
/// অন্য বইয়ের অধ্যায় যোগ করতে একই নিয়মে নতুন key বসান — স্ক্রিন নিজে থেকেই দেখাবে।
class HadithChapter {
  /// অধ্যায় নম্বর (১, ২, ৩ ...)
  final int number;

  /// অধ্যায়ের নাম
  final String name;

  /// এই অধ্যায়ের প্রথম হাদিস নম্বর
  final int from;

  /// এই অধ্যায়ের শেষ হাদিস নম্বর
  final int to;

  const HadithChapter(this.number, this.name, this.from, this.to);

  int get count => to - from + 1;
}

const Map<String, List<HadithChapter>> kHadithChapters = {
  'bukhari': kBukhariChapters,
};

/// সহীহ বুখারী — ৯৭টি অধ্যায় (হাদিস ১ – ৭৫৬৩)
const List<HadithChapter> kBukhariChapters = [
  HadithChapter(1, 'ওহীর সূচনা অধ্যায়', 1, 7),
  HadithChapter(2, 'ঈমান', 8, 58),
  HadithChapter(3, 'ইলম', 59, 134),
  HadithChapter(4, 'ওযু', 135, 247),
  HadithChapter(5, 'গোসল', 248, 293),
  HadithChapter(6, 'হায়েজ', 294, 333),
  HadithChapter(7, 'তায়াম্মুম', 334, 348),
  HadithChapter(8, 'সালাত', 349, 520),
  HadithChapter(9, 'সালাতের ওয়াক্তসমূহ', 521, 602),
  HadithChapter(10, 'আজান', 603, 875),
  HadithChapter(11, 'জুমা', 876, 941),
  HadithChapter(12, 'খাওফ (ভয় ভীতির সালাত)', 942, 947),
  HadithChapter(13, 'দুই ঈদ', 948, 989),
  HadithChapter(14, 'বিতর', 990, 1004),
  HadithChapter(15, 'বৃষ্টির জন্য দোয়া', 1005, 1039),
  HadithChapter(16, 'সূর্যগ্রহণ', 1040, 1066),
  HadithChapter(17, 'কুরআন তিলাওয়াতের সিজদা', 1067, 1079),
  HadithChapter(18, 'সালাতে কসর করা', 1080, 1119),
  HadithChapter(19, 'তাহাজ্জুদ', 1120, 1187),
  HadithChapter(20, 'মক্কা ও মদীনার মসজিদে সালাতের মর্যাদা', 1188, 1197),
  HadithChapter(21, 'সালাতের সাথে সংশ্লিষ্ট কাজ', 1198, 1223),
  HadithChapter(22, 'সাহু', 1224, 1236),
  HadithChapter(23, 'জানাজা', 1237, 1394),
  HadithChapter(24, 'যাকাত', 1395, 1512),
  HadithChapter(25, 'হজ্জ', 1513, 1772),
  HadithChapter(26, 'উমরাহ', 1773, 1805),
  HadithChapter(27, 'পথে আটকে পড়া ও ইহরাম অবস্থায় শিকারকারীর বিধান', 1806, 1820),
  HadithChapter(28, 'ইহরাম অবস্থায় শিকার ও অনুরূপ কিছুর বদলা', 1821, 1866),
  HadithChapter(29, 'মদীনার ফজিলত', 1867, 1890),
  HadithChapter(30, 'সাওম', 1891, 2007),
  HadithChapter(31, 'তারাবীহর সালাত', 2008, 2013),
  HadithChapter(32, 'লাইলাতুল কদর এর ফজিলত', 2014, 2024),
  HadithChapter(33, 'ইতিকাফ', 2025, 2046),
  HadithChapter(34, 'ক্রয়-বিক্রয়', 2047, 2238),
  HadithChapter(35, 'সলম (অগ্রিম ক্রয়-বিক্রয়)', 2239, 2256),
  HadithChapter(36, 'শুফআ', 2257, 2259),
  HadithChapter(37, 'ইজারা', 2260, 2286),
  HadithChapter(38, 'হাওয়ালাত', 2287, 2289),
  HadithChapter(39, 'যামিন হওয়া', 2290, 2298),
  HadithChapter(40, 'ওয়াকালাহ (প্রতিনিধিত্ব)', 2299, 2319),
  HadithChapter(41, 'চাষাবাদ', 2320, 2350),
  HadithChapter(42, 'পানি সেচ', 2351, 2384),
  HadithChapter(43, 'ঋণ গ্রহণ, ঋণ পরিশোধ, নিষেধাজ্ঞা আরোপ ও দেউলিয়া ঘোষণা', 2385, 2409),
  HadithChapter(44, 'ঝগড়া-বিবাদ মীমাংসা', 2410, 2425),
  HadithChapter(45, 'পড়ে থাকা বস্তু উঠানো', 2426, 2439),
  HadithChapter(46, 'জুলুম ও কিসাস', 2440, 2482),
  HadithChapter(47, 'অংশীদারিত্ব', 2483, 2507),
  HadithChapter(48, 'বন্ধক', 2508, 2516),
  HadithChapter(49, 'ক্রীতদাস আযাদ করা', 2517, 2559),
  HadithChapter(50, 'মুকাতাব (চুক্তিবদ্ধ দাসের বর্ণনা)', 2560, 2565),
  HadithChapter(51, 'হিবা ও তার ফজিলত এবং এর প্রতি উৎসাহ প্রদান', 2566, 2636),
  HadithChapter(52, 'সাক্ষ্যদান', 2637, 2689),
  HadithChapter(53, 'বিবাদ মীমাংসা', 2690, 2710),
  HadithChapter(54, 'শর্তাবলী', 2711, 2737),
  HadithChapter(55, 'ওসিয়াত', 2738, 2781),
  HadithChapter(56, 'জিহাদ', 2782, 3090),
  HadithChapter(57, 'খুমুস (এক পঞ্চমাংশ)', 3091, 3155),
  HadithChapter(58, 'জিযিয়া কর ও সন্ধি স্থাপন', 3156, 3189),
  HadithChapter(59, 'সৃষ্টির সূচনা', 3190, 3325),
  HadithChapter(60, 'আম্বিয়া কিরাম (আঃ)', 3326, 3488),
  HadithChapter(61, 'মর্যাদা ও বৈশিষ্ট্য', 3489, 3648),
  HadithChapter(62, 'সাহাবীগণের মর্যাদা', 3649, 3775),
  HadithChapter(63, 'আনসারগণের মর্যাদা', 3776, 3948),
  HadithChapter(64, 'মাগাজি', 3949, 4473),
  HadithChapter(65, 'তাফসীর', 4474, 4977),
  HadithChapter(66, 'ফজায়িলুল কুরআন', 4978, 5062),
  HadithChapter(67, 'বিয়ে-শাদি', 5063, 5250),
  HadithChapter(68, 'তালাক', 5251, 5350),
  HadithChapter(69, 'ভরণ-পোষণ', 5351, 5372),
  HadithChapter(70, 'আহার সংক্রান্ত', 5373, 5466),
  HadithChapter(71, 'আকীকা', 5467, 5474),
  HadithChapter(72, 'যবেহ ও শিকার করা', 5475, 5544),
  HadithChapter(73, 'কুরবানী', 5545, 5574),
  HadithChapter(74, 'পানীয় দ্রব্যসমূহ', 5575, 5639),
  HadithChapter(75, 'রোগীদের বর্ণনা', 5640, 5677),
  HadithChapter(76, 'চিকিৎসা', 5678, 5782),
  HadithChapter(77, 'পোশাক-পরিচ্ছদ', 5783, 5969),
  HadithChapter(78, 'আচার-ব্যবহার', 5970, 6226),
  HadithChapter(79, 'অনুমতি চাওয়া', 6227, 6303),
  HadithChapter(80, 'দোয়া', 6304, 6411),
  HadithChapter(81, 'কোমল হওয়া', 6412, 6593),
  HadithChapter(82, 'তাকদীর', 6594, 6620),
  HadithChapter(83, 'শপথ ও মানত', 6621, 6707),
  HadithChapter(84, 'শপথের কাফফারা', 6708, 6722),
  HadithChapter(85, 'উত্তরাধিকার', 6723, 6771),
  HadithChapter(86, 'শরিয়তের শাস্তি', 6772, 6860),
  HadithChapter(87, 'রক্তপণ', 6861, 6917),
  HadithChapter(88, 'আল্লাহদ্রোহী ও ধর্মত্যাগীদেরকে তাওবার প্রতি আহ্বান ও তাদের সাথে যুদ্ধ', 6918, 6939),
  HadithChapter(89, 'বলপ্রয়োগে বাধ্য করা', 6940, 6952),
  HadithChapter(90, 'কূটকৌশল', 6953, 6981),
  HadithChapter(91, 'স্বপ্নের ব্যাখ্যা প্রদান', 6982, 7047),
  HadithChapter(92, 'ফিতনা', 7048, 7136),
  HadithChapter(93, 'আহকাম', 7137, 7225),
  HadithChapter(94, 'আকাঙ্ক্ষা', 7226, 7245),
  HadithChapter(95, 'খবরে ওয়াহিদ', 7246, 7267),
  HadithChapter(96, 'কুরআন ও সুন্নাহকে দৃঢ়ভাবে ধারণ করা', 7268, 7370),
  HadithChapter(97, 'জাহমিয়াদের মতের খণ্ডন ও তাওহীদ প্রসঙ্গ', 7371, 7563),
];
