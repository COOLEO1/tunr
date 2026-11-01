import 'dart:math';
import 'package:on_audio_query/on_audio_query.dart';
import '../data/repo.dart';

class AutoQueue {
  /// lowercase artist names similar to the current one (Last.fm fills this later)
  static Set<String> similar = {};
  static final _r = Random();

  static List<SongModel> pick(SongModel cur, List<SongModel> all, Set<int> exclude, int n) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final scored = <MapEntry<SongModel, double>>[];
    for (final s in all) {
      if (exclude.contains(s.id)) continue;
      var sc = _r.nextDouble() * 2;
      if (s.artist != null && s.artist == cur.artist) sc += 5;
      if (s.artist != null && similar.contains(s.artist!.toLowerCase())) sc += 4;
      if (s.genre != null && s.genre == cur.genre) sc += 3;
      if (s.album != null && s.album == cur.album) sc += 1.5;
      if (Repo.i.favs.value.contains(s.id)) sc += 1;
      final st = Repo.i.stats[s.id];
      if (st != null) {
        sc += min(st.plays, 5) * 0.4 - st.skips * 1.5;
        if (now - st.last < 3600000) sc -= 4;
      }
      scored.add(MapEntry(s, sc));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(n).map((e) => e.key).toList();
  }
}
