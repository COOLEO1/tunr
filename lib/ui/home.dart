import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'ai_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget heading(String text, {String action = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 25),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800,
            )),
          ),
          if (action.isNotEmpty)
            Text(action, style: const TextStyle(
              color: accent, fontWeight: FontWeight.w600,
            )),
        ],
      ),
    );
  }

  Widget songCards(List<SongModel> songs) {
    if (songs.isEmpty) {
      return const Text('Add music to your device to get started.',
          style: TextStyle(color: muted));
    }
    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 13),
        itemBuilder: (_, i) {
          final s = songs[i];
          return GestureDetector(
            onTap: () => Player.i.radio(s),
            child: SizedBox(
              width: 145,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Art(s, size: 145, r: 17),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xBB080411)],
                              stops: [.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10, right: 8, bottom: 10,
                          child: Text(cleanTitle(s),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(artistOf(s), maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final p = Player.i;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' :
        hour < 18 ? 'Good afternoon' : 'Good evening';

    final recentEntries = Repo.i.stats.entries.toList()
      ..sort((a, b) => b.value.last.compareTo(a.value.last));
    final recent = recentEntries.take(12)
      .map((e) => p.byId(e.key)).whereType<SongModel>().toList();

    final added = [...p.all]
      ..sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF290044), bg, bg],
          stops: [0, .48, 1],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 28),
          children: [
            Row(
              children: [
                const Icon(Icons.graphic_eq, color: accent, size: 30),
                const SizedBox(width: 9),
                const Text('TUNR', style: TextStyle(
                  fontSize: 23, fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                )),
                const Spacer(),
                IconButton(
                  onPressed: () => showAiSheet(c),
                  icon: const Icon(Icons.auto_awesome, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(greeting, style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900,
            )),
            const Text("Let's find your next favourite song.",
              style: TextStyle(color: muted, fontSize: 14)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => showAiSheet(c),
              child: Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8100F5), Color(0xFF35105D)],
                  ),
                  boxShadow: [
                    BoxShadow(color: purple.withOpacity(.25),
                      blurRadius: 25, offset: const Offset(0, 9)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 34),
                    SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your AI Music Companion',
                          style: TextStyle(fontWeight: FontWeight.w800,
                            fontSize: 15)),
                        SizedBox(height: 5),
                        Text('Create a playlist for any mood',
                          style: TextStyle(color: Colors.white70,
                            fontSize: 12)),
                      ],
                    )),
                    Icon(Icons.arrow_forward_ios, size: 17),
                  ],
                ),
              ),
            ),
            heading('Made for you'),
            if (recent.isNotEmpty)
              songCards(recent)
            else
              songCards(added.take(12).toList()),
            heading('Recently added'),
            songCards(added.take(15).toList()),
            heading('Your music'),
            Container(
              decoration: BoxDecoration(
                color: card.withOpacity(.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(.13)),
              ),
              child: Column(children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF4B1282),
                    child: Icon(Icons.music_note, color: Colors.white),
                  ),
                  title: const Text('All songs',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${p.all.length} songs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => p.shuffleAll(),
                ),
                const Divider(height: 1, color: Colors.white10),
                ValueListenableBuilder<Set<int>>(
                  valueListenable: Repo.i.favs,
                  builder: (_, f, __) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF4B1282),
                      child: Icon(Icons.favorite, color: Colors.white),
                    ),
                    title: const Text('Liked songs',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${f.length} songs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final songs = p.all.where((s) => f.contains(s.id)).toList();
                      if (songs.isNotEmpty) p.play(songs, 0);
                    },
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
