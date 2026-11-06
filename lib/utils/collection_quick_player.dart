import 'dart:io';
import 'package:flutter/foundation.dart';
import 'quran_audio_helper.dart';
import 'quran_collections_helper.dart';
import 'quran_database_helper.dart';

enum QuickPlayStatus { idle, loading, playing, paused }

class QuickPlayState {
  final int? collectionId;
  final QuickPlayStatus status;
  const QuickPlayState(this.collectionId, this.status);
  static const idle = QuickPlayState(null, QuickPlayStatus.idle);
}

/// "আমার কোরআন" তালিকা থেকে সরাসরি (কালেকশনের ভেতরে না ঢুকে) পুরো
/// কালেকশন ক্রমান্বয়ে বাজানোর জন্য। CollectionDetailScreen-এর "সব শোনো"
/// লজিকের মতোই কাজ করে — একক আইটেমের repeat_count, গ্রুপের repeat_count,
/// এবং নিজের দোয়া/অডিও (custom) সবই সমর্থিত।
class CollectionQuickPlayer {
  CollectionQuickPlayer._();

  static final ValueNotifier<QuickPlayState> state =
      ValueNotifier(QuickPlayState.idle);

  static int _token = 0; // প্রতিটা নতুন সেশনে বাড়ে; পুরোনো callback বাতিল করে
  static bool _listening = false;

  static bool isActive(int collectionId) =>
      state.value.collectionId == collectionId &&
      state.value.status != QuickPlayStatus.idle;

  /// সূরা-স্ক্রিন/অন্য কোথাও থেকে সূরা প্লে শুরু হলে এই প্লেয়ারের স্টেট রিসেট।
  static void _ensureListener() {
    if (_listening) return;
    _listening = true;
    QuranAudioHelper.activeSession.addListener(() {
      if (QuranAudioHelper.activeSession.value != null &&
          state.value.status != QuickPlayStatus.idle) {
        _token++;
        state.value = QuickPlayState.idle;
      }
    });
  }

  /// বাটনে চাপ: idle → শুরু, playing → pause, paused → resume।
  static Future<void> toggle(int collectionId) async {
    final s = state.value;
    if (s.collectionId == collectionId) {
      if (s.status == QuickPlayStatus.playing) {
        state.value = QuickPlayState(collectionId, QuickPlayStatus.paused);
        await QuranAudioHelper.pause();
        return;
      }
      if (s.status == QuickPlayStatus.paused) {
        state.value = QuickPlayState(collectionId, QuickPlayStatus.playing);
        await QuranAudioHelper.resume();
        return;
      }
      if (s.status == QuickPlayStatus.loading) return;
    }
    await _start(collectionId);
  }

  static Future<void> stop() async {
    _token++;
    state.value = QuickPlayState.idle;
    await QuranAudioHelper.stop();
  }

  /// কালেকশন মুছে ফেলার আগে — এটা চলমান থাকলে থামানো হয়।
  static Future<void> stopIfPlaying(int collectionId) async {
    if (state.value.collectionId == collectionId) await stop();
  }

  // ── ভেতরের লজিক ──

  static Future<void> _start(int collectionId) async {
    _ensureListener();
    final my = ++_token;
    state.value = QuickPlayState(collectionId, QuickPlayStatus.loading);

    try {
      final items = await QuranCollectionsHelper.getCollectionItems(collectionId);
      if (items.isEmpty) {
        if (my == _token) state.value = QuickPlayState.idle;
        return;
      }
      final chapters = await QuranDatabaseHelper.getChapters();
      final suraNames = {
        for (final c in chapters)
          (c['sura'] as int): (c['name_transliteration'] as String? ?? ''),
      };

      // ── প্লেলিস্ট তৈরি: repeat বিস্তারিত করে সাজানো ──
      // গ্রুপ (group_key আছে): পুরো গ্রুপ repeat_count বার। একক: আইটেম নিজে।
      final entries = <_Entry>[];
      var i = 0;
      while (i < items.length) {
        final it = items[i];
        final groupKey = it['group_key'] as String?;
        final repeat = ((it['repeat_count'] as int?) ?? 1).clamp(1, 1000);
        if (groupKey == null) {
          for (var r = 0; r < repeat; r++) {
            entries.add(await _makeEntry(it, suraNames));
          }
          i++;
        } else {
          final group = <Map<String, dynamic>>[];
          while (i < items.length && items[i]['group_key'] == groupKey) {
            group.add(items[i]);
            i++;
          }
          final groupEntries = <_Entry>[];
          for (final g in group) {
            groupEntries.add(await _makeEntry(g, suraNames));
          }
          for (var r = 0; r < repeat; r++) {
            entries.addAll(groupEntries);
          }
        }
      }

      if (my != _token) return;
      state.value = QuickPlayState(collectionId, QuickPlayStatus.playing);
      await _playAt(entries, 0, my, collectionId);
    } catch (e) {
      debugPrint('QUICK PLAY START ERROR: $e');
      if (my == _token) state.value = QuickPlayState.idle;
    }
  }

  static Future<_Entry> _makeEntry(
      Map<String, dynamic> item, Map<int, String> suraNames) async {
    final type = item['item_type'] as String? ?? 'aya';
    if (type == 'custom') {
      return _Entry.custom(
        item['custom_file_path'] as String?,
        (item['custom_title'] as String?),
      );
    }
    final sura = item['sura'] as int;
    final aya = item['aya'] as int;
    final segment = await QuranDatabaseHelper.getAyaSegment(sura, aya);
    final audio = await QuranDatabaseHelper.getSurahAudio(sura);
    return _Entry.aya(sura, aya, suraNames[sura] ?? '', segment, audio);
  }

  static bool _seamless(List<_Entry> list, int idx) {
    if (idx <= 0 || idx >= list.length) return false;
    final prev = list[idx - 1];
    final cur = list[idx];
    if (prev.isCustom || cur.isCustom) return false;
    if (prev.sura != cur.sura) return false;
    final prevEnd = prev.segment?['timestamp_to_ms'] as int?;
    final thisStart = cur.segment?['timestamp_from_ms'] as int?;
    if (prevEnd == null || thisStart == null) return false;
    return (thisStart - prevEnd).abs() < 400;
  }

  static Future<void> _playAt(
      List<_Entry> list, int idx, int my, int collectionId) async {
    if (my != _token) return;
    if (idx >= list.length) {
      state.value = QuickPlayState.idle;
      return;
    }
    final e = list[idx];

    void next() {
      if (my != _token) return;
      _playAt(list, idx + 1, my, collectionId);
    }

    try {
      if (e.isCustom) {
        final path = e.filePath;
        if (path == null || !await File(path).exists()) {
          next();
          return;
        }
        await QuranAudioHelper.playCustomAudio(
          filePath: path,
          title: e.title,
          onComplete: next,
        );
        return;
      }

      if (e.segment == null || e.audio == null) {
        next();
        return;
      }
      await QuranAudioHelper.playAya(
        sura: e.sura!,
        surahAudioUrl: e.audio!['audio_url'] as String,
        startMs: e.segment!['timestamp_from_ms'] as int,
        endMs: e.segment!['timestamp_to_ms'] as int,
        suraName: e.suraName,
        ayaNumber: e.aya,
        continuePlayback: _seamless(list, idx),
        nextIsSeamless: _seamless(list, idx + 1),
        onComplete: next,
      );
    } catch (err) {
      debugPrint('QUICK PLAY ERROR (index $idx): $err');
      next(); // একটা আইটেমের সমস্যায় পুরো সিকোয়েন্স থামে না
    }
  }
}

class _Entry {
  final bool isCustom;
  final String? filePath;
  final String? title;
  final int? sura;
  final int? aya;
  final String suraName;
  final Map<String, dynamic>? segment;
  final Map<String, dynamic>? audio;

  _Entry.custom(this.filePath, this.title)
      : isCustom = true,
        sura = null,
        aya = null,
        suraName = '',
        segment = null,
        audio = null;

  _Entry.aya(this.sura, this.aya, this.suraName, this.segment, this.audio)
      : isCustom = false,
        filePath = null,
        title = null;
}
