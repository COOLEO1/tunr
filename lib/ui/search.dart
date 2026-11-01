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
    final t = q.toLowerCase();
    final res = t.isEmpty
        ? []
        : Player.i.all
            .where((s) =>
                s.title.toLowerCase().contains(t) ||
                (s.artist ?? '').toLowerCase().contains(t) ||
                (s.album ?? '').toLowerCase().contains(t))
            .take(100)
            .toList();
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'Songs, artists, albums',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: res.length,
            itemBuilder: (_, i) => SongTile(res[i], onTap: () => Player.i.play([...res], i)),
          ),
        ),
      ]),
    );
  }
}
