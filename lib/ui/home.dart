import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'ai_companion.dart';
import 'ai_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

const _heading = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.4);

List<Widget> _songRow(String title, List<SongModel> list) {
  if (list.isEmpty) return [];
  return [
    const SizedBox(height: 28),
    Row(children: [
      Expanded(child: Text(title, style: _heading)),
      Text(list.length.toString(), style: const TextStyle(color: textMuted, fontSize: 11)),
    ]),
    const SizedBox(height: 13),
    SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final song = list[i];
          return GestureDetector(
            onTap: () => Player.i.radio(song),
            child: SizedBox(width: 132, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Art(song, size: 132, r: 15),
              const SizedBox(height: 9),
              Text(cleanTitle(song), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(artistOf(song), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: textMuted, fontSize: 12)),
            ])),
          );
        },
      ),
    ),
  ];
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Player.i;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'GOOD MORNING' : hour < 18 ? 'GOOD AFTERNOON' : 'GOOD EVENING';
    return SafeArea(
      child: ValueListenableBuilder<SongModel?>(
        valueListenable: player.current,
        builder: (_, current, __) {
          final stats = Repo.i.stats.entries.toList()
            ..sort((a, b) => b.value.last.compareTo(a.value.last));
          final recent = stats.take(12).map((e) => player.byId(e.key)).whereType<SongModel>().toList();
          final added = [...player.all]..sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
          final favIds = Repo.i.favs.value;
          final favorites = player.all.where((s) => favIds.contains(s.id)).toList();
          final popular = [...player.all]
            ..sort((a, b) => (Repo.i.stats[b.id]?.plays ?? 0).compareTo(Repo.i.stats[a.id]?.plays ?? 0));
          final hasPopular = popular.isNotEmpty && (Repo.i.stats[popular.first.id]?.plays ?? 0) > 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting, style: const TextStyle(color: accent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  const Text('Your sound,\nyour world.', style: TextStyle(fontSize: 29, height: 1.04, letterSpacing: -1.1, fontWeight: FontWeight.w900)),
                ])),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15), border: Border.all(color: outline)),
                  child: const Icon(Icons.graphic_eq_rounded, color: accent),
                ),
              ]),
              const SizedBox(height: 23),
              if (current != null)
                _ContinueCard(song: current)
              else
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF2A1D45), Color(0xFF14101E), Color(0xFF09090D)]),
                    border: Border.all(color: accent.withOpacity(.24)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('YOUR PERSONAL SOUNDTRACK', style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 13),
                    const Text('Every mood.\nOne library.', style: TextStyle(fontSize: 27, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                    const SizedBox(height: 8),
                    Text(player.all.isEmpty ? 'Add music to your device to get started.' :
                      player.all.length.toString() + ' tracks ready when you are.',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: player.all.isEmpty ? null : player.shuffleAll,
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('Start listening'),
                      style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: const Color(0xFF100B1C)),
                    ),
                  ]),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _QuickAction(
                  icon: Icons.auto_awesome_rounded, title: 'Music AI',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCompanionPage())),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.shuffle_rounded, title: 'Shuffle all',
                  onTap: player.shuffleAll,
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.playlist_add_rounded, title: 'Create mix',
                  onTap: () => showAiSheet(context),
                )),
              ]),
              ..._songRow('Jump back in', recent),
              ..._songRow('Heavy rotation', hasPopular ? popular.take(15).toList() : []),
              ..._songRow('Your favourites', favorites.take(15).toList()),
              ..._songRow('Recently added', added.take(15).toList()),
              if (player.all.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('Your library', style: _heading),
                const SizedBox(height: 8),
                Text(player.all.length.toString() + ' songs · stored on this device',
                  style: const TextStyle(color: textMuted, fontSize: 12)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final SongModel song;
  const _ContinueCard({required this.song});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(children: [
      Positioned.fill(child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Opacity(opacity: .55, child: Art(song, size: 420, r: 0)),
      )),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [bg.withOpacity(.45), bg.withOpacity(.94)]),
      ))),
      Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.play_circle_outline_rounded, color: accent, size: 17),
          SizedBox(width: 7),
          Text('CONTINUE LISTENING', style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 17),
        Row(children: [
          Art(song, size: 94, r: 14),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cleanTitle(song), maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(artistOf(song), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => Player.i.ap.play(),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Resume'),
            ),
          ])),
        ]),
      ])),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: card, borderRadius: BorderRadius.circular(15),
    child: InkWell(
      borderRadius: BorderRadius.circular(15), onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
        child: Column(children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 7),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}