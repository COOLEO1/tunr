import 'tint.dart';
import 'meta.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../data/repo.dart';
import 'autoqueue.dart';

class Player {
  static final i = Player._();
  Player._();

  final ap = AudioPlayer();
  final _q = OnAudioQuery();
  List<SongModel> all = [];
  List<SongModel> queue = [];
  final _byId = <int, SongModel>{};
  final current = ValueNotifier<SongModel?>(null);
  final shuffle = ValueNotifier<bool>(false);
  final loop = ValueNotifier<LoopMode>(LoopMode.off);
  final autoQueue = ValueNotifier<bool>(true);
  ConcatenatingAudioSource? _src;
  int _lastIdx = -1;
  DateTime _started = DateTime.now();
  bool _extending = false;

  Future<bool> init() async {
    var ok = await _q.permissionsStatus();
    if (!ok) ok = await _q.permissionsRequest();
    if (!ok) return false;
    await scan();
    ap.currentIndexStream.listen(_onIndex);
    return true;
  }

  Future<void> scan() async {
    final list = await _q.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    all = list.where((s) => (s.duration ?? 0) > 30000 && s.uri != null).toList();
    _byId
      ..clear()
      ..addEntries(all.map((s) => MapEntry(s.id, s)));
  }

  SongModel? byId(int id) => _byId[id];

  AudioSource _source(SongModel s) => AudioSource.uri(
        Uri.parse(s.uri!),
        tag: MediaItem(
          id: '${s.id}',
          title: cleanTitle(s),
          artist: artistOf(s),
          album: s.album,
          duration: Duration(milliseconds: s.duration ?? 0),
        ),
      );

  Future<void> play(List<SongModel> list, int index) async {
    if (list.isEmpty) return;
    queue = [...list];
    _lastIdx = -1;
    _src = ConcatenatingAudioSource(children: queue.map(_source).toList());
    await ap.setAudioSource(_src!, initialIndex: index);
    await ap.setShuffleModeEnabled(shuffle.value);
    await ap.setLoopMode(loop.value);
    ap.play();
  }

  /// Spotify-style radio: start from one song, the rest is picked for you
  Future<void> radio(SongModel s) async {
    await AutoQueue.prepare(s);
    final more = AutoQueue.pick(s, all, {s.id}, 20);
    await play([s, ...more], 0);
  }

  Future<void> shuffleAll() async {
    if (all.isEmpty) return;
    shuffle.value = true;
    await play(all, Random().nextInt(all.length));
  }

  void toggleShuffle() {
    shuffle.value = !shuffle.value;
    ap.setShuffleModeEnabled(shuffle.value);
  }

  void cycleLoop() {
    loop.value = {
      LoopMode.off: LoopMode.all,
      LoopMode.all: LoopMode.one,
      LoopMode.one: LoopMode.off,
    }[loop.value]!;
    ap.setLoopMode(loop.value);
  }

  void _onIndex(int? idx) {
    if (idx == null || idx >= queue.length) return;
    if (_lastIdx >= 0 && _lastIdx < queue.length && _lastIdx != idx) {
      final secs = DateTime.now().difference(_started).inSeconds;
      Repo.i.logPlay(queue[_lastIdx].id, skipped: secs < 20);
    }
    _lastIdx = idx;
    _started = DateTime.now();
    current.value = queue[idx];
    Tint.of(queue[idx]).then((c) { if (c != null && current.value?.id == queue[idx].id) current.notifyListeners(); });
    _maybeExtend(idx);
  }

  Future<void> _maybeExtend(int idx) async {
    if (!autoQueue.value || loop.value != LoopMode.off || _extending || _src == null) return;
    if (idx < queue.length - 2) return;
    _extending = true;
    await AutoQueue.prepare(queue[idx]);
    final more = AutoQueue.pick(queue[idx], all, queue.map((s) => s.id).toSet(), 15);
    if (more.isNotEmpty) {
      queue = [...queue, ...more];
      await _src!.addAll(more.map(_source).toList());
    }
    _extending = false;
  }
}
