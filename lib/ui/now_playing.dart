import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/lyrics.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'lyrics_view.dart';
import 'playlists.dart';
import 'theme.dart';
import 'widgets.dart';

String fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key});

  void _showQueue(BuildContext context) {
    final p = Player.i;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .65,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(children: [
                const Expanded(child: Text('Up next', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                Text('${p.queue.length} tracks', style: const TextStyle(color: textMuted)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: p.queue.length,
                itemBuilder: (_, i) {
                  final song = p.queue[i];
                  final active = p.current.value?.id == song.id;
                  return ListTile(
                    leading: Art(song, size: 46, r: 8),
                    title: Text(cleanTitle(song), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: active ? accent : Colors.white, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                    subtitle: Text(artistOf(song), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: active ? const Icon(Icons.graphic_eq, color: accent) : Text('${i + 1}', style: const TextStyle(color: textMuted)),
                    onTap: () async {
                      await p.ap.seek(Duration.zero, index: i);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final p = Player.i;
    return ValueListenableBuilder<SongModel?>(
      valueListenable: p.current,
      builder: (_, s, __) {
        if (s == null) return const Scaffold();
        final size = MediaQuery.of(c).size;
        final artSize = math.min(size.width - 64, size.height * .43);
        return Scaffold(
          backgroundColor: bg,
          body: Stack(children: [
            Positioned.fill(
              child: ClipRect(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 55, sigmaY: 55),
                  child: Opacity(opacity: .42, child: Center(child: Art(s, size: size.width * 1.35, r: 0))),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [bg.withOpacity(.38), bg.withOpacity(.76), bg],
                    stops: const [0, .48, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 32), onPressed: () => Navigator.pop(c)),
                    const Column(children: [
                      Text('NOW PLAYING', style: TextStyle(fontSize: 11, letterSpacing: 2, color: textMuted, fontWeight: FontWeight.w700)),
                      Text('YOUR LIBRARY', style: TextStyle(fontSize: 9, letterSpacing: 1.6, color: Colors.white38)),
                    ]),
                    IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => songMenu(c, s)),
                  ]),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: Lyrics.enabled,
                      builder: (_, on, __) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        child: on
                            ? LyricsView(key: ValueKey('lyrics-${s.id}'), song: s)
                            : Center(
                                key: ValueKey('art-${s.id}'),
                                child: Hero(
                                  tag: 'tunr-art-${s.id}',
                                  child: StreamBuilder<bool>(
                                    stream: p.ap.playingStream,
                                    builder: (_, sn) => AnimatedScale(
                                      scale: (sn.data ?? false) ? 1 : .94,
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOutCubic,
                                      child: Container(
                                        width: artSize, height: artSize,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(22),
                                          boxShadow: [BoxShadow(color: tintFor(s).withOpacity(.3), blurRadius: 48, spreadRadius: 2, offset: const Offset(0, 22))],
                                        ),
                                        child: Art(s, size: artSize, r: 22),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cleanTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 23, letterSpacing: -.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(artistOf(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textMuted, fontSize: 15)),
                    ])),
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: Repo.i.favs,
                      builder: (_, f, __) {
                        final fav = f.contains(s.id);
                        return IconButton(
                          iconSize: 27,
                          icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? accent : Colors.white70),
                          onPressed: () => Repo.i.toggleFav(s.id),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 8),
                  StreamBuilder<Duration>(
                    stream: p.ap.positionStream,
                    builder: (_, sn) {
                      final pos = sn.data ?? Duration.zero;
                      final dur = p.ap.duration ?? Duration(milliseconds: s.duration ?? 1);
                      final mx = math.max(1.0, dur.inMilliseconds.toDouble());
                      return Column(children: [
                        Slider(value: math.min(pos.inMilliseconds.toDouble(), mx), max: mx,
                          onChanged: (v) => p.ap.seek(Duration(milliseconds: v.toInt()))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(fmt(pos), style: const TextStyle(fontSize: 11, color: textMuted)),
                            Text(fmt(dur), style: const TextStyle(fontSize: 11, color: textMuted)),
                          ]),
                        ),
                      ]);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: p.shuffle,
                      builder: (_, on, __) => IconButton(icon: Icon(Icons.shuffle, color: on ? accent : textMuted), onPressed: p.toggleShuffle),
                    ),
                    IconButton(iconSize: 34, onPressed: p.ap.seekToPrevious, icon: const Icon(Icons.skip_previous_rounded)),
                    StreamBuilder<bool>(
                      stream: p.ap.playingStream,
                      builder: (_, sn) {
                        final playing = sn.data ?? false;
                        return GestureDetector(
                          onTap: () => playing ? p.ap.pause() : p.ap.play(),
                          child: Container(
                            width: 72, height: 72,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 42),
                          ),
                        );
                      },
                    ),
                    IconButton(iconSize: 34, onPressed: p.ap.seekToNext, icon: const Icon(Icons.skip_next_rounded)),
                    ValueListenableBuilder<LoopMode>(
                      valueListenable: p.loop,
                      builder: (_, m, __) => IconButton(
                        icon: Icon(m == LoopMode.one ? Icons.repeat_one : Icons.repeat, color: m == LoopMode.off ? textMuted : accent),
                        onPressed: p.cycleLoop,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: Lyrics.enabled,
                      builder: (_, on, __) => _BottomAction(icon: Icons.lyrics_outlined, label: 'Lyrics', active: on, onTap: Lyrics.toggle),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: p.autoQueue,
                      builder: (_, on, __) => _BottomAction(icon: Icons.auto_awesome, label: 'Autoplay', active: on, onTap: () => p.autoQueue.value = !on),
                    ),
                    _BottomAction(icon: Icons.queue_music_rounded, label: 'Queue', onTap: () => _showQueue(c)),
                    _BottomAction(icon: Icons.playlist_add, label: 'Playlist', onTap: () => addToPlaylistDialog(c, s.id)),
                  ]),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BottomAction({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? accent : textMuted, size: 21),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? accent : textMuted)),
      ]),
    ),
  );
}
