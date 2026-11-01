import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'art_store.dart';

/// Dominant color of the album art, used for the Spotify-style backgrounds
class Tint {
  static final _c = <int, Color>{};
  static Color? peek(SongModel s) => _c[s.id];

  static Future<Color?> of(SongModel s) async {
    if (_c.containsKey(s.id)) return _c[s.id];
    try {
      Uint8List? b = await OnAudioQuery().queryArtwork(s.id, ArtworkType.AUDIO, size: 64);
      if (b == null || b.isEmpty) {
        final f = await ArtStore.cached(s);
        b = f == null ? null : await f.readAsBytes();
      }
      if (b == null || b.isEmpty) return null;
      final codec = await ui.instantiateImageCodec(b, targetWidth: 12, targetHeight: 12);
      final img = (await codec.getNextFrame()).image;
      final d = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      double r = 0, g = 0, bl = 0, w = 0;
      for (var i = 0; i < d.lengthInBytes; i += 4) {
        final R = d.getUint8(i), G = d.getUint8(i + 1), B = d.getUint8(i + 2);
        final k = (max(R, max(G, B)) - min(R, min(G, B))) / 255 + .05;
        r += R * k;
        g += G * k;
        bl += B * k;
        w += k;
      }
      final base = Color.fromARGB(255, (r / w).round(), (g / w).round(), (bl / w).round());
      final hsl = HSLColor.fromColor(base);
      final out = hsl.saturation < .12 ? const Color(0xFF2A2A2A) : HSLColor.fromAHSL(1, hsl.hue, hsl.saturation.clamp(.35, .75).toDouble(), .3).toColor();
      return _c[s.id] = out;
    } catch (_) {
      return null;
    }
  }
}
