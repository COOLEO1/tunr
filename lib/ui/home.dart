import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext c) {
    final p = Player.i;
    final h = DateTime.now().hour;
    final greet = h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';
    return SafeArea(
      child: ValueListenableBuilder<SongModel?>(
        valueListenable: p.current,
        builder: (_, __, ___) {
          final entries = Repo.i.stats.entries.toList()..sort((a, b) => b.value.last.compareTo(a.value.last));
          final recent = entries.take(12).map((e) => p.byId(e.key)).whereType<SongModel>().toList();
          return ListView(padding: const EdgeInsets.all(20), children: [
            Text(greet, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: p.shuffleAll,
              icon: const Icon(Icons.shuffle),
              label: Text('Shuffle all (${p.all.length})'),
            ),
            const SizedBox(height: 28),
            if (recent.isNotEmpty) ...[
              const Text('Jump back in', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final s = recent[i];
                    return GestureDetector(
                      onTap: () => p.radio(s),
                      child: SizedBox(
                        width: 130,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Art(s, size: 130, r: 10),
                          const SizedBox(height: 8),
                          Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(s.artist ?? 'Unknown',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Text('Play a few songs and your history shows up here.', style: TextStyle(color: Colors.white54)),
          ]);
        },
      ),
    );
  }
}
