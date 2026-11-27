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
