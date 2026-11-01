import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart';

class Stat {
  int plays, skips, last;
  Stat(this.plays, this.skips, this.last);
}

class Repo {
  static final i = Repo._();
  Repo._();
  final favs = ValueNotifier<Set<int>>({});
  final stats = <int, Stat>{};

  Future<void> load() async {
    final d = await Db.get();
    favs.value = (await d.query('fav')).map((r) => r['id'] as int).toSet();
    for (final r in await d.query('stats')) {
      stats[r['id'] as int] = Stat(r['plays'] as int, r['skips'] as int, r['last'] as int);
    }
  }

  Future<void> toggleFav(int id) async {
    final d = await Db.get();
    final s = {...favs.value};
    if (s.remove(id)) {
      await d.delete('fav', where: 'id=?', whereArgs: [id]);
    } else {
      s.add(id);
      await d.insert('fav', {'id': id}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    favs.value = s;
  }

  Future<void> logPlay(int id, {required bool skipped}) async {
    final st = stats.putIfAbsent(id, () => Stat(0, 0, 0));
    if (skipped) {
      st.skips++;
    } else {
      st.plays++;
    }
    st.last = DateTime.now().millisecondsSinceEpoch;
    final d = await Db.get();
    await d.insert('stats', {'id': id, 'plays': st.plays, 'skips': st.skips, 'last': st.last},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> playlists() async =>
      (await Db.get()).query('playlists', orderBy: 'id DESC');

  Future<void> newPlaylist(String name) async =>
      (await Db.get()).insert('playlists', {'name': name});

  Future<void> deletePlaylist(int id) async {
    final d = await Db.get();
    await d.delete('playlists', where: 'id=?', whereArgs: [id]);
    await d.delete('pl_songs', where: 'pl=?', whereArgs: [id]);
  }

  Future<void> addToPlaylist(int pl, int song) async => (await Db.get())
      .insert('pl_songs', {'pl': pl, 'song': song}, conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<List<int>> playlistSongIds(int pl) async {
    final r = await (await Db.get()).query('pl_songs', where: 'pl=?', whereArgs: [pl]);
    return r.map((e) => e['song'] as int).toList();
  }

  Future<String?> getLyrics(int id) async {
    final r = await (await Db.get()).query('lyrics', where: 'id=?', whereArgs: [id]);
    return r.isEmpty ? null : r.first['body'] as String;
  }

  Future<void> putLyrics(int id, String body) async => (await Db.get())
      .insert('lyrics', {'id': id, 'body': body}, conflictAlgorithm: ConflictAlgorithm.replace);
}
