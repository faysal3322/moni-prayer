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
  // সূরা আল-ফাতিহা ছাড়া বাকি সব সূরার ১ নং আয়াতের অডিওতে শুরুতেই
  // "বিসমিল্লাহির রহমানির রহিম" তেলাওয়াতও থাকে, কিন্তু ডেটাবেজে এটা আলাদা
  // সেগমেন্ট হিসেবে চিহ্নিত না — পুরোটাই আয়াত ১-এর timestamp থেকে ধরা।
  // এই কনস্ট্যান্টটা শুধু হাইলাইট কখন বদলাবে তা ঠিক করতে ব্যবহার হয় —
  // কখনোই audio seek/position-এর জন্য না, তাহলে বিসমিল্লাহর অডিওটাই
  // স্কিপ হয়ে যাবে (আগে এই ভুলটাই হয়েছিল)। এই সময় অতিক্রম হওয়ার
  // পরই হাইলাইট আয়াত ১-এ যাবে, কিন্তু audio ঠিক শুরু (0ms) থেকেই বাজবে।
  // বাস্তব Basmalah দৈর্ঘ্যের সাথে না মিললে এই মান পরিবর্তন করে ঠিক করা যায়।
  static const int _basmalahDurationMs = 5000;

  int _sequenceToken = 0;

  // পরে prev/next বাটনে দ্রুত সিক করার জন্য বর্তমান সেশনের ফাইল/সেগমেন্ট/
  // কলব্যাক মনে রাখা হয় — এতে পুরো audio source আবার লোড না করেই লাফানো যায়।
  String? _currentFilePath;
  List<Map<String, dynamic>>? _currentSegments;
  void Function(int ayaIndex, int ayaNumber)? _currentOnAyaStart;
  void Function()? _currentOnSequenceComplete;
  int _currentAyaIndex = -1;

  // নোটিফিকেশনে "সূরার নাম + Verse N" দেখানোর জন্য বর্তমান সূরার নাম/নম্বর
  // মনে রাখা হয় — [_publishMediaItem] প্রতিটা আয়াত পরিবর্তনের সময় এটা
  // ব্যবহার করে audio_service-এর mediaItem স্ট্রিমে নতুন তথ্য পাঠায়।
  int? _currentSuraNumber;
  String _currentSuraName = '';

  /// audio_service-কে জানায় এখন কোন সূরা/আয়াত চলছে, যা থেকে সিস্টেম
  /// নোটিফিকেশন (এবং lock screen media control) তার টাইটেল/সাবটাইটেল
  /// বানায় — অন্য অনেক কুরআন অ্যাপে যেমন দেখা যায় ("Al-Baqara — Verse 2"
  /// লেখা, পাশে play/pause/rewind/close বাটন)। আগে [mediaItem] কখনো
  /// আপডেট করা হতো না, তাই নোটিফিকেশনে কোনো সূরা/আয়াত তথ্যই দেখাত না।
  void _publishMediaItem(int ayaIndex, int ayaNumber) {
    if (_currentSuraNumber == null) return;
    final subtitle = ayaIndex >= 0 ? 'Verse $ayaNumber' : 'Bismillah';
    mediaItem.add(MediaItem(
      // id-তে সূরা+আয়াত রাখা হচ্ছে যাতে প্রতিটা আয়াতের জন্য আলাদা id হয় —
      // কিছু লঞ্চার/ওয়াচ media-item-কে id দিয়ে ক্যাশ করে, তাই id একই
      // থাকলে title/subtitle বদলালেও UI আপডেট নাও দেখাতে পারে।
      id: 'quran_${_currentSuraNumber}_$ayaNumber',
      title: _currentSuraName,
      artist: subtitle,
      album: 'Al-Quran',
    ));
  }

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
    // await করা যাবে না — just_audio-তে play()-এর future audio শেষ না হওয়া
    // পর্যন্ত resolve হয় না, ফলে এই ফাংশন কখনো রিটার্ন করত না।
    unawaited(player.play());
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
      final ms = pos.inMilliseconds;
      // startMs-এর আগের (stale/pre-seek) position event উপেক্ষা করা হয়।
      // setAudioSource()/seek()-এর পরও positionStream থেকে সাথে সাথেই
      // নতুন (seek-করা) position আসার নিশ্চয়তা নেই — মাঝেমধ্যে আগের
      // অবস্থানের একটা event ফাঁকতালে চলে আসে, যেটা কাকতালীয়ভাবে
      // endMs-এর সমান/বেশি হলে আয়াত সময়ের অনেক আগেই থেমে যেত। startMs-এর
      // নিচের যেকোনো event উপেক্ষা করলে শুধু আসল, seek-পরবর্তী progress-ই
      // boundary চেক করবে।
      if (ms < startMs) return;
      if (_currentStopAtMs != null && ms >= _currentStopAtMs!) {
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
    required int suraNumber,
    required String suraName,
    required List<Map<String, dynamic>> segments,
    required void Function(int ayaIndex, int ayaNumber) onAyaStart,
    void Function()? onSequenceComplete,
    int startIndex = 0,
  }) async {
    if (segments.isEmpty) return;
    _currentSuraNumber = suraNumber;
    _currentSuraName = suraName;
    // নেগেটিভ বা রেঞ্জের বাইরের ইনডেক্স হলে নিরাপদে শুরু থেকে চালানো হবে।
    final safeStart = (startIndex < 0 || startIndex >= segments.length) ? 0 : startIndex;
    final myToken = ++_sequenceToken;

    await _positionSub?.cancel();
    await _completionSub?.cancel();
    _positionSub = null;
    _currentStopAtMs = null;
    _onAyaComplete = null;

    // একই ফাইল আগে থেকেই লোড থাকলে নতুন করে setAudioSource না করে শুধু
    // seek করলেই চলে — এতে বারবার চালু/থামানোয় দেরি হয় না।
    // গুরুত্বপূর্ণ: এই তুলনা অবশ্যই _currentFilePath আপডেট করার আগে করতে
    // হবে, নাহলে সবসময় "same file" ধরা পড়ে এবং ভুল সূরার audio বেজেই যায়।
    final sameFileAlreadyLoaded = _currentFilePath == filePath && player.duration != null;

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
      _publishMediaItem(i, ayaNumber);
      onAyaStart(i, ayaNumber);
    }

    // হাইলাইট কখন সেগমেন্ট i-তে ঢুকবে তার threshold — সাধারণ stream-lag
    // delay সব সেগমেন্টে যোগ হয়, আর সূরা ১ ছাড়া বাকি সব সূরার আয়াত ১-এ
    // অতিরিক্ত বিসমিল্লাহ-ডিউরেশনও যোগ হয় (কারণ অডিওতে বিসমিল্লাহ ওই
    // আয়াতের শুরুতেই আছে কিন্তু সেটা ডেটাবেজে আলাদা সেগমেন্ট না)।
    // এটা শুধু হাইলাইট কখন বদলাবে তা ঠিক করে — audio seek করে raw
    // timestamp দিয়েই (নিচে), তাই audio কখনোই বিসমিল্লাহ স্কিপ করে না।
    int highlightThreshold(int i) {
      final base = segments[i]['timestamp_from_ms'] as int;
      final sura = segments[i]['sura'] as int?;
      final aya = segments[i]['aya'] as int?;
      final isBasmalahAya = aya == 1 && sura != 1;
      return base + (isBasmalahAya ? _basmalahDurationMs : 0);
    }

    if (!sameFileAlreadyLoaded) {
      // আগের সূরা 'completed' state-এ থামার পরপরই (auto-continue চেইনে)
      // নতুন audio source লোড করা হলে, just_audio-র কিছু ভার্সনে player
      // ঠিকভাবে নতুন করে চালু না-ও হতে পারে যদি আগে থেকে completed state
      // পরিষ্কার করা না হয়। তাই নতুন source লোডের আগে player-কে reset
      // করে নেওয়া হচ্ছে — এটাই সম্ভবত "এক সূরা শেষে পরের সূরায় গিয়ে
      // থেমে থাকা" সমস্যার কারণ ছিল।
      if (player.processingState == ProcessingState.completed) {
        await player.stop();
      }
      await player.setAudioSource(AudioSource.uri(Uri.file(filePath)));
    }
    // এখানে raw timestamp_from_ms দিয়েই seek হয় — অডিও ঠিক রেকর্ড করা
    // জায়গা থেকেই শুরু হবে, বিসমিল্লাহসহ। কোনো offset প্রয়োগ করা হয় না।
    await player.seek(Duration(milliseconds: segments[safeStart]['timestamp_from_ms'] as int));
    // গুরুত্বপূর্ণ: player.play() কে await করা যাবে না। just_audio-তে play()-এর
    // future ততক্ষণ resolve হয় না যতক্ষণ না পুরো audio শেষ হয়/থামানো হয় —
    // অর্থাৎ await করলে এই পুরো playFullSurah() ফাংশনটাই পুরো সূরা শেষ না
    // হওয়া পর্যন্ত আটকে থাকত। ফলে caller-এর finally ব্লক (_fullSurahLoading
    // false করা) কখনো চলত না — Play বাটন চাপার পর spinner চিরকাল ঘুরতে
    // থাকত এবং বাটন disabled থেকে যেত (Pause/Stop কাজ করত না)।
    unawaited(player.play());
    if (myToken != _sequenceToken) return; // stopped/superseded while loading

    // সূরা ১ ছাড়া বাকি সব সূরায় যদি একদম প্রথম আয়াত (বিসমিল্লাহসহ) থেকে
    // প্লে শুরু হয়, তাহলে সাথে সাথে হাইলাইট না করে position stream-কেই
    // (নিচে) সেটা ট্রিগার করতে দেওয়া হয় — বিসমিল্লাহ পড়া চলাকালীন হাইলাইট
    // যেন ভুলভাবে আয়াত ১-এ না চলে যায়।
    final firstAya = segments[safeStart]['aya'] as int?;
    final firstSura = segments[safeStart]['sura'] as int?;
    final skipImmediateEnter = firstAya == 1 && firstSura != 1;
    if (!skipImmediateEnter) {
      enterIndex(safeStart);
    } else {
      // বিসমিল্লাহ তেলাওয়াত শুরু হয়েছে (ডেটাবেজে আলাদা সেগমেন্ট নেই)।
      // -1 ইনডেক্স দিয়ে UI-কে জানানো হচ্ছে যে এখন বিসমিল্লাহ চলছে, যাতে
      // UI বিসমিল্লাহ লাইনটাকেই হাইলাইট করতে পারে — ঠিক যেমন সূরা
      // আল-ফাতিহায় ১ নং আয়াত হিসেবে বিসমিল্লাহ হাইলাইট হয়। currentIndex
      // ইতিমধ্যেই -1 (উপরে সেট করা), তাই enterIndex(-1) কল করলে
      // onAyaStart কল হবে না (i == currentIndex চেক ব্যর্থ হবে বলে) —
      // তাই সরাসরি কলব্যাক কল করা হচ্ছে।
      _publishMediaItem(-1, 0);
      onAyaStart(-1, 0);
    }
    // skipImmediateEnter হলে currentIndex ইতিমধ্যেই -1 আছে (উপরে সেট করা),
    // তাই নিচের position-stream লুপ segments[safeStart]-এর (বিসমিল্লাহসহ)
    // threshold অতিক্রম হওয়া পর্যন্ত অপেক্ষা করে, তারপরই enterIndex কল
    // করবে — বিসমিল্লাহ শেষ হওয়ার পরই হাইলাইট পড়বে।

    _positionSub = player.positionStream.listen((pos) {
      if (myToken != _sequenceToken) {
        _positionSub?.cancel();
        _positionSub = null;
        return;
      }
      final ms = pos.inMilliseconds;
      while (currentIndex + 1 < segments.length &&
          ms >= highlightThreshold(currentIndex + 1)) {
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
    // এখানেও await player.play() ব্যবহার করা যাবে না, একই কারণে —
    // audio শেষ না হওয়া পর্যন্ত future resolve হয় না।
    if (!player.playing) unawaited(player.play());
    if (myToken != _sequenceToken) return;

    _currentAyaIndex = index;
    final ayaNumber = segments[index]['aya'] as int;
    _publishMediaItem(index, ayaNumber);
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
      while (currentIndex + 1 < segments.length) {
        final next = segments[currentIndex + 1];
        final nextBase = next['timestamp_from_ms'] as int;
        final nextIsBasmalahAya = next['aya'] == 1 && next['sura'] != 1;
        final threshold = nextBase + (nextIsBasmalahAya ? _basmalahDurationMs : 0);
        if (ms < threshold) break;
        currentIndex++;
        _currentAyaIndex = currentIndex;
        final num = segments[currentIndex]['aya'] as int;
        _publishMediaItem(currentIndex, num);
        onAyaStart(currentIndex, num);
      }
    });
  }

  @override
  Future<void> play() async {
    // await করা যাবে না — একই কারণে (just_audio play() future audio শেষ
    // না হওয়া পর্যন্ত resolve হয় না)। এটাই resume()-এর মূল কল, তাই এটা
    // await করলে Pause থেকে Resume চাপলেও সেই একই "বাটন আটকে যাওয়া"
    // সমস্যা হতো (আগে শুধু একটা timeout দিয়ে ৫ সেকেন্ড পর জোর করে এগিয়ে
    // যাওয়া হতো — এখন root cause ঠিক হওয়ায় সাথে সাথেই রেসপন্স করবে)।
    unawaited(player.play());
  }

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
    _currentSuraNumber = null;
    _currentSuraName = '';
    mediaItem.add(null);
    await player.stop();
    await super.stop();
  }
}
