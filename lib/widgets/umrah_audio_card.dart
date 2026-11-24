import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/app_language.dart';
import '../utils/app_theme.dart';
import '../utils/umrah_audio_helper.dart';
import 'umrah_widgets.dart';

/// ধাপের অডিও তালিকা — ফোনের Music/Umrah MP3/<ধাপ নম্বর …> ফোল্ডার থেকে চলে।
class UmrahAudioCard extends StatefulWidget {
  final int stepNo; // ১-ভিত্তিক ধাপ নম্বর
  final AppLanguage lang;
  const UmrahAudioCard({super.key, required this.stepNo, required this.lang});

  @override
  State<UmrahAudioCard> createState() => _UmrahAudioCardState();
}

class _UmrahAudioCardState extends State<UmrahAudioCard> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];

  bool _loading = true;
  bool _noPermission = false;
  List<File> _files = [];
  int _current = -1;
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  String? _error;

  bool get _bn => widget.lang.isBn;
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
    final files = await UmrahAudioHelper.filesForStep(widget.stepNo);
    if (!mounted) return;
    setState(() {
      _noPermission = false;
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

  /// একটি শেষ হলে পরেরটি নিজে থেকে চলবে
  void _onCompleted() {
    if (_current >= 0 && _current + 1 < _files.length) {
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
                  _t('অডিও গাইড', 'Audio guide'),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
          else ...[
            for (int i = 0; i < _files.length; i++) _row(i),
          ],
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
