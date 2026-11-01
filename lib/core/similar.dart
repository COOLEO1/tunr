import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'net.dart';
import 'settings.dart';

/// Last.fm "similar artists", fetched once per artist and cached forever
class Similar {
  static Future<Set<String>> get(String artist) async {
    if (artist == 'Unknown artist' || Settings.lastfmKey.isEmpty) return {};
    final p = await SharedPreferences.getInstance();
    final ck = 'sim:${artist.toLowerCase()}';
    final cached = p.getString(ck);
    if (cached != null) return cached.isEmpty ? {} : cached.split('|').toSet();
    if (!await Net.allowed()) return {};
    try {
      final r = await http
          .get(Uri.https('ws.audioscrobbler.com', '/2.0/', {
            'method': 'artist.getsimilar',
            'artist': artist,
            'api_key': Settings.lastfmKey,
            'format': 'json',
            'limit': '40',
            'autocorrect': '1',
          }))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return {};
      final list = (jsonDecode(utf8.decode(r.bodyBytes))['similarartists']?['artist'] as List?) ?? [];
      final names = list.map((e) => (e['name'] as String).toLowerCase()).toList();
      await p.setString(ck, names.join('|'));
      return names.toSet();
    } catch (_) {
      return {};
    }
  }
}
