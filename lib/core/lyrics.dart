import 'meta.dart';
import 'net.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repo.dart';

class Line {
  final Duration t;
  final String text;
  Line(this.t, this.text);
}

class Lyrics {
  static final enabled = ValueNotifier<bool>(false);

  static Future<void> load() async {
    enabled.value = (await SharedPreferences.getInstance()).getBool('lyrics') ?? false;
  }

  static Future<void> toggle() async {
    enabled.value = !enabled.value;
    (await SharedPreferences.getInstance()).setBool('lyrics', enabled.value);
  }

  /// Cache first. Network is only touched once per song, ever.
  static Future<String?> fetch(SongModel s) async {
    final cached = await Repo.i.getLyrics(s.id);
    if (cached != null) return cached.isEmpty ? null : cached;
    final artist = artistOf(s);
    if (!await Net.allowed()) return null;
    if (artist == "Unknown artist") return null;
    try {
      final params = {
        'track_name': cleanTitle(s),
        'artist_name': artist,
        'duration': '${(s.duration ?? 0) ~/ 1000}',
      };
      final r = await http
          .get(Uri.https('lrclib.net', '/api/get', params), headers: {'User-Agent': 'Tunr/1.0'})
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 404) {
        await Repo.i.putLyrics(s.id, '');
        return null;
      }
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      final body = (j['syncedLyrics'] ?? j['plainLyrics'] ?? '') as String;
      await Repo.i.putLyrics(s.id, body);
      return body.isEmpty ? null : body;
    } catch (_) {
      return null;
    }
  }

  static List<Line> parse(String body) {
    final re = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\](.*)$');
    final out = <Line>[];
    for (final l in body.split('\n')) {
      final m = re.firstMatch(l.trim());
      if (m == null) continue;
      final ms = (int.parse(m[1]!) * 60 + double.parse(m[2]!)) * 1000;
      out.add(Line(Duration(milliseconds: ms.round()), m[3]!.trim()));
    }
    return out;
  }
}
