/// ওমরাহ অডিওর দোয়া ও অর্থ (আরবি + বাংলা + ইংরেজি)।
///
/// ফাইলের নামে `sec<নম্বর>` (যেমন "assets sec14 des ar") থাকলে সেই নম্বর দিয়ে
/// মেলানো হয়। নাম না মিললে ধাপের ক্রম (০, ১, ২ ...) অনুযায়ী মেলে।
/// নতুন ধাপের অর্থ যোগ করতে [UmrahAudioMeanings.bySection] ও [byStepOrder]-এ যোগ করুন।
class UmrahAudioMeaning {
  final String arabic;
  final String bn;
  final String en;
  const UmrahAudioMeaning({
    required this.arabic,
    required this.bn,
    required this.en,
  });
}

class UmrahAudioMeanings {
  UmrahAudioMeanings._();

  static const _d1 = UmrahAudioMeaning(
    arabic: 'بِسْمِ اللهِ، تَوَكَّلْتُ عَلَى اللهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ',
    bn: 'আল্লাহর নামে (শুরু করছি), আমি আল্লাহর ওপর ভরসা করলাম; আল্লাহর সাহায্য ছাড়া কোনো শক্তি ও সামর্থ্য নেই।',
    en: 'In the name of Allah, I place my trust in Allah; there is no might and no power except through Allah.',
  );

  static const _d2 = UmrahAudioMeaning(
    arabic: 'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ',
    bn: 'আল্লাহ সবচেয়ে মহান, আল্লাহ সবচেয়ে মহান, আল্লাহ সবচেয়ে মহান।',
    en: 'Allah is The Greatest, Allah is The Greatest, Allah is The Greatest.',
  );

  static const _d3 = UmrahAudioMeaning(
    arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
    bn: 'পবিত্র ও মহান তিনি, যিনি এই বাহনকে আমাদের অধীন করে দিয়েছেন, অথচ আমরা একে বশ করতে সক্ষম ছিলাম না। আর নিশ্চয়ই আমরা আমাদের রবের কাছেই ফিরে যাব।',
    en: 'Glory to Him who has brought this [vehicle] under our control, though we were unable to control it [ourselves], and indeed, to Our Lord we will surely return.',
  );

  static const _d4 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا، وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ',
    bn: 'হে আল্লাহ, আমাদের এই সফরে আমরা আপনার কাছে নেকি ও তাকওয়া চাই, আর এমন আমল চাই যা আপনি পছন্দ করেন। হে আল্লাহ, আমাদের জন্য এই সফর সহজ করে দিন এবং এর দূরত্ব গুটিয়ে দিন। হে আল্লাহ, আপনিই সফরে সঙ্গী এবং পরিবারের তত্ত্বাবধায়ক। হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই সফরের কষ্ট থেকে, মন খারাপ করা দৃশ্য দেখা থেকে এবং সম্পদ ও পরিবারের ব্যাপারে মন্দ পরিণতিতে ফিরে আসা থেকে।',
    en: 'O Allah, we ask You on this journey of ours for righteousness and mindfulness of You, and for deeds that please You. O Allah, make this journey easy for us and shorten its distance. O Allah, You are the Companion on the journey and the One entrusted with our family. O Allah, I seek refuge in You from the hardships of travel, a distressing sight, and an adverse return concerning wealth and family.',
  );

  static const _d5 = UmrahAudioMeaning(
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    bn: 'আমি আল্লাহর পরিপূর্ণ বাণীসমূহের মাধ্যমে তাঁর সৃষ্ট সব কিছুর অনিষ্ট থেকে আশ্রয় চাই।',
    en: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
  );

  /// ধাপ নম্বর → (ফাইলের sec নম্বর → দোয়া)
  static const Map<int, Map<int, UmrahAudioMeaning>> bySection = {
    1: {14: _d1, 15: _d2, 16: _d3, 19: _d4, 20: _d5},
  };

  /// ধাপ নম্বর → ক্রম অনুযায়ী দোয়া (ফাইলের নাম না মিললে এটি কাজ করে)
  static const Map<int, List<UmrahAudioMeaning>> byStepOrder = {
    1: [_d1, _d2, _d3, _d4, _d5],
  };

  static UmrahAudioMeaning? find(int stepNo, String fileName, int orderInStep) {
    final m = RegExp(r'sec[\s_\-]*(\d+)', caseSensitive: false).firstMatch(fileName);
    if (m != null) {
      final hit = bySection[stepNo]?[int.parse(m.group(1)!)];
      if (hit != null) return hit;
    }
    final list = byStepOrder[stepNo];
    if (list != null && orderInStep >= 0 && orderInStep < list.length) {
      return list[orderInStep];
    }
    return null;
  }
}
