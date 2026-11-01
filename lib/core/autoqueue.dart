import 'dart:math';
import 'package:on_audio_query/on_audio_query.dart';
import '../data/repo.dart';
import 'meta.dart';
import 'similar.dart';

class AutoQueue {
  static Set<String> similar = {};
  static final _r = Random();

  static Future<void> prepare(SongModel s) async {
    similar = await Similar.get(artistOf(s));
  }

  static bool _isSimilar(String artist) {
    final x = artist.toLowerCase();
    return x != 'unknown artist' && similar.any((n) => x.contains(n) || n.contains(x));
  }

  static List<SongModel> pick(
    SongModel cur,
    List<SongModel> all,
    Set<int> exclude,
    int n, {
    String mode = 'balanced',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final curArtist = artistOf(cur).toLowerCase();
    final scored = <MapEntry<SongModel, double>>[];
    for (final s in all) {
      if (exclude.contains(s.id)) continue;
      final artist = artistOf(s);
      final a = artist.toLowerCase();
      final stat = Repo.i.stats[s.id];
      var score = _r.nextDouble() * 1.2;
      if (a == curArtist && a != 'unknown artist') score += mode == 'familiar' ? 6 : 2;
      if (_isSimilar(artist)) score += mode == 'discover' ? 6 : 3;
      if (s.genre != null && s.genre == cur.genre) score += 2;
      if (Repo.i.favs.value.contains(s.id)) score += mode == 'familiar' ? 3 : 1.2;
      if (stat != null) {
        score += min(stat.plays, 5) * (mode == 'discover' ? .12 : .45);
        score -= min(stat.skips, 8) * (mode == 'familiar' ? .55 : 1.1);
        final age = now - stat.last;
        if (age < 3600000) score -= mode == 'familiar' ? 1.5 : 4.5;
        else if (age > const Duration(days: 30).inMilliseconds) score += mode == 'discover' ? 3 : 1.2;
      } else {
        score += mode == 'discover' ? 3.5 : 1;
      }
      scored.add(MapEntry(s, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));

    // Greedy artist diversity: don't let one artist dominate a radio queue.
    final selected = <SongModel>[];
    final artistCounts = <String, int>{};
    final deferred = <SongModel>[];
    final perArtistLimit = mode == 'familiar' ? 3 : 2;
    for (final entry in scored) {
      final artist = artistOf(entry.key).toLowerCase();
      final count = artistCounts[artist] ?? 0;
      if (artist == 'unknown artist' || count < perArtistLimit) {
        selected.add(entry.key);
        artistCounts[artist] = count + 1;
        if (selected.length >= n) break;
      } else {
        deferred.add(entry.key);
      }
    }
    if (selected.length < n) selected.addAll(deferred.take(n - selected.length));
    return selected;
  }
}
