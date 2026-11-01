import 'package:on_audio_query/on_audio_query.dart';

class Meta {
  final String title, artist;
  Meta(this.title, this.artist);
}

final _cache = <int, Meta>{};
final _ext = RegExp(r'\.(mp3|m4a|mp4|wav|flac|ogg)$', caseSensitive: false);
final _junk = RegExp(
    r'\s*[\(\[][^\)\]]*(video|audio|lyric|official|visuali|hd|hq|4k)[^\)\]]*[\)\]]',
    caseSensitive: false);

Meta metaOf(SongModel s) => _cache.putIfAbsent(s.id, () {
      var t = s.title.replaceAll(_ext, '').replaceAll('_', ' ');
      var a = (s.artist ?? '').trim();
      if ((a.isEmpty || a == '<unknown>') && t.contains(' - ')) {
        final i = t.indexOf(' - ');
        a = t.substring(0, i).replaceAll('#', '').trim();
        t = t.substring(i + 3);
      }
      t = t.replaceAll(_junk, '').trim();
      if (t.isEmpty) t = s.title;
      if (a.isEmpty || a == '<unknown>') a = 'Unknown artist';
      return Meta(t, a);
    });

String cleanTitle(SongModel s) => metaOf(s).title;
String artistOf(SongModel s) => metaOf(s).artist;
