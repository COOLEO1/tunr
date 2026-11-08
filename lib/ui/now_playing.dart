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

String fmt(Duration d) =>
  '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key});

  @override
  Widget build(BuildContext c) {
    final p = Player.i;
    return ValueListenableBuilder<SongModel?>(
      valueListenable: p.current,
      builder: (_, s, __) {
        if (s == null) return const Scaffold();
        final size = MediaQuery.of(c).size;
        final artSize = math.min(size.width - 76, size.height * .42);

        return GestureDetector(
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 400) Navigator.pop(c);
          },
          child: Scaffold(
            body: Stack(children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tintFor(s),
                        const Color(0xFF180B2A),
                        bg,
                      ],
                      stops: const [0, .48, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -100, right: -100,
                child: Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(.12),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 23),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                          onPressed: () => Navigator.pop(c),
                        ),
                        const Column(children: [
                          Text('NOW PLAYING', style: TextStyle(
                            fontSize: 11, letterSpacing: 2,
                            color: Colors.white70)),
                          SizedBox(height: 3),
                          Text('TUNR PLAYER', style: TextStyle(
                            fontSize: 9, color: accent,
                            letterSpacing: 1.5)),
                        ]),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () => songMenu(c, s),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: Lyrics.enabled,
                        builder: (_, on, __) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: on
                            ? LyricsView(key: ValueKey(s.id), song: s)
                            : Center(
                              child: StreamBuilder<bool>(
                                stream: p.ap.playingStream,
                                builder: (_, sn) => AnimatedScale(
                                  scale: (sn.data ?? false) ? 1 : .94,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutBack,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(.22),
                                          blurRadius: 40,
                                          spreadRadius: 3,
                                        ),
                                        const BoxShadow(
                                          color: Colors.black54,
                                          blurRadius: 35,
                                          offset: Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: Art(s, size: artSize, r: 25),
                                  ),
                                ),
                              ),
                            ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cleanTitle(s),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text(artistOf(s),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70, fontSize: 15)),
                        ],
                      )),
                      ValueListenableBuilder<Set<int>>(
                        valueListenable: Repo.i.favs,
                        builder: (_, f, __) {
                          final liked = f.contains(s.id);
                          return IconButton(
                            iconSize: 27,
                            icon: Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              color: liked ? pink : Colors.white70,
                            ),
                            onPressed: () => Repo.i.toggleFav(s.id),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    StreamBuilder<Duration>(
                      stream: p.ap.positionStream,
                      builder: (_, sn) {
                        final pos = sn.data ?? Duration.zero;
                        final dur = p.ap.duration ??
                          Duration(milliseconds: s.duration ?? 1);
                        final max = math.max(1.0, dur.inMilliseconds.toDouble());
                        return Column(children: [
                          Slider(
                            value: pos.inMilliseconds.toDouble().clamp(0, max).toDouble(),
                            max: max,
                            onChanged: (v) => p.ap.seek(
                              Duration(milliseconds: v.toInt())),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(fmt(pos), style: const TextStyle(
                                  fontSize: 11, color: Colors.white60)),
                                Text(fmt(dur), style: const TextStyle(
                                  fontSize: 11, color: Colors.white60)),
                              ],
                            ),
                          ),
                        ]);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: p.shuffle,
                          builder: (_, on, __) => IconButton(
                            icon: Icon(Icons.shuffle,
                              color: on ? accent : Colors.white70),
                            onPressed: p.toggleShuffle,
                          ),
                        ),
                        IconButton(
                          iconSize: 34,
                          icon: const Icon(Icons.skip_previous_rounded),
                          onPressed: p.ap.seekToPrevious,
                        ),
                        StreamBuilder<bool>(
                          stream: p.ap.playingStream,
                          builder: (_, sn) {
                            final playing = sn.data ?? false;
                            return GestureDetector(
                              onTap: () => playing
                                ? p.ap.pause() : p.ap.play(),
                              child: Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE75BFF), Color(0xFF8B20FF)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(.4),
                                      blurRadius: 25,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  playing ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                  color: Colors.white, size: 43,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          iconSize: 34,
                          icon: const Icon(Icons.skip_next_rounded),
                          onPressed: p.ap.seekToNext,
                        ),
                        ValueListenableBuilder<LoopMode>(
                          valueListenable: p.loop,
                          builder: (_, mode, __) => IconButton(
                            icon: Icon(
                              mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                              color: mode == LoopMode.off ? Colors.white70 : accent,
                            ),
                            onPressed: p.cycleLoop,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.045),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: Lyrics.enabled,
                            builder: (_, on, __) => IconButton(
                              tooltip: 'Lyrics',
                              icon: Icon(Icons.lyrics_outlined,
                                color: on ? accent : Colors.white70),
                              onPressed: Lyrics.toggle,
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: p.autoQueue,
                            builder: (_, on, __) => IconButton(
                              tooltip: 'Smart queue',
                              icon: Icon(Icons.auto_awesome,
                                color: on ? accent : Colors.white70),
                              onPressed: () => p.autoQueue.value = !on,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add to playlist',
                            icon: const Icon(Icons.playlist_add,
                              color: Colors.white70),
                            onPressed: () => addToPlaylistDialog(c, s.id),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
