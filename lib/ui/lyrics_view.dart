import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/lyrics.dart';
import '../core/player.dart';

class LyricsView extends StatefulWidget {
  final SongModel song;
  const LyricsView({required this.song, super.key});
  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  late final Future<String?> f = Lyrics.fetch(widget.song);
  final sc = ScrollController();
  int _cur = -1;

  @override
  void dispose() {
    sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => FutureBuilder<String?>(
        future: f,
        builder: (_, sn) {
          if (sn.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final body = sn.data;
          if (body == null) {
            return const Center(child: Text('No lyrics found', style: TextStyle(color: Colors.white54)));
          }
          final lines = Lyrics.parse(body);
          if (lines.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.6, fontWeight: FontWeight.w600)),
            );
          }
          return StreamBuilder<Duration>(
            stream: Player.i.ap.positionStream,
            builder: (_, ps) {
              final pos = ps.data ?? Duration.zero;
              final i = lines.lastIndexWhere((l) => l.t <= pos);
              if (i != _cur) {
                _cur = i;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (sc.hasClients && i >= 0) {
                    sc.animateTo((i * 56.0 - 120).clamp(0.0, sc.position.maxScrollExtent).toDouble(),
                        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                });
              }
              return ListView.builder(
                controller: sc,
                itemExtent: 56,
                itemCount: lines.length,
                itemBuilder: (_, k) => Center(
                  child: Text(
                    lines[k].text.isEmpty ? '•' : lines[k].text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: k == i ? Colors.white : Colors.white30),
                  ),
                ),
              );
            },
          );
        },
      );
}
