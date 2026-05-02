class AppLanguage {
  final String code;
  AppLanguage(this.code);

  bool get isBn => code == 'bn';

  String get appName => 'MONI PRAYER';
  String get bismillah => 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ';

  String prayerCount(String name) =>
      isBn ? "$name'র Prayer Counts" : "$name's Prayer Counts";

  String get sunday => isBn ? 'রবিবার' : 'Sunday';
  String get monday => isBn ? 'সোমবার' : 'Monday';
  String get tuesday => isBn ? 'মঙ্গলবার' : 'Tuesday';
  String get wednesday => isBn ? 'বুধবার' : 'Wednesday';
  String get thursday => isBn ? 'বৃহস্পতিবার' : 'Thursday';
  String get friday => isBn ? 'শুক্রবার' : 'Friday';
  String get saturday => isBn ? 'শনিবার' : 'Saturday';
  String get jummah => isBn ? 'জুম্মা' : 'Jummah';
  String get namazBaki => isBn ? 'নামাজ বাকি' : 'Prayers Pending';
  String get rozaBaki => isBn ? 'রোজা বাকি' : 'Fasts Pending';
  String get fajr => isBn ? 'ফজর' : 'Fajr';
  String get dhuhr => isBn ? 'যোহর' : 'Dhuhr';
  String get asr => isBn ? 'আসর' : 'Asr';
  String get maghrib => isBn ? 'মাগরিব' : 'Maghrib';
  String get isha => isBn ? 'এশা' : 'Isha';
  String get roza => isBn ? 'রোজা' : 'Roza/Sawm';
  String get prayed => isBn ? 'আদায়' : 'Prayed';
  String get missed => isBn ? 'মিস' : 'Missed';
  String get summary => isBn ? 'সারসংক্ষেপ' : 'Summary';
  String get calendar => isBn ? 'ক্যালেন্ডার' : 'Calendar';
  String get home => isBn ? 'হোম' : 'Home';
  String get settings => isBn ? 'সেটিংস' : 'Settings';
  String get prayerTimes => isBn ? 'নামাজের সময়' : 'Prayer Times';
  String get totalMissed => isBn ? 'মোট মিস' : 'Total Missed';
  String get totalPrayed => isBn ? 'মোট আদায়' : 'Total Prayed';
  String get currentPending => isBn ? 'বর্তমানে বাকি' : 'Currently Pending';
  String get allTime => isBn ? 'সব সময়' : 'All Time';
  String get thisYear => isBn ? 'এই বছর' : 'This Year';
  String get thisMonth => isBn ? 'এই মাস' : 'This Month';
  String get namazHisab => isBn ? 'নামাজ হিসাব' : 'Prayer Stats';
  String get rozaHisab => isBn ? 'রোজা হিসাব' : 'Fasting Stats';
  String get language => isBn ? 'ভাষা' : 'Language';
  String get bangla => 'বাংলা';
  String get english => 'English';
  String get userName => isBn ? 'আপনার নাম' : 'Your Name';
  String get save => isBn ? 'সেভ করুন' : 'Save';
  String get backup => isBn ? 'ব্যাকআপ' : 'Backup';
  String get restore => isBn ? 'রিস্টোর' : 'Restore';
  String get backupWarning => isBn
      ? 'রিস্টোর করলে বর্তমান সব ডেটা মুছে যাবে। নিশ্চিত?'
      : 'Restoring will erase all current data. Are you sure?';
  String get confirm => isBn ? 'নিশ্চিত' : 'Confirm';
  String get cancel => isBn ? 'বাতিল' : 'Cancel';
  String get missedNamaz => isBn ? 'মিস হওয়া নামাজ' : 'Missed Prayers';
  String get missedRoza => isBn ? 'মিস হওয়া রোজা' : 'Missed Fasts';
  String get nextPrayer => isBn ? 'পরবর্তী নামাজ' : 'Next Prayer';
  String get wakt => isBn ? 'ওয়াক্ত' : 'prayers';

  String dayName(int weekday) {
    switch (weekday) {
      case DateTime.sunday: return sunday;
      case DateTime.monday: return monday;
      case DateTime.tuesday: return tuesday;
      case DateTime.wednesday: return wednesday;
      case DateTime.thursday: return thursday;
      case DateTime.friday: return friday;
      case DateTime.saturday: return saturday;
      default: return '';
    }
  }

  List<String> get months => isBn
      ? ['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন',
         'জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর']
      : ['January','February','March','April','May','June',
         'July','August','September','October','November','December'];

  String formatDate(DateTime date) {
    if (isBn) {
      return '${_toBanglaNum(date.day)} ${months[date.month - 1]} ${_toBanglaNum(date.year)}';
    }
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _toBanglaNum(int n) {
    const Map<String, String> map = {
      '0':'০','1':'১','2':'২','3':'৩','4':'৪',
      '5':'৫','6':'৬','7':'৭','8':'৮','9':'৯'
    };
    return n.toString().split('').map((c) => map[c] ?? c).join();
  }

  String toLocalNum(int n) => isBn ? _toBanglaNum(n) : n.toString();
}
