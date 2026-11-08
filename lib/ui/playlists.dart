import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> addToPlaylistDialog(BuildContext c, int songId) async {
  final pls = await Repo.i.playlists();
  if (!c.mounted) return;

  showModalBottomSheet(
    context: c,
    backgroundColor: card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(15),
        children: [
          const Center(child: Text('ADD TO PLAYLIST',
            style: TextStyle(
              fontWeight: FontWeight.w900, letterSpacing: 1.5))),
          const SizedBox(height: 15),
          if (pls.isEmpty)
            const ListTile(title: Text('Create a playlist first')),
          for (final p in pls)
            ListTile(
              leading: const Icon(Icons.queue_music, color: accent),
              title: Text(p['name'] as String),
              onTap: () {
                Repo.i.addToPlaylist(p['id'] as int, songId);
                Navigator.pop(c);
              },
            ),
        ],
      ),
    ),
  );
}

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});
  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  Future<void> create() async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: const Text('Create playlist'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    ctl.dispose();
    if (name != null && name.isNotEmpty) {
      await Repo.i.newPlaylist(name);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext c) => FutureBuilder<List<Map<String, Object?>>>(
    future: Repo.i.playlists(),
    builder: (_, sn) {
      final playlists = sn.data ?? [];
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
        children: [
          GestureDetector(
            onTap: create,
            child: Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF9200E8), Color(0xFF39105F)],
                ),
              ),
              child: const Row(children: [
                Icon(Icons.add_circle_outline, size: 35),
                SizedBox(width: 13),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create a playlist',
                      style: TextStyle(fontWeight: FontWeight.w900,
                        fontSize: 16)),
                    Text('Build your own music collection',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )),
                Icon(Icons.arrow_forward_ios, size: 15),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          const Text('YOUR COLLECTION',
            style: TextStyle(
              fontSize: 11, letterSpacing: 1.5,
              color: muted, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (sn.connectionState == ConnectionState.waiting)
            const Center(child: CircularProgressIndicator(color: accent)),
          if (playlists.isEmpty && sn.connectionState == ConnectionState.done)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Your playlists will appear here',
                style: TextStyle(color: muted))),
            ),
          for (final p in playlists)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: accent.withOpacity(.12)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
                leading: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB32CFF), Color(0xFF35105D)],
                    ),
                  ),
                  child: const Icon(Icons.queue_music, color: Colors.white),
                ),
                title: Text(p['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Your personal collection',
                  style: TextStyle(color: muted, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, color: accent),
                onTap: () => Navigator.push(c, MaterialPageRoute(
                  builder: (_) => PlaylistPage(
                    p['id'] as int, p['name'] as String))),
                onLongPress: () async {
                  await Repo.i.deletePlaylist(p['id'] as int);
                  if (mounted) setState(() {});
                },
              ),
            ),
        ],
      );
    },
  );
}

class PlaylistPage extends StatelessWidget {
  final int id;
  final String name;
  const PlaylistPage(this.id, this.name, {super.key});

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(name,
      style: const TextStyle(fontWeight: FontWeight.w900))),
    body: FutureBuilder<List<int>>(
      future: Repo.i.playlistSongIds(id),
      builder: (_, sn) {
        final songs = (sn.data ?? [])
          .map(Player.i.byId).whereType<SongModel>().toList();
        if (songs.isEmpty) return const Center(
          child: Text('This playlist is waiting for music.',
            style: TextStyle(color: muted)));
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12),
          itemCount: songs.length,
          itemBuilder: (_, i) => SongTile(songs[i],
            onTap: () => Player.i.play(songs, i)),
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      onPressed: () async {
        final all = Player.i.all;
        if (all.isEmpty) return;
        final song = await showModalBottomSheet<SongModel>(
          context: c,
          backgroundColor: card,
          builder: (_) => ListView(children: [
            const ListTile(title: Text('Choose a song')),
            for (final s in all)
              ListTile(
                leading: Art(s),
                title: Text(s.title, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(c, s),
              ),
          ]),
        );
        if (song != null) {
          await Repo.i.addToPlaylist(id, song.id);
        }
      },
      child: const Icon(Icons.add),
    ),
  );
}
