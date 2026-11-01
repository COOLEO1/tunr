import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'meta.dart';
import 'net.dart';
import 'settings.dart';

/// Missing album art: fetched ONCE per song (iTunes search, ~30KB), saved forever.
class ArtStore {
  static final _mem = <int, Future<File?>>{};
  static Directory? _dir;
  static Future<void> _gate = Future.value();

  static Future<Directory> _d() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/art');
    await d.create(recursive: true);
    return _dir = d;
  }

  static Future<File?> cached(SongModel s) async {
    final f = File('${(await _d()).path}/${s.id}.jpg');
    return await f.exists() ? f : null;
  }

  static Future<File?> get(SongModel s) => _mem.putIfAbsent(s.id, () => _load(s));

  static Future<void> clear() async {
    final d = await _d();
    if (await d.exists()) await d.delete(recursive: true);
    _dir = null;
    _mem.clear();
  }

  static Future<File?> _load(SongModel s) async {
    final dir = await _d();
    final f = File('${dir.path}/${s.id}.jpg');
    if (await f.exists()) return f;
    final none = File('${dir.path}/${s.id}.none');
    if (await none.exists()) return null;
    final artist = artistOf(s);
    if (artist == 'Unknown artist' || !Settings.artOnline || !await Net.allowed()) return null;

    // one request at a time, 3s apart (keeps us under the free API limit)
    final prev = _gate;
    final done = Completer<void>();
    _gate = done.future;
    await prev;
    try {
      final r = await http
          .get(Uri.https('itunes.apple.com', '/search',
              {'term': '$artist ${cleanTitle(s)}', 'entity': 'song', 'limit': '1'}))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final res = jsonDecode(r.body)['results'] as List;
        if (res.isNotEmpty) {
          final url = (res.first['artworkUrl100'] as String).replaceAll('100x100bb', '400x400bb');
          final img = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          if (img.statusCode == 200) {
            await f.writeAsBytes(img.bodyBytes);
            return f;
          }
        } else {
          await none.writeAsString('1');
        }
      }
    } catch (_) {
    } finally {
      Future.delayed(const Duration(seconds: 3), done.complete);
    }
    return null;
  }
}
