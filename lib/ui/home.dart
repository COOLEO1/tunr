import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'ai_sheet.dart';
import 'settings_page.dart';
import 'theme.dart';
import 'widgets.dart';

const _h = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);

List<Widget> _songRow(String title, List<SongModel> list) {
  if (list.isEmpty) return [];
  return [
    const SizedBox(height: 28),
    Text(title, style: _h),
    const SizedBox(height: 12),
    SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final s = list[i];
          return GestureDetector(
            onTap: () => Player.i.radio(s),
            child: SizedBox(
              width: 130,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Art(s, size: 130, r: 10),
                const SizedBox(height: 8),
                Text(cleanTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(artistOf(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ),
          );
        },
      ),
    ),
  ];
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext c) {
    final p = Player.i;
    final h = DateTime.now().hour;
    final greet = h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: const Alignment(0, -.2),
          colors: [accent.withOpacity(.30), bg],
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<SongModel?>(
          valueListenable: p.current,
          builder: (_, __, ___) {
            final entries = Repo.i.stats.entries.toList()..sort((a, b) => b.value.last.compareTo(a.value.last));
            final recent = entries.take(12).map((e) => p.byId(e.key)).whereType<SongModel>().toList();
            final added = [...p.all]..sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
            final groups = <String, List<SongModel>>{};
            for (final s in p.all) {
              final a = artistOf(s);
              if (a != 'Unknown artist') groups.putIfAbsent(a, () => []).add(s);
            }
            final artists = groups.entries.where((e) => e.value.length >= 2).toList()
              ..sort((a, b) => b.value.length.compareTo(a.value.length));
            return ListView(padding: const EdgeInsets.all(20), children: [
              Row(children: [
                Expanded(child: Text(greet, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const SettingsPage())),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: p.shuffleAll,
                    icon: const Icon(Icons.shuffle),
                    label: Text('Shuffle (${p.all.length})'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => showAiSheet(c),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI playlist'),
                  ),
                ),
              ]),
              ..._songRow('Jump back in', recent),
              ..._songRow('Recently added', added.take(15).toList()),
              if (artists.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('Your artists', style: _h),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: artists.take(12).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final e = artists[i];
                      return GestureDetector(
                        onTap: () => p.play([...e.value]..shuffle(), 0),
                        child: SizedBox(
                          width: 100,
                          child: Column(children: [
                            Art(e.value.first, size: 100, r: 50),
                            const SizedBox(height: 8),
                            Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${e.value.length} songs', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ]);
          },
        ),
      ),
    );
  }
}
