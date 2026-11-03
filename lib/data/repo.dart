import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart';

class Stat {
  int plays, skips, last, totalMs, completed;
  Stat(this.plays, this.skips, this.last, {this.totalMs = 0, this.completed = 0});
}

class Repo {
  static final i = Repo._();
  Repo._();
  final favs = ValueNotifier<Set<int>>({});
  final statsRevision = ValueNotifier<int>(0);
  final stats = <int, Stat>{};

  int get totalPlays => stats.values.fold(0, (sum, s) => sum + s.plays);
  int get totalSkips => stats.values.fold(0, (sum, s) => sum + s.skips);
  int get totalListeningMs => stats.values.fold(0, (sum, s) => sum + s.totalMs);
  int get completedTracks => stats.values.fold(0, (sum, s) => sum + s.completed);
  List<MapEntry<int, Stat>> get mostPlayed {
    final entries = stats.entries.toList()..sort((a, b) => b.value.plays.compareTo(a.value.plays));
    return entries.take(10).toList();
  }

  Future<void> load() async {
    final d = await Db.get();
    favs.value = (await d.query('fav')).map((r) => r['id'] as int).toSet();
    await _reloadStats();
    await recoverOpenSessions();
  }

  Future<void> toggleFav(int id) async {
    final d = await Db.get();
    final next = {...favs.value};
    if (next.remove(id)) {
      await d.delete('fav', where: 'id=?', whereArgs: [id]);
    } else {
      next.add(id);
      await d.insert('fav', {'id': id}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    favs.value = next;
  }

  Future<int> beginListeningSession(int songId, int durationMs, int positionMs) async {
    return (await Db.get()).insert('listening_sessions', {
      'song_id': songId, 'started_at': DateTime.now().millisecondsSinceEpoch,
      'duration_ms': durationMs, 'listened_ms': 0,
    });
  }

  Future<void> checkpointListeningSession(int id, int listenedMs) async {
    await (await Db.get()).update('listening_sessions', {'listened_ms': listenedMs},
      where: 'id=? AND ended_at IS NULL', whereArgs: [id]);
  }

  Future<void> finishListeningSession({
    required int sessionId, required int listenedMs, required int durationMs,
    required String reason, bool completed = false, bool skipped = false,
  }) async {
    final d = await Db.get();
    await d.transaction((txn) async {
      final rows = await txn.query('listening_sessions', where: 'id=?', whereArgs: [sessionId], limit: 1);
      if (rows.isEmpty || rows.first['counted'] == 1) return;
      final songId = rows.first['song_id'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final qualified = listenedMs >= 30000 ||
        (durationMs > 0 && durationMs < 60000 && listenedMs >= durationMs ~/ 2);
      final done = completed || (durationMs > 0 && listenedMs >= durationMs * .8);
      final skip = skipped || (reason == 'skipped' && !qualified);
      await txn.update('listening_sessions', {
        'ended_at': now, 'listened_ms': listenedMs, 'completed': done ? 1 : 0,
        'skipped': skip ? 1 : 0, 'end_reason': reason, 'counted': 1,
      }, where: 'id=?', whereArgs: [sessionId]);
      final oldRows = await txn.query('stats', where: 'id=?', whereArgs: [songId], limit: 1);
      final old = oldRows.isEmpty ? <String, Object?>{} : oldRows.first;
      await txn.insert('stats', {
        'id': songId,
        'plays': ((old['plays'] as int?) ?? 0) + (qualified ? 1 : 0),
        'skips': ((old['skips'] as int?) ?? 0) + (skip ? 1 : 0),
        'last': now,
        'total_ms': ((old['total_ms'] as int?) ?? 0) + listenedMs,
        'completed': ((old['completed'] as int?) ?? 0) + (done ? 1 : 0),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await _reloadStats();
  }

  Future<void> recoverOpenSessions() async {
    final rows = await (await Db.get()).query('listening_sessions', where: 'ended_at IS NULL');
    for (final row in rows) {
      await finishListeningSession(
        sessionId: row['id'] as int, listenedMs: row['listened_ms'] as int? ?? 0,
        durationMs: row['duration_ms'] as int? ?? 0, reason: 'interrupted',
      );
    }
  }

  Future<void> _reloadStats() async {
    stats.clear();
    for (final row in await (await Db.get()).query('stats')) {
      stats[row['id'] as int] = Stat(
        row['plays'] as int, row['skips'] as int, row['last'] as int,
        totalMs: row['total_ms'] as int? ?? 0,
        completed: row['completed'] as int? ?? 0,
      );
    }
    statsRevision.value++;
  }

  Future<List<int>> dailyListening({int days = 7}) async {
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final midnight = DateTime(start.year, start.month, start.day);
    final rows = await (await Db.get()).query('listening_sessions',
      columns: ['started_at', 'listened_ms'],
      where: 'started_at >= ?', whereArgs: [midnight.millisecondsSinceEpoch]);
    final values = List<int>.filled(days, 0);
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int);
      final index = DateTime(date.year, date.month, date.day).difference(midnight).inDays;
      if (index >= 0 && index < days) values[index] += row['listened_ms'] as int? ?? 0;
    }
    return values;
  }

  Future<void> clearListeningHistory() async {
    final d = await Db.get();
    await d.transaction((txn) async {
      await txn.delete('listening_sessions');
      await txn.delete('stats');
    });
    stats.clear();
    statsRevision.value++;
  }

  Future<void> logPlay(int id, {required bool skipped, int durationMs = 0, bool completed = false}) async {
    final st = stats.putIfAbsent(id, () => Stat(0, 0, 0));
    if (skipped) { st.skips++; } else { st.plays++; }
    st.last = DateTime.now().millisecondsSinceEpoch;
    st.totalMs += durationMs;
    if (completed) st.completed++;
    await (await Db.get()).insert('stats', {
      'id': id, 'plays': st.plays, 'skips': st.skips, 'last': st.last,
      'total_ms': st.totalMs, 'completed': st.completed,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    statsRevision.value++;
  }

  Future<List<Map<String, Object?>>> playlists() async =>
      (await Db.get()).query('playlists', orderBy: 'id DESC');
  Future<void> newPlaylist(String name) async => (await Db.get()).insert('playlists', {'name': name});
  Future<void> deletePlaylist(int id) async {
    final d = await Db.get();
    await d.delete('playlists', where: 'id=?', whereArgs: [id]);
    await d.delete('pl_songs', where: 'pl=?', whereArgs: [id]);
  }
  Future<void> addToPlaylist(int pl, int song) async => (await Db.get())
      .insert('pl_songs', {'pl': pl, 'song': song}, conflictAlgorithm: ConflictAlgorithm.ignore);
  Future<List<int>> playlistSongIds(int pl) async {
    final rows = await (await Db.get()).query('pl_songs', where: 'pl=?', whereArgs: [pl]);
    return rows.map((e) => e['song'] as int).toList();
  }
  Future<String?> getLyrics(int id) async {
    final rows = await (await Db.get()).query('lyrics', where: 'id=?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first['body'] as String;
  }
  Future<void> putLyrics(int id, String body) async => (await Db.get())
      .insert('lyrics', {'id': id, 'body': body}, conflictAlgorithm: ConflictAlgorithm.replace);
}