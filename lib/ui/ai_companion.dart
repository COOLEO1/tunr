import 'package:flutter/material.dart';
import '../core/ai.dart';
import '../core/autoqueue.dart';
import '../core/meta.dart';
import '../core/player.dart';
import '../core/settings.dart';
import '../data/repo.dart';
import 'theme.dart';
import 'widgets.dart';

class AiCompanionPage extends StatefulWidget {
  const AiCompanionPage({super.key});

  @override
  State<AiCompanionPage> createState() => _AiCompanionPageState();
}

class _AiCompanionPageState extends State<AiCompanionPage> {
  final _prompt = TextEditingController();
  bool _working = false;
  String? _message;
  String _mode = 'Balanced';

  static const _prompts = [
    'Late-night headphones',
    'Songs I have forgotten',
    'A calm start to the day',
    'Build my gym energy',
    'Mix familiar songs with discoveries',
  ];

  Future<void> _createMix() async {
    final vibe = _prompt.text.trim();
    if (vibe.isEmpty || _working) return;
    setState(() { _working = true; _message = null; });
    try {
      final result = await AiPlaylist.build('$vibe. Create a varied, well-paced playlist.');
      if (!mounted) return;
      await Player.i.play(result.songs, 0);
      setState(() => _message = 'Created “${result.name}” from your library.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _startLocalMix() async {
    final p = Player.i;
    if (p.all.isEmpty || _working) return;
    setState(() { _working = true; _message = null; });
    try {
      final seed = p.all.firstWhere(
        (s) => Repo.i.favs.value.contains(s.id),
        orElse: () => p.current.value ?? p.all.first,
      );
      await AutoQueue.prepare(seed);
      final picks = AutoQueue.pick(seed, p.all, {seed.id}, 24, mode: _mode.toLowerCase());
      await p.play([seed, ...picks], 0);
      if (mounted) setState(() => _message = 'Your $_mode radio is ready — made on this device.');
    } catch (e) {
      if (mounted) setState(() => _message = 'Could not start radio: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = Player.i.all.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Tunr Intelligence', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF211A35), Color(0xFF0D0C13), Color(0xFF09090D)],
              ),
              border: Border.all(color: accent.withOpacity(.22)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, color: accent, size: 28),
              const SizedBox(height: 18),
              const Text('Your library,\nwith a little intuition.', style: TextStyle(fontSize: 27, height: 1.12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('$count songs available to explore. AI is optional; local radio works offline.', style: const TextStyle(color: textMuted, height: 1.45)),
            ]),
          ),
          const SizedBox(height: 26),
          const Text('Ask your music companion', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          const Text('Describe a mood, moment or listening goal.', style: TextStyle(color: textMuted)),
          const SizedBox(height: 14),
          TextField(
            controller: _prompt,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'e.g. Make a late-night mix that starts mellow and builds...',
              prefixIcon: Icon(Icons.edit_note, color: accent),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _prompts.map((v) => ActionChip(
              label: Text(v),
              backgroundColor: card,
              side: const BorderSide(color: outline),
              onPressed: () => setState(() => _prompt.text = v),
            )).toList(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _working ? null : _createMix,
            icon: _working ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
            label: Text(_working ? 'Thinking...' : 'Create my AI mix'),
            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: const Color(0xFF100B1C), padding: const EdgeInsets.symmetric(vertical: 15)),
          ),
          if (Settings.groqKey.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Add your Groq key in Settings to enable AI-generated mixes. Local radio is ready without it.', style: TextStyle(color: textMuted, fontSize: 12)),
            ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: outline)),
              child: Text(_message!, style: const TextStyle(color: Colors.white70)),
            ),
          ],
          const SizedBox(height: 30),
          const Text('Smart Radio', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          const Text('Personalised on this device using your listening habits.', style: TextStyle(color: textMuted)),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Familiar', label: Text('Familiar')),
              ButtonSegment(value: 'Balanced', label: Text('Balanced')),
              ButtonSegment(value: 'Discover', label: Text('Discover')),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : textMuted),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _working ? null : _startLocalMix,
            icon: const Icon(Icons.radio),
            label: const Text('Start local radio'),
            style: OutlinedButton.styleFrom(foregroundColor: accent, side: const BorderSide(color: outline), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 26),
          const Text('Your listening, your data', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Tunr builds local recommendations from songs on your device. Only AI playlist requests send compact song metadata to the Groq service.', style: TextStyle(color: textMuted, height: 1.45, fontSize: 12)),
        ],
      ),
    );
  }
}
