import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Db {
  static Database? _db;

  static Future<Database> get() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'tunr.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE fav(id INTEGER PRIMARY KEY)');
        await d.execute('CREATE TABLE playlists(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
        await d.execute('CREATE TABLE pl_songs(pl INTEGER, song INTEGER, PRIMARY KEY(pl, song))');
        await d.execute('CREATE TABLE stats(id INTEGER PRIMARY KEY, plays INTEGER NOT NULL DEFAULT 0, skips INTEGER NOT NULL DEFAULT 0, last INTEGER NOT NULL DEFAULT 0, total_ms INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0)');
        await d.execute('CREATE TABLE lyrics(id INTEGER PRIMARY KEY, body TEXT)');
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await d.execute('ALTER TABLE stats ADD COLUMN total_ms INTEGER NOT NULL DEFAULT 0');
          await d.execute('ALTER TABLE stats ADD COLUMN completed INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
    return _db!;
  }
}