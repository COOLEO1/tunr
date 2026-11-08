import 'package:flutter/material.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'playlists.dart';
import 'theme.dart';
import 'widgets.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext c) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('My Music',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => Player.i.shuffleAll(),
            icon: const Icon(Icons.shuffle, color: accent)),
        ],
        bottom: TabBar(
          indicatorColor: accent,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: muted,
          tabs: const [
            Tab(text: 'All songs'),
            Tab(text: 'Liked'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [SongsTab(), FavTab(), PlaylistsTab()],
      ),
    ),
  );
}

class SongsTab extends StatelessWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext c) {
    final songs = Player.i.all;
    if (songs.isEmpty) return const Center(
      child: Text('Your music will appear here', style: TextStyle(color: muted)));
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 25),
      itemCount: songs.length,
      itemBuilder: (_, i) => SongTile(songs[i],
        onTap: () => Player.i.play(songs, i)),
    );
  }
}

class FavTab extends StatelessWidget {
  const FavTab({super.key});

  @override
  Widget build(BuildContext c) => ValueListenableBuilder<Set<int>>(
    valueListenable: Repo.i.favs,
    builder: (_, f, __) {
      final songs = Player.i.all.where((s) => f.contains(s.id)).toList();
      if (songs.isEmpty) return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite_border, size: 55, color: accent),
          SizedBox(height: 12),
          Text('Your liked songs live here',
            style: TextStyle(color: muted)),
        ]),
      );
      return ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: songs.length,
        itemBuilder: (_, i) => SongTile(songs[i],
          onTap: () => Player.i.play(songs, i)),
      );
    },
  );
}
