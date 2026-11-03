import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repo.dart';
import 'autoqueue.dart';
import 'meta.dart';
import 'notif_art.dart';
import 'listening_session_tracker.dart';
import 'tint.dart';

class Player {
  static final i = Player._();
  Player._();
  final ap = AudioPlayer();
  late final ListeningSessionTracker _sessionTracker = ListeningSessionTracker(ap);
  final _q = OnAudioQuery();
  List<SongModel> all = [];
  List<SongModel> queue = [];
  final _byId = <int, SongModel>{};
  final current = ValueNotifier<SongModel?>(null);
  final shuffle = ValueNotifier<bool>(false);
  final loop = ValueNotifier<LoopMode>(LoopMode.off);
  final autoQueue = ValueNotifier<bool>(true);
  final sleepSeconds = ValueNotifier<int?>(null);
  ConcatenatingAudioSource? _src;
  int _lastIdx = -1;
  bool _extending = false;
  Timer? _saveTimer;
  Timer? _sleepTimer;
  SharedPreferences? _prefs;

  Future<bool> init() async {
    _prefs = await SharedPreferences.getInstance();
    var ok = await _q.permissionsStatus();
    if (!ok) ok = await _q.permissionsRequest();
    if (!ok) return false;
    await scan();
    NotifArt.warm(all);
    await _restoreQueue();
    await _sessionTracker.attach();
    ap.currentIndexStream.listen((idx) {
      _onIndex(idx);
      _savePlayback();
    });
    ap.playerStateStream.listen((state) {
      _savePlayback();
      if (state.processingState == ProcessingState.completed) {
        _sessionTracker.finish('completed');
      }
    });
    if (ap.currentIndex != null && ap.currentIndex! >= 0) {
      _lastIdx = -1;
      _onIndex(ap.currentIndex);
    }
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _savePlayback());
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
          id: '\${s.id}',
          title: cleanTitle(s),
          artist: artistOf(s),
          artUri: NotifArt.uriFor(s.id),
          duration: Duration(milliseconds: s.duration ?? 0),
        ),
      );

  Future<void> _restoreQueue() async {
    final ids = _prefs?.getStringList('playback.queue') ?? const <String>[];
    final restored = ids.map((v) => int.tryParse(v)).whereType<int>()
        .map((id) => _byId[id]).whereType<SongModel>().toList();
    if (restored.isEmpty) return;
    final index = (_prefs?.getInt('playback.index') ?? 0).clamp(0, restored.length - 1).toInt();
    queue = restored;
    shuffle.value = _prefs?.getBool('playback.shuffle') ?? false;
    final loopIndex = (_prefs?.getInt('playback.loop') ?? 0).clamp(0, 2).toInt();
    loop.value = [LoopMode.off, LoopMode.all, LoopMode.one][loopIndex];
    _src = ConcatenatingAudioSource(children: queue.map(_source).toList());
    await ap.setAudioSource(_src!, initialIndex: index, preload: true);
    await ap.setShuffleModeEnabled(shuffle.value);
    await ap.setLoopMode(loop.value);
    final position = (_prefs?.getInt('playback.position') ?? 0)
        .clamp(0, queue[index].duration ?? 0).toInt();
    if (position > 0) await ap.seek(Duration(milliseconds: position), index: index);
    _lastIdx = index;
    current.value = queue[index];
  }

  Future<void> _savePlayback() async {
    final prefs = _prefs;
    if (prefs == null || queue.isEmpty) return;
    final index = ap.currentIndex ?? _lastIdx;
    if (index < 0 || index >= queue.length) return;
    await prefs.setStringList('playback.queue', queue.map((s) => '\${s.id}').toList());
    await prefs.setInt('playback.index', index);
    await prefs.setInt('playback.position', ap.position.inMilliseconds);
    await prefs.setBool('playback.shuffle', shuffle.value);
    await prefs.setInt('playback.loop', [LoopMode.off, LoopMode.all, LoopMode.one].indexOf(loop.value));
  }

  Future<void> play(List<SongModel> list, int index) async {
    if (list.isEmpty || index < 0 || index >= list.length) return;
    queue = [...list];
    _lastIdx = -1;
    _extending = false;
    _src = ConcatenatingAudioSource(children: queue.map(_source).toList());
    await ap.setAudioSource(_src!, initialIndex: index);
    await ap.setShuffleModeEnabled(shuffle.value);
    await ap.setLoopMode(loop.value);
    await _savePlayback();
    await ap.play();
  }

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
    _savePlayback();
  }

  void cycleLoop() {
    loop.value = {
      LoopMode.off: LoopMode.all,
      LoopMode.all: LoopMode.one,
      LoopMode.one: LoopMode.off,
    }[loop.value]!;
    ap.setLoopMode(loop.value);
    _savePlayback();
  }

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    var remaining = duration.inSeconds;
    sleepSeconds.value = remaining;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      sleepSeconds.value = remaining > 0 ? remaining : 0;
      if (remaining <= 0) {
        timer.cancel();
        _sleepTimer = null;
        ap.pause();
        sleepSeconds.value = null;
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepSeconds.value = null;
  }

  void _onIndex(int? idx) {
    if (idx == null || idx < 0 || idx >= queue.length || idx == _lastIdx) return;
    _lastIdx = idx;
    current.value = queue[idx];
    unawaited(_sessionTracker.start(queue[idx]));
    Tint.of(queue[idx]).then((c) {
      if (c != null && current.value?.id == queue[idx].id) current.notifyListeners();
    });
    _maybeExtend(idx);
  }

  Future<void> _maybeExtend(int idx) async {
    if (!autoQueue.value || loop.value != LoopMode.off || _extending || _src == null) return;
    if (idx < queue.length - 2) return;
    _extending = true;
    try {
      final seed = queue[idx];
      await AutoQueue.prepare(seed);
      final more = AutoQueue.pick(seed, all, queue.map((s) => s.id).toSet(), 15);
      if (more.isNotEmpty && _src != null) {
        queue = [...queue, ...more];
        await _src!.addAll(more.map(_source).toList());
        await _savePlayback();
      }
    } catch (e) {
      debugPrint('Tunr auto-queue extension failed: $e');
    } finally {
      _extending = false;
    }
  }
}