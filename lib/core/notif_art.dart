import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'art_store.dart';

/// Saves each song's cover to a file once, so the notification can show it
class NotifArt {
  static final ready = <int>{};
  static String _base = '';
  static bool _running = false;

  static Future<void> warm(List<SongModel> songs) async {
    if (_running) return;
    _running = true;
    final dir = await ArtStore.dir();
    _base = dir.path;
    final q = OnAudioQuery();
    for (final s in songs) {
      final f = File('$_base/${s.id}.jpg');
      if (await f.exists()) {
        ready.add(s.id);
        continue;
      }
      try {
        final b = await q.queryArtwork(s.id, ArtworkType.AUDIO, size: 512, quality: 85);
        if (b != null && b.isNotEmpty) {
          await f.writeAsBytes(b);
          ready.add(s.id);
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 15));
    }
    _running = false;
  }

  static Uri? uriFor(int id) => ready.contains(id) ? Uri.file('$_base/$id.jpg') : null;
}
