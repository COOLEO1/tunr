import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../data/repo.dart';

/// Measures playback-position movement, never wall-clock time.
/// Pauses, buffering and seek discontinuities are excluded.
class ListeningSessionTracker {
  final AudioPlayer player;
  ListeningSessionTracker(this.player);

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  Timer? _checkpointTimer;
  int? _sessionId;
  int _durationMs = 0;
  int _listenedMs = 0;
  int _lastPositionMs = 0;
  bool _isPlaying = false;
  bool _completed = false;
  bool _disposed = false;

  int get activeListeningMs => _listenedMs;

  Future<void> attach() async {
    _positionSub = player.positionStream.listen(_onPosition);
    _stateSub = player.playerStateStream.listen(_onPlayerState);
    _checkpointTimer = Timer.periodic(const Duration(seconds: 5), (_) => checkpoint());
  }

  Future<void> start(SongModel song) async {
    await finish('track_changed');
    if (_disposed) return;
    _durationMs = song.duration ?? player.duration?.inMilliseconds ?? 0;
    _listenedMs = 0;
    _completed = false;
    _lastPositionMs = player.position.inMilliseconds;
    _isPlaying = player.playing && player.processingState == ProcessingState.ready;
    _sessionId = await Repo.i.beginListeningSession(song.id, _durationMs, _lastPositionMs);
  }

  void _onPlayerState(PlayerState state) {
    _isPlaying = state.playing && state.processingState == ProcessingState.ready;
    _lastPositionMs = player.position.inMilliseconds;
    if (!_isPlaying) checkpoint();
  }

  void _onPosition(Duration position) {
    final now = position.inMilliseconds;
    if (_isPlaying && player.playing && player.processingState == ProcessingState.ready) {
      final delta = now - _lastPositionMs;
      if (delta > 0 && delta <= 2500) {
        _listenedMs += delta;
        if (_durationMs > 0 && now >= _durationMs * .8) _completed = true;
      }
    }
    _lastPositionMs = now;
  }

  Future<void> checkpoint() async {
    final id = _sessionId;
    if (id == null) return;
    await Repo.i.checkpointListeningSession(id, _listenedMs);
  }

  Future<void> finish(String reason) async {
    final id = _sessionId;
    if (id == null) return;
    _isPlaying = false;
    final listened = _listenedMs;
    final duration = _durationMs;
    final completed = _completed || reason == 'completed';
    final skipped = reason == 'track_changed' && !completed && listened < 30000;
    // Clear the live value before the aggregate update notifies Insights.
    _sessionId = null;
    _listenedMs = 0;
    _durationMs = 0;
    _completed = false;
    await Repo.i.finishListeningSession(
      sessionId: id,
      listenedMs: listened,
      durationMs: duration,
      reason: reason,
      completed: completed,
      skipped: skipped,
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _checkpointTimer?.cancel();
    await checkpoint();
    await _positionSub?.cancel();
    await _stateSub?.cancel();
  }
}