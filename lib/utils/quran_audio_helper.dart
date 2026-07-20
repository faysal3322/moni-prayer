import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

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
class QuranAudioHelper {
  static const String _reciterFolder = 'saad-al-ghamdi';
  static Directory? _cachedDir;
  static final AudioPlayer player = AudioPlayer();

  static StreamSubscription<Duration>? _positionSub;
  static int? _currentStopAtMs;
  static VoidCallback? _onAyaComplete;

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
    VoidCallback? onComplete,
  }) async {
    final file = await _localSurahFile(sura);
    if (!await file.exists()) {
      await downloadSurah(sura, surahAudioUrl);
    }

    await _positionSub?.cancel();
    _onAyaComplete = onComplete;
    _currentStopAtMs = endMs;

    await player.stop();
    await player.play(DeviceFileSource(file.path), position: Duration(milliseconds: startMs));

    _positionSub = player.onPositionChanged.listen((pos) {
      if (_currentStopAtMs != null && pos.inMilliseconds >= _currentStopAtMs!) {
        player.pause();
        _positionSub?.cancel();
        _positionSub = null;
        _onAyaComplete?.call();
      }
    });
  }

  /// Stops playback and cancels any pending auto-stop watcher.
  static Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _currentStopAtMs = null;
    await player.stop();
  }

  static Future<void> pause() async {
    await player.pause();
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

typedef VoidCallback = void Function();
