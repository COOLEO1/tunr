import '../core/tint.dart';
import '../core/art_store.dart';
import 'dart:io';
import '../core/meta.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'now_playing.dart';
import 'playlists.dart';
import 'theme.dart';

Color tintFor(SongModel s) =>
    Tint.peek(s) ?? HSLColor.fromAHSL(1, (s.title.hashCode.abs() % 360).toDouble(), .45, .22).toColor();

Widget fallbackArt(SongModel s) {
  final h = (s.title.hashCode.abs() % 360).toDouble();
  final a = HSLColor.fromAHSL(1, h, .55, .38).toColor();
  final b = HSLColor.fromAHSL(1, (h + 45) % 360, .6, .22).toColor();
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
    ),
    alignment: Alignment.center,
    child: LayoutBuilder(
      builder: (_, bc) => Text(
        cleanTitle(s)[0].toUpperCase(),
        style: TextStyle(fontSize: bc.maxHeight * .45, fontWeight: FontWeight.w800, color: Colors.white70),
      ),
    ),
  );
}

class Art extends StatelessWidget {
  final SongModel s;
  final double size, r;
  const Art(this.s, {this.size = 52, this.r = 6, super.key});

  @override
  Widget build(BuildContext c) => ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: SizedBox(
          width: size,
          height: size,
          child: QueryArtworkWidget(
            id: s.id,
            type: ArtworkType.AUDIO,
            size: 500,
            quality: 80,
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
          final on = cur?.id == s.id;
          return ListTile(
            onTap: onTap,
            onLongPress: () => songMenu(c, s),
            leading: Art(s),
            title: Text(cleanTitle(s),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: on ? accent : Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(artistOf(s),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
            trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54), onPressed: () => songMenu(c, s)),
          );
        },
      );
}

void songMenu(BuildContext c, SongModel s) {
  showModalBottomSheet(
    context: c,
    backgroundColor: card,
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: Art(s, size: 44),
            title: Text(cleanTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(artistOf(s))),
        const Divider(height: 1),
        ListTile(
            leading: const Icon(Icons.radio),
            title: const Text('Start radio'),
            onTap: () {
              Navigator.pop(c);
              Player.i.radio(s);
            }),
        ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Favorite / unfavorite'),
            onTap: () {
              Navigator.pop(c);
              Repo.i.toggleFav(s.id);
            }),
        ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to playlist'),
            onTap: () {
              Navigator.pop(c);
              addToPlaylistDialog(c, s.id);
            }),
      ]),
    ),
  );
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<SongModel?>(
    valueListenable: Player.i.current,
    builder: (_, song, __) {
      if (song == null) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, animation, __) => const NowPlaying(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        )),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 7),
          padding: const EdgeInsets.fromLTRB(9, 9, 5, 6),
          decoration: BoxDecoration(
            color: cardRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(.22)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Art(song, size: 43, r: 9),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cleanTitle(song), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 2),
                Text(artistOf(song), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textMuted, fontSize: 10)),
              ])),
              ValueListenableBuilder<Set<int>>(
                valueListenable: Repo.i.favs,
                builder: (_, favorites, __) => IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(favorites.contains(song.id) ? Icons.favorite : Icons.favorite_border,
                    color: favorites.contains(song.id) ? accent : textMuted, size: 20),
                  onPressed: () => Repo.i.toggleFav(song.id),
                ),
              ),
              StreamBuilder<bool>(
                stream: Player.i.ap.playingStream,
                builder: (_, snapshot) {
                  final playing = snapshot.data ?? false;
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 27),
                    onPressed: () => playing ? Player.i.ap.pause() : Player.i.ap.play(),
                  );
                },
              ),
            ]),
            StreamBuilder<Duration>(
              stream: Player.i.ap.positionStream,
              builder: (_, snapshot) {
                final duration = Player.i.ap.duration?.inMilliseconds ?? 1;
                final position = snapshot.data?.inMilliseconds ?? 0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (position / duration).clamp(0.0, 1.0).toDouble(),
                    minHeight: 2,
                    backgroundColor: Colors.white10,
                    color: accent,
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
