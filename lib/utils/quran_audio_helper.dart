import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'quran_audio_handler.dart';
import 'quran_prefs.dart';
import 'quran_database_helper.dart';

/// Describes what's currently playing, for the persistent "now playing"
/// banner shown across the whole app (not just inside the Quran screen).
class QuranNowPlaying {
  final int sura;
  final String suraName;
  final int? ayaNumber; // null while Bismillah is being recited
  final bool isPaused;
  const QuranNowPlaying({
    required this.sura,
    required this.suraName,
    required this.ayaNumber,
    this.isPaused = false,
  });

  QuranNowPlaying copyWith({int? ayaNumber, bool? isPaused}) => QuranNowPlaying(
        sura: sura,
        suraName: suraName,
        ayaNumber: ayaNumber ?? this.ayaNumber,
        isPaused: isPaused ?? this.isPaused,
      );
}

/// চলমান full-surah playback সেশনের ধারাবাহিক ইনডেক্স/আয়াত তথ্য —
/// [QuranAudioHelper.activeSession] এর ভ্যালু হিসেবে ব্যবহৃত হয়।
///
/// আগে প্রতিটা SurahDetailScreen নিজের একটা লোকাল `onAyaStart` কলব্যাক
/// দিয়ে playFullSurah শুরু করত, আর সেই কলব্যাকই স্ক্রল/হাইলাইট/ব্যানার
/// সব আপডেট করত। কিন্তু persistent ব্যানারে ট্যাপ করে যখন একটা *নতুন*
/// SurahDetailScreen push হতো (আসল প্লেব্যাক তখনো আগের সেশনেই চলছিল,
/// নতুন playFullSurah কল হতো না), তখন হ্যান্ডলারের `_currentOnAyaStart`
/// এখনো পুরনো (এখন dispose হওয়া) স্ক্রিনের callback-কেই ধরে থাকত —
/// ফলে নতুন স্ক্রিনে স্ক্রল/হাইলাইট কখনো আপডেট হতো না, এবং Play/Pause
/// বাটনে চাপলে নতুন স্ক্রিন ভাবত playback শুরুই হয়নি, তাই ১ নং আয়াত
/// থেকে আবার নতুন সেশন শুরু করে দিত।
///
/// সমাধান: হ্যান্ডলার নিজেই তার "এখন কোন সূরা, কোন ইনডেক্সে আছে" তথ্য
/// একটা গ্লোবাল ValueNotifier-এ রাখে (screen-নির্ভর না করে), প্রতিটা
/// SurahDetailScreen এটা শুনে নিজে থেকেই স্ক্রল/হাইলাইট মেলায়, আর
/// Play/Pause বাটন এই স্টেট দেখেই বোঝে চলমান সেশন resume করতে হবে
/// নাকি নতুন করে শুরু করতে হবে।
class QuranActiveSession {
  final int sura;
  final int ayaIndex; // -1 মানে বিসমিল্লাহ চলছে
  final int ayaNumber; // ayaIndex == -1 হলে অর্থহীন (0)
  final bool isPaused;
  const QuranActiveSession({
    required this.sura,
    required this.ayaIndex,
    required this.ayaNumber,
    required this.isPaused,
  });

  QuranActiveSession copyWith({bool? isPaused}) => QuranActiveSession(
        sura: sura,
        ayaIndex: ayaIndex,
        ayaNumber: ayaNumber,
        isPaused: isPaused ?? this.isPaused,
      );
}

/// Manages Saad al-Ghamdi recitation audio, stored as one gapless mp3 per
/// surah (matches the well-known MuslimPro-style layout, so files placed
/// there manually by the user are recognized automatically):
///
///   <app external files>/Download/Recitations/saad-al-ghamdi/001.mp3
///
/// Individual ayah playback is done by seeking into the surah's mp3 file
/// using timestamp data (quran_audio_segments table) and stopping playback
/// once the ayah's end timestamp is reached — no separate per-ayah files
/// are downloaded.
///
/// Actual playback runs inside a [QuranPlaybackHandler], hosted by
/// audio_service as a real Android foreground service with a media-style
/// notification. That's what keeps recitation playing when the screen locks
/// or the app is backgrounded — a plain in-app player gets killed by the OS
/// as soon as the app leaves the foreground, which is what was happening
/// before this used audio_service.
class QuranAudioHelper {
  static const String _reciterFolder = 'saad-al-ghamdi';
  static Directory? _cachedDir;

  // যোগ করা হয়েছে: আউযুবিল্লাহ ও বিসমিল্লাহর bundled asset path (Saad
  // Al-Ghamdi কণ্ঠে)। এই দুটো mp3 assets/audio/quran/ এ bundle করা আছে
  // (pubspec.yaml-এ assets/audio/ আগে থেকেই wildcard হিসেবে declare করা,
  // তাই আলাদা করে নতুন এন্ট্রি যোগ করার দরকার হয়নি)। এখনো কোনো playback
  // flow-তে এগুলো ব্যবহার করা হচ্ছে না — শুধু bundle ও রেফারেন্সের জন্য
  // প্রস্তুত রাখা হলো, যাতে ভবিষ্যতে সূরা শুরুর আগে "আউযুবিল্লাহ +
  // বিসমিল্লাহ" চালানোর ফিচার লাগলে সহজে এখান থেকেই ব্যবহার করা যায়।
  static const String isti3athaAssetPath = 'assets/audio/quran/isti3atha.mp3';
  static const String bismillahAssetPath = 'assets/audio/quran/bismillah.mp3';


  static QuranPlaybackHandler? _handler;
  static Future<QuranPlaybackHandler>? _initFuture;

  /// অ্যাপের যেকোনো স্ক্রিন থেকে শোনা যায় এমন গ্লোবাল "এখন কী তেলাওয়াত
  /// হচ্ছে" স্টেট। কুরআন স্ক্রিনের বাইরে থাকা অবস্থাতেও একটা ছোট
  /// ব্যানার/মিনি-প্লেয়ার দেখানোর জন্য এটা ব্যবহার হয়, যেটাতে চাপলে সরাসরি
  /// সেই চলমান আয়াতে ফিরে যাওয়া যাবে। প্লেব্যাক বন্ধ/থেমে গেলে এটা `null`
  /// হয়ে যায়, তখন ব্যানারটাও লুকিয়ে যাবে।
  static final ValueNotifier<QuranNowPlaying?> nowPlaying = ValueNotifier(null);

  /// হ্যান্ডলার-লেভেলের গ্লোবাল "এখন কোন সূরা, কোন আয়াত ইনডেক্সে চলছে"
  /// তথ্য — কোনো নির্দিষ্ট SurahDetailScreen-এর callback-এর উপর নির্ভর
  /// করে না, তাই সেই স্ক্রিন dispose হয়ে গেলেও বা persistent ব্যানার
  /// থেকে একটা নতুন SurahDetailScreen push হলেও এই ভ্যালু নির্ভরযোগ্যভাবে
  /// আপডেট থাকে। নতুন করে push হওয়া SurahDetailScreen নিজে থেকেই এটা
  /// শুনে (ValueListenableBuilder দিয়ে) সঠিক আয়াতে স্ক্রল/হাইলাইট করে,
  /// এবং Play/Pause বাটন বুঝতে পারে চলমান সেশন resume করা উচিত নাকি
  /// নতুন সেশন শুরু করা উচিত।
  static final ValueNotifier<QuranActiveSession?> activeSession = ValueNotifier(null);

  /// বিস্তারিত মিনি-প্লেয়ার (progress bar দেখানোর জন্য) থেকে ব্যবহারের
  /// জন্য — বর্তমান audio position/duration স্ট্রিম। হ্যান্ডলার এখনো
  /// initialize না হলে null রিটার্ন করে (তখন progress bar খালি দেখাবে)।
  static Stream<Duration>? get positionStream => _handler?.player.positionStream;
  static Duration? get currentDuration => _handler?.player.duration;
  static Duration get currentPosition => _handler?.player.position ?? Duration.zero;
  static Future<void> seekTo(Duration position) async {
    await _handler?.player.seek(position);
  }

  /// বর্তমান তেলাওয়াতের গতি (1.0 = স্বাভাবিক, 0.75 = স্লো, ইত্যাদি)।
  /// হ্যান্ডলার এখনো initialize না হলে 1.0 রিটার্ন করে।
  static double get currentSpeed => _handler?.player.speed ?? 1.0;

  /// তেলাওয়াতের গতি বদলায় এবং QuranPrefs-এ সেভ করে রাখে, যাতে পরের বার
  /// অ্যাপ খুললেও একই গতি মনে থাকে। হ্যান্ডলার এখনো শুরু না হয়ে থাকলে
  /// (যেমন প্লে করার আগেই স্পিড বদলানো হলো) শুধু prefs-এ সেভ হয়ে যায়,
  /// পরের বার প্লে শুরু হওয়ার সময় [playFullSurah]/[playAya] সেটা প্রয়োগ করে।
  static Future<void> setSpeed(double speed) async {
    await _handler?.player.setSpeed(speed);
    await QuranPrefs.setPlaybackSpeed(speed);
  }

  /// Initializes the audio_service session (once, lazily) and returns the
  /// running handler. Must be awaited before any playback call.
  ///
  /// Requests notification permission first: on Android 13+, the foreground
  /// service that keeps audio playing in the background needs to show a
  /// notification, and without POST_NOTIFICATIONS granted that can prevent
  /// the service (and therefore playback) from starting correctly.
  ///
  /// Also requests "all files access" (MANAGE_EXTERNAL_STORAGE) here, since
  /// that's what lets [_getAudioDir] write to a public folder instead of the
  /// app-specific one that Android deletes automatically on uninstall.
  static Future<QuranPlaybackHandler> _ensureHandler() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await _ensureManageExternalStoragePermission();
    }
    return _initFuture ??= AudioService.init(
      builder: () => QuranPlaybackHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.moni_prayer.quran_audio',
        androidNotificationChannelName: 'Quran Recitation',
        // ক্র্যাশ ফিক্স: আগে এই লাইনটা ছিল না, তাই audio_service ডিফল্টভাবে
        // mipmap/ic_launcher খুঁজত — কিন্তু প্রজেক্টে mipmap ফোল্ডারই ছিল
        // না (কোনো app icon বসানো হয়নি)। ফলে notification বানানোর সময়
        // Android "no valid small icon" ধরে IllegalArgumentException ছুঁড়ে
        // পুরো অ্যাপ ক্র্যাশ করত — এটাই "বিসমিল্লাহ" বলে বন্ধ হয়ে যাওয়ার
        // আসল কারণ (সূরা প্লে শুরু করা মাত্র এই notification তৈরির চেষ্টা
        // হতো)। এখন app icon বসানো হয়েছে বলে এই রেফারেন্স ঠিকভাবে resolve
        // হবে।
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: false,
        // false রাখা জরুরি: true থাকলে pause করার সাথে সাথে Android
        // foreground service বন্ধ হয়ে যায়, এরপর আবার Play/Pause চাপলে
        // handler-এর কমান্ড আর সাড়া দেয় না (UI আটকে যায়, force-close
        // করা লাগে)। false রাখলে pause করলেও service/notification চালু
        // থাকে এবং resume/pause নির্ভরযোগ্যভাবে কাজ করে।
        androidStopForegroundOnPause: false,
      ),
    ).then((handler) => _handler = handler);
  }

  static bool _manageStorageRequested = false;

  /// "সব ফাইলে অ্যাক্সেস" (MANAGE_EXTERNAL_STORAGE) পারমিশন চায় — এই
  /// পারমিশন ছাড়া Android 11+ এ app-specific ফোল্ডারের বাইরে (যেমন
  /// পাবলিক Download/... ) কিছু লেখা যায় না। এই পারমিশনের জন্য একটা
  /// সিস্টেম সেটিংস পেজ খোলে (সাধারণ রানটাইম ডায়ালগ না), তাই একবার
  /// চাওয়ার পর বারবার না চেয়ে মনে রাখা হচ্ছে।
  static Future<void> _ensureManageExternalStoragePermission() async {
    if (_manageStorageRequested) return;
    _manageStorageRequested = true;
    try {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    } catch (_) {
      // পুরনো Android ভার্সনে (যেখানে এই পারমিশনের দরকারই নেই) বা কোনো
      // কারণে request ব্যর্থ হলেও অ্যাপ চলতে থাকবে — _getAudioDir-এর
      // নিজস্ব fallback (app-specific ফোল্ডার) তখন ব্যবহার হবে।
    }
  }

  /// Returns (and creates if needed) the Recitations/saad-al-ghamdi folder.
  ///
  /// এখন ইচ্ছাকৃতভাবে **পাবলিক** স্টোরেজে (app-specific
  /// /Android/data/<package>/... ফোল্ডারে না) রাখা হচ্ছে —
  /// /storage/emulated/0/Music/Recitations/saad-al-ghamdi — কারণ
  /// app-specific ফোল্ডার Android নিজেই অ্যাপ আনইনস্টল করার সময়
  /// স্বয়ংক্রিয়ভাবে মুছে দেয় (এটা অ্যাপের কোনো কোড দিয়ে আটকানো সম্ভব
  /// না), কিন্তু পাবলিক ফোল্ডার আনইনস্টলে অক্ষত থাকে। এর জন্য
  /// MANAGE_EXTERNAL_STORAGE পারমিশন প্রয়োজন (Android 11+), যেটা
  /// [_ensureManageExternalStoragePermission] চেয়ে নেয়। পারমিশন না
  /// পাওয়া গেলে (বা পুরনো Android-এ প্রয়োজন না হলেও লেখা ব্যর্থ হলে)
  /// নিরাপদে আগের app-specific ফোল্ডারেই ফিরে যাওয়া হয়, যাতে audio
  /// চালানো অন্তত বন্ধ না হয়ে যায় — শুধু তখন আনইনস্টলে সেই কপি মুছে
  /// যাবে, যেমনটা আগে হতো।
  static Future<Directory> _getAudioDir() async {
    if (_cachedDir != null) return _cachedDir!;

    Directory? dir;
    if (Platform.isAndroid) {
      try {
        final publicDir = Directory(
          '/storage/emulated/0/Music/Recitations/$_reciterFolder',
        );
        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }
        // লেখা সত্যিই সম্ভব কিনা যাচাই করা হচ্ছে (পারমিশন না থাকলে
        // create() নিজেই ব্যর্থ হতে পারে, বা কিছু ডিভাইসে সাইলেন্টলি
        // ব্যর্থ হয়) — ব্যর্থ হলে exception ধরে নিচের fallback-এ যাওয়া হয়।
        final probe = File('${publicDir.path}/.write_test');
        await probe.writeAsBytes(const [0]);
        await probe.delete();
        dir = publicDir;
      } catch (_) {
        dir = null; // পারমিশন নেই বা লেখা ব্যর্থ — নিচে fallback ব্যবহার হবে
      }
    }

    if (dir == null) {
      // Fallback: app-specific external storage (আগের আচরণ) — এটা
      // permission ছাড়াই সবসময় লেখা যায়, কিন্তু অ্যাপ আনইনস্টল করলে
      // এখানকার ফাইল মুছে যাবে।
      final base = await getExternalStorageDirectory(); // .../Android/data/<pkg>/files
      dir = Directory('${base!.path}/Download/Recitations/$_reciterFolder');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }

    _cachedDir = dir;
    return dir;
  }

  /// Creates the Recitations/saad-al-ghamdi folder immediately (e.g. at app
  /// startup) so it exists on the device even before the user plays or
  /// downloads any audio. This lets the user manually copy recitation files
  /// into it via a file manager right after installing the app.
  ///
  /// Also migrates any surah files already downloaded into the *old*
  /// app-specific folder (from before this update) into the new public
  /// folder, so previously-downloaded surahs don't need re-downloading —
  /// this only runs once per app run and is safe to call multiple times.
  ///
  /// Requests the "all files access" permission first (not lazily inside
  /// [_ensureHandler] anymore) — if that request happened only when
  /// playback started, the very first [_getAudioDir] call (this one, at
  /// app startup) would run before permission was granted, silently fall
  /// back to the app-specific folder, and cache that choice for the rest
  /// of the app's lifetime — so later playback would never actually use
  /// the public, uninstall-safe folder even after the user granted the
  /// permission.
  ///
  /// Safe to call multiple times and safe to ignore failures — folder
  /// creation is a convenience, not something that should block app startup.
  static Future<void> ensureAudioDirExists() async {
    try {
      if (Platform.isAndroid) {
        await _ensureManageExternalStoragePermission();
      }
      await _getAudioDir();
      await _migrateOldDownloadsIfNeeded();
    } catch (_) {
      // Ignore: e.g. storage not ready yet on some devices at first launch.
      // The folder will still be created lazily the first time playback
      // or download is attempted.
    }
  }

  static bool _migrationAttempted = false;

  /// পুরনো app-specific ফোল্ডার (/Android/data/<package>/files/...) থেকে
  /// আগে ডাউনলোড হওয়া সূরার mp3 ফাইলগুলো নতুন পাবলিক ফোল্ডারে কপি করে —
  /// যাতে এই আপডেটের আগে যেসব সূরা ডাউনলোড করা হয়েছিল, সেগুলো আবার নতুন
  /// করে ডাউনলোড করতে না হয়। শুধু তখনই কিছু করে যখন নতুন পাবলিক
  /// ফোল্ডার আসলে ব্যবহার হচ্ছে (অর্থাৎ পারমিশন পাওয়া গেছে) এবং পুরনো
  /// ফোল্ডারে ফাইল আছে যা নতুন ফোল্ডারে এখনো নেই।
  static Future<void> _migrateOldDownloadsIfNeeded() async {
    if (_migrationAttempted) return;
    _migrationAttempted = true;
    if (!Platform.isAndroid) return;

    final newDir = _cachedDir;
    if (newDir == null) return;
    // নতুন ফোল্ডার আসলে পাবলিক পাথে আছে কিনা যাচাই — না থাকলে (যেমন
    // পারমিশন না পাওয়ায় fallback ব্যবহার হচ্ছে) মাইগ্রেট করার কিছু নেই।
    if (!newDir.path.startsWith('/storage/emulated/0/')) return;

    try {
      // পুরনো app-specific ফোল্ডার থেকে মাইগ্রেশন (আগে থেকেই ছিল)
      final base = await getExternalStorageDirectory();
      if (base != null) {
        final oldAppDir = Directory('${base.path}/Download/Recitations/$_reciterFolder');
        await _copyMp3sIfMissing(oldAppDir, newDir);
      }

      // পুরনো পাবলিক Download ফোল্ডার থেকে মাইগ্রেশন (এই আপডেটে যোগ হলো) —
      // আগে অডিও পাবলিক Download/Recitations/... ফোল্ডারে সেভ হতো, এখন
      // থেকে পাবলিক Music/Recitations/... ফোল্ডারে হচ্ছে। আগে যেসব সূরা
      // Download ফোল্ডারে ডাউনলোড করা ছিল, সেগুলো যেন আবার নতুন করে
      // ডাউনলোড করতে না হয়, তাই এখানে কপি করে আনা হচ্ছে।
      final oldPublicDir = Directory(
        '/storage/emulated/0/Download/Recitations/$_reciterFolder',
      );
      await _copyMp3sIfMissing(oldPublicDir, newDir);
    } catch (_) {
      // মাইগ্রেশন সম্পূর্ণ ঐচ্ছিক একটা সুবিধা — ব্যর্থ হলেও অ্যাপ
      // স্বাভাবিকভাবে চলবে, শুধু আগের ডাউনলোডগুলো আবার নতুন করে
      // ডাউনলোড হবে।
    }
  }

  /// [oldDir]-এ থাকা mp3 ফাইলগুলো, যেগুলো এখনো [newDir]-এ নেই (বা ফাঁকা),
  /// সেগুলো কপি করে। একটা ফাইল কপি ব্যর্থ হলেও বাকিগুলোর চেষ্টা চলতে থাকে।
  static Future<void> _copyMp3sIfMissing(Directory oldDir, Directory newDir) async {
    if (!await oldDir.exists()) return;
    await for (final entity in oldDir.list()) {
      if (entity is! File || !entity.path.endsWith('.mp3')) continue;
      final filename = entity.uri.pathSegments.last;
      final newFile = File('${newDir.path}/$filename');
      if (await newFile.exists() && await newFile.length() > 0) continue;
      try {
        await entity.copy(newFile.path);
      } catch (_) {
        // এই একটা ফাইল কপি ব্যর্থ হলেও বাকিগুলো চেষ্টা চালিয়ে যাওয়া হয়;
        // ব্যর্থ হওয়া ফাইলগুলো পরে প্রয়োজন হলে স্বাভাবিকভাবেই আবার
        // ডাউনলোড হয়ে যাবে।
      }
    }
  }

  static String _filenameForSura(int sura) => '${sura.toString().padLeft(3, '0')}.mp3';

  /// True if the surah's audio file already exists locally (downloaded
  /// before, or placed there manually by the user).
  static Future<bool> isSurahDownloaded(int sura) async {
    final dir = await _getAudioDir();
    final file = File('${dir.path}/${_filenameForSura(sura)}');
    return file.exists();
  }

  static Future<File> _localSurahFile(int sura) async {
    final dir = await _getAudioDir();
    return File('${dir.path}/${_filenameForSura(sura)}');
  }

  /// আগের একটা bug-এর কারণে (fixed now) কোনো সূরার ফাইল আংশিক/করাপ্টেড
  /// অবস্থায় ডিস্কে থেকে যেতে পারত এবং কখনো re-download হতো না। এই
  /// ফাংশনটা একটা নির্দিষ্ট সূরার লোকাল ফাইল মুছে দেয়, যাতে পরের বার
  /// play করার সময় সেটা নতুন করে সম্পূর্ণভাবে ডাউনলোড হয়।
  static Future<void> redownloadSurah(int sura) async {
    final file = await _localSurahFile(sura);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// পুরো Recitations ফোল্ডার (সব ডাউনলোড করা সূরার mp3) মুছে দেয়। এটা
  /// একটা "ক্যাশ পরিষ্কার করুন" অপশন হিসেবে সেটিংসে দেখানো যেতে পারে —
  /// পুরনো, সম্ভাব্য-করাপ্টেড ডাউনলোডগুলো থেকে মুক্তি পেতে সবচেয়ে
  /// নিশ্চিত উপায়। পরবর্তী প্লে-এর সময় প্রতিটা সূরা আবার নতুন করে
  /// ডাউনলোড হবে।
  static Future<void> clearAllDownloadedAudio() async {
    final dir = await _getAudioDir();
    if (await dir.exists()) {
      final entries = await dir.list().toList();
      for (final entry in entries) {
        if (entry is File) {
          await entry.delete();
        }
      }
    }
  }

  /// Downloads the surah's audio from the CDN and saves it locally.
  /// Does nothing if a complete file already exists.
  ///
  /// A timeout is applied to the network call: without one, a slow/stalled
  /// connection (e.g. right after auto-continuing into the next surah) can
  /// leave this await hanging forever, which was leaving playback silently
  /// stuck — the loading spinner never resolved and nothing ever played.
  ///
  /// গুরুত্বপূর্ণ: শুধু `file.exists()` চেক করাই যথেষ্ট না। আগে যদি কোনো
  /// ডাউনলোড মাঝপথে বিচ্ছিন্ন হয়ে থাকে (নেটওয়ার্ক ড্রপ, অ্যাপ ব্যাকগ্রাউন্ডে
  /// চলে যাওয়া, ইত্যাদি), তাহলে একটা আংশিক/ছোট mp3 ফাইল ডিস্কে থেকে যেত,
  /// এবং `file.exists()` সবসময় true রিটার্ন করত বলে সেটা আর কখনো নতুন করে
  /// ডাউনলোড হতো না। ফলে প্রতিটা আয়াতের জন্য ডেটাবেজের (পূর্ণ ফাইলের
  /// জন্য বানানো) timestamp সেই ছোট ফাইলের সাথে মিলত না — ফাইলের প্রকৃত
  /// দৈর্ঘ্যের চেয়ে timestamp বেশি হয়ে যেত, তাই প্রতিটা আয়াত (ধারাবাহিকভাবে,
  /// সব সূরাতেই) সময়ের অনেক আগে কেটে যাচ্ছিল/থেমে যাচ্ছিল। এখন ডাউনলোড
  /// হওয়া বাইট সংখ্যা সার্ভারের ঘোষিত Content-Length-এর সাথে মিলিয়ে
  /// দেখা হয়; না মিললে ফাইলটা রাখা হয় না এবং exception ছোড়া হয়, যাতে
  /// পরের বার আবার নতুন করে সম্পূর্ণ ডাউনলোডের চেষ্টা হয়।
  static Future<void> downloadSurah(int sura, String audioUrl) async {
    final file = await _localSurahFile(sura);
    if (await file.exists()) {
      final existingLength = await file.length();
      if (existingLength > 0) return; // already have a non-empty file
      await file.delete(); // zero-byte leftover from a previous failure
    }

    final response = await http
        .get(Uri.parse(audioUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Download failed (${response.statusCode})');
    }

    final expectedLength = response.contentLength;
    final actualLength = response.bodyBytes.length;
    if (expectedLength != null && expectedLength > 0 && actualLength != expectedLength) {
      // অসম্পূর্ণ ডাউনলোড — ফাইলটা সেভ না করে exception ছোড়া হচ্ছে, যাতে
      // ভাঙা ফাইল কখনো ডিস্কে থেকে না যায় (এবং পরের চেষ্টায় আবার পুরো
      // ফাইল নতুন করে ডাউনলোড হওয়ার সুযোগ পায়)।
      throw Exception(
        'Incomplete download for surah $sura: expected ${expectedLength}B, got ${actualLength}B',
      );
    }

    await file.writeAsBytes(response.bodyBytes, flush: true);
  }

  /// Plays a single ayah by seeking into the surah's gapless mp3 and
  /// stopping automatically once the ayah's end timestamp is reached.
  /// Downloads the surah file first if not already present.
  static Future<void> playAya({
    required int sura,
    required String surahAudioUrl,
    required int startMs,
    required int endMs,
    void Function()? onComplete,
  }) async {
    final handler = await _ensureHandler();
    // আগে সেভ করা স্পিড (যদি 1.0 না হয়) প্রয়োগ করা হচ্ছে, যাতে ব্যবহারকারী
    // একবার স্পিড বদলালে তা পরবর্তী প্রতিটা প্লে-তেও বজায় থাকে।
    await handler.player.setSpeed(await QuranPrefs.getPlaybackSpeed());
    final file = await _localSurahFile(sura);
    if (!await file.exists()) {
      await downloadSurah(sura, surahAudioUrl);
    }
    await handler.playAya(
      filePath: file.path,
      startMs: startMs,
      endMs: endMs,
      onComplete: onComplete,
    );
  }

  /// Plays every ayah of a surah back-to-back. Calls [onAyaStart] just
  /// before each ayah begins (so the UI can auto-scroll to it) and
  /// [onSequenceComplete] once the final ayah finishes. Call [stop] to
  /// cancel at any point.
  ///
  /// [segments] must be every row from quran_audio_segments for this surah,
  /// ordered by aya ASC (see QuranDatabaseHelper.getAllSegmentsForSura).
  ///
  /// [suraName] persistent ব্যানারে দেখানোর জন্য (যেমন "Al-Baqara") — এই
  /// প্যারামিটারটা caller (SurahDetailScreen) থেকে একবারই দেওয়া হয়, আর
  /// এই ফাংশন নিজেই তারপর থেকে প্রতিটা আয়াতে [nowPlaying] আপডেট করে
  /// রাখে। আগে এই আপডেট SurahDetailScreen-এর নিজস্ব onAyaStart-এর ভেতরে
  /// হতো — অর্থাৎ ব্যবহারকারী কোরআন স্ক্রিন থেকে অন্য কোথাও চলে গিয়ে
  /// সেই স্ক্রিন dispose হয়ে গেলে (audio ব্যাকগ্রাউন্ডে চলতেই থাকত),
  /// আর কেউ nowPlaying আপডেট করত না — ব্যানারে তাই শেষবার দেখা আয়াত
  /// নম্বরই (যেমন ২) আটকে থাকত, যদিও প্রকৃতপক্ষে আরও অনেক দূর (যেমন ২০)
  /// এগিয়ে গেছে। এখন এই আপডেট হ্যান্ডলার-স্তরে হওয়ায় স্ক্রিন খোলা থাকুক
  /// বা না থাকুক, ব্যানার সবসময় প্রকৃত চলমান আয়াতই দেখাবে।
  static Future<void> playFullSurah({
    required int sura,
    required String suraName,
    required String surahAudioUrl,
    required List<Map<String, dynamic>> segments,
    required void Function(int ayaIndex, int ayaNumber) onAyaStart,
    void Function()? onSequenceComplete,
    int startIndex = 0,
  }) async {
    final handler = await _ensureHandler();
    // আগে সেভ করা স্পিড (যদি 1.0 না হয়) প্রয়োগ করা হচ্ছে, যাতে ব্যবহারকারী
    // একবার স্পিড বদলালে তা পরবর্তী প্রতিটা প্লে-তেও বজায় থাকে।
    await handler.player.setSpeed(await QuranPrefs.getPlaybackSpeed());
    if (segments.isEmpty) return;
    final file = await _localSurahFile(sura);
    if (!await file.exists()) {
      await downloadSurah(sura, surahAudioUrl);
    }
    await handler.playFullSurah(
      filePath: file.path,
      suraNumber: sura,
      suraName: suraName,
      segments: segments,
      // caller-এর নিজস্ব onAyaStart (স্ক্রল/হাইলাইট করার জন্য) কল করার
      // পাশাপাশি গ্লোবাল activeSession ও nowPlaying দুটোই এখানে,
      // হ্যান্ডলার-স্তরেই আপডেট করা হচ্ছে — কোনো নির্দিষ্ট স্ক্রিন বেঁচে
      // আছে কিনা তার উপর নির্ভর না করে।
      onAyaStart: (ayaIndex, ayaNumber) {
        activeSession.value = QuranActiveSession(
          sura: sura,
          ayaIndex: ayaIndex,
          ayaNumber: ayaNumber,
          isPaused: false,
        );
        nowPlaying.value = QuranNowPlaying(
          sura: sura,
          suraName: suraName,
          ayaNumber: ayaIndex >= 0 ? ayaNumber : null,
        );
        // ফিক্স: আগে "সর্বশেষ পঠিত অবস্থান" শুধু স্ক্রিনের ম্যানুয়াল
        // স্ক্রলে (surah_detail_screen.dart) সেভ হতো — কিন্তু পূর্ণ সূরা
        // তেলাওয়াত চলাকালীন স্ক্রল প্রোগ্রাম্যাটিকভাবে হয় (ব্যবহারকারীর
        // হাতে টানা না), তাই সেই স্ক্রল last-read আপডেট করত না। ফলে
        // ব্যবহারকারী স্ক্রিন থেকে বেরিয়ে গেলে (ব্যাকগ্রাউন্ডে তেলাওয়াত
        // চলতে থাকলে) "সর্বশেষ পঠিত" কার্ড পুরনো, ম্যানুয়ালি স্ক্রল করা
        // অবস্থানই দেখাতো — তেলাওয়াত আসলে যতদূর এগিয়ে গেছে তা নয়। এখন
        // এখানেই (হ্যান্ডলার-স্তরে, স্ক্রিন খোলা থাকুক বা না থাকুক)
        // প্রতিটা আয়াত শুরু হওয়ার সাথে সাথে সরাসরি সেভ করা হচ্ছে।
        if (ayaIndex >= 0) {
          QuranPrefs.setLastRead(sura, ayaNumber);
        }
        onAyaStart(ayaIndex, ayaNumber);
      },
      onSequenceComplete: () {
        activeSession.value = null;
        onSequenceComplete?.call();
        // মূল ফিক্স: আগে পরের সূরায় chain করার একমাত্র উপায় ছিল UI
        // screen-এর (SurahDetailScreen) নিজস্ব কলব্যাক, যেটা `mounted`
        // চেক করত। কিন্তু ব্যাকগ্রাউন্ডে সূরা চলতে থাকা অবস্থায় (স্ক্রিন
        // থেকে বেরিয়ে গেলে) সেই widget dispose হয়ে যেত, ফলে "mounted"
        // false থাকায় পরের সূরায় কখনো যেত না — এক সূরা শেষে অডিও চুপচাপ
        // থেমে যেত, ব্যানারেও শেষ আয়াতই দেখাতে থাকত। এখন এখানে,
        // হ্যান্ডলার-স্তরেই (কোনো UI screen বেঁচে আছে কিনা তার উপর
        // নির্ভর না করে) নিজে থেকে পরের সূরা লোড করে চালানো হচ্ছে।
        if (sura < 114) {
          // মাইক্রোটাস্ক শেষে চালানো হচ্ছে যাতে এই কলব্যাকের বাকি অংশ
          // (এবং caller-এর নিজস্ব onSequenceComplete, উপরে) আগে সম্পূর্ণ
          // হয়ে যায়।
          Future.microtask(() => _playNextSurahInChain(sura + 1));
        } else {
          // সূরা ১১৪ (আন-নাস) শেষ — chain করার আর কিছু নেই।
          nowPlaying.value = null;
        }
      },
      startIndex: startIndex,
    );
  }

  /// একটা সূরা শেষ হওয়ার পর, কোনো UI screen বেঁচে আছে কিনা তার ওপর
  /// নির্ভর না করেই পরের সূরা লোড করে অটো-প্লে করে — এটাই ব্যাকগ্রাউন্ড
  /// প্লেব্যাকে chain কাজ করার আসল ভিত্তি। ব্যর্থ হলে (যেমন ডাটাবেজ/অডিও
  /// ফাইল সমস্যা) নিঃশব্দে থেমে যায়, পুরো অ্যাপ ক্র্যাশ করে না।
  static Future<void> _playNextSurahInChain(int nextSura) async {
    try {
      final chapter = await QuranDatabaseHelper.getChapter(nextSura);
      final surahAudio = await QuranDatabaseHelper.getSurahAudio(nextSura);
      final segments = await QuranDatabaseHelper.getAllSegmentsForSura(nextSura);
      if (chapter == null || surahAudio == null || segments.isEmpty) return;
      final suraName = chapter['name_transliteration'] as String? ?? 'Surah $nextSura';
      await playFullSurah(
        sura: nextSura,
        suraName: suraName,
        surahAudioUrl: surahAudio['audio_url'] as String,
        segments: segments,
        // এখানে কোনো নির্দিষ্ট UI callback নেই (হাইলাইট/স্ক্রল আপডেট করার
        // মতো কোনো স্ক্রিন এই মুহূর্তে সক্রিয় নাও থাকতে পারে) — তবে
        // activeSession ও nowPlaying তো playFullSurah নিজেই ওপরে
        // আপডেট করবে, তাই ব্যানার ও পরবর্তীতে খোলা যেকোনো স্ক্রিন ঠিকই
        // সিঙ্ক হয়ে যাবে।
        onAyaStart: (_, __) {},
      );
    } catch (_) {
      // chain থেমে যাক, কিন্তু অ্যাপ বা এই ফাংশনের caller প্রভাবিত না হোক।
    }
  }

  /// [sura] এর জন্য এখন সত্যিই একটা full-surah playback সেশন চলমান/পজড
  /// আছে কিনা — screen-নির্ভর কোনো লোকাল ফ্ল্যাগের বদলে হ্যান্ডলারের
  /// প্রকৃত অবস্থা থেকে সরাসরি জানা যায়। ব্যানার থেকে নতুন push হওয়া
  /// SurahDetailScreen এটা দিয়ে বুঝে নেয় Play বাটনে চাপলে নতুন সেশন
  /// শুরু করতে হবে, নাকি চলমান সেশনকেই resume/pause করতে হবে।
  static bool isSessionActiveFor(int sura) => activeSession.value?.sura == sura;

  /// Stops playback and cancels any pending auto-stop watcher.
  ///
  /// Wrapped with a timeout: if the platform/audio_service call ever hangs
  /// (e.g. the foreground service got killed unexpectedly), this still
  /// returns instead of leaving the UI's await stuck forever — which is
  /// what forced a full app close before.
  static Future<void> stop() async {
    if (_handler == null) return;
    try {
      await _handler!.stop().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Timed out or failed — nothing more we can safely do here; the UI
      // layer's setState still runs so the Play/Pause button stays usable.
    }
    nowPlaying.value = null;
    activeSession.value = null;
  }

  static Future<void> pause() async {
    if (_handler == null) return;
    try {
      await _handler!.pause().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Same reasoning as stop(): never let this hang the UI.
    }
    if (nowPlaying.value != null) {
      nowPlaying.value = nowPlaying.value!.copyWith(isPaused: true);
    }
    if (activeSession.value != null) {
      activeSession.value = activeSession.value!.copyWith(isPaused: true);
    }
  }

  /// পজ করা থেকে আবার চালু করে — নতুন করে শুরু থেকে না বাজিয়ে ঠিক
  /// যেখানে পজ হয়েছিল সেখান থেকেই resume করে।
  static Future<void> resume() async {
    if (_handler == null) return;
    try {
      await _handler!.play().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Same reasoning as stop(): never let this hang the UI.
    }
    if (nowPlaying.value != null) {
      nowPlaying.value = nowPlaying.value!.copyWith(isPaused: false);
    }
    if (activeSession.value != null) {
      activeSession.value = activeSession.value!.copyWith(isPaused: false);
    }
  }

  /// Prev/Next বাটনের জন্য — চলমান সেশনেই দ্রুত নির্দিষ্ট আয়াতে সিক করে,
  /// পুরো audio source আবার লোড করে না বলে প্রায় সাথে সাথে কাজ করে।
  /// হ্যান্ডলার ভেতরে ভেতরে সেই একই (playFullSurah-এ wrap করা) onAyaStart
  /// কলব্যাক আবার কল করে, যা activeSession-ও আপডেট করে দেয় — তাই এখানে
  /// আলাদা করে কিছু করার দরকার নেই।
  static Future<void> seekToIndex(int index) async {
    if (_handler == null) return;
    await _handler!.seekToIndex(index);
  }

  /// Downloads audio for a whole surah (single file) — used for the
  /// "download for offline" option per-surah. Skips if already present.
  static Future<void> downloadFullSurah(
    int sura,
    String audioUrl, {
    void Function()? onDone,
  }) async {
    await downloadSurah(sura, audioUrl);
    onDone?.call();
  }
}
