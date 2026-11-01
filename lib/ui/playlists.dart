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
    builder: (_) => SafeArea(
      child: ListView(shrinkWrap: true, children: [
        if (pls.isEmpty) const ListTile(title: Text('No playlists yet. Create one in Library.')),
        for (final p in pls)
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(p['name'] as String),
            onTap: () {
              Repo.i.addToPlaylist(p['id'] as int, songId);
              Navigator.pop(c);
            },
          ),
      ]),
    ),
  );
}

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});
  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  Future<void> _create() async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: card,
        title: const Text('New playlist'),
        content: TextField(controller: ctl, autofocus: true, decoration: const InputDecoration(hintText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctl.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await Repo.i.newPlaylist(name);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext c) => FutureBuilder<List<Map<String, Object?>>>(
        future: Repo.i.playlists(),
        builder: (_, sn) {
          final pls = sn.data ?? [];
          return ListView(children: [
            ListTile(
              leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.add)),
              title: const Text('New playlist', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: _create,
            ),
            for (final p in pls)
              ListTile(
                leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.queue_music, color: accent)),
                title: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.push(
                    c, MaterialPageRoute(builder: (_) => PlaylistPage(p['id'] as int, p['name'] as String))),
                onLongPress: () async {
                  await Repo.i.deletePlaylist(p['id'] as int);
                  setState(() {});
                },
              ),
          ]);
        },
      );
}

class PlaylistPage extends StatelessWidget {
  final int id;
  final String name;
  const PlaylistPage(this.id, this.name, {super.key});

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: FutureBuilder<List<int>>(
          future: Repo.i.playlistSongIds(id),
          builder: (_, sn) {
            final songs = (sn.data ?? []).map(Player.i.byId).whereType<SongModel>().toList();
            if (songs.isEmpty) {
              return const Center(child: Text('Empty. Add songs from the ⋮ menu.', style: TextStyle(color: Colors.white54)));
            }
            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (_, i) => SongTile(songs[i], onTap: () => Player.i.play(songs, i)),
            );
          },
        ),
      );
}
