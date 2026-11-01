import 'core/settings.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/lyrics.dart';
import 'core/player.dart';
import 'data/repo.dart';
import 'ui/home.dart';
import 'ui/library.dart';
import 'ui/search.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.leon.tunr.audio',
    androidNotificationChannelName: 'Playback',
    androidNotificationOngoing: true,
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
      title: 'Tunr', debugShowCheckedModeBanner: false, theme: appTheme, home: const Boot());
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
          if (!sn.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (sn.data == false) {
            return const Scaffold(body: Center(child: Text('Allow music access in Settings, then reopen')));
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
  @override
  Widget build(BuildContext c) => Scaffold(
        body: IndexedStack(index: tab, children: const [HomePage(), SearchPage(), LibraryPage()]),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          const MiniPlayer(),
          NavigationBar(
            backgroundColor: bg,
            indicatorColor: Colors.transparent,
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                  icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
            ],
          ),
        ]),
      );
}
