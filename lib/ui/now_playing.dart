import 'dart:math' as math;
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

  @override
  Widget build(BuildContext c) {
    final p = Player.i;
    final w = MediaQuery.of(c).size.width - 56;
    return ValueListenableBuilder<SongModel?>(
      valueListenable: p.current,
      builder: (_, s, __) {
        if (s == null) return const Scaffold();
        return GestureDetector(
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 400) Navigator.pop(c);
          },
          child: Scaffold(
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tintFor(s), bg],
                  stops: const [0, .85],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 32), onPressed: () => Navigator.pop(c)),
                      const Text('NOW PLAYING', style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Colors.white70)),
                      IconButton(icon: const Icon(Icons.more_vert), onPressed: () => songMenu(c, s)),
                    ]),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: Lyrics.enabled,
                        builder: (_, on, __) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: on
                              ? LyricsView(key: ValueKey(s.id), song: s)
                              : Center(
                                  child: StreamBuilder<bool>(
                                    stream: p.ap.playingStream,
                                    builder: (_, sn) => AnimatedScale(
                                      scale: (sn.data ?? false) ? 1 : .88,
                                      duration: const Duration(milliseconds: 350),
                                      curve: Curves.easeOutBack,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 20))],
                                        ),
                                        child: Art(s, size: w, r: 16),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cleanTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          Text(artistOf(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                        ]),
                      ),
                      ValueListenableBuilder<Set<int>>(
                        valueListenable: Repo.i.favs,
                        builder: (_, f, __) {
                          final fav = f.contains(s.id);
                          return IconButton(
                            icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? accent : Colors.white70),
                            onPressed: () => Repo.i.toggleFav(s.id),
                          );
                        },
                      ),
                    ]),
                    StreamBuilder<Duration>(
                      stream: p.ap.positionStream,
                      builder: (_, sn) {
                        final pos = sn.data ?? Duration.zero;
                        final dur = p.ap.duration ?? Duration(milliseconds: s.duration ?? 1);
                        final mx = math.max(1.0, dur.inMilliseconds.toDouble());
                        return Column(children: [
                          Slider(
                            value: math.min(pos.inMilliseconds.toDouble(), mx),
                            max: mx,
                            onChanged: (v) => p.ap.seek(Duration(milliseconds: v.toInt())),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(fmt(pos), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                              Text(fmt(dur), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                            ]),
                          ),
                        ]);
                      },
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: p.shuffle,
                        builder: (_, on, __) => IconButton(icon: Icon(Icons.shuffle, color: on ? accent : Colors.white70), onPressed: p.toggleShuffle),
                      ),
                      IconButton(iconSize: 38, icon: const Icon(Icons.skip_previous), onPressed: p.ap.seekToPrevious),
                      StreamBuilder<bool>(
                        stream: p.ap.playingStream,
                        builder: (_, sn) {
                          final pl = sn.data ?? false;
                          return GestureDetector(
                            onTap: () => pl ? p.ap.pause() : p.ap.play(),
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(pl ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 38),
                            ),
                          );
                        },
                      ),
                      IconButton(iconSize: 38, icon: const Icon(Icons.skip_next), onPressed: p.ap.seekToNext),
                      ValueListenableBuilder<LoopMode>(
                        valueListenable: p.loop,
                        builder: (_, m, __) => IconButton(
                          icon: Icon(m == LoopMode.one ? Icons.repeat_one : Icons.repeat, color: m == LoopMode.off ? Colors.white70 : accent),
                          onPressed: p.cycleLoop,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: Lyrics.enabled,
                        builder: (_, on, __) => IconButton(
                          tooltip: 'Lyrics',
                          icon: Icon(Icons.lyrics_outlined, color: on ? accent : Colors.white70),
                          onPressed: Lyrics.toggle,
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: p.autoQueue,
                        builder: (_, on, __) => IconButton(
                          tooltip: 'Auto-queue',
                          icon: Icon(Icons.auto_awesome, color: on ? accent : Colors.white70),
                          onPressed: () => p.autoQueue.value = !on,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.playlist_add, color: Colors.white70), onPressed: () => addToPlaylistDialog(c, s.id)),
                    ]),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
