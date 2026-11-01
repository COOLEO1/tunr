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
  Widget _field(String label, String key, {bool secret = false, String def = ''}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          initialValue: Settings.str(key, def),
          obscureText: secret,
          onChanged: (v) => Settings.setStr(key, v),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      );

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('AI and lookups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 12),
          _field('Groq API key', 'groq', secret: true),
          _field('Groq model', 'model', def: 'llama-3.3-70b-versatile'),
          _field('Last.fm API key', 'lastfm', secret: true),
          const SizedBox(height: 8),
          const Text('Data saving', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accent)),
          SwitchListTile(
            title: const Text('Wi-Fi only'),
            subtitle: const Text('Lyrics, album art and similar-artist lookups wait for Wi-Fi'),
            value: Settings.wifiOnly,
            onChanged: (v) async {
              await Settings.setFlag('wifi', v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Fetch missing album art'),
            subtitle: const Text('One small download per song, saved forever'),
            value: Settings.artOnline,
            onChanged: (v) async {
              await Settings.setFlag('art', v);
              setState(() {});
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: Lyrics.enabled,
            builder: (_, on, __) => SwitchListTile(
              title: const Text('Show lyrics'),
              subtitle: const Text('Cached after the first fetch'),
              value: on,
              onChanged: (_) => Lyrics.toggle(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear downloaded album art'),
            onTap: () async {
              final m = ScaffoldMessenger.of(c);
              await ArtStore.clear();
              m.showSnackBar(const SnackBar(content: Text('Art cache cleared')));
            },
          ),
        ]),
      );
}
