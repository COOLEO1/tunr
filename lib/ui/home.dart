import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'ai_companion.dart';
import 'ai_sheet.dart';
import 'settings_page.dart';
import 'theme.dart';
import 'widgets.dart';

const _h = TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.2);

List<Widget> _songRow(String title, List<SongModel> list) {
  if (list.isEmpty) return [];
  return [
    const SizedBox(height: 28),
    Text(title, style: _h),
    const SizedBox(height: 13),
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
              width: 132,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Art(s, size: 132, r: 13),
                const SizedBox(height: 9),
                Text(cleanTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(artistOf(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textMuted, fontSize: 12)),
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
      color: bg,
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
            final favs = Repo.i.favs.value;
            final favourites = p.all.where((s) => favs.contains(s.id)).toList();
            return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 28), children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greet, style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  const Text('Your sound, your world.', style: TextStyle(fontSize: 25, letterSpacing: -.8, fontWeight: FontWeight.w900)),
                ])),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: card),
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const SettingsPage())),
                ),
              ]),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withOpacity(.22)),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF211A35), Color(0xFF111019), Color(0xFF0A0A0E)]),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome, color: accent, size: 18),
                    const SizedBox(width: 7),
                    const Text('TUNR INTELLIGENCE', style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${p.all.length} tracks', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Find the feeling.\nWe’ll find the music.', style: TextStyle(fontSize: 22, height: 1.12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('AI-crafted mixes and personal radio, built around your library.', style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: const Color(0xFF100B1C)),
                      onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const AiCompanionPage())),
                      icon: const Icon(Icons.auto_awesome, size: 17), label: const Text('Open companion'),
                    )),
                    const SizedBox(width: 9),
                    IconButton.filledTonal(
                      tooltip: 'Quick AI playlist',
                      onPressed: () => showAiSheet(c),
                      icon: const Icon(Icons.playlist_add),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: outline), padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: p.shuffleAll, icon: const Icon(Icons.shuffle, size: 18), label: Text('Shuffle all · ${p.all.length}'),
                )),
              ]),
              ..._songRow('Jump back in', recent),
              ..._songRow('Your favourites', favourites.take(15).toList()),
              ..._songRow('Recently added', added.take(15).toList()),
              if (artists.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('Your artists', style: _h),
                const SizedBox(height: 13),
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
                        child: SizedBox(width: 100, child: Column(children: [
                          Art(e.value.first, size: 100, r: 50),
                          const SizedBox(height: 8),
                          Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${e.value.length} songs', style: const TextStyle(color: textMuted, fontSize: 11)),
                        ])),
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
