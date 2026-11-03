import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Db {
  static Database? _db;
  static Future<Database> get() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'tunr.db');
    _db = await openDatabase(path, version: 3,
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE fav(id INTEGER PRIMARY KEY)');
        await d.execute('CREATE TABLE playlists(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
        await d.execute('CREATE TABLE pl_songs(pl INTEGER, song INTEGER, PRIMARY KEY(pl, song))');
        await d.execute('CREATE TABLE stats(id INTEGER PRIMARY KEY, plays INTEGER NOT NULL DEFAULT 0, skips INTEGER NOT NULL DEFAULT 0, last INTEGER NOT NULL DEFAULT 0, total_ms INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0)');
        await d.execute('CREATE TABLE lyrics(id INTEGER PRIMARY KEY, body TEXT)');
        await d.execute('CREATE TABLE listening_sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, song_id INTEGER NOT NULL, started_at INTEGER NOT NULL, ended_at INTEGER, duration_ms INTEGER NOT NULL DEFAULT 0, listened_ms INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0, skipped INTEGER NOT NULL DEFAULT 0, end_reason TEXT, counted INTEGER NOT NULL DEFAULT 0)');
        await d.execute('CREATE INDEX idx_sessions_song ON listening_sessions(song_id)');
        await d.execute('CREATE INDEX idx_sessions_started ON listening_sessions(started_at)');
        await d.execute('CREATE INDEX idx_sessions_ended ON listening_sessions(ended_at)');
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await d.execute('ALTER TABLE stats ADD COLUMN total_ms INTEGER NOT NULL DEFAULT 0');
          await d.execute('ALTER TABLE stats ADD COLUMN completed INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          // Old time/completion values were wall-clock estimates, so retain
          // historic play/skip counts but reset those two unreliable totals.
          await d.execute('UPDATE stats SET total_ms=0, completed=0');
          await d.execute('CREATE TABLE listening_sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, song_id INTEGER NOT NULL, started_at INTEGER NOT NULL, ended_at INTEGER, duration_ms INTEGER NOT NULL DEFAULT 0, listened_ms INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0, skipped INTEGER NOT NULL DEFAULT 0, end_reason TEXT, counted INTEGER NOT NULL DEFAULT 0)');
          await d.execute('CREATE INDEX idx_sessions_song ON listening_sessions(song_id)');
          await d.execute('CREATE INDEX idx_sessions_started ON listening_sessions(started_at)');
          await d.execute('CREATE INDEX idx_sessions_ended ON listening_sessions(ended_at)');
        }
      });
    return _db!;
  }
}