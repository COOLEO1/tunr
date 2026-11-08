import 'core/settings.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/lyrics.dart';
import 'core/player.dart';
import 'data/repo.dart';
import 'ui/home.dart';
import 'ui/library.dart';
import 'ui/search.dart';
import 'ui/stats_page.dart';
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
    title: 'TUNR',
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: const Boot(),
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
      if (!sn.hasData) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: accent)),
        );
      }
      if (sn.data == false) {
        return const Scaffold(
          body: Center(child: Text(
            'Allow music access in Settings, then reopen',
          )),
        );
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

  static const pages = [
    HomePage(),
    SearchPage(),
    LibraryPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext c) => Scaffold(
    body: IndexedStack(index: tab, children: pages),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            height: 67,
            backgroundColor: const Color(0xFF10091D),
            indicatorColor: purple.withOpacity(.22),
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: accent),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore, color: accent),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music, color: accent),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.equalizer),
                selectedIcon: Icon(Icons.equalizer, color: accent),
                label: 'Stats',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: accent),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
