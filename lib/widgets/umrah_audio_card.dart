import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/umrah_audio_meanings.dart';
import '../utils/app_language.dart';
import '../utils/app_theme.dart';
import '../utils/umrah_audio_helper.dart';
import 'umrah_widgets.dart';

/// ধাপের অডিও তালিকা — ফোনের Music/Umrah MP3/<ধাপ নম্বর …> ফোল্ডার থেকে চলে।
class UmrahAudioCard extends StatefulWidget {
  final int stepNo; // ১-ভিত্তিক ধাপ নম্বর
  final AppLanguage lang;

  /// null হলে সব সেকশন দেখাবে। সংখ্যা দিলে (০-ভিত্তিক) শিরোনামওয়ালা সেকশনগুলোর
  /// মধ্যে শুধু সেই ক্রমের সেকশনটি দেখাবে — যেমন ১ম চক্করে "Round 1"।
  final int? activeGroup;
  const UmrahAudioCard({
    super.key,
    required this.stepNo,
    required this.lang,
    this.activeGroup,
  });

  @override
  State<UmrahAudioCard> createState() => _UmrahAudioCardState();
}

class _UmrahAudioCardState extends State<UmrahAudioCard> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];

  bool _loading = true;
  bool _noPermission = false;
  List<File> _files = []; // সব ফাইল (গুচ্ছ অনুযায়ী পরপর)
  List<UmrahAudioGroup> _groups = [];
  List<int> _groupEnd = []; // প্রতিটি ফাইল যে গুচ্ছে, তার শেষ ইনডেক্স (বাদে)
  int _current = -1;
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  String? _error;
  final Set<String> _open = {}; // খোলা সেকশন (সব-সেকশন মোডে)
  bool _cardOpen = false; // সাধারণ ধাপে পুরো অডিও তালিকা খোলা কি না (ডিফল্ট বন্ধ)

  bool get _bn => widget.lang.isBn;

  /// সাব-ফোল্ডার ছাড়া সাধারণ ধাপ (সব ফাইল সরাসরি ধাপের ফোল্ডারে)
  bool get _flat => _groups.isNotEmpty && _groups.every((g) => g.title == null);
  String _t(String bn, String en) => _bn ? bn : en;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
      if (s.processingState == ProcessingState.completed) _onCompleted();
    }));
    _subs.add(_player.positionStream.listen((p) {
      if (mounted) setState(() => _pos = p);
    }));
    _subs.add(_player.durationStream.listen((d) {
      if (mounted) setState(() => _dur = d ?? Duration.zero);
    }));
    _load();
  }

  @override
  void didUpdateWidget(covariant UmrahAudioCard old) {
    super.didUpdateWidget(old);
    // চক্কর বদলালে আগের চক্করের অডিও থামিয়ে দিন
    if (old.activeGroup != widget.activeGroup) {
      _player.stop();
      setState(() {
        _current = -1;
        _pos = Duration.zero;
        _dur = Duration.zero;
        _playing = false;
      });
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _load({bool ask = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    bool ok = await UmrahAudioHelper.hasPermission();
    if (!ok && ask) ok = await UmrahAudioHelper.requestPermission();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _noPermission = true;
        _loading = false;
      });
      return;
    }
    final groups = await UmrahAudioHelper.groupsForStep(widget.stepNo);
    final files = <File>[];
    final ends = <int>[];
    for (final g in groups) {
      files.addAll(g.files);
      ends.addAll(List.filled(g.files.length, files.length));
    }
    if (!mounted) return;
    setState(() {
      _noPermission = false;
      _groups = groups;
      _groupEnd = ends;
      _files = files;
      _loading = false;
    });
  }

  Future<void> _play(int i) async {
    try {
      if (_current == i) {
        if (_player.playing) {
          await _player.pause();
        } else {
          if (_player.processingState == ProcessingState.completed) {
            await _player.seek(Duration.zero);
          }
          _player.play(); // await করা যাবে না (শেষ না হওয়া পর্যন্ত ফেরে না)
        }
        return;
      }
      setState(() {
        _current = i;
        _pos = Duration.zero;
        _dur = Duration.zero;
        _error = null;
      });
      await _player.setFilePath(_files[i].path);
      _player.play();
    } catch (e) {
      if (mounted) {
        setState(() => _error = _t('অডিও চালানো যায়নি', 'Could not play audio'));
      }
    }
  }

  /// একটি শেষ হলে একই গুচ্ছের পরেরটি নিজে থেকে চলবে
  void _onCompleted() {
    if (_current >= 0 && _current + 1 < _groupEnd[_current]) {
      _play(_current + 1);
    }
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    return widget.lang.isBn ? _toBn(s) : s;
  }

  String _toBn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.replaceAllMapped(RegExp(r'\d'), (m) => bn[int.parse(m.group(0)!)]);
  }

  @override
  Widget build(BuildContext context) {
    // ফোল্ডার না থাকলে/খালি হলে এই ধাপে কার্ডটি লুকানো থাকবে
    if (!_loading && !_noPermission && _files.isEmpty) {
      return const SizedBox.shrink();
    }
    return umrahBox(
      border: kUmrahGreen.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones, color: kUmrahGreen, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _flat
                      ? '${_t('অডিও গাইড', 'Audio guide')}  (${widget.lang.toLocalNum(_files.length)})'
                      : _t('অডিও গাইড', 'Audio guide'),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_loading && !_noPermission && _flat) ...[
                // সব অডিও একটার পর একটা চালানোর বাটন
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _toggleGroup(0, _files.length),
                  child: _playCircle(_current >= 0 && _playing),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => _cardOpen = !_cardOpen),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _arrow(_cardOpen),
                  ),
                ),
              ] else
                IconButton(
                  tooltip: _t('আবার খুঁজুন', 'Refresh'),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.refresh, size: 20, color: AppTheme.soft),
                  onPressed: () => _load(),
                ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_noPermission)
            _message(
              _t('অডিও চালাতে ফোনের ফাইল অ্যাক্সেসের অনুমতি দিন।',
                  'Allow file access to play audio.'),
              action: _t('অনুমতি দিন', 'Allow'),
              onAction: () => _load(ask: true),
            )
          else if (_files.isEmpty)
            _message(_t(
              'কোনো অডিও পাওয়া যায়নি। অডিও ফাইলগুলো Music › Recitations › Umrah MP3 › “${widget.stepNo} …” ফোল্ডারে রাখুন।',
              'No audio found. Put files in Music › Recitations › Umrah MP3 › "${widget.stepNo} …" folder.',
            ))
          else
            ..._buildGroups(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!,
                  style: TextStyle(color: AppTheme.missed, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroups() {
    final out = <Widget>[];
    int start = 0;
    int titled = 0; // শিরোনামওয়ালা সেকশনের ক্রম
    for (final g in _groups) {
      final from = start;
      start += g.files.length;
      final end = start;
      final rows = <Widget>[for (int i = from; i < end; i++) _row(i)];

      if (g.title == null) {
        if (!_flat || _cardOpen) out.addAll(rows);
        continue;
      }
      final order = titled++;
      if (widget.activeGroup != null && order != widget.activeGroup) continue;

      final key = g.title!;
      final open = _open.contains(key); // ডিফল্ট বন্ধ
      final groupPlaying = _current >= from && _current < end && _playing;

      out.add(
        Column(
          children: [
            InkWell(
              onTap: () => setState(() {
                if (!_open.remove(key)) _open.add(key);
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${g.title}  (${widget.lang.toLocalNum(g.files.length)})',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // সব অডিও একটার পর একটা চালানোর বাটন
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _toggleGroup(from, end),
                      child: _playCircle(groupPlaying),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: _arrow(open),
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              ...rows,
          ],
        ),
      );
    }
    return out;
  }

  Widget _playCircle(bool playing) => Container(
        width: 40,
        height: 40,
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: kUmrahGreen),
        child: Icon(playing ? Icons.pause : Icons.play_arrow,
            color: Colors.white),
      );

  Widget _arrow(bool open) => AnimatedRotation(
        turns: open ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: Icon(Icons.keyboard_arrow_down, color: AppTheme.textPrimary),
      );

  /// সেকশনের প্লে/পজ: সেকশনের অডিও চলছে হলে পজ/রিজিউম, নইলে প্রথমটি থেকে শুরু
  /// (একটি শেষ হলে পরেরটি নিজে চলে)।
  void _toggleGroup(int from, int end) {
    if (_current >= from && _current < end) {
      _play(_current);
    } else {
      _play(from);
    }
  }

  Widget _message(String text, {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13.5, height: 1.5)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }

  /// অডিওর নিচে আরবি দোয়া + ভাষা অনুযায়ী (বাংলা/ইংরেজি) অর্থ
  Widget _meaning(int i) {
    // এই ফাইলটি ধাপের কত নম্বর ফাইল (ধাপের সব গুচ্ছ ধরে)
    final m = UmrahAudioMeanings.find(
      widget.stepNo,
      _files[i].path.split('/').last,
      i,
    );
    if (m == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Text(
              m.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'ScheherazadeNew',
                fontSize: 22,
                height: 1.9,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bn ? m.bn : m.en,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(int i) {
    final active = _current == i;
    final playing = active && _playing;
    final maxMs = _dur.inMilliseconds > 0 ? _dur.inMilliseconds.toDouble() : 1.0;
    final posMs = _pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: active ? kUmrahGreen.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? kUmrahGreen : AppTheme.divider,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _play(i),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kUmrahGreen,
                    ),
                    child: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      UmrahAudioHelper.titleOf(_files[i]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _meaning(i),
          if (active)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 6),
              child: Row(
                children: [
                  Text(_fmt(_pos),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                        activeTrackColor: kUmrahGreen,
                        thumbColor: kUmrahGreen,
                      ),
                      child: Slider(
                        min: 0,
                        max: maxMs,
                        value: posMs,
                        onChanged: (v) =>
                            _player.seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                  ),
                  Text(_fmt(_dur),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
