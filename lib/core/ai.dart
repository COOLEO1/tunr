import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:on_audio_query/on_audio_query.dart';
import '../data/db.dart';
import 'meta.dart';
import 'player.dart';
import 'settings.dart';

class AiResult {
  final String name;
  final List<SongModel> songs;
  AiResult(this.name, this.songs);
}

/// Two small calls instead of one huge one:
/// 1) which of YOUR artists fit the vibe  2) which of THEIR songs, in order
class AiPlaylist {
  static Future<Map<String, dynamic>> _chat(String system, String user) async {
    final r = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {'Authorization': 'Bearer ${Settings.groqKey}', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': Settings.model,
            'temperature': 0.7,
            'response_format': {'type': 'json_object'},
            'messages': [
              {'role': 'system', 'content': system},
              {'role': 'user', 'content': user},
            ],
          }),
        )
        .timeout(const Duration(seconds: 40));
    if (r.statusCode != 200) {
      final b = r.body.length > 160 ? r.body.substring(0, 160) : r.body;
      throw Exception('Groq error ${r.statusCode}. Check key/model in Settings. $b');
    }
    final txt = jsonDecode(utf8.decode(r.bodyBytes))['choices'][0]['message']['content'] as String;
    return jsonDecode(txt) as Map<String, dynamic>;
  }

  static Future<AiResult> build(String vibe) async {
    if (Settings.groqKey.isEmpty) throw Exception('Add your Groq key in Settings first.');
    final all = Player.i.all;
    if (all.isEmpty) throw Exception('No songs found.');

    final counts = <String, int>{};
    for (final s in all) {
      final a = artistOf(s);
      if (a != 'Unknown artist') counts[a] = (counts[a] ?? 0) + 1;
    }
    final artists = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final chosen = <String>{};
    if (artists.isNotEmpty) {
      final r1 = await _chat(
        'You pick music artists that fit a vibe. Reply as JSON: {"artists": [names]}. Use only names from the list. Max 25.',
        'Vibe: $vibe\nArtists: ${artists.take(400).join('; ')}',
      );
      for (final e in (r1['artists'] as List? ?? [])) {
        chosen.add(e.toString().toLowerCase());
      }
    }

    var pool = all.where((s) => chosen.contains(artistOf(s).toLowerCase())).toList();
    final unknown = all.where((s) => artistOf(s) == 'Unknown artist').toList()..shuffle();
    pool.addAll(unknown.take(40));
    if (pool.length < 20) pool = ([...all]..shuffle());
    pool.shuffle();
    if (pool.length > 250) pool = pool.sublist(0, 250);

    final lines = pool.map((s) => '${s.id}|${artistOf(s)}|${cleanTitle(s)}').join('\n');
    final r2 = await _chat(
      'You build playlists. Reply as JSON: {"name": short playlist name, "ids": [song ids in a good listening order]}. Use only ids from the list. 15 to 30 songs.',
      'Vibe: $vibe\nSongs (id|artist|title):\n$lines',
    );

    final byId = {for (final s in pool) s.id: s};
    final seen = <int>{};
    final songs = <SongModel>[];
    for (final e in (r2['ids'] as List? ?? [])) {
      final id = int.tryParse(e.toString());
      if (id != null && byId.containsKey(id) && seen.add(id)) songs.add(byId[id]!);
    }
    if (songs.length < 5) throw Exception('AI could not match songs. Try another vibe.');

    final name = ((r2['name'] as String?) ?? vibe).trim();
    final d = await Db.get();
    final plId = await d.insert('playlists', {'name': name.isEmpty ? vibe : name});
    for (final s in songs) {
      await d.insert('pl_songs', {'pl': plId, 'song': s.id});
    }
    return AiResult(name, songs);
  }
}
