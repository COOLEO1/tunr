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
            title: const Text('Your Library', style: TextStyle(fontWeight: FontWeight.w800)),
            bottom: const TabBar(
              indicatorColor: accent,
              dividerColor: Colors.transparent,
              tabs: [Tab(text: 'Songs'), Tab(text: 'Favorites'), Tab(text: 'Playlists')],
            ),
          ),
          body: const TabBarView(children: [SongsTab(), FavTab(), PlaylistsTab()]),
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

class FavTab extends StatelessWidget {
  const FavTab({super.key});
  @override
  Widget build(BuildContext c) => ValueListenableBuilder<Set<int>>(
        valueListenable: Repo.i.favs,
        builder: (_, f, __) {
          final list = Player.i.all.where((s) => f.contains(s.id)).toList();
          if (list.isEmpty) {
            return const Center(child: Text('Tap the heart on a song', style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => SongTile(list[i], onTap: () => Player.i.play(list, i)),
          );
        },
      );
}
