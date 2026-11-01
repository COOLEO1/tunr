import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static late SharedPreferences _p;

  static Future<void> load() async {
    _p = await SharedPreferences.getInstance();
  }

  static String str(String k, [String d = '']) => _p.getString(k) ?? d;
  static bool flag(String k, bool d) => _p.getBool(k) ?? d;
  static Future<void> setStr(String k, String v) async {
    await _p.setString(k, v);
  }

  static Future<void> setFlag(String k, bool v) async {
    await _p.setBool(k, v);
  }

  static String get groqKey => str('groq').trim();
  static String get lastfmKey => str('lastfm').trim();
  static String get model => str('model', 'llama-3.3-70b-versatile').trim();
  static bool get wifiOnly => flag('wifi', false);
  static bool get artOnline => flag('art', true);
}
