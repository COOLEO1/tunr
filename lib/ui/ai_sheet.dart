import 'package:flutter/material.dart';
import '../core/ai.dart';
import '../core/player.dart';
import 'theme.dart';

void showAiSheet(BuildContext c) {
  final ctl = TextEditingController();
  var loading = false;
  String? err;
  const vibes = [
    'Late night drive',
    'Lil Baby melodic vibes',
    'Heartbreak',
    'Gym energy',
    'Chill and relax',
    'Old favourites',
    'Party mode',
    'Songs like my favourites',
  ];

  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF150B24),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(
          21, 12, 21, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
              )),
              const SizedBox(height: 24),
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE32DFF), Color(0xFF7500FF)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome, size: 30),
              ),
              const SizedBox(height: 17),
              const Text('Your AI DJ',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Tell TUNR what you want to feel. Your AI DJ will build a playlist from your own music.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: ctl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Describe your mood or music...',
                  prefixIcon: Icon(Icons.edit_note, color: accent),
                ),
              ),
              const SizedBox(height: 17),
              const Text('QUICK IDEAS', style: TextStyle(
                fontSize: 11, letterSpacing: 1.5,
                color: muted, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 9,
                children: [
                  for (final v in vibes)
                    ActionChip(
                      backgroundColor: card,
                      side: BorderSide(color: accent.withOpacity(.2)),
                      label: Text(v, style: const TextStyle(fontSize: 12)),
                      onPressed: () => set(() => ctl.text = v),
                    ),
                ],
              ),
              if (err != null) ...[
                const SizedBox(height: 14),
                Text(err!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 23),
              SizedBox(
                width: double.infinity, height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17)),
                  ),
                  onPressed: loading ? null : () async {
                    final vibe = ctl.text.trim();
                    if (vibe.isEmpty) return;
                    final messenger = ScaffoldMessenger.of(c);
                    set(() { loading = true; err = null; });
                    try {
                      final result = await AiPlaylist.build(vibe);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(content: Text('Created ${result.name}')));
                      await Player.i.play(result.songs, 0);
                    } catch (e) {
                      set(() {
                        loading = false;
                        err = e.toString().replaceFirst('Exception: ', '');
                      });
                    }
                  },
                  child: loading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome),
                          SizedBox(width: 9),
                          Text('Create my playlist',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
