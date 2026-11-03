import 'package:flutter/material.dart';
import '../core/art_store.dart';
import '../core/lyrics.dart';
import '../core/player.dart';
import '../core/settings.dart';
import '../data/repo.dart';
import 'theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Widget _field(String label, String key, {bool secret = false, String def = ''}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: Settings.str(key, def),
      obscureText: secret,
      onChanged: (v) => Settings.setStr(key, v),
      decoration: InputDecoration(labelText: label,
        prefixIcon: Icon(secret ? Icons.key_outlined : Icons.tune_rounded, color: accent)),
    ),
  );

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: const Text('Clear listening history?'),
        content: const Text('This removes listening sessions, play counts and Insights data. Your music, playlists and favorites stay untouched.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear history')),
        ],
      ),
    );
    if (confirm == true) {
      await Repo.i.clearListeningHistory();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listening history cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 32), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF251B3C), Color(0xFF100E17)]),
          border: Border.all(color: accent.withOpacity(.2)),
        ),
        child: const Row(children: [
          Icon(Icons.graphic_eq_rounded, color: accent, size: 30),
          SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TUNR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
            SizedBox(height: 3),
            Text('Your music. Your world.', style: TextStyle(color: textMuted, fontSize: 12)),
          ])),
          Text('1.0', style: TextStyle(color: textMuted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 25),
      const _SectionTitle('INTELLIGENCE & DISCOVERY'),
      const SizedBox(height: 12),
      _field('Groq API key', 'groq', secret: true),
      _field('Groq model', 'model', def: 'llama-3.3-70b-versatile'),
      _field('Last.fm API key', 'lastfm', secret: true),
      const SizedBox(height: 12),
      const _SectionTitle('PLAYBACK & EXPERIENCE'),
      ValueListenableBuilder<bool>(
        valueListenable: Player.i.autoQueue,
        builder: (_, enabled, __) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Smart autoplay'),
          subtitle: const Text('Extend the queue with music from your library'),
          value: enabled, onChanged: (v) => Player.i.autoQueue.value = v,
        ),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: Lyrics.enabled,
        builder: (_, enabled, __) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show lyrics'),
          subtitle: const Text('Fetch and cache lyrics when available'),
          value: enabled, onChanged: (_) => Lyrics.toggle(),
        ),
      ),
      const SizedBox(height: 12),
      const _SectionTitle('NETWORK & STORAGE'),
      SwitchListTile(
        contentPadding: EdgeInsets.zero, title: const Text('Wi-Fi only'),
        subtitle: const Text('Lyrics, album art and similar-artist lookups wait for Wi-Fi'),
        value: Settings.wifiOnly,
        onChanged: (v) async { await Settings.setFlag('wifi', v); setState(() {}); },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero, title: const Text('Fetch missing album art'),
        subtitle: const Text('Cache artwork locally after the first fetch'),
        value: Settings.artOnline,
        onChanged: (v) async { await Settings.setFlag('art', v); setState(() {}); },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.image_not_supported_outlined, color: textMuted),
        title: const Text('Clear downloaded album art'),
        subtitle: const Text('Remove cached artwork; embedded artwork stays'),
        onTap: () async {
          await ArtStore.clear();
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork cache cleared')),
          );
        },
      ),
      const SizedBox(height: 12),
      const _SectionTitle('YOUR DATA'),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFFFF8294)),
        title: const Text('Clear listening history'),
        subtitle: const Text('Clear stats without deleting playlists or favorites'),
        onTap: _clearHistory,
      ),
      const SizedBox(height: 18),
      const Center(child: Text('Private by design · Your listening data stays on this device',
        textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 11))),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(color: accent, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w800));
}