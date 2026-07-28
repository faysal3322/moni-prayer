import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'quran_audio_handler.dart';

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

  static QuranPlaybackHandler? _handler;
  static Future<QuranPlaybackHandler>? _initFuture;

  /// অ্যাপের যেকোনো স্ক্রিন থেকে শোনা যায় এমন গ্লোবাল "এখন কী তেলাওয়াত
  /// হচ্ছে" স্টেট। কুরআন স্ক্রিনের বাইরে থাকা অবস্থাতেও একটা ছোট
  /// ব্যানার/মিনি-প্লেয়ার দেখানোর জন্য এটা ব্যবহার হয়, যেটাতে চাপলে সরাসরি
  /// সেই চলমান আয়াতে ফিরে যাওয়া যাবে। প্লেব্যাক বন্ধ/থেমে গেলে এটা `null`
  /// হয়ে যায়, তখন ব্যানারটাও লুকিয়ে যাবে।
  static final ValueNotifier<QuranNowPlaying?> nowPlaying = ValueNotifier(null);

  /// Initializes the audio_service session (once, lazily) and returns the
  /// running handler. Must be awaited before any playback call.
  ///
  /// Requests notification permission first: on Android 13+, the foreground
  /// service that keeps audio playing in the background needs to show a
  /// notification, and without POST_NOTIFICATIONS granted that can prevent
  /// the service (and therefore playback) from starting correctly.
  static Future<QuranPlaybackHandler> _ensureHandler() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    return _initFuture ??= AudioService.init(
      builder: () => QuranPlaybackHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.moni_prayer.quran_audio',
        androidNotificationChannelName: 'Quran Recitation',
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

  /// Returns (and creates if needed) the Recitations/saad-al-ghamdi folder.
  static Future<Directory> _getAudioDir() async {
    if (_cachedDir != null) return _cachedDir!;
    final base = await getExternalStorageDirectory(); // .../Android/data/<pkg>/files
    final dir = Directory('${base!.path}/Download/Recitations/$_reciterFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  /// Creates the Recitations/saad-al-ghamdi folder immediately (e.g. at app
  /// startup) so it exists on the device even before the user plays or
  /// downloads any audio. This lets the user manually copy recitation files
  /// into it via a file manager right after installing the app.
  ///
  /// Safe to call multiple times and safe to ignore failures — folder
  /// creation is a convenience, not something that should block app startup.
  static Future<void> ensureAudioDirExists() async {
    try {
      await _getAudioDir();
    } catch (_) {
      // Ignore: e.g. storage not ready yet on some devices at first launch.
      // The folder will still be created lazily the first time playback
      // or download is attempted.
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
  static Future<void> playFullSurah({
    required int sura,
    required String surahAudioUrl,
    required List<Map<String, dynamic>> segments,
    required void Function(int ayaIndex, int ayaNumber) onAyaStart,
    void Function()? onSequenceComplete,
    int startIndex = 0,
  }) async {
    final handler = await _ensureHandler();
    if (segments.isEmpty) return;
    final file = await _localSurahFile(sura);
    if (!await file.exists()) {
      await downloadSurah(sura, surahAudioUrl);
    }
    await handler.playFullSurah(
      filePath: file.path,
      segments: segments,
      onAyaStart: onAyaStart,
      onSequenceComplete: onSequenceComplete,
      startIndex: startIndex,
    );
  }

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
  }

  /// Prev/Next বাটনের জন্য — চলমান সেশনেই দ্রুত নির্দিষ্ট আয়াতে সিক করে,
  /// পুরো audio source আবার লোড করে না বলে প্রায় সাথে সাথে কাজ করে।
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
