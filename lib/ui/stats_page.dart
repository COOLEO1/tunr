import 'package:flutter/material.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'theme.dart';
import 'widgets.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final songs = Player.i.all;
    final ranked = Repo.i.stats.entries.toList()
      ..sort((a, b) => b.value.plays.compareTo(a.value.plays));

    final totalPlays = Repo.i.stats.values.fold<int>(
      0, (sum, s) => sum + s.plays,
    );
    final totalSkips = Repo.i.stats.values.fold<int>(
      0, (sum, s) => sum + s.skips,
    );

    final artists = <String, int>{};
    for (final entry in Repo.i.stats.entries) {
      final song = Player.i.byId(entry.key);
      if (song != null) {
        final artist = artistOf(song);
        artists[artist] = (artists[artist] ?? 0) + entry.value.plays;
      }
    }
    final topArtist = artists.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget metric(String label, String value, IconData icon) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 23),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(
              color: muted, fontSize: 12)),
          ],
        ),
      ));

    return Scaffold(
      appBar: AppBar(title: const Text('Your Music DNA',
        style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Your listening overview',
            style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          Row(children: [
            metric('Completed plays', '$totalPlays', Icons.play_circle),
            const SizedBox(width: 12),
            metric('Skipped tracks', '$totalSkips', Icons.skip_next),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            metric('Library songs', '${songs.length}', Icons.library_music),
            const SizedBox(width: 12),
            metric('Artists played', '${artists.length}', Icons.person),
          ]),
          const SizedBox(height: 28),
          const Text('Your top artist',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (topArtist.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7200B8), Color(0xFF24103D)],
                ),
              ),
              child: Row(children: [
                const Icon(Icons.graphic_eq, size: 38),
                const SizedBox(width: 14),
                Expanded(child: Text(topArtist.first.key,
                  style: const TextStyle(fontSize: 19,
                    fontWeight: FontWeight.w900))),
                Text('${topArtist.first.value} plays'),
              ]),
            )
          else
            const Text('Play some music to build your listening profile.',
              style: TextStyle(color: muted)),
          const SizedBox(height: 28),
          const Text('Most played tracks',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (ranked.isEmpty)
            const Text('Your listening history will appear here.',
              style: TextStyle(color: muted)),
          for (final entry in ranked.take(10))
            if (Player.i.byId(entry.key) != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Art(Player.i.byId(entry.key)!),
                title: Text(cleanTitle(Player.i.byId(entry.key)!),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(artistOf(Player.i.byId(entry.key)!)),
                trailing: Text('${entry.value.plays} plays',
                  style: const TextStyle(color: accent)),
                onTap: () => Player.i.radio(Player.i.byId(entry.key)!),
              ),
        ],
      ),
    );
  }
}
