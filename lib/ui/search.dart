import 'package:flutter/material.dart';
import '../core/player.dart';
import 'theme.dart';
import 'widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String q = '';

  @override
  Widget build(BuildContext c) {
    final query = q.trim().toLowerCase();
    final results = query.isEmpty ? [] : Player.i.all.where((s) {
      return s.title.toLowerCase().contains(query) ||
        (s.artist ?? '').toLowerCase().contains(query) ||
        (s.album ?? '').toLowerCase().contains(query);
    }).take(150).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'Songs, artists, albums...',
              prefixIcon: const Icon(Icons.search, color: accent),
              suffixIcon: q.isEmpty ? null : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => q = ''),
              ),
            ),
          ),
        ),
        Expanded(child: query.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: purple.withOpacity(.13),
                  ),
                  child: const Icon(Icons.search, size: 48, color: accent),
                ),
                const SizedBox(height: 17),
                const Text('Find your sound',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                const Text('Search your personal music library',
                  style: TextStyle(color: muted)),
              ],
            ))
          : results.isEmpty
            ? const Center(child: Text('No matching songs found',
                style: TextStyle(color: muted)))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: results.length,
                itemBuilder: (_, i) => SongTile(results[i],
                  onTap: () => Player.i.play(results, i)),
              ),
        ),
      ]),
    );
  }
}
