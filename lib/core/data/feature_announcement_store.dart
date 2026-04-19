import 'package:shared_preferences/shared_preferences.dart';

abstract final class FeatureAnnouncementStore {
  static const _collectorStatusIntroDismissedKey =
      'feature_announcement.collector_status_intro.dismissed.v1';

  static Future<bool> isCollectorStatusIntroDismissed() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_collectorStatusIntroDismissedKey) ?? false;
  }

  static Future<void> dismissCollectorStatusIntro() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_collectorStatusIntroDismissedKey, true);
  }
}
