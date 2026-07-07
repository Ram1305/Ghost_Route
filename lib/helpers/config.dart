import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class Config {
  static final _config = FirebaseRemoteConfig.instance;

  static const _defaultValues = {
    "min_app_version": "0.0.0",
    "latest_app_version": "0.0.0",
    "force_update_enabled": false,
    "update_title": "Update available",
    "update_message":
        "A new version of Ghost Route is available with improvements and bug fixes.",
    "ios_app_store_id": "",
  };

  static Future<void> initConfig() async {
    await _config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 30)));

    await _config.setDefaults(_defaultValues);
    try {
      await _config.fetchAndActivate();
    } catch (e) {
      // Defaults from setDefaults() above remain active; don't block/crash startup.
      log('Remote Config fetch failed, using defaults: $e');
    }

    _config.onConfigUpdated.listen((event) async {
      await _config.activate();
    });
  }

  // App update (Firebase Remote Config)
  static String get minAppVersion => _config.getString('min_app_version');
  static String get latestAppVersion => _config.getString('latest_app_version');
  static bool get forceUpdateEnabled => _config.getBool('force_update_enabled');
  static String get updateTitle => _config.getString('update_title');
  static String get updateMessage => _config.getString('update_message');
  static String get iosAppStoreId => _config.getString('ios_app_store_id');
}
