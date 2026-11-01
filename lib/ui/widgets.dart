import '../core/meta.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'now_playing.dart';
import 'playlists.dart';
import 'theme.dart';

Color tintFor(SongModel s) =>
    HSLColor.fromAHSL(1, (s.title.hashCode.abs() % 360).toDouble(), .45, .22).toColor();

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
            nullArtworkWidget: fallbackArt(s),
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
  Widget build(BuildContext c) => ValueListenableBuilder<SongModel?>(
        valueListenable: Player.i.current,
        builder: (_, s, __) {
          if (s == null) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => Navigator.push(
              c,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const NowPlaying(),
                transitionsBuilder: (_, a, __, child) => SlideTransition(
                  position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
              decoration: BoxDecoration(color: tintFor(s), borderRadius: BorderRadius.circular(10)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Art(s, size: 42, r: 5),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cleanTitle(s),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(artistOf(s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                  ValueListenableBuilder<Set<int>>(valueListenable: Repo.i.favs, builder: (_, f, __) => IconButton(icon: Icon(f.contains(s.id) ? Icons.favorite : Icons.favorite_border, color: f.contains(s.id) ? accent : Colors.white70), onPressed: () => Repo.i.toggleFav(s.id))),
                  StreamBuilder<bool>(
                    stream: Player.i.ap.playingStream,
                    builder: (_, sn) {
                      final pl = sn.data ?? false;
                      return IconButton(
                          icon: Icon(pl ? Icons.pause : Icons.play_arrow, size: 30),
                          onPressed: () => pl ? Player.i.ap.pause() : Player.i.ap.play());
                    },
                  ),
                ]),
                const SizedBox(height: 6),
                StreamBuilder<Duration>(
                  stream: Player.i.ap.positionStream,
                  builder: (_, sn) {
                    final d = Player.i.ap.duration?.inMilliseconds ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: LinearProgressIndicator(
                          value: ((sn.data?.inMilliseconds ?? 0) / d).clamp(0.0, 1.0).toDouble(),
                          minHeight: 2,
                          backgroundColor: Colors.white12,
                          color: Colors.white),
                    );
                  },
                ),
              ]),
            ),
          );
        },
      );
}
