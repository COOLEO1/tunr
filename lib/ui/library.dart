import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/player.dart';
import '../core/meta.dart';
import '../data/repo.dart';
import 'playlists.dart';
import 'theme.dart';
import 'widgets.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});
  @override
  Widget build(BuildContext c) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Your Library', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(tooltip: 'Listening stats', icon: const Icon(Icons.insights_outlined), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const ListeningStatsPage())))],
        bottom: const TabBar(
          isScrollable: true,
          indicatorColor: accent,
          dividerColor: Colors.transparent,
          tabs: [Tab(text: 'Songs'), Tab(text: 'Artists'), Tab(text: 'Albums'), Tab(text: 'Favorites'), Tab(text: 'Playlists')],
        ),
      ),
      body: const TabBarView(children: [SongsTab(), ArtistsTab(), AlbumsTab(), FavTab(), PlaylistsTab()]),
    ),
  );
}

class SongsTab extends StatelessWidget {
  const SongsTab({super.key});
  @override
  Widget build(BuildContext c) {
    final all = Player.i.all;
    return ListView.builder(
      itemCount: all.length,
      itemBuilder: (_, i) => SongTile(all[i], onTap: () => Player.i.play(all, i)),
    );
  }
}

Map<String, List<SongModel>> _groupSongs(List<SongModel> songs, String Function(SongModel) keyOf) {
  final result = <String, List<SongModel>>{};
  for (final s in songs) {
    final key = keyOf(s).trim().isEmpty ? 'Unknown' : keyOf(s).trim();
    (result[key] ??= []).add(s);
  }
  return result;
}

class ArtistsTab extends StatelessWidget {
  const ArtistsTab({super.key});
  @override
  Widget build(BuildContext c) {
    final groups = _groupSongs(Player.i.all, artistOf).entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return ListView(children: [
      for (final e in groups)
        ListTile(
          leading: Art(e.value.first, size: 50, r: 25),
          title: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('\${e.value.length} songs'),
          trailing: const Icon(Icons.chevron_right, color: textMuted),
          onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => CollectionPage(e.key, e.value))),
        ),
    ]);
  }
}

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});
  @override
  Widget build(BuildContext c) {
    final groups = _groupSongs(Player.i.all, (s) => s.album ?? '').entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return ListView(children: [
      for (final e in groups)
        ListTile(
          leading: Art(e.value.first, size: 50, r: 7),
          title: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('\${artistOf(e.value.first)} • \${e.value.length} songs'),
          trailing: const Icon(Icons.chevron_right, color: textMuted),
          onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => CollectionPage(e.key, e.value))),
        ),
    ]);
  }
}

class CollectionPage extends StatelessWidget {
  final String title;
  final List<SongModel> songs;
  const CollectionPage(this.title, this.songs, {super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(title), actions: [
      IconButton(icon: const Icon(Icons.play_arrow_rounded), onPressed: () => Player.i.play(songs, 0)),
      IconButton(icon: const Icon(Icons.shuffle), onPressed: () {
        final shuffled = [...songs]..shuffle();
        Player.i.play(shuffled, 0);
      }),
    ]),
    body: ListView.builder(
      itemCount: songs.length,
      itemBuilder: (_, i) => SongTile(songs[i], onTap: () => Player.i.play(songs, i)),
    ),
  );
}

class FavTab extends StatelessWidget {
  const FavTab({super.key});
  @override
  Widget build(BuildContext c) => ValueListenableBuilder<Set<int>>(
    valueListenable: Repo.i.favs,
    builder: (_, f, __) {
      final list = Player.i.all.where((s) => f.contains(s.id)).toList();
      if (list.isEmpty) return const Center(child: Text('Tap the heart on a song', style: TextStyle(color: Colors.white54)));
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) => SongTile(list[i], onTap: () => Player.i.play(list, i)),
      );
    },
  );
}

String _timeLabel(int ms) {
  final minutes = ms ~/ 60000;
  final hours = minutes ~/ 60;
  if (hours > 0) return '\${hours}h \${minutes % 60}m';
  return '\${minutes}m';
}

class ListeningStatsPage extends StatelessWidget {
  const ListeningStatsPage({super.key});
  @override
  Widget build(BuildContext c) {
    final repo = Repo.i;
    final top = repo.mostPlayed;
    return Scaffold(
      appBar: AppBar(title: const Text('Listening insights')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _StatCard(label: 'Tracks played', value: '\${repo.totalPlays}', icon: Icons.play_circle_outline),
            _StatCard(label: 'Listening time', value: _timeLabel(repo.totalListeningMs), icon: Icons.headphones),
            _StatCard(label: 'Skipped tracks', value: '\${repo.totalSkips}', icon: Icons.skip_next),
            _StatCard(label: 'Near-completions', value: '\${repo.completedTracks}', icon: Icons.check_circle_outline),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Most played', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (top.isEmpty) const Text('Your listening stats will appear as you play music.', style: TextStyle(color: textMuted)),
        for (var i = 0; i < top.length; i++)
          if (Player.i.byId(top[i].key) != null)
            ListTile(
              leading: Text('\${i + 1}', style: const TextStyle(color: accent, fontWeight: FontWeight.w800)),
              title: Text(cleanTitle(Player.i.byId(top[i].key)!)),
              subtitle: Text(artistOf(Player.i.byId(top[i].key)!)),
              trailing: Text('\${top[i].value.plays} plays', style: const TextStyle(color: textMuted)),
              onTap: () => Player.i.play([Player.i.byId(top[i].key)!], 0),
            ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: accent),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: textMuted, fontSize: 12)),
    ]),
  );
}