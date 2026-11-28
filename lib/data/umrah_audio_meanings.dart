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

  // ───────────── ধাপ ২: ইহরামের পোশাক পরা ─────────────

  static const _s2d1 = UmrahAudioMeaning(
    arabic: 'بِسْمِ اللهِ وَبِاللهِ. اللَّهُمَّ اجْعَلْهُ لِي نُورًا وَطَهُورًا وَحِرْزًا وَأَمْنًا مِنْ كُلِّ خَوْفٍ، وَشِفَاءً مِنْ كُلِّ دَاءٍ وَسُقْمٍ. اللَّهُمَّ طَهِّرْنِي، وَطَهِّرْ لِي قَلْبِي، وَاشْرَحْ لِي صَدْرِي، وَأَجْرِ عَلَى لِسَانِي مَحَبَّتَكَ وَمِدْحَتَكَ وَالثَّنَاءَ عَلَيْكَ؛ فَإِنَّهُ لَا قُوَّةَ لِي إِلَّا بِكَ، وَقَدْ عَلِمْتُ أَنَّ قِوَامَ دِينِي التَّسْلِيمُ لِأَمْرِكَ وَالِاتِّبَاعُ لِسُنَّةِ نَبِيِّكَ، صَلَوَاتُكَ عَلَيْهِ وَآلِهِ',
    bn: 'আল্লাহর নামে এবং আল্লাহর সাহায্যে। হে আল্লাহ, এই গোসলকে আমার জন্য নূর, পবিত্রতা, সুরক্ষা, সব ভয় থেকে নিরাপত্তা এবং সব রোগ ও অসুস্থতা থেকে আরোগ্য বানিয়ে দিন। হে আল্লাহ, আমাকে পবিত্র করুন, আমার অন্তরকে পবিত্র করুন, আমার বক্ষ প্রশস্ত করে দিন এবং আমার জিহ্বায় আপনার ভালোবাসা, প্রশংসা ও গুণগান জারি করে দিন। কারণ আপনি ছাড়া আমার কোনো শক্তি নেই। আমি জানি, আমার দ্বীনের ভিত্তি হলো আপনার নির্দেশের সামনে আত্মসমর্পণ এবং আপনার নবীর সুন্নাহর অনুসরণ; তাঁর ও তাঁর পরিবারের ওপর আপনার রহমত বর্ষিত হোক।',
    en: "In the name of Allah and with Allah's help. O Allah, make this bath a light and purification for me, a protection and security from every fear, and a cure for every illness and ailment. O Allah, purify me and my heart, expand my chest, and let my tongue express love, praise, and gratitude to You. I have no strength except through You, and I know that the foundation of my religion is submission to Your command and following the practice of Your Prophet; may Your blessings be upon him and his family.",
  );

  static const _s2d2 = UmrahAudioMeaning(
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي رَزَقَنِي مَا أُوَارِي بِهِ عَوْرَتِي، وَأُؤَدِّي فِيهِ فَرْضِي، وَأَعْبُدُ فِيهِ رَبِّي، وَأَنْتَهِي فِيهِ إِلَى مَا أَمَرَنِي. الْحَمْدُ لِلَّهِ الَّذِي قَصَدْتُهُ فَبَلَّغَنِي، وَأَرَدْتُهُ فَأَعَانَنِي وَقَبِلَنِي وَلَمْ يَقْطَعْ بِي، وَوَجْهَهُ أَرَدْتُ فَسَلَّمَنِي؛ فَهُوَ حِصْنِي وَكَهْفِي وَحِرْزِي وَظَهْرِي وَمَلَاذِي وَرَجَائِي وَمَنْجَايَ وَذُخْرِي وَعُدَّتِي فِي شِدَّتِي وَرَخَائِي',
    bn: 'সব প্রশংসা আল্লাহর, যিনি আমাকে এমন পোশাক দান করেছেন যা দিয়ে আমি আমার লজ্জাস্থান ঢাকি, আমার ফরজ আদায় করি, আমার রবের ইবাদত করি এবং তিনি আমাকে যা আদেশ করেছেন তার ওপর স্থির থাকি। সব প্রশংসা আল্লাহর, আমি তাঁর দিকে মনোনিবেশ করেছি, তিনি আমাকে (গন্তব্যে) পৌঁছে দিয়েছেন; আমি তাঁকে চেয়েছি, তিনি আমাকে সাহায্য করেছেন, কবুল করেছেন এবং আমাকে পরিত্যাগ করেননি; আমি তাঁর সন্তুষ্টি চেয়েছি, তিনি আমাকে নিরাপদ রেখেছেন। তিনিই আমার দুর্গ, আশ্রয়স্থল, সুরক্ষা, অবলম্বন, ঠাঁই, আশা, মুক্তির উপায়, সঞ্চয় এবং কষ্ট ও স্বাচ্ছন্দ্যে আমার সম্বল।',
    en: 'All praise belongs to Allah, who provided me with clothing by which I cover myself, perform my obligations, worship my Lord, and carry out what He commanded me. All praise belongs to Allah: I sought Him and He enabled me to reach my destination; I desired Him and He helped and accepted me without abandoning me; I sought His countenance and He granted me safety. He is my fortress, refuge, protection, support, shelter, hope, salvation, reserve, and provision in hardship and ease.',
  );

  static const _s2d3 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ أَنْ تَجْعَلَنِي مِمَّنِ اسْتَجَابَ لَكَ، وَآمَنَ بِوَعْدِكَ، وَاتَّبَعَ أَمْرَكَ؛ فَإِنِّي عَبْدُكَ وَفِي قَبْضَتِكَ، لَا أُوقَى إِلَّا مَا وَقَيْتَ، وَلَا آخُذُ إِلَّا مَا أَعْطَيْتَ. وَقَدْ ذَكَرْتَ الْحَجَّ، فَأَسْأَلُكَ أَنْ تَعْزِمَ لِي عَلَيْهِ عَلَى كِتَابِكَ وَسُنَّةِ نَبِيِّكَ، صَلَوَاتُكَ عَلَيْهِ وَآلِهِ، وَأَنْ تُقَوِّيَنِي عَلَى مَا ضَعُفْتُ عَنْهُ، وَتُسَلِّمَ مِنِّي مَنَاسِكِي فِي يُسْرٍ مِنْكَ وَعَافِيَةٍ، وَاجْعَلْنِي مِنْ وَفْدِكَ الَّذِينَ رَضِيتَهُمْ وَارْتَضَيْتَهُمْ وَسَمَّيْتَهُمْ وَكَتَبْتَهُمْ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে প্রার্থনা করি, আমাকে তাদের অন্তর্ভুক্ত করুন যারা আপনার ডাকে সাড়া দিয়েছে, আপনার প্রতিশ্রুতিতে বিশ্বাস করেছে এবং আপনার নির্দেশ অনুসরণ করেছে। কারণ আমি আপনার বান্দা এবং আপনার মুঠোয়; আপনি যা থেকে রক্ষা করেন কেবল তা থেকেই আমি রক্ষা পাই, আর আপনি যা দেন কেবল তাই আমি পাই। আপনি হজের কথা উল্লেখ করেছেন, তাই আমি প্রার্থনা করি, আপনার কিতাব ও আপনার নবীর সুন্নাহ অনুযায়ী তা পালনের দৃঢ় সংকল্প আমাকে দান করুন; তাঁর ও তাঁর পরিবারের ওপর আপনার রহমত বর্ষিত হোক। আমি যেখানে দুর্বল, সেখানে আমাকে শক্তি দিন, আপনার পক্ষ থেকে সহজতা ও নিরাপত্তার সঙ্গে আমার হজের কার্যাবলি কবুল করুন এবং আমাকে আপনার সেই প্রতিনিধিদলের অন্তর্ভুক্ত করুন, যাদের আপনি পছন্দ করেছেন, সন্তুষ্ট হয়েছেন, নাম রেখেছেন ও লিখে নিয়েছেন।',
    en: 'O Allah, include me among those who respond to Your call, believe Your promise, and follow Your command. I am Your servant and under Your authority; I am protected only when You protect me, and I receive only what You grant. You have mentioned Hajj, so I ask You to make me resolute in performing it according to Your Book and the practice of Your Prophet—may Your blessings be upon him and his family. Strengthen me where I am weak, accept my rites from me with ease and well-being, and include me among the delegation whom You have accepted, chosen, named, and recorded.',
  );

  static const _s2d4 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي خَرَجْتُ مِنْ شُقَّةٍ بَعِيدَةٍ، وَأَنْفَقْتُ مَالِي ابْتِغَاءَ مَرْضَاتِكَ. اللَّهُمَّ فَتَمِّمْ لِي حَجَّتِي وَعُمْرَتِي',
    bn: 'হে আল্লাহ, আমি দূর-দূরান্ত থেকে বের হয়েছি এবং আপনার সন্তুষ্টি লাভের আশায় আমার সম্পদ ব্যয় করেছি। হে আল্লাহ, আমার হজ ও ওমরাহ পূর্ণ করে দিন।',
    en: 'O Allah, I have travelled from far away and spent my wealth seeking Your pleasure. O Allah, complete my Hajj and Umrah for me.',
  );

  static const _s2d5 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أُرِيدُ التَّمَتُّعَ بِالْعُمْرَةِ إِلَى الْحَجِّ عَلَى كِتَابِكَ وَسُنَّةِ نَبِيِّكَ، صَلَوَاتُكَ عَلَيْهِ وَآلِهِ. فَإِنْ عَرَضَ لِي عَارِضٌ يَحْبِسُنِي، فَحَلَّنِي حَيْثُ حَبَسْتَنِي لِقَدَرِكَ الَّذِي قَدَّرْتَ عَلَيَّ',
    bn: 'হে আল্লাহ, আমি আপনার কিতাব ও আপনার নবীর সুন্নাহ অনুযায়ী হজ পর্যন্ত ওমরাহর মাধ্যমে উপকৃত হতে (তামাত্তু করতে) চাই; তাঁর ও তাঁর পরিবারের ওপর আপনার রহমত বর্ষিত হোক। যদি আমার সামনে কোনো বাধা আসে যা আমাকে আটকে দেয়, তবে আপনি আমার জন্য যে তাকদির নির্ধারণ করেছেন তার কারণে যেখানে আমাকে আটকে দেবেন, সেখানেই আমাকে (ইহরাম থেকে) মুক্ত করে দিন।',
    en: 'O Allah, I intend to perform Umrah followed by Hajj in accordance with Your Book and the practice of Your Prophet—may Your blessings be upon him and his family. If an impediment prevents me, release me where Your decree causes me to stop.',
  );

  static const _s2d6 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنْ لَمْ تَكُنْ حَجَّةً فَعُمْرَةً. أُحْرِمُ لَكَ شَعْرِي وَبَشَرِي وَلَحْمِي وَدَمِي وَعِظَامِي وَمُخِّي وَعَصَبِي مِنَ النِّسَاءِ وَالثِّيَابِ وَالطِّيبِ، أَبْتَغِي بِذَلِكَ وَجْهَكَ وَالدَّارَ الْآخِرَةَ',
    bn: 'হে আল্লাহ, যদি তা হজ না হয়, তবে ওমরাহ হোক। আপনার জন্য আমি আমার চুল, চামড়া, গোশত, রক্ত, হাড়, মজ্জা ও স্নায়ুকে নারী (সহবাস), (সেলাই করা) পোশাক ও সুগন্ধি থেকে ইহরামের নিষেধাজ্ঞার অধীনে রাখলাম; এর মাধ্যমে আমি আপনার সন্তুষ্টি ও আখিরাত কামনা করি।',
    en: 'O Allah, if it is not to be Hajj, then let it be Umrah. For Your sake, I place my hair, skin, flesh, blood, bones, marrow, nerves, marital relations, clothing, and perfume under the restrictions of Ihram, seeking Your countenance and the Hereafter.',
  );

  // ───────────── ধাপ ৩: মীকাতে ইহরামে প্রবেশ ─────────────

  static const _s3d1 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أُرِيدُ الْعُمْرَةَ، فَيَسِّرْهَا لِي وَتَقَبَّلْهَا مِنِّي',
    bn: 'হে আল্লাহ, আমি ওমরাহ করার ইচ্ছা করছি। আপনি তা আমার জন্য সহজ করে দিন এবং আমার পক্ষ থেকে কবুল করুন।',
    en: 'O Allah, I intend to perform Umrah. Make it easy for me and accept it from me.',
  );

  static const _s3d2 = UmrahAudioMeaning(
    arabic: 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
    bn: 'আমি হাজির, হে আল্লাহ, আমি হাজির। আমি হাজির, আপনার কোনো শরিক নেই, আমি হাজির। নিশ্চয়ই সমস্ত প্রশংসা, নিয়ামত ও রাজত্ব আপনারই। আপনার কোনো শরিক নেই।',
    en: 'Here I am, O Allah, here I am. Here I am; You have no partner, here I am. All praise, grace, and sovereignty belong to You. You have no partner.',
  );

  // ───────────── ধাপ ৪: হারামে প্রবেশ ─────────────

  static const _s4d1 = UmrahAudioMeaning(
    arabic: 'أَعُوذُ بِاللهِ الْعَظِيمِ، وَبِوَجْهِهِ الْكَرِيمِ، وَسُلْطَانِهِ الْقَدِيمِ، مِنَ الشَّيْطَانِ الرَّجِيمِ',
    bn: 'আমি মহান আল্লাহর কাছে, তাঁর সম্মানিত সত্তার কাছে এবং তাঁর চিরন্তন কর্তৃত্বের কাছে বিতাড়িত শয়তান থেকে আশ্রয় চাই।',
    en: 'I seek refuge in Allah the Magnificent, in His noble countenance, and in His eternal authority from Satan the accursed.',
  );

  static const _s4d2 = UmrahAudioMeaning(
    arabic: 'بِسْمِ اللهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللهِ، اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    bn: 'আল্লাহর নামে (প্রবেশ করছি), আল্লাহর রাসূলের ওপর দরূদ ও সালাম বর্ষিত হোক। হে আল্লাহ, আমার জন্য আপনার রহমতের দরজাসমূহ খুলে দিন।',
    en: 'In the name of Allah, and blessings and peace be upon the Messenger of Allah. O Allah, open for me the gates of Your mercy.',
  );

  static const _s4d3 = UmrahAudioMeaning(
    arabic: 'اللهُ أَكْبَرُ - اللهُ أَكْبَرُ - لَا إِلَهَ إِلَّا اللهُ',
    bn: 'আল্লাহ সবচেয়ে মহান। আল্লাহ সবচেয়ে মহান। আল্লাহ ছাড়া কোনো ইলাহ (উপাস্য) নেই।',
    en: 'Allah is The Greatest. Allah is The Greatest. There is no God except Allah.',
  );

  // ───────────── ধাপ ৫: তাওয়াফের ৭ চক্কর — রাউন্ড ১ ─────────────

  static const _s5r1d1 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا اكْشِفْ عَنَّا الْعَذَابَ إِنَّا مُؤْمِنُونَ',
    bn: 'হে আমাদের রব, আমাদের থেকে আযাব দূর করে দিন; নিশ্চয়ই আমরা ঈমানদার।',
    en: 'Our Lord! Relieve us of the torment, for we do really believe.',
  );

  static const _s5r1d2 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ',
    bn: 'হে আমাদের রব, আমাদের এবং ঈমানে আমাদের অগ্রগামী ভাইদের ক্ষমা করুন, আর মুমিনদের প্রতি আমাদের অন্তরে কোনো বিদ্বেষ রাখবেন না। হে আমাদের রব, নিশ্চয়ই আপনি পরম দয়ালু, অতি দয়াময়।',
    en: 'Our Lord, forgive us and our brothers who preceded us in faith, and do not place in our hearts any resentment toward those who believe. Our Lord, You are truly Most Kind and Most Merciful.',
  );

  static const _s5r1d3 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا عَلَيْكَ تَوَكَّلْنَا وَإِلَيْكَ أَنَبْنَا وَإِلَيْكَ الْمَصِيرُ',
    bn: 'হে আমাদের রব, আমরা আপনার ওপরই ভরসা করেছি, আপনারই অভিমুখী হয়েছি এবং আপনার কাছেই (আমাদের) প্রত্যাবর্তন।',
    en: 'Our Lord, upon You we have relied, and to You we have returned, and to You is the destination.',
  );

  static const _s5r1d4 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلَّذِينَ كَفَرُوا وَاغْفِرْ لَنَا رَبَّنَا إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ',
    bn: 'হে আমাদের রব, আমাদেরকে কাফিরদের জন্য পরীক্ষার পাত্র বানাবেন না এবং আমাদের ক্ষমা করুন। হে আমাদের রব, নিশ্চয়ই আপনি পরাক্রমশালী, প্রজ্ঞাময়।',
    en: 'Our Lord, make us not [objects of] torment for the disbelievers and forgive us, our Lord. Indeed, it is You who is the Exalted in Might, the Wise.',
  );

  static const _s5r1d5 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَاغْفِرْ لَنَا إِنَّكَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    bn: 'হে আমাদের রব, আমাদের জন্য আমাদের নূরকে পূর্ণ করে দিন এবং আমাদের ক্ষমা করুন। নিশ্চয়ই আপনি সব কিছুর ওপর ক্ষমতাবান।',
    en: 'Our Lord! Perfect our light for us and forgive us our sins, for verily You have power over all things.',
  );

  static const _s5r1d6 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    bn: 'হে আমাদের রব, আমাদেরকে দুনিয়াতে কল্যাণ দিন, আখিরাতেও কল্যাণ দিন এবং আমাদেরকে জাহান্নামের আযাব থেকে রক্ষা করুন।',
    en: 'Our Lord, give us in this world (that which is) good and in the Hereafter (that which is) good and protect us from the punishment of the Fire',
  );

  static const _s5r1d7 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَاقَةِ وَمَوَاقِفِ الْخِزْيِ فِي الدُّنْيَا وَالْآخِرَةِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে কুফর, দারিদ্র্য এবং দুনিয়া ও আখিরাতের লাঞ্ছনার স্থানসমূহ থেকে আশ্রয় চাই।',
    en: 'O Allah, I take refuge in You from disbelief, poverty and from any humiliation in this world and the next',
  );

  static const _s5r1d8 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ قَنِّعْنِي بِمَا رَزَقْتَنِي، وَبَارِكْ لِي فِيهِ، وَاخْلُفْ عَلَيَّ كُلَّ غَائِبَةٍ لِي بِخَيْرٍ',
    bn: 'হে আল্লাহ, আপনি আমাকে যা রিজিক দিয়েছেন তাতে আমাকে তৃপ্ত রাখুন, তাতে আমার জন্য বরকত দিন এবং আমার প্রতিটি অনুপস্থিত বা হারানো জিনিসের বিনিময়ে উত্তম কিছু দান করুন।',
    en: 'O Allah, make me content with what You have provided, bless it for me, and replace every absent or lost thing of mine with something better.',
  );

  static const _s5r1d9 = UmrahAudioMeaning(
    arabic: 'بِسْمِ اللهِ وَاللهُ أَكْبَرُ',
    bn: 'আল্লাহর নামে (শুরু করছি) এবং আল্লাহ সবচেয়ে মহান।',
    en: 'In the name of Allah and Allah is the Greatest',
  );

  // ───────────── ধাপ ৫: তাওয়াফের ৭ চক্কর — রাউন্ড ২ ─────────────
  // (৪–৭ নম্বর দোয়া রাউন্ড ১-এর ৬–৯ নম্বরের হুবহু একই, তাই সেগুলোই ব্যবহার হয়েছে)

  static const _s5r2d1 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
    bn: 'হে আমাদের রব, আপনার পক্ষ থেকে আমাদের রহমত দান করুন এবং আমাদের কাজকর্মে সঠিক পথনির্দেশনার ব্যবস্থা করে দিন।',
    en: 'Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance',
  );

  static const _s5r2d2 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا إِنَّكَ تَعْلَمُ مَا نُخْفِي وَمَا نُعْلِنُ وَمَا يَخْفَى عَلَى اللهِ مِنْ شَيْءٍ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ',
    bn: 'হে আমাদের রব, আমরা যা গোপন করি এবং যা প্রকাশ করি, নিশ্চয়ই আপনি তা জানেন। আসমান ও জমিনের কোনো কিছুই আল্লাহর কাছে গোপন নেই।',
    en: 'Our Lord! You truly know all that we may hide [in our hearts] as well as all that we bring into the open, for nothing whatever, be it on earth or in heaven, remains hidden from Allah',
  );

  static const _s5r2d3 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    bn: 'হে আমাদের রব, আমাদের স্ত্রী ও সন্তানদের পক্ষ থেকে আমাদের চোখের শীতলতা দান করুন এবং আমাদেরকে মুত্তাকীদের জন্য আদর্শ নেতা বানিয়ে দিন।',
    en: 'Our Lord, grant us from among our wives and offspring comfort to our eyes and make us an example for the righteous.',
  );

  // ───────────── ধাপ ৫: তাওয়াফের ৭ চক্কর — রাউন্ড ৩ ─────────────
  // (৪–৭ নম্বর দোয়া রাউন্ড ১-এর ৬–৯ নম্বরের হুবহু একই; ফাইল sec64 এই রাউন্ডে নেই)

  static const _s5r3d1 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ',
    bn: 'হে আমাদের রব, আপনি আমাদের হিদায়াত দেওয়ার পর আমাদের অন্তরকে বক্র করে দেবেন না এবং আপনার পক্ষ থেকে আমাদের রহমত দান করুন। নিশ্চয়ই আপনি মহান দাতা।',
    en: 'Our Lord! Let not our hearts deviate from the truth after You have guided us, and bestow upon us mercy from Your grace. Verily You are the Giver of bounties without measure',
  );

  static const _s5r3d2 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    bn: 'হে আমাদের রব, আমরা নিজেদের ওপর জুলুম করেছি। আপনি যদি আমাদের ক্ষমা না করেন এবং আমাদের প্রতি দয়া না করেন, তবে আমরা অবশ্যই ক্ষতিগ্রস্তদের অন্তর্ভুক্ত হব।',
    en: 'Our Lord! We have sinned against ourselves, and unless You grant us forgiveness and bestow Your mercy upon us, we shall most certainly be lost!',
  );

  static const _s5r3d3 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا لَا تَجْعَلْنَا مَعَ الْقَوْمِ الظَّالِمِينَ',
    bn: 'হে আমাদের রব, আমাদেরকে জালিম সম্প্রদায়ের সঙ্গী করবেন না।',
    en: 'Our Lord, do not place us with the wrongdoing people',
  );

  // ───────────── ধাপ ৫: তাওয়াফের ৭ চক্কর — রাউন্ড ৪ ─────────────
  // (৫–৮ নম্বর দোয়া রাউন্ড ১-এর ৬–৯ নম্বরের হুবহু একই)

  static const _s5r4d1 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
    bn: 'হে আমাদের রব, আমরা যদি ভুলে যাই কিংবা ভুল করি, তবে আমাদের পাকড়াও করবেন না। হে আমাদের রব, আমাদের পূর্ববর্তীদের ওপর যেমন বোঝা চাপিয়েছিলেন, তেমন বোঝা আমাদের ওপর চাপাবেন না। হে আমাদের রব, যে বোঝা বহনের সামর্থ্য আমাদের নেই, তা আমাদের ওপর চাপাবেন না। আমাদের মার্জনা করুন, আমাদের ক্ষমা করুন এবং আমাদের প্রতি দয়া করুন। আপনিই আমাদের অভিভাবক; অতএব কাফির সম্প্রদায়ের বিরুদ্ধে আমাদের সাহায্য করুন।',
    en: 'Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people',
  );

  static const _s5r4d2 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
    bn: 'হে আমাদের রব, আমাদের গুনাহসমূহ এবং আমাদের কাজকর্মে সীমালঙ্ঘন ক্ষমা করুন, আমাদের পা দৃঢ় রাখুন এবং কাফির সম্প্রদায়ের বিরুদ্ধে আমাদের সাহায্য করুন।',
    // দ্রষ্টব্য: অ্যাপের স্ক্রিনশটে এই আরবির নিচে "pour patience upon us..." (সূরা বাকারা ২:২৫০) লেখা ছিল,
    // যা এই আরবির (সূরা আলে ইমরান ৩:১৪৭) অনুবাদ নয়। এখানে আরবির সঠিক ইংরেজি অর্থ দেওয়া হয়েছে।
    en: 'Our Lord, forgive us our sins and our excesses in our affairs, make our feet firm, and grant us victory over the disbelieving people.',
  );

  static const _s5r4d3 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ',
    bn: 'হে আমাদের রব, আমাদের গুনাহসমূহ ক্ষমা করুন, আমাদের মন্দ কাজগুলো মুছে দিন এবং নেককারদের সঙ্গে আমাদের মৃত্যু দিন।',
    en: 'Our Lord! Forgive us our sins and efface our bad deeds and take our souls in the company of the righteous.',
  );

  static const _s5r4d4 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا وَآتِنَا مَا وَعَدْتَنَا عَلَى رُسُلِكَ وَلَا تُخْزِنَا يَوْمَ الْقِيَامَةِ إِنَّكَ لَا تُخْلِفُ الْمِيعَادَ',
    bn: 'হে আমাদের রব, আপনি আপনার রাসূলদের মাধ্যমে আমাদের যা দেওয়ার প্রতিশ্রুতি দিয়েছেন তা আমাদের দান করুন এবং কিয়ামতের দিন আমাদের লাঞ্ছিত করবেন না। নিশ্চয়ই আপনি প্রতিশ্রুতি ভঙ্গ করেন না।',
    en: 'Our Lord! And grant us that which you have promised to us by Your messengers and save us from shame on the Day of Judgement. Verily You never fail to fulfill Your promise.',
  );

  // ───────────── ধাপ ৫: তাওয়াফের ৭ চক্কর — রাউন্ড ৫ ─────────────
  // (৪–৭ নম্বর দোয়া রাউন্ড ১-এর ৬–৯ নম্বরের হুবহু একই)

  static const _s5r5d1 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
    bn: 'হে আমাদের রব, যেদিন হিসাব কায়েম হবে সেদিন আমাকে, আমার পিতামাতাকে এবং মুমিনদের ক্ষমা করে দিন।',
    en: 'Our Lord! Forgive me and my parents and the believers on the Day when the reckoning will take place',
  );

  static const _s5r5d2 = UmrahAudioMeaning(
    arabic: 'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَنْ دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ وَلَا تَزِدِ الظَّالِمِينَ إِلَّا تَبَارًا',
    bn: 'হে আমার রব, আমাকে, আমার পিতামাতাকে, যে মুমিন অবস্থায় আমার ঘরে প্রবেশ করে তাকে এবং সব মুমিন নারী-পুরুষকে ক্ষমা করুন। আর জালিমদের ধ্বংস ছাড়া আর কিছুই বাড়িয়ে দেবেন না।',
    en: 'My Lord! forgive me and my parents and him who enters my house believing, and the believing men and the believing women; and do not increase the unjust in aught but destruction!',
  );

  static const _s5r5d3 = UmrahAudioMeaning(
    arabic: 'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَى وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ وَأَصْلِحْ لِي فِي ذُرِّيَّتِي إِنِّي تُبْتُ إِلَيْكَ وَإِنِّي مِنَ الْمُسْلِمِينَ',
    bn: 'হে আমার রব, আপনি আমাকে ও আমার পিতামাতাকে যে নিয়ামত দান করেছেন তার শুকরিয়া আদায় করার এবং আপনার পছন্দনীয় সৎকর্ম করার তাওফিক দিন। আমার জন্য আমার সন্তানদের সৎ বানিয়ে দিন। নিশ্চয়ই আমি আপনার কাছে তাওবা করলাম এবং আমি মুসলিমদের অন্তর্ভুক্ত।',
    en: 'My Lord, enable me to be grateful for Your favor which You have bestowed upon me and upon my parents and to work righteousness of which You will approve and make righteous for me my offspring. Indeed, I have repented to You, and indeed, I am of the Muslims',
  );

  // ───────────── ধাপ ৫: তাওয়াফের ৭ চক্কর — রাউন্ড ৬ ─────────────
  // (৬–৯ নম্বর দোয়া রাউন্ড ১-এর ৬–৯ নম্বরের হুবহু একই)

  static const _s5r6d1 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    bn: 'হে আমাদের রব, আমাদেরকে দুনিয়াতে কল্যাণ দিন, আখিরাতেও কল্যাণ দিন এবং আমাদেরকে জাহান্নামের আযাব থেকে রক্ষা করুন।',
    en: 'Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire',
  );

  static const _s5r6d2 = UmrahAudioMeaning(
    arabic: 'أَنِّي مَسَّنِيَ الضُّرُّ وَأَنْتَ أَرْحَمُ الرَّاحِمِينَ',
    bn: 'নিশ্চয়ই আমাকে দুঃখ-কষ্ট স্পর্শ করেছে, আর আপনি দয়াবানদের মধ্যে সর্বশ্রেষ্ঠ দয়াবান।',
    en: 'Verily, distress has seized me, and You are the Most Merciful of all those who show mercy',
  );

  static const _s5r6d3 = UmrahAudioMeaning(
    arabic: 'رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ الشَّيَاطِينِ',
    bn: 'হে আমার রব, আমি শয়তানদের প্ররোচনা থেকে আপনার কাছে আশ্রয় চাই।',
    en: 'My Lord! I seek refuge in You from the temptations of the devils',
  );

  static const _s5r6d4 = UmrahAudioMeaning(
    arabic: 'وَأَعُوذُ بِكَ رَبِّ أَنْ يَحْضُرُونِ',
    bn: 'হে আমার রব, তারা আমার কাছে উপস্থিত হওয়া থেকেও আমি আপনার কাছে আশ্রয় চাই।',
    en: 'I seek refuge with you, Lord, so that they may not come near me',
  );

  static const _s5r6d5 = UmrahAudioMeaning(
    arabic: 'رَبِّ قَدْ آتَيْتَنِي مِنَ الْمُلْكِ وَعَلَّمْتَنِي مِنْ تَأْوِيلِ الْأَحَادِيثِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ أَنْتَ وَلِيِّي فِي الدُّنْيَا وَالْآخِرَةِ تَوَفَّنِي مُسْلِمًا وَأَلْحِقْنِي بِالصَّالِحِينَ',
    bn: 'হে আমার রব, আপনি আমাকে রাজত্ব দান করেছেন এবং স্বপ্নের ব্যাখ্যা শিক্ষা দিয়েছেন। হে আসমান ও জমিনের স্রষ্টা, দুনিয়া ও আখিরাতে আপনিই আমার অভিভাবক। মুসলিম অবস্থায় আমার মৃত্যু দিন এবং আমাকে সৎকর্মশীলদের সঙ্গে মিলিত করুন।',
    en: 'My Lord, You have given me authority and taught me something of the interpretation of dreams. O Originator of the heavens and earth, You are my Protector in this world and in the Hereafter. Cause me to die as a Muslim [submitting to You], and join me with the righteous.',
  );

  // ───────────── ধাপ ৫: তাওয়াফের ৭ চক্কর — রাউন্ড ৭ ─────────────
  // (৫–৮ নম্বর দোয়া রাউন্ড ১-এর ৬–৯ নম্বরের হুবহু একই)

  static const _s5r7d1 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا، وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ وَارْحَمْنِي إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
    bn: 'হে আল্লাহ, আমি নিজের ওপর অনেক জুলুম করেছি, আর আপনি ছাড়া গুনাহ ক্ষমা করার কেউ নেই। তাই আপনার পক্ষ থেকে আমাকে ক্ষমা করুন এবং আমার প্রতি দয়া করুন। নিশ্চয়ই আপনি অতি ক্ষমাশীল, পরম দয়ালু।',
    en: 'O Allah, I have greatly wronged myself and no one forgives sins but You. So, grant me forgiveness and have mercy on me. Surely, you are Forgiving, Merciful',
  );

  static const _s5r7d2 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ، دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ وَآخِرَهُ، وَعَلَانِيَتَهُ وَسِرَّهُ',
    bn: 'হে আল্লাহ, আমার সব গুনাহ ক্ষমা করে দিন, ছোট ও বড়, প্রথম ও শেষ, প্রকাশ্য ও গোপন।',
    en: 'O Allah, forgive me all my sins, great and small, the first and the last, those that are apparent and those that are hidden',
  );

  static const _s5r7d3 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ اغْفِرْ لِي، وَارْحَمْنِي، وَاهْدِنِي، وَاجْبُرْنِي، وَعَافِنِي، وَارْزُقْنِي، وَارْفَعْنِي',
    bn: 'হে আল্লাহ, আমাকে ক্ষমা করুন, আমার প্রতি দয়া করুন, আমাকে হিদায়াত দিন, আমার ঘাটতি পূরণ করে আমাকে সামলে নিন, আমাকে নিরাপদে ও সুস্থ রাখুন, আমাকে রিজিক দিন এবং আমাকে উচ্চ মর্যাদা দিন।',
    en: 'O Allah forgive me, have mercy on me, guide me, support me, protect me, provide for me and elevate me.',
  );

  static const _s5r7d4 = UmrahAudioMeaning(
    arabic: 'رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِنْ ذُرِّيَّتِنَا أُمَّةً مُسْلِمَةً لَكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    bn: 'হে আমাদের রব, আমাদের দুজনকে আপনার অনুগত বানিয়ে দিন এবং আমাদের বংশধরদের মধ্য থেকে আপনার অনুগত একটি জাতি তৈরি করুন। আমাদেরকে ইবাদতের নিয়ম-পদ্ধতি দেখিয়ে দিন এবং আমাদের তাওবা কবুল করুন। নিশ্চয়ই আপনি তাওবা কবুলকারী, পরম দয়ালু।',
    en: 'Our Lord! Make us submissive to You and make out of our descendants a community that submits itself to You, and show us the ways of Your worship, and turn to us in mercy. You are Much-Relenting, Most Compassionate',
  );

  // ───────────── ধাপ ৭: তাওয়াফ শেষে ৩৭টি দোয়া ─────────────
  // ফাইল: sec103–sec112 (দোয়া ১–১০) এবং sec114–sec140 (দোয়া ১১–৩৭); sec113 নেই

  static const _s7d1 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আমার দ্বীন, দুনিয়া, পরিবার ও সম্পদের ব্যাপারে ক্ষমা ও নিরাপত্তা (আফিয়াত) চাই।',
    en: 'O Allah, I ask You for pardon and well-being in my religion, my worldly life, my family, and my wealth.',
  );

  static const _s7d2 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي',
    bn: 'হে আল্লাহ, আমার দোষত্রুটি ঢেকে দিন এবং আমার ভয়ভীতিকে নিরাপত্তায় বদলে দিন। হে আল্লাহ, আমাকে হেফাজত করুন আমার সামনে থেকে, পেছন থেকে, ডান দিক থেকে, বাম দিক থেকে ও ওপর থেকে। আর আমি আপনার মহত্ত্বের আশ্রয় চাই, নিচ থেকে হঠাৎ আক্রান্ত হওয়া থেকে।',
    en: 'O Allah, conceal my faults and calm my fears. O Allah, protect me from in front of me, from behind me, on my right, on my left, and from above me. I seek refuge in Your greatness from being unexpectedly harmed from beneath me.',
  );

  static const _s7d3 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ',
    bn: 'হে আল্লাহ, আমার শরীরে সুস্থতা দিন। হে আল্লাহ, আমার শ্রবণশক্তিতে সুস্থতা দিন। হে আল্লাহ, আমার দৃষ্টিশক্তিতে সুস্থতা দিন। আপনি ছাড়া কোনো ইলাহ নেই।',
    en: 'O Allah, grant health to my body. O Allah, preserve my hearing. O Allah, preserve my sight. There is no deity except You.',
  );

  static const _s7d4 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে কুফর ও দারিদ্র্য থেকে আশ্রয় চাই এবং কবরের আযাব থেকে আশ্রয় চাই। আপনি ছাড়া কোনো ইলাহ নেই।',
    en: 'O Allah, I seek refuge in You from disbelief and poverty, and I seek refuge in You from the punishment of the grave. There is no deity except You.',
  );

  static const _s7d5 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    bn: 'হে আল্লাহ, আপনিই আমার রব, আপনি ছাড়া কোনো ইলাহ নেই। আপনি আমাকে সৃষ্টি করেছেন এবং আমি আপনার বান্দা। আমি যথাসাধ্য আপনার অঙ্গীকার ও প্রতিশ্রুতির ওপর আছি। আমি যা করেছি তার অনিষ্ট থেকে আপনার কাছে আশ্রয় চাই। আমার ওপর আপনার নিয়ামতের স্বীকৃতি দিচ্ছি এবং আমার গুনাহের স্বীকারোক্তি দিচ্ছি। অতএব আমাকে ক্ষমা করুন, কারণ আপনি ছাড়া গুনাহ ক্ষমা করার কেউ নেই।',
    en: 'O Allah, You are my Lord; there is no deity except You. You created me and I am Your servant. I uphold Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge Your favor upon me and I acknowledge my sin, so forgive me, for no one forgives sins except You.',
  );

  static const _s7d6 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে দুশ্চিন্তা ও দুঃখ থেকে আশ্রয় চাই; অক্ষমতা ও অলসতা থেকে, কৃপণতা ও ভীরুতা থেকে আশ্রয় চাই; এবং ঋণের বোঝা ও মানুষের দমন-পীড়ন থেকে আশ্রয় চাই।',
    en: 'O Allah! I seek refuge in You from worry and sorrow. I seek refuge in You from impotence and sloth, from stinginess and cowardice, and I seek refuge in You from the burden of debt and from being humbled by men',
  );

  static const _s7d7 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ اجْعَلْ أَوَّلَ هَذَا الْيَوْمِ صَلَاحًا، وَأَوْسَطَهُ فَلَاحًا، وَآخِرَهُ نَجَاحًا، وَأَسْأَلُكَ خَيْرَيِ الدُّنْيَا وَالْآخِرَةِ يَا أَرْحَمَ الرَّاحِمِينَ',
    bn: 'হে আল্লাহ, এই দিনের শুরুকে কল্যাণময়, মধ্যভাগকে সফল এবং শেষভাগকে সার্থক করে দিন। হে পরম দয়ালুদের মধ্যে সর্বশ্রেষ্ঠ দয়ালু, আমি আপনার কাছে দুনিয়া ও আখিরাতের কল্যাণ চাই।',
    en: 'O Allah! Make the beginning of this day good, the middle prosperous, and the end successful. I ask You to grant me the good of this world and of the Hereafter, O Most Merciful of all Who shows us Mercy!',
  );

  static const _s7d8 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الرِّضَا بَعْدَ الْقَضَاءِ، وَبَرْدَ الْعَيْشِ بَعْدَ الْمَوْتِ، وَلَذَّةَ النَّظَرِ إِلَى وَجْهِكَ الْكَرِيمِ، وَالشَّوْقَ إِلَى لِقَائِكَ، فِي غَيْرِ ضَرَّاءَ مُضِرَّةٍ، وَلَا فِتْنَةٍ مُضِلَّةٍ، وَأَعُوذُ بِكَ أَنْ أَظْلِمَ أَوْ أُظْلَمَ، أَوْ أَعْتَدِيَ أَوْ يُعْتَدَى عَلَيَّ، أَوْ أَكْتَسِبَ خَطِيئَةً أَوْ ذَنْبًا لَا تَغْفِرُهُ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই: আপনার সিদ্ধান্তের পর সন্তুষ্টি, মৃত্যুর পর জীবনের শীতলতা, আপনার সম্মানিত চেহারার দিকে তাকানোর স্বাদ এবং আপনার সাক্ষাতের আগ্রহ, কোনো ক্ষতিকর বিপদ বা পথভ্রষ্টকারী ফিতনা ছাড়া। আমি আপনার কাছে আশ্রয় চাই জুলুম করা বা জুলুমের শিকার হওয়া থেকে, সীমালঙ্ঘন করা বা সীমালঙ্ঘনের শিকার হওয়া থেকে, এবং এমন ভুল বা গুনাহ অর্জন করা থেকে যা আপনি ক্ষমা করবেন না।',
    en: 'O Allah, I ask You for contentment after Your decree, the pleasantness of life after death, the delight of looking at Your noble Face, and the longing to meet You, without harmful adversity or a misleading trial. I seek refuge in You from wronging others or being wronged, from transgressing or being transgressed against, and from committing an error or sin that You do not forgive.',
  );

  static const _s7d9 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ أَنْ أُرَدَّ إِلَى أَرْذَلِ الْعُمُرِ. اللَّهُمَّ اهْدِنِي لِأَحْسَنِ الْأَعْمَالِ وَأَحْسَنِ الْأَخْلَاقِ، لَا يَهْدِي لِأَحْسَنِهَا إِلَّا أَنْتَ، وَاصْرِفْ عَنِّي سَيِّئَهَا، لَا يَصْرِفُ عَنِّي سَيِّئَهَا إِلَّا أَنْتَ. اللَّهُمَّ أَصْلِحْ لِي دِينِي، وَوَسِّعْ لِي فِي دَارِي، وَبَارِكْ لِي فِي رِزْقِي',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই বার্ধক্যের চরম দুর্বলতায় ফিরে যাওয়া থেকে। হে আল্লাহ, আমাকে সর্বোত্তম আমল ও সর্বোত্তম চরিত্রের পথ দেখান; আপনি ছাড়া কেউ সর্বোত্তমের পথ দেখায় না। আর আমার থেকে মন্দ আমল ও মন্দ চরিত্র দূরে সরিয়ে দিন; আপনি ছাড়া কেউ তা দূর করতে পারে না। হে আল্লাহ, আমার দ্বীনকে সংশোধন করে দিন, আমার বাসস্থানে প্রশস্ততা দিন এবং আমার রিজিকে বরকত দিন।',
    en: 'O Allah! I seek refuge in You from the feebleness of old age. O Allah! Guide me to the best of deeds and the best of morals, as none can guide to the best except You, and save me from bad deeds, as none can save me from what is bad except You. O Allah! Strengthen my faith, expand my living space and bless me in my livelihood',
  );

  static const _s7d10 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْقَسْوَةِ وَالْغَفْلَةِ وَالذِّلَّةِ وَالْمَسْكَنَةِ، وَأَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفُسُوقِ وَالشِّقَاقِ وَالسُّمْعَةِ وَالرِّيَاءِ، وَأَعُوذُ بِكَ مِنَ الصَّمَمِ وَالْبَكَمِ وَالْجُنُونِ وَالْجُذَامِ وَسَيِّئِ الْأَسْقَامِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই অন্তরের কঠোরতা, উদাসীনতা, লাঞ্ছনা ও দীনতা থেকে। আমি আপনার কাছে আশ্রয় চাই কুফর, পাপাচার, বিভেদ, খ্যাতিলোভ ও লোক-দেখানো আমল থেকে। আমি আপনার কাছে আশ্রয় চাই বধিরতা, বোবাত্ব, পাগলামি, কুষ্ঠরোগ ও মারাত্মক ব্যাধি থেকে।',
    en: 'O Allah, I seek refuge in You from hardness of heart, heedlessness, humiliation, and destitution. I seek refuge in You from disbelief, wickedness, discord, seeking reputation, and showing off. I seek refuge in You from deafness, muteness, madness, leprosy, and serious illnesses.',
  );

  static const _s7d11 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عِلْمٍ لَا يَنْفَعُ، وَقَلْبٍ لَا يَخْشَعُ، وَنَفْسٍ لَا تَشْبَعُ، وَدَعْوَةٍ لَا يُسْتَجَابُ لَهَا',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই এমন জ্ঞান থেকে যা উপকার করে না, এমন অন্তর থেকে যা বিনয়ী হয় না, এমন মন থেকে যা তৃপ্ত হয় না এবং এমন দোয়া থেকে যা কবুল হয় না।',
    en: 'O Allah, I seek refuge in You from knowledge that does not benefit, a heart that is not humble, a soul that is never satisfied, and a supplication that is not answered.',
  );

  static const _s7d12 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ شَرِّ مَا عَمِلْتُ، وَمِنْ شَرِّ مَا لَمْ أَعْمَلْ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا عَلِمْتُ، وَمِنْ شَرِّ مَا لَمْ أَعْلَمْ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই আমার করা কাজের অনিষ্ট থেকে এবং যা করিনি তার অনিষ্ট থেকে; আমি যা জানি তার অনিষ্ট থেকে এবং যা জানি না তার অনিষ্ট থেকে।',
    en: 'O Allah! I seek refuge in You from the evil of what I did and from the evil of what I did not do; from the evil of what I know and from the evil of what I did not know',
  );

  static const _s7d13 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ زَوَالِ نِعْمَتِكَ، وَتَحَوُّلِ عَافِيَتِكَ، وَفُجَاءَةِ نِقْمَتِكَ، وَجَمِيعِ سَخَطِكَ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই আপনার নিয়ামত চলে যাওয়া, আপনার দেওয়া নিরাপত্তা বদলে যাওয়া, আপনার আকস্মিক শাস্তি এবং আপনার সব ধরনের অসন্তুষ্টি থেকে।',
    en: 'O Allah! I seek refuge in You from a decline in Your favor, from a change in Your protection, from Your sudden punishment and all Your displeasure',
  );

  static const _s7d14 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَدْمِ وَالتَّرَدِّي، وَمِنَ الْغَرَقِ وَالْحَرَقِ وَالْهَرَمِ، وَأَعُوذُ بِكَ مِنْ أَنْ يَتَخَبَّطَنِيَ الشَّيْطَانُ عِنْدَ الْمَوْتِ، وَأَعُوذُ بِكَ مِنْ أَنْ أَمُوتَ لَدِيغًا، وَأَعُوذُ بِكَ مِنْ طَمَعٍ يَهْدِي إِلَى طَبَعٍ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ مُنْكَرَاتِ الْأَخْلَاقِ وَالْأَعْمَالِ وَالْأَهْوَاءِ وَالْأَدْوَاءِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ، وَقَهْرِ الْعَدُوِّ، وَشَمَاتَةِ الْأَعْدَاءِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই চাপা পড়া ও উঁচু থেকে পড়ে যাওয়া থেকে, ডুবে যাওয়া, পুড়ে যাওয়া ও চরম বার্ধক্য থেকে। আমি আপনার কাছে আশ্রয় চাই মৃত্যুর সময় শয়তান আমাকে বিভ্রান্ত করা থেকে, বিষাক্ত দংশনে মারা যাওয়া থেকে এবং এমন লোভ থেকে যা লাঞ্ছনার দিকে নিয়ে যায়। হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই মন্দ চরিত্র, মন্দ আমল, কুপ্রবৃত্তি ও রোগব্যাধি থেকে; এবং ঋণের চাপ, শত্রুর দমন ও শত্রুদের উপহাস থেকে।',
    en: 'O Allah, I seek refuge in You from being crushed by a collapse or falling from a height, from drowning, burning, and senility. I seek refuge in You from Satan confusing me at the time of death, from dying of a venomous bite, and from greed that leads to disgraceful conduct. O Allah, I seek refuge in You from reprehensible character, deeds, whims, and diseases; from overwhelming debt, the domination of an enemy, and the gloating of enemies.',
  );

  static const _s7d15 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ أَصْلِحْ لِي دِينِيَ الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِيَ الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الْحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، وَاجْعَلِ الْمَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ',
    bn: 'হে আল্লাহ, আমার দ্বীনকে সংশোধন করে দিন, যা আমার সব কাজের রক্ষাকবচ। আমার দুনিয়াকে সংশোধন করুন, যেখানে আমার জীবিকা। আমার আখিরাতকে সংশোধন করুন, যেখানে আমার প্রত্যাবর্তন। জীবনকে আমার জন্য সব কল্যাণে বৃদ্ধির কারণ বানান এবং মৃত্যুকে সব অনিষ্ট থেকে আমার জন্য শান্তি বানান।',
    en: 'O Allah! Strengthen my religion, which is my fortress, make this world a better place of sojourn for me, and grant me a good life in the Hereafter which will be my abode. Make my life increase in all goodness and my death a rest from all evil',
  );

  static const _s7d16 = UmrahAudioMeaning(
    arabic: 'رَبِّ أَعِنِّي وَلَا تُعِنْ عَلَيَّ، وَانْصُرْنِي وَلَا تَنْصُرْ عَلَيَّ، وَاهْدِنِي وَيَسِّرِ الْهُدَى لِي',
    bn: 'হে আমার রব, আমাকে সাহায্য করুন, আমার বিরুদ্ধে কাউকে সাহায্য করবেন না; আমাকে বিজয় দিন, আমার বিরুদ্ধে কাউকে বিজয়ী করবেন না; আমাকে হিদায়াত দিন এবং হিদায়াতের পথ আমার জন্য সহজ করে দিন।',
    en: 'O Allah! Support me and help me, and do not let others overpower me; guide me and make the following of Your Commands easy for me',
  );

  static const _s7d17 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ اجْعَلْنِي لَكَ ذَكَّارًا، لَكَ شَكَّارًا، لَكَ مِطْوَاعًا، إِلَيْكَ مُخْبِتًا، لَكَ أَوَّاهًا مُنِيبًا، رَبِّ تَقَبَّلْ تَوْبَتِي، وَاغْسِلْ حَوْبَتِي، وَأَجِبْ دَعْوَتِي، وَثَبِّتْ حُجَّتِي، وَاهْدِ قَلْبِي، وَسَدِّدْ لِسَانِي، وَاسْلُلْ سَخِيمَةَ صَدْرِي',
    bn: 'হে আল্লাহ, আমাকে আপনার অধিক জিকিরকারী, অধিক কৃতজ্ঞ, অধিক অনুগত, বিনয়ী এবং অনুতপ্ত ও প্রত্যাবর্তনকারী বানিয়ে দিন। হে আমার রব, আমার তাওবা কবুল করুন, আমার গুনাহ ধুয়ে দিন, আমার দোয়া কবুল করুন, আমার যুক্তি দৃঢ় করুন, আমার অন্তরকে হিদায়াত দিন, আমার জবানকে সঠিক রাখুন এবং আমার অন্তর থেকে বিদ্বেষ দূর করে দিন।',
    en: 'O Allah! Make me grateful to You, mindful of You, full of fear toward You, devoted to the obedience of You, humble before You, earnest in supplication, and penitent. My Lord, accept my repentance, wash away my sins, answer my supplication, establish my veracity, guide my heart, make my tongue truthful, and remove all ill-feeling from my heart',
  );

  static const _s7d18 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الثَّبَاتَ فِي الْأَمْرِ، وَالْعَزِيمَةَ عَلَى الرُّشْدِ، وَأَسْأَلُكَ شُكْرَ نِعْمَتِكَ وَحُسْنَ عِبَادَتِكَ، وَأَسْأَلُكَ قَلْبًا سَلِيمًا، وَلِسَانًا صَادِقًا، وَأَسْأَلُكَ مِنْ خَيْرِ مَا تَعْلَمُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا تَعْلَمُ، وَأَسْتَغْفِرُكَ مِمَّا تَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে সব কাজে দৃঢ়তা এবং সঠিক পথে অবিচল সংকল্প চাই। আমি আপনার নিয়ামতের শুকরিয়া ও উত্তমরূপে আপনার ইবাদত করার তাওফিক চাই। আমি আপনার কাছে সুস্থ অন্তর ও সত্যবাদী জবান চাই। আপনার জানা সব কল্যাণ আমি চাই, আপনার জানা সব অনিষ্ট থেকে আশ্রয় চাই এবং আপনার জানা সব ভুলের জন্য ক্ষমা চাই। আপনিই অদৃশ্য সম্পর্কে সম্যক জ্ঞাত।',
    en: 'O Allah, I ask You for steadfastness in all matters and determination upon right guidance. I ask You to make me grateful for Your favor and excellent in worshipping You, and to grant me a sound heart and truthful tongue. I ask You for the good that You know, seek refuge in You from the evil that You know, and ask Your forgiveness for what You know. You are the Knower of the unseen.',
  );

  static const _s7d19 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ أَلْهِمْنِي رُشْدِي، وَقِنِي شَرَّ نَفْسِي. اللَّهُمَّ إِنِّي أَسْأَلُكَ فِعْلَ الْخَيْرَاتِ، وَتَرْكَ الْمُنْكَرَاتِ، وَحُبَّ الْمَسَاكِينِ، وَأَنْ تَغْفِرَ لِي وَتَرْحَمَنِي، وَإِذَا أَرَدْتَ بِعِبَادِكَ فِتْنَةً فَتَوَفَّنِي إِلَيْكَ غَيْرَ مَفْتُونٍ',
    bn: 'হে আল্লাহ, আমাকে সঠিক পথের বুঝ দান করুন এবং আমার নফসের অনিষ্ট থেকে রক্ষা করুন। হে আল্লাহ, আমি আপনার কাছে চাই ভালো কাজ করার, মন্দ কাজ ছেড়ে দেওয়ার এবং মিসকিনদের ভালোবাসার তাওফিক; আর আপনি আমাকে ক্ষমা করুন ও দয়া করুন। আপনি যখন আপনার বান্দাদের কোনো ফিতনায় ফেলতে চান, তখন আমাকে ফিতনায় না পড়া অবস্থায় আপনার কাছে তুলে নিন।',
    en: 'O Allah, inspire me with right guidance and protect me from the evil of my own soul. O Allah, I ask You to enable me to do good, leave wrongdoing, and love the poor, and that You forgive me and have mercy on me. If You decree a trial for Your servants, take me to You without being led astray by it.',
  );

  static const _s7d20 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ حُبَّكَ، وَحُبَّ مَنْ يُحِبُّكَ، وَحُبَّ كُلِّ عَمَلٍ يُقَرِّبُنِي إِلَى حُبِّكَ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আপনার ভালোবাসা চাই, আপনাকে যারা ভালোবাসে তাদের ভালোবাসা চাই এবং এমন প্রতিটি আমলের ভালোবাসা চাই যা আমাকে আপনার ভালোবাসার নিকটবর্তী করে।',
    en: 'O Allah! I ask You for Your love and the love of those who love You, and for the love of every action which will bring me closer to Your love',
  );

  static const _s7d21 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَسْأَلَةِ، وَخَيْرَ الدُّعَاءِ، وَخَيْرَ النَّجَاحِ، وَخَيْرَ الثَّوَابِ، وَثَبِّتْنِي، وَثَقِّلْ مَوَازِينِي، وَحَقِّقْ إِيمَانِي، وَارْفَعْ دَرَجَاتِي، وَتَقَبَّلْ صَلَاتِي، وَاغْفِرْ خَطِيئَاتِي، وَأَسْأَلُكَ الدَّرَجَاتِ الْعُلَى مِنَ الْجَنَّةِ. اللَّهُمَّ إِنِّي أَسْأَلُكَ فَوَاتِحَ الْخَيْرِ، وَخَوَاتِمَهُ، وَجَوَامِعَهُ، وَأَوَّلَهُ، وَآخِرَهُ، وَظَاهِرَهُ، وَبَاطِنَهُ، وَالدَّرَجَاتِ الْعُلَى مِنَ الْجَنَّةِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে সর্বোত্তম প্রার্থনা, সর্বোত্তম দোয়া, সর্বোত্তম সফলতা ও সর্বোত্তম প্রতিদান চাই। আমাকে দৃঢ় রাখুন, আমার আমলের পাল্লা ভারী করুন, আমার ঈমানকে বাস্তব করুন, আমার মর্যাদা উঁচু করুন, আমার নামাজ কবুল করুন এবং আমার ভুলত্রুটি ক্ষমা করুন। আমি আপনার কাছে জান্নাতের সর্বোচ্চ মর্যাদা চাই। হে আল্লাহ, আমি আপনার কাছে কল্যাণের সূচনা, সমাপ্তি, সামগ্রিকতা, প্রথম, শেষ, প্রকাশ্য ও গোপন সবটুকু এবং জান্নাতের সর্বোচ্চ মর্যাদা চাই।',
    en: 'O Allah, I ask You for the best request, the best supplication, the best success, and the best reward. Make me steadfast, make my scale heavy, confirm my faith, raise my ranks, accept my prayer, forgive my sins, and grant me the highest ranks in Paradise. O Allah, I ask You for the beginnings, endings, entirety, first, last, outward, and inward of goodness, and for the highest ranks in Paradise.',
  );

  static const _s7d22 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ أَنْ تَرْفَعَ ذِكْرِي، وَتَضَعَ وِزْرِي، وَتُطَهِّرَ قَلْبِي، وَتُحَصِّنَ فَرْجِي، وَتَغْفِرَ لِي ذَنْبِي، وَأَسْأَلُكَ الدَّرَجَاتِ الْعُلَى مِنَ الْجَنَّةِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই যে আপনি আমার আলোচনা উঁচু করুন, আমার বোঝা নামিয়ে দিন, আমার অন্তর পবিত্র করুন, আমার লজ্জাস্থান হেফাজত করুন, আমার গুনাহ ক্ষমা করুন; আর আমি আপনার কাছে জান্নাতের সর্বোচ্চ মর্যাদা চাই।',
    en: 'O Allah, raise my remembrance, remove my burden, purify my heart, guard my chastity, forgive my sin, and grant me the highest ranks in Paradise.',
  );

  static const _s7d23 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ أَنْ تُبَارِكَ فِي سَمْعِي، وَفِي بَصَرِي، وَفِي رُوحِي، وَفِي خَلْقِي، وَفِي خُلُقِي، وَفِي أَهْلِي، وَفِي مَحْيَايَ، وَفِي مَمَاتِي، وَفِي عَمَلِي، وَتَقَبَّلْ حَسَنَاتِي، وَأَسْأَلُكَ الدَّرَجَاتِ الْعُلَى مِنَ الْجَنَّةِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই যে আপনি আমার শ্রবণ, দৃষ্টি, আত্মা, আকৃতি, চরিত্র, পরিবার, জীবন, মৃত্যু ও আমলে বরকত দিন, আমার নেক আমলগুলো কবুল করুন; আর আমি আপনার কাছে জান্নাতের সর্বোচ্চ মর্যাদা চাই।',
    en: 'O Allah, bless my hearing, my sight, my soul, my physical form, my character, my family, my life, my death, and my deeds. Accept my good deeds, and I ask You for the highest ranks in Paradise.',
  );

  static const _s7d24 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ جَهْدِ الْبَلَاءِ، وَدَرَكِ الشَّقَاءِ، وَسُوءِ الْقَضَاءِ، وَشَمَاتَةِ الْأَعْدَاءِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই কঠিন বিপদ, দুর্ভাগ্যের নাগাল, মন্দ ফয়সালা এবং শত্রুদের উপহাস থেকে।',
    en: 'O Allah! I seek refuge in You against difficulties, calamities, troubles, oppression and the ridicule of enemies.',
  );

  static const _s7d25 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ مُقَلِّبَ الْقُلُوبِ، ثَبِّتْ قَلْبِي عَلَى دِينِكَ. اللَّهُمَّ مُصَرِّفَ الْقُلُوبِ وَالْأَبْصَارِ، صَرِّفْ قُلُوبَنَا عَلَى طَاعَتِكَ',
    bn: 'হে আল্লাহ, হে অন্তরসমূহের পরিবর্তনকারী, আমার অন্তরকে আপনার দ্বীনের ওপর দৃঢ় রাখুন। হে আল্লাহ, হে অন্তর ও দৃষ্টির পরিচালক, আমাদের অন্তরগুলোকে আপনার আনুগত্যের দিকে ফিরিয়ে দিন।',
    en: 'O Allah, Controller of hearts, keep my heart firm upon Your religion. O Allah, Director of hearts and sight, direct our hearts toward obedience to You.',
  );

  static const _s7d26 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ أَحْسِنْ عَاقِبَتَنَا فِي الْأُمُورِ كُلِّهَا، وَأَجِرْنَا مِنْ خِزْيِ الدُّنْيَا وَعَذَابِ الْآخِرَةِ',
    bn: 'হে আল্লাহ, আমাদের সব কাজের পরিণাম উত্তম করে দিন এবং আমাদেরকে দুনিয়ার লাঞ্ছনা ও আখিরাতের আযাব থেকে রক্ষা করুন।',
    en: 'O Allah! Grant us the best of outcomes in all our affairs, and save us from disgrace in this world and from punishment in the Hereafter',
  );

  static const _s7d27 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ اقْسِمْ لَنَا مِنْ خَشْيَتِكَ مَا تَحُولُ بِهِ بَيْنَنَا وَبَيْنَ مَعْصِيَتِكَ، وَمِنْ طَاعَتِكَ مَا تُبَلِّغُنَا بِهِ جَنَّتَكَ، وَمِنَ الْيَقِينِ مَا تُهَوِّنُ بِهِ عَلَيْنَا مَصَائِبَ الدُّنْيَا، وَمَتِّعْنَا بِأَسْمَاعِنَا وَأَبْصَارِنَا وَقُوَّتِنَا مَا أَحْيَيْتَنَا، وَاجْعَلْهَا الْوَارِثَ مِنَّا، وَاجْعَلْ ثَأْرَنَا عَلَى مَنْ ظَلَمَنَا، وَانْصُرْنَا عَلَى مَنْ عَادَانَا، وَلَا تَجْعَلِ الدُّنْيَا أَكْبَرَ هَمِّنَا وَلَا مَبْلَغَ عِلْمِنَا، وَلَا تَجْعَلْ مُصِيبَتَنَا فِي دِينِنَا، وَلَا تُسَلِّطْ عَلَيْنَا بِذُنُوبِنَا مَنْ لَا يَخَافُكَ وَلَا يَرْحَمُنَا',
    bn: 'হে আল্লাহ, আমাদের এমন পরিমাণ আপনার ভয় দান করুন যা আমাদের ও আপনার অবাধ্যতার মাঝে অন্তরায় হবে; এমন আনুগত্য দিন যা আমাদের আপনার জান্নাতে পৌঁছাবে; এবং এমন দৃঢ় বিশ্বাস দিন যা দিয়ে দুনিয়ার বিপদগুলো আমাদের জন্য সহজ করে দেবেন। আমরা যতদিন বেঁচে থাকি, আমাদের শ্রবণ, দৃষ্টি ও শক্তি দিয়ে আমাদের উপকৃত রাখুন এবং এগুলোকে আমাদের উত্তরাধিকারী (শেষ পর্যন্ত অবশিষ্ট) করুন। যে আমাদের ওপর জুলুম করেছে তার ওপর আমাদের ন্যায্য প্রতিশোধের অধিকার দিন এবং যে আমাদের সঙ্গে শত্রুতা করেছে তার বিরুদ্ধে আমাদের সাহায্য করুন। দুনিয়াকে আমাদের সবচেয়ে বড় চিন্তা ও জ্ঞানের শেষ সীমা বানাবেন না, আমাদের দ্বীনের ব্যাপারে আমাদের কোনো বিপদ দেবেন না এবং আমাদের গুনাহের কারণে এমন কাউকে আমাদের ওপর কর্তৃত্ব দেবেন না যে আপনাকে ভয় করে না এবং আমাদের প্রতি দয়া করে না।',
    en: 'O Allah! Grant us such fear of You as will come between us and acts of disobedience to You; such obedience to You as will bring us to Your Garden; and such certainty that the calamities of this world will be made easy for us by You. Let us enjoy our hearing, our sight and our faculties as long as You grant us life, and let it be the last to be taken away from us. Avenge us from those who have wronged us and help us against our enemies. Let no calamity befall our religion; let not worldly affairs be our greatest care or all about which we know; and Let not those who have no fear of You and who do not show mercy toward us rule over us.',
  );

  static const _s7d28 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مُوجِبَاتِ رَحْمَتِكَ، وَعَزَائِمَ مَغْفِرَتِكَ، وَالْغَنِيمَةَ مِنْ كُلِّ بِرٍّ، وَالسَّلَامَةَ مِنْ كُلِّ شَرٍّ، وَالْفَوْزَ بِالْجَنَّةِ، وَالنَّجَاةَ مِنَ النَّارِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই আপনার রহমত লাভের উপায়সমূহ, আপনার ক্ষমার দৃঢ় নিশ্চয়তা, প্রতিটি নেক কাজ থেকে প্রাপ্তি, সব অনিষ্ট থেকে নিরাপত্তা, জান্নাতে সফলতা এবং জাহান্নাম থেকে মুক্তি।',
    en: 'O Allah! I ask You to bestow Your Mercy on me, to Forgive me, to Protect me from every sin, to give me a share of every good, and to Grant me the attainment of the Garden and salvation from the Fire.',
  );

  static const _s7d29 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ لَا تَدَعْ لَنَا ذَنْبًا إِلَّا غَفَرْتَهُ، وَلَا عَيْبًا إِلَّا سَتَرْتَهُ، وَلَا هَمًّا إِلَّا فَرَّجْتَهُ، وَلَا دَيْنًا إِلَّا قَضَيْتَهُ، وَلَا حَاجَةً مِنْ حَوَائِجِ الدُّنْيَا وَالْآخِرَةِ هِيَ لَكَ رِضًا وَلَنَا صَلَاحٌ إِلَّا قَضَيْتَهَا يَا أَرْحَمَ الرَّاحِمِينَ',
    bn: 'হে আল্লাহ, আমাদের কোনো গুনাহ ক্ষমা না করে ছাড়বেন না, কোনো দোষ গোপন না করে ছাড়বেন না, কোনো দুশ্চিন্তা দূর না করে ছাড়বেন না, কোনো ঋণ পরিশোধ না করে ছাড়বেন না এবং দুনিয়া ও আখিরাতের এমন কোনো প্রয়োজন অপূর্ণ রাখবেন না যাতে আপনার সন্তুষ্টি আছে এবং আমাদের কল্যাণ আছে। হে পরম দয়ালু।',
    en: 'O Allah, leave no sin of ours unforgiven, no fault unconcealed, no worry unrelieved, no debt unpaid, and no beneficial need of this world or the Hereafter unfulfilled. O Most Merciful, have mercy on us.',
  );

  static const _s7d30 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ رَحْمَةً مِنْ عِنْدِكَ تَهْدِي بِهَا قَلْبِي، وَتَجْمَعُ بِهَا أَمْرِي، وَتَلُمُّ بِهَا شَعَثِي، وَتَحْفَظُ بِهَا غَائِبِي، وَتَرْفَعُ بِهَا شَاهِدِي، وَتُبَيِّضُ بِهَا وَجْهِي، وَتُزَكِّي بِهَا عَمَلِي، وَتُلْهِمُنِي بِهَا رُشْدِي، وَتَرُدُّ بِهَا الْفِتَنَ عَنِّي، وَتَعْصِمُنِي بِهَا مِنْ كُلِّ سُوءٍ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আপনার পক্ষ থেকে এমন রহমত চাই যার মাধ্যমে আপনি আমার অন্তরকে হিদায়াত দেবেন, আমার কাজগুলো গুছিয়ে দেবেন, আমার বিক্ষিপ্ততা দূর করবেন, আমার অনুপস্থিত বিষয়গুলো হেফাজত করবেন, আমার প্রকাশ্য অবস্থাকে উন্নত করবেন, আমার চেহারা উজ্জ্বল করবেন, আমার আমল পরিশুদ্ধ করবেন, আমাকে সঠিক পথের বুঝ দেবেন, আমার থেকে ফিতনা দূরে সরিয়ে দেবেন এবং সব মন্দ থেকে আমাকে রক্ষা করবেন।',
    en: 'O Allah! I ask for mercy from You by which You will guide my heart, settle my affairs, remove my worries, protect me from what is unseen to me, make my face radiant, purify my deeds, inspire me with wisdom, avert calamities from me, and protect me from every evil',
  );

  static const _s7d31 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْفَوْزَ يَوْمَ الْقَضَاءِ، وَعَيْشَ السُّعَدَاءِ، وَمَنْزِلَ الشُّهَدَاءِ، وَمُرَافَقَةَ الْأَنْبِيَاءِ، وَالنَّصْرَ عَلَى الْأَعْدَاءِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই ফয়সালার দিনে সফলতা, সৌভাগ্যবানদের জীবন, শহীদদের মর্যাদা, নবীদের সঙ্গ এবং শত্রুদের বিরুদ্ধে বিজয়।',
    en: 'O Allah! I ask You for success on the day of Judgement, and a life of happiness, and the rank of martyrs, the companionship of the prophets, and victory over the enemies',
  );

  static const _s7d32 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ صِحَّةً فِي إِيمَانٍ، وَإِيمَانًا فِي حُسْنِ خُلُقٍ، وَنَجَاحًا يَتْبَعُهُ فَلَاحٌ، وَرَحْمَةً مِنْكَ، وَعَافِيَةً وَمَغْفِرَةً وَرِضْوَانًا',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই ঈমানের সুস্থতা (সঠিকতা), উত্তম চরিত্রের সঙ্গে ঈমান, এমন সফলতা যার পর চূড়ান্ত কামিয়াবি আসে, আপনার পক্ষ থেকে রহমত, নিরাপত্তা, ক্ষমা ও সন্তুষ্টি।',
    en: 'O Allah! I ask You for correctness of belief; for a faith which leads to good conduct; for a success which results in eternal felicity, for mercy, health and forgiveness from You, and for your pleasure',
  );

  static const _s7d33 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الصِّحَّةَ وَالْعِفَّةَ، وَحُسْنَ الْخُلُقِ، وَالرِّضَا بِالْقَدَرِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই সুস্থতা, চারিত্রিক পবিত্রতা, উত্তম চরিত্র এবং তাকদিরের প্রতি সন্তুষ্টি।',
    en: 'O Allah! I ask You for health, for integrity, for good character, and that I may be pleased with my portion',
  );

  static const _s7d34 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ كُلِّ دَابَّةٍ أَنْتَ آخِذٌ بِنَاصِيَتِهَا، إِنَّ رَبِّي عَلَى صِرَاطٍ مُسْتَقِيمٍ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে আমার নফসের অনিষ্ট থেকে এবং এমন প্রতিটি প্রাণীর অনিষ্ট থেকে আশ্রয় চাই যার কপালের চুল আপনার হাতে ধরা। নিশ্চয়ই আমার রব সরল পথের ওপর আছেন।',
    en: 'O Allah, I seek refuge in You from the evil of my own soul and from the evil of every creature whose forelock You hold. Indeed, my Lord is upon a straight path.',
  );

  static const _s7d35 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنَّكَ تَسْمَعُ كَلَامِي، وَتَرَى مَكَانِي، وَتَعْلَمُ سِرِّي وَعَلَانِيَتِي، وَلَا يَخْفَى عَلَيْكَ شَيْءٌ مِنْ أَمْرِي، وَأَنَا الْبَائِسُ الْفَقِيرُ، الْمُسْتَغِيثُ الْمُسْتَجِيرُ، وَالْوَجِلُ الْمُشْفِقُ، الْمُقِرُّ الْمُعْتَرِفُ إِلَيْكَ بِذَنْبِهِ، أَسْأَلُكَ مَسْأَلَةَ الْمِسْكِينِ، وَأَدْعُوكَ دُعَاءَ الْخَائِفِ الضَّرِيرِ، دُعَاءَ مَنْ خَضَعَتْ لَكَ رَقَبَتُهُ، وَذَلَّ لَكَ جَسَدُهُ، وَرَغِمَ لَكَ أَنْفُهُ',
    bn: 'হে আল্লাহ, আপনি আমার কথা শোনেন, আমার অবস্থান দেখেন এবং আমার গোপন ও প্রকাশ্য সব জানেন; আমার কোনো বিষয়ই আপনার কাছে গোপন নয়। আমি দুর্দশাগ্রস্ত অভাবী, সাহায্যপ্রার্থী ও আশ্রয়প্রার্থী, ভীত ও শঙ্কিত, নিজের গুনাহ স্বীকারকারী। আমি আপনার কাছে মিসকিনের মতো চাই, আপনাকে ডাকি ভীত ও বিপদগ্রস্ত ব্যক্তির মতো; এমন ব্যক্তির দোয়া যার ঘাড় আপনার সামনে নত হয়েছে, যার শরীর আপনার সামনে হীন হয়েছে এবং যার নাক আপনার সামনে ধুলায় মিশেছে।',
    en: 'O Allah, You hear my words, see my situation, and know what I conceal and what I disclose. Nothing of my affairs is hidden from You. I am the distressed and needy one, seeking help and protection, fearful and apprehensive, acknowledging and confessing my sin to You. I ask You as a destitute person asks, and I call upon You as one who is fearful and afflicted: the supplication of one whose neck has submitted to You, whose body has humbled itself before You, and whose face has been lowered before You.',
  );

  static const _s7d36 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ صِحَّةً فِي إِيمَانِي، وَحُسْنًا فِي خُلُقِي، وَمَغْفِرَةً لِذُنُوبِي، وَرِضْوَانًا مِنْكَ فِي الْآخِرَةِ',
    bn: 'হে আল্লাহ, আমি আপনার কাছে চাই আমার ঈমানের সুস্থতা, আমার চরিত্রের সৌন্দর্য, আমার গুনাহের ক্ষমা এবং আখিরাতে আপনার পক্ষ থেকে সন্তুষ্টি।',
    en: 'O Allah! Grant me soundness of belief, goodness of character, forgiveness of my sins, and Your eternal pleasure in the Hereafter',
  );

  static const _s7d37 = UmrahAudioMeaning(
    arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى سَيِّدِنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ',
    bn: 'হে আল্লাহ, আমাদের নেতা মুহাম্মাদ (সাল্লাল্লাহু আলাইহি ওয়া সাল্লাম) এবং তাঁর সকল পরিবার-পরিজন ও সাহাবীদের ওপর রহমত, শান্তি ও বরকত বর্ষণ করুন।',
    en: 'O Allah, send Your blessings, peace, and grace upon our master Muhammad and upon all his family and Companions.',
  );

  /// ধাপ নম্বর → (ফাইলের sec নম্বর → দোয়া)
  static const Map<int, Map<int, UmrahAudioMeaning>> bySection = {
    1: {14: _d1, 15: _d2, 16: _d3, 19: _d4, 20: _d5},
    2: {22: _s2d1, 23: _s2d2, 27: _s2d3, 28: _s2d4, 29: _s2d5, 30: _s2d6},
    3: {32: _s3d1, 34: _s3d2},
    4: {37: _s4d1, 39: _s4d2, 40: _s4d3},
    5: {
      45: _s5r1d1,
      46: _s5r1d2,
      47: _s5r1d3,
      48: _s5r1d4,
      49: _s5r1d5,
      50: _s5r1d6,
      51: _s5r1d7,
      52: _s5r1d8,
      53: _s5r1d9,
      54: _s5r2d1,
      55: _s5r2d2,
      56: _s5r2d3,
      57: _s5r1d6,
      58: _s5r1d7,
      59: _s5r1d8,
      60: _s5r1d9,
      61: _s5r3d1,
      62: _s5r3d2,
      63: _s5r3d3,
      65: _s5r1d6,
      66: _s5r1d7,
      67: _s5r1d8,
      68: _s5r1d9,
      69: _s5r4d1,
      70: _s5r4d2,
      71: _s5r4d3,
      72: _s5r4d4,
      73: _s5r1d6,
      74: _s5r1d7,
      75: _s5r1d8,
      76: _s5r1d9,
      77: _s5r5d1,
      78: _s5r5d2,
      79: _s5r5d3,
      80: _s5r1d6,
      81: _s5r1d7,
      82: _s5r1d8,
      83: _s5r1d9,
      84: _s5r6d1,
      85: _s5r6d2,
      86: _s5r6d3,
      87: _s5r6d4,
      88: _s5r6d5,
      89: _s5r1d6,
      90: _s5r1d7,
      91: _s5r1d8,
      92: _s5r1d9,
      93: _s5r7d1,
      94: _s5r7d2,
      95: _s5r7d3,
      96: _s5r7d4,
      97: _s5r1d6,
      98: _s5r1d7,
      99: _s5r1d8,
      100: _s5r1d9,
    },
    7: {
      103: _s7d1,
      104: _s7d2,
      105: _s7d3,
      106: _s7d4,
      107: _s7d5,
      108: _s7d6,
      109: _s7d7,
      110: _s7d8,
      111: _s7d9,
      112: _s7d10,
      114: _s7d11,
      115: _s7d12,
      116: _s7d13,
      117: _s7d14,
      118: _s7d15,
      119: _s7d16,
      120: _s7d17,
      121: _s7d18,
      122: _s7d19,
      123: _s7d20,
      124: _s7d21,
      125: _s7d22,
      126: _s7d23,
      127: _s7d24,
      128: _s7d25,
      129: _s7d26,
      130: _s7d27,
      131: _s7d28,
      132: _s7d29,
      133: _s7d30,
      134: _s7d31,
      135: _s7d32,
      136: _s7d33,
      137: _s7d34,
      138: _s7d35,
      139: _s7d36,
      140: _s7d37,
    },
  };

  /// ধাপ নম্বর → ক্রম অনুযায়ী দোয়া (ফাইলের নাম না মিললে এটি কাজ করে)
  /// (ধাপ ৫-এ একাধিক রাউন্ড থাকায় এখানে দেওয়া হয়নি; সেখানে শুধু sec নম্বর দিয়ে মেলে)
  static const Map<int, List<UmrahAudioMeaning>> byStepOrder = {
    1: [_d1, _d2, _d3, _d4, _d5],
    2: [_s2d1, _s2d2, _s2d3, _s2d4, _s2d5, _s2d6],
    3: [_s3d1, _s3d2],
    4: [_s4d1, _s4d2, _s4d3],
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
