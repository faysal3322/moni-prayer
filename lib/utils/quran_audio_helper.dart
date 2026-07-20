import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'quran_audio_handler.dart';

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

  /// Initializes the audio_service session (once, lazily) and returns the
  /// running handler. Must be awaited before any playback call.
  static Future<QuranPlaybackHandler> _ensureHandler() {
    return _initFuture ??= AudioService.init(
      builder: () => QuranPlaybackHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.moni_prayer.quran_audio',
        androidNotificationChannelName: 'Quran Recitation',
        androidNotificationOngoing: true,
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

  /// Downloads the surah's audio from the CDN and saves it locally.
  /// Does nothing if the file already exists.
  static Future<void> downloadSurah(int sura, String audioUrl) async {
    final file = await _localSurahFile(sura);
    if (await file.exists()) return;

    final response = await http.get(Uri.parse(audioUrl));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes, flush: true);
    } else {
      throw Exception('Download failed (${response.statusCode})');
    }
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
    );
  }

  /// Stops playback and cancels any pending auto-stop watcher.
  static Future<void> stop() async {
    if (_handler == null) return;
    await _handler!.stop();
  }

  static Future<void> pause() async {
    if (_handler == null) return;
    await _handler!.pause();
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
