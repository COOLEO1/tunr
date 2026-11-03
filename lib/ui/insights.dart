import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../data/repo.dart';
import 'theme.dart';
import 'widgets.dart';

String _durationLabel(int ms) {
  final minutes = ms ~/ 60000;
  final hours = minutes ~/ 60;
  if (hours > 0) return hours.toString() + 'h ' + (minutes % 60).toString() + 'm';
  return minutes.toString() + 'm';
}

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _days = 7;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ValueListenableBuilder<int>(
      valueListenable: Repo.i.statsRevision,
      builder: (_, revision, __) => FutureBuilder<List<int>>(
        future: Repo.i.dailyListening(days: _days),
        builder: (_, snapshot) {
          final daily = snapshot.data ?? List<int>.filled(_days, 0);
          final repo = Repo.i;
          final top = repo.mostPlayed.where((e) => Player.i.byId(e.key) != null).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('YOUR LISTENING', style: TextStyle(color: accent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Insights', style: TextStyle(fontSize: 30, letterSpacing: -1, fontWeight: FontWeight.w900)),
                ])),
                IconButton.filledTonal(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh insights'),
              ]),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF251B3C), Color(0xFF100E17), Color(0xFF09090D)]),
                  border: Border.all(color: accent.withOpacity(.22)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.headphones_rounded, color: accent), SizedBox(width: 8),
                    Text('TIME WELL SPENT', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800))]),
                  const SizedBox(height: 12),
                  Text(_durationLabel(repo.totalListeningMs + Player.i.activeListeningMs), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                  const Text('Total listening time', style: TextStyle(color: textMuted)),
                  const SizedBox(height: 20),
                  Row(children: [
                    _MiniMetric(label: 'Plays', value: repo.totalPlays.toString()),
                    const SizedBox(width: 24),
                    _MiniMetric(label: 'Completed', value: repo.completedTracks.toString()),
                    const SizedBox(width: 24),
                    _MiniMetric(label: 'Skips', value: repo.totalSkips.toString()),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Text('Listening activity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7D')),
                    ButtonSegment(value: 30, label: Text('30D')),
                  ],
                  selected: {_days},
                  onSelectionChanged: (v) => setState(() => _days = v.first),
                  style: const ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11))),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: outline)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_durationLabel(daily.fold<int>(0, (a, b) => a + b)) + ' in the last ' + _days.toString() + ' days',
                    style: const TextStyle(color: textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  SizedBox(height: 145, child: _ActivityChart(values: daily)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_days == 7 ? '7 days ago' : '30 days ago', style: const TextStyle(color: textMuted, fontSize: 10)),
                    const Text('Today', style: TextStyle(color: textMuted, fontSize: 10)),
                  ]),
                ]),
              ),
              const SizedBox(height: 26),
              const Text('Your most played', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (top.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18)),
                  child: const Column(children: [
                    Icon(Icons.equalizer_rounded, color: accent, size: 30),
                    SizedBox(height: 10),
                    Text('Your story starts here', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 5),
                    Text('Play music for a while and your real listening history will appear here.',
                      textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 12, height: 1.4)),
                  ]),
                )
              else
                for (var i = 0; i < top.length; i++)
                  _TopTrack(rank: i + 1, song: Player.i.byId(top[i].key)!, plays: top[i].value.plays),
              const SizedBox(height: 18),
              const Text('Stats are calculated from actual playback sessions on this device.',
                style: TextStyle(color: textMuted, fontSize: 11, height: 1.4)),
            ],
          );
        },
      ),
    ),
  );
}

class _MiniMetric extends StatelessWidget {
  final String label, value;
  const _MiniMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: textMuted, fontSize: 11)),
  ]));
}

class _TopTrack extends StatelessWidget {
  final int rank, plays;
  final SongModel song;
  const _TopTrack({required this.rank, required this.song, required this.plays});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    leading: SizedBox(width: 24, child: Center(child: Text(rank.toString().padLeft(2, '0'),
      style: const TextStyle(color: accent, fontWeight: FontWeight.w800)))),
    title: Text(cleanTitle(song), maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(artistOf(song), maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Text(plays.toString() + ' plays', style: const TextStyle(color: textMuted, fontSize: 11)),
    onTap: () => Player.i.play([song], 0),
  );
}

class _ActivityChart extends StatelessWidget {
  final List<int> values;
  const _ActivityChart({required this.values});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ActivityPainter(values),
    child: const SizedBox.expand(),
  );
}

class _ActivityPainter extends CustomPainter {
  final List<int> values;
  _ActivityPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = math.max(1, values.reduce((a, b) => a > b ? a : b)).toDouble();
    final step = size.width / math.max(1, values.length);
    final barWidth = math.max(3.0, step * .48).toDouble();
    final base = Paint()..color = outline;
    final fill = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [accent, accentSoft],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    for (var i = 0; i < values.length; i++) {
      final x = i * step + (step - barWidth) / 2;
      final h = (values[i] == 0 ? 3.0 : math.max(5.0, (values[i] / maxValue) * (size.height - 8))).toDouble();
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barWidth, h), const Radius.circular(5));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - 3, barWidth, 3), const Radius.circular(3)), base);
      canvas.drawRRect(rect, fill);
    }
  }
  @override
  bool shouldRepaint(covariant _ActivityPainter oldDelegate) => oldDelegate.values != values;
}