import 'package:flutter/material.dart';
import '../core/art_store.dart';
import '../core/lyrics.dart';
import '../core/settings.dart';
import 'theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Widget section(String title, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 23, 4, 12),
    child: Row(children: [
      Icon(icon, color: accent, size: 20),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(
        color: accent, fontWeight: FontWeight.w800, fontSize: 15)),
    ]),
  );

  Widget field(String label, String key,
      {bool secret = false, String def = '', String hint = ''}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        initialValue: Settings.str(key, def),
        obscureText: secret,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (v) => Settings.setStr(key, v),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(secret ? Icons.key : Icons.tune, color: accent),
          suffixIcon: secret ? const Icon(Icons.lock_outline, size: 18) : null,
        ),
      ),
    );

  Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: accent.withOpacity(.14)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Settings',
      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(17, 5, 17, 35),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: const LinearGradient(
              colors: [Color(0xFF8312D7), Color(0xFF25103D)],
            ),
          ),
          child: const Row(children: [
            Icon(Icons.graphic_eq, size: 42),
            SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TUNR', style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('Your music. Your universe.',
                style: TextStyle(color: Colors.white70)),
            ]),
          ]),
        ),
        section('AI intelligence', Icons.auto_awesome),
        panel(Column(children: [
          field('Groq API key', 'groq', secret: true),
          field('Groq model', 'model', def: 'llama-3.3-70b-versatile'),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Used for AI playlist generation.',
              style: TextStyle(color: muted, fontSize: 12)),
          ),
        ])),
        section('Music discovery', Icons.public),
        panel(Column(children: [
          field('Last.fm API key', 'lastfm', secret: true),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Used for artist and track discovery.',
              style: TextStyle(color: muted, fontSize: 12)),
          ),
        ])),
        section('Playback and experience', Icons.headphones),
        panel(Column(children: [
          ValueListenableBuilder<bool>(
            valueListenable: Lyrics.enabled,
            builder: (_, on, __) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.lyrics, color: accent),
              title: const Text('Lyrics'),
              subtitle: const Text('Display lyrics in Now Playing'),
              value: on,
              activeThumbColor: accent,
              onChanged: (_) => Lyrics.toggle(),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.wifi, color: accent),
            title: const Text('Wi-Fi only'),
            subtitle: const Text('Save mobile data for online lookups'),
            value: Settings.wifiOnly,
            activeThumbColor: accent,
            onChanged: (v) async {
              await Settings.setFlag('wifi', v);
              setState(() {});
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.album, color: accent),
            title: const Text('Fetch missing artwork'),
            subtitle: const Text('Cache artwork for offline use'),
            value: Settings.artOnline,
            activeThumbColor: accent,
            onChanged: (v) async {
              await Settings.setFlag('art', v);
              setState(() {});
            },
          ),
        ])),
        section('Storage', Icons.storage),
        panel(ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline, color: pink),
          title: const Text('Clear artwork cache'),
          subtitle: const Text('Remove cached album images'),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(c);
            await ArtStore.clear();
            messenger.showSnackBar(
              const SnackBar(content: Text('Artwork cache cleared')));
          },
        )),
        const SizedBox(height: 22),
        const Center(child: Text('TUNR • Made for music lovers',
          style: TextStyle(color: muted, fontSize: 12))),
      ],
    ),
  );
}
