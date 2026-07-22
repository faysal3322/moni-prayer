import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// The AudioHandler that audio_service runs inside its foreground service.
/// This is what keeps Quran recitation playing when the screen turns off or
/// the app is backgrounded — audio_service wraps this in a real Android
/// foreground service + media-style notification (with lock-screen controls),
/// so the OS doesn't kill the audio the way it did with a plain in-app player.
///
/// All actual playback state (position stream, gapless surah seeking, ayah
/// boundary detection) lives here; QuranAudioHelper is a thin static
/// wrapper other screens call into, matching the app's existing call sites.
class QuranPlaybackHandler extends BaseAudioHandler {
  final AudioPlayer player = AudioPlayer();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _completionSub;
  int? _currentStopAtMs;
  void Function()? _onAyaComplete;

  // Each call to playFullSurah gets a fresh session token. If stop() (or a
  // new playFullSurah/playAya call) happens, the token no longer matches, so
  // any in-flight step silently no-ops instead of fighting with whatever
  // plays next.
  int _sequenceToken = 0;

  // পরে prev/next বাটনে দ্রুত সিক করার জন্য বর্তমান সেশনের ফাইল/সেগমেন্ট/
  // কলব্যাক মনে রাখা হয় — এতে পুরো audio source আবার লোড না করেই লাফানো যায়।
  String? _currentFilePath;
  List<Map<String, dynamic>>? _currentSegments;
  void Function(int ayaIndex, int ayaNumber)? _currentOnAyaStart;
  void Function()? _currentOnSequenceComplete;
  int _currentAyaIndex = -1;

  QuranPlaybackHandler() {
    // Surface just_audio's playing/processing state to audio_service so the
    // notification's play/pause icon and lock-screen controls stay in sync.
    player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.play,
          MediaAction.pause,
        },
        playing: player.playing,
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[player.processingState]!,
        updatePosition: player.position,
      ));
    });
  }

  /// Loads [filePath] and starts playback at [startPosition]. Used for both
  /// single-ayah seeks and full-surah playback — the caller decides what to
  /// do with the position stream afterwards.
  Future<void> _loadAndPlay(String filePath, Duration startPosition) async {
    await player.setAudioSource(AudioSource.uri(Uri.file(filePath)));
    await player.seek(startPosition);
    await player.play();
  }

  /// Plays a single ayah by seeking into the surah's gapless mp3 and
  /// stopping automatically once the ayah's end timestamp is reached.
  Future<void> playAya({
    required String filePath,
    required int startMs,
    required int endMs,
    void Function()? onComplete,
  }) async {
    _sequenceToken++; // invalidate any in-flight full-surah sequence
    await _positionSub?.cancel();
    await _completionSub?.cancel();
    _onAyaComplete = onComplete;
    _currentStopAtMs = endMs;

    await _loadAndPlay(filePath, Duration(milliseconds: startMs));

    _positionSub = player.positionStream.listen((pos) {
      if (_currentStopAtMs != null && pos.inMilliseconds >= _currentStopAtMs!) {
        player.pause();
        _positionSub?.cancel();
        _positionSub = null;
        _onAyaComplete?.call();
      }
    });
  }

  /// Plays every ayah of a surah back-to-back from one gapless mp3, calling
  /// [onAyaStart] just before each ayah begins and [onSequenceComplete] once
  /// the final ayah finishes. [segments] must be every row from
  /// quran_audio_segments for this surah, ordered by aya ASC.
  Future<void> playFullSurah({
    required String filePath,
    required List<Map<String, dynamic>> segments,
    required void Function(int ayaIndex, int ayaNumber) onAyaStart,
    void Function()? onSequenceComplete,
    int startIndex = 0,
  }) async {
    if (segments.isEmpty) return;
    // নেগেটিভ বা রেঞ্জের বাইরের ইনডেক্স হলে নিরাপদে শুরু থেকে চালানো হবে।
    final safeStart = (startIndex < 0 || startIndex >= segments.length) ? 0 : startIndex;
    final myToken = ++_sequenceToken;

    await _positionSub?.cancel();
    await _completionSub?.cancel();
    _positionSub = null;
    _currentStopAtMs = null;
    _onAyaComplete = null;

    // পরে দ্রুত seekToIndex() কল করার জন্য এই সেশনের তথ্য মনে রাখা হচ্ছে।
    _currentFilePath = filePath;
    _currentSegments = segments;
    _currentOnAyaStart = onAyaStart;
    _currentOnSequenceComplete = onSequenceComplete;

    // Tracks which ayah index we're currently "in" so the position listener
    // only fires onAyaStart once per boundary crossed.
    int currentIndex = -1;
    void enterIndex(int i) {
      if (i == currentIndex) return;
      currentIndex = i;
      _currentAyaIndex = i;
      final ayaNumber = segments[i]['aya'] as int;
      onAyaStart(i, ayaNumber);
    }

    // একই ফাইল আগে থেকেই লোড থাকলে নতুন করে setAudioSource না করে শুধু
    // seek করলেই চলে — এতে বারবার চালু/থামানোয় দেরি হয় না।
    final sameFileAlreadyLoaded = _currentFilePath == filePath && player.duration != null;
    if (!sameFileAlreadyLoaded) {
      await player.setAudioSource(AudioSource.uri(Uri.file(filePath)));
    }
    await player.seek(Duration(milliseconds: segments[safeStart]['timestamp_from_ms'] as int));
    await player.play();
    if (myToken != _sequenceToken) return; // stopped/superseded while loading
    enterIndex(safeStart);

    _positionSub = player.positionStream.listen((pos) {
      if (myToken != _sequenceToken) {
        _positionSub?.cancel();
        _positionSub = null;
        return;
      }
      final ms = pos.inMilliseconds;
      while (currentIndex + 1 < segments.length &&
          ms >= (segments[currentIndex + 1]['timestamp_from_ms'] as int)) {
        enterIndex(currentIndex + 1);
      }
    });

    _completionSub = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _completionSub?.cancel();
        _positionSub?.cancel();
        _positionSub = null;
        if (myToken == _sequenceToken) onSequenceComplete?.call();
      }
    });
  }

  /// Prev/Next বাটনের জন্য দ্রুত সিক — audio source নতুন করে লোড না করে
  /// ঠিক টার্গেট আয়াতের timestamp-এ সরাসরি seek করে, তাই প্রায় তাৎক্ষণিক।
  /// শুধুমাত্র playFullSurah ইতিমধ্যে চলমান/পজড থাকলে কাজ করে (session data লাগে)।
  Future<void> seekToIndex(int index) async {
    final segments = _currentSegments;
    final onAyaStart = _currentOnAyaStart;
    if (segments == null || onAyaStart == null) return;
    if (index < 0 || index >= segments.length) return;

    final myToken = _sequenceToken; // same session, no token bump needed
    await player.seek(Duration(milliseconds: segments[index]['timestamp_from_ms'] as int));
    if (!player.playing) await player.play();
    if (myToken != _sequenceToken) return;

    _currentAyaIndex = index;
    final ayaNumber = segments[index]['aya'] as int;
    onAyaStart(index, ayaNumber);

    // পুরনো position listener বন্ধ করে নতুন index থেকে আবার শুরু করা হয়,
    // যাতে boundary-detection লুপ ঠিক জায়গা থেকে গণনা করে।
    await _positionSub?.cancel();
    int currentIndex = index;
    _positionSub = player.positionStream.listen((pos) {
      if (myToken != _sequenceToken) {
        _positionSub?.cancel();
        _positionSub = null;
        return;
      }
      final ms = pos.inMilliseconds;
      while (currentIndex + 1 < segments.length &&
          ms >= (segments[currentIndex + 1]['timestamp_from_ms'] as int)) {
        currentIndex++;
        _currentAyaIndex = currentIndex;
        final num = segments[currentIndex]['aya'] as int;
        onAyaStart(currentIndex, num);
      }
    });
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    _sequenceToken++; // invalidate any in-flight sequence
    await _positionSub?.cancel();
    await _completionSub?.cancel();
    _positionSub = null;
    _currentStopAtMs = null;
    _onAyaComplete = null;
    await player.stop();
    await super.stop();
  }
}
