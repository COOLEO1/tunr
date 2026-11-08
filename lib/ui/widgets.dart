import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/tint.dart';
import '../core/art_store.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'now_playing.dart';
import 'playlists.dart';
import 'theme.dart';

Color tintFor(SongModel s) => Color.lerp(
  Tint.peek(s) ?? const Color(0xFF32105A), purple, .62)!;

Widget fallbackArt(SongModel s) {
  final h = (s.title.hashCode.abs() % 360).toDouble();
  final a = HSLColor.fromAHSL(1, h, .65, .35).toColor();
  final b = HSLColor.fromAHSL(1, (h + 55) % 360, .7, .13).toColor();
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      cleanTitle(s).isEmpty ? '♪' : cleanTitle(s)[0].toUpperCase(),
      style: const TextStyle(
        fontSize: 45, fontWeight: FontWeight.w900,
        color: Colors.white70,
      ),
    ),
  );
}

class Art extends StatelessWidget {
  final SongModel s;
  final double size, r;
  const Art(this.s, {this.size = 52, this.r = 12, super.key});

  @override
  Widget build(BuildContext c) => ClipRRect(
    borderRadius: BorderRadius.circular(r),
    child: SizedBox(
      width: size, height: size,
      child: QueryArtworkWidget(
        id: s.id,
        type: ArtworkType.AUDIO,
        size: 500,
        quality: 90,
        artworkWidth: size,
        artworkHeight: size,
        artworkFit: BoxFit.cover,
        artworkBorder: BorderRadius.zero,
        keepOldArtwork: true,
        nullArtworkWidget: CachedArt(s, size: size),
      ),
    ),
  );
}

class SongTile extends StatelessWidget {
  final SongModel s;
  final VoidCallback onTap;
  const SongTile(this.s, {required this.onTap, super.key});

  @override
  Widget build(BuildContext c) => ValueListenableBuilder<SongModel?>(
    valueListenable: Player.i.current,
    builder: (_, cur, __) {
      final active = cur?.id == s.id;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: active ? purple.withOpacity(.15) : Colors.white.withOpacity(.025),
          borderRadius: BorderRadius.circular(17),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            onTap: onTap,
            onLongPress: () => songMenu(c, s),
            leading: Art(s, size: 53, r: 12),
            title: Text(cleanTitle(s),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? const Color(0xFFE9B5FF) : Colors.white,
                fontWeight: FontWeight.w700,
              )),
            subtitle: Text(artistOf(s),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz, color: muted),
              onPressed: () => songMenu(c, s),
            ),
          ),
        ),
      );
    },
  );
}

void songMenu(BuildContext c, SongModel s) {
  showModalBottomSheet(
    context: c,
    backgroundColor: card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 38, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(8))),
          ListTile(
            leading: Art(s, size: 50),
            title: Text(cleanTitle(s), maxLines: 1,
              overflow: TextOverflow.ellipsis),
            subtitle: Text(artistOf(s)),
          ),
          ListTile(
            leading: const Icon(Icons.radio, color: accent),
            title: const Text('Start song radio'),
            onTap: () { Navigator.pop(c); Player.i.radio(s); },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: pink),
            title: const Text('Like / unlike'),
            onTap: () { Navigator.pop(c); Repo.i.toggleFav(s.id); },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: accent),
            title: const Text('Add to playlist'),
            onTap: () { Navigator.pop(c); addToPlaylistDialog(c, s.id); },
          ),
        ]),
      ),
    ),
  );
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext c) => ValueListenableBuilder<SongModel?>(
    valueListenable: Player.i.current,
    builder: (_, s, __) {
      if (s == null) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => Navigator.push(c, PageRouteBuilder(
          pageBuilder: (_, a, __) => const NowPlaying(),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        )),
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 4, 10, 7),
          padding: const EdgeInsets.fromLTRB(9, 8, 8, 7),
          decoration: BoxDecoration(
            color: const Color(0xFF28133F),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: accent.withOpacity(.4)),
            boxShadow: [
              BoxShadow(color: purple.withOpacity(.2), blurRadius: 18),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Art(s, size: 43, r: 10),
              const SizedBox(width: 11),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cleanTitle(s), maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(artistOf(s), maxLines: 1,
                    style: const TextStyle(color: muted, fontSize: 11)),
                ],
              )),
              ValueListenableBuilder<Set<int>>(
                valueListenable: Repo.i.favs,
                builder: (_, f, __) => IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(f.contains(s.id) ? Icons.favorite : Icons.favorite_border,
                    color: f.contains(s.id) ? pink : Colors.white70),
                  onPressed: () => Repo.i.toggleFav(s.id),
                ),
              ),
              StreamBuilder<bool>(
                stream: Player.i.ap.playingStream,
                builder: (_, sn) {
                  final playing = sn.data ?? false;
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 29, color: Colors.white),
                    onPressed: () => playing
                      ? Player.i.ap.pause() : Player.i.ap.play(),
                  );
                },
              ),
            ]),
            StreamBuilder<Duration>(
              stream: Player.i.ap.positionStream,
              builder: (_, sn) {
                final duration = Player.i.ap.duration?.inMilliseconds ?? 1;
                final value = ((sn.data?.inMilliseconds ?? 0) / duration)
                  .clamp(0.0, 1.0).toDouble();
                return ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: value, minHeight: 3,
                    backgroundColor: Colors.white12, color: accent,
                  ),
                );
              },
            ),
          ]),
        ),
      );
    },
  );
}

class CachedArt extends StatelessWidget {
  final SongModel s;
  final double size;
  const CachedArt(this.s, {required this.size, super.key});

  @override
  Widget build(BuildContext c) => FutureBuilder<File?>(
    future: ArtStore.get(s),
    builder: (_, sn) => sn.data == null
      ? fallbackArt(s)
      : Image.file(sn.data!, width: size, height: size, fit: BoxFit.cover),
  );
}
