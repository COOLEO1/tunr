import 'package:flutter/material.dart';
import '../core/ai.dart';
import '../core/player.dart';
import 'theme.dart';

void showAiSheet(BuildContext c) {
  final ctl = TextEditingController();
  var loading = false;
  String? err;
  const vibes = ['Late night drive', 'Sad but hype', 'Gym', 'Heartbreak', 'Chill study', 'Party'];
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    backgroundColor: card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome, color: accent),
            SizedBox(width: 10),
            Text('Make a playlist with AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: ctl,
            decoration: InputDecoration(
              hintText: 'Describe the vibe...',
              filled: true,
              fillColor: bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final v in vibes) ActionChip(label: Text(v), onPressed: () => ctl.text = v),
          ]),
          if (err != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(err!, style: const TextStyle(color: Colors.redAccent))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: loading
                  ? null
                  : () async {
                      final vibe = ctl.text.trim();
                      if (vibe.isEmpty) return;
                      final m = ScaffoldMessenger.of(c);
                      set(() {
                        loading = true;
                        err = null;
                      });
                      AiResult? res;
                      try {
                        res = await AiPlaylist.build(vibe);
                      } catch (e) {
                        set(() {
                          loading = false;
                          err = e.toString().replaceFirst('Exception: ', '');
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      m.showSnackBar(SnackBar(content: Text('Saved "${res.name}" to Playlists')));
                      await Player.i.play(res.songs, 0);
                    },
              child: loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Generate', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    ),
  );
}
