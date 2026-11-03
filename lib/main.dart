import 'core/settings.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/lyrics.dart';
import 'core/player.dart';
import 'data/repo.dart';
import 'ui/home.dart';
import 'ui/library.dart';
import 'ui/search.dart';
import 'ui/insights.dart';
import 'ui/settings_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.leon.tunr.audio',
    androidNotificationChannelName: 'Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_notif',
    notificationColor: accent,
  );
  await Settings.load();
  await Repo.i.load();
  await Lyrics.load();
  runApp(const TunrApp());
}

class TunrApp extends StatelessWidget {
  const TunrApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Tunr', debugShowCheckedModeBanner: false,
    theme: appTheme, home: const Boot(),
  );
}

class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  final f = Player.i.init();
  @override
  Widget build(BuildContext c) => FutureBuilder<bool>(
    future: f,
    builder: (_, sn) {
      if (sn.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (sn.data != true) {
        return Scaffold(body: Center(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.library_music_rounded, color: accent, size: 44),
            const SizedBox(height: 14),
            const Text('Give Tunr access to your music', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Allow music access in Android Settings, then reopen Tunr.',
              textAlign: TextAlign.center, style: TextStyle(color: textMuted)),
          ]),
        )));
      }
      return const Shell();
    },
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  static const _pages = [
    HomePage(), SearchPage(), LibraryPage(), InsightsPage(), SettingsPage(),
  ];

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: bg,
    body: IndexedStack(index: tab, children: _pages),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(color: bg, border: Border(top: BorderSide(color: outline, width: .5))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniPlayer(),
        NavigationBar(
          height: 66,
          backgroundColor: bg,
          indicatorColor: accent.withOpacity(.13),
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
            NavigationDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ]),
    ),
  );
}