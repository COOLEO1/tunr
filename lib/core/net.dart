import 'package:connectivity_plus/connectivity_plus.dart';
import 'settings.dart';

class Net {
  /// false when offline, or on mobile data while "Wi-Fi only" is on
  static Future<bool> allowed() async {
    final r = await Connectivity().checkConnectivity();
    if (r.contains(ConnectivityResult.none)) return false;
    if (!Settings.wifiOnly) return true;
    return r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet);
  }
}
