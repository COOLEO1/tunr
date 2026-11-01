import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/player.dart';
import '../core/meta.dart';
import '../data/repo.dart';
import 'theme.dart';
import 'widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String q = '';
  String filter = 'Songs';
  String sort = 'Title';

  List<SongModel> get matches {
    final term = q.trim().toLowerCase();
    final list = Player.i.all.where((s) {
      if (term.isEmpty) return false;
      return cleanTitle(s).toLowerCase().contains(term) ||
          artistOf(s).toLowerCase().contains(term) ||
          (s.album ?? '').toLowerCase().contains(term) ||
          (s.genre ?? '').toLowerCase().contains(term);
    }).toList();
    if (sort == 'Recently added') {
      list.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    } else if (sort == 'Most played') {
      list.sort((a, b) => (Repo.i.stats[b.id]?.plays ?? 0).compareTo(Repo.i.stats[a.id]?.plays ?? 0));
    } else {
      list.sort((a, b) => cleanTitle(a).toLowerCase().compareTo(cleanTitle(b).toLowerCase()));
    }
    return list;
  }

  Map<String, List<SongModel>> _groups(List<SongModel> songs, String Function(SongModel) keyOf) {
    final result = <String, List<SongModel>>{};
    for (final s in songs) {
      final key = keyOf(s).trim().isEmpty ? 'Unknown' : keyOf(s).trim();
      (result[key] ??= []).add(s);
    }
    return result;
  }

  @override
  Widget build(BuildContext c) {
    final res = matches;
    final artists = _groups(res, artistOf);
    final albums = _groups(res, (s) => s.album ?? 'Unknown album');
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'Songs, artists, albums, genres',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => q = '')),
              filled: true, fillColor: card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            for (final item in ['Songs', 'Artists', 'Albums'])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(item),
                  selected: filter == item,
                  onSelected: (_) => setState(() => filter = item),
                  selectedColor: accent.withOpacity(.2),
                ),
              ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: sort,
              underline: const SizedBox.shrink(),
              dropdownColor: card,
              items: const [
                DropdownMenuItem(value: 'Title', child: Text('Title A–Z')),
                DropdownMenuItem(value: 'Recently added', child: Text('Recently added')),
                DropdownMenuItem(value: 'Most played', child: Text('Most played')),
              ],
              onChanged: (v) => setState(() => sort = v ?? 'Title'),
            ),
          ]),
        ),
        Expanded(
          child: q.trim().isEmpty
              ? const Center(child: Text('Search your music library', style: TextStyle(color: textMuted)))
              : res.isEmpty
                  ? const Center(child: Text('No matches found', style: TextStyle(color: textMuted)))
                  : filter == 'Songs'
                      ? ListView.builder(
                          itemCount: res.length,
                          itemBuilder: (_, i) => SongTile(res[i], onTap: () => Player.i.play(res, i)),
                        )
                      : filter == 'Artists'
                          ? ListView(children: artists.entries.map((e) => ListTile(
                              leading: Art(e.value.first, size: 48),
                              title: Text(e.key),
                              subtitle: Text('\${e.value.length} tracks'),
                              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => SearchCollectionPage(e.key, e.value))),
                            )).toList())
                          : ListView(children: albums.entries.map((e) => ListTile(
                              leading: Art(e.value.first, size: 48),
                              title: Text(e.key),
                              subtitle: Text('\${artistOf(e.value.first)} • \${e.value.length} tracks'),
                              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => SearchCollectionPage(e.key, e.value))),
                            )).toList()),
        ),
      ]),
    );
  }
}

class SearchCollectionPage extends StatelessWidget {
  final String title;
  final List<SongModel> songs;
  const SearchCollectionPage(this.title, this.songs, {super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView.builder(
      itemCount: songs.length,
      itemBuilder: (_, i) => SongTile(songs[i], onTap: () => Player.i.play(songs, i)),
    ),
  );
}