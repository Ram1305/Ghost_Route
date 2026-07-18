import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../helpers/config.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../helpers/version_compare.dart';
import '../widgets/app_update_dialog.dart';

class AppUpdateStatus {
  final bool updateAvailable;
  final bool forceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String message;

  const AppUpdateStatus({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.message,
  });

  static const none = AppUpdateStatus(
    updateAvailable: false,
    forceUpdate: false,
    currentVersion: '',
    latestVersion: '',
    title: '',
    message: '',
  );
}

class AppUpdateService {
  AppUpdateService._();

  static StreamSubscription<InstallStatus>? _flexInstallSub;
  static bool _flexListenerAttached = false;

  static Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  static Future<String> currentVersionName() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<AppUpdateStatus> evaluate() async {
    // firebase_remote_config has no Windows implementation; Config's getters
    // would throw MissingPluginException there.
    if (kIsWeb || Platform.isWindows) return AppUpdateStatus.none;

    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    final minVersion = Config.minAppVersion;
    final latestVersion = Config.latestAppVersion;
    final title = Config.updateTitle;
    final message = Config.updateMessage;

    final belowMin =
        minVersion.isNotEmpty && VersionCompare.isLessThan(current, minVersion);
    final belowLatest = latestVersion.isNotEmpty &&
        VersionCompare.isLessThan(current, latestVersion);
    final force = belowMin ||
        (Config.forceUpdateEnabled && belowLatest);

    if (!belowMin && !belowLatest) {
      return AppUpdateStatus.none;
    }

    final target = belowMin ? minVersion : latestVersion;
    return AppUpdateStatus(
      updateAvailable: true,
      forceUpdate: force,
      currentVersion: current,
      latestVersion: target,
      title: title,
      message: message,
    );
  }

  static Future<bool> checkOnLaunch(BuildContext context) async {
    while (true) {
      final status = await evaluate();
      if (!status.updateAvailable) return true;

      if (!status.forceUpdate &&
          Pref.dismissedOptionalUpdateVersion == status.latestVersion) {
        return true;
      }

      if (!context.mounted) return !status.forceUpdate;

      await _showUpdateFlow(
        context,
        status: status,
      );

      if (!status.forceUpdate) return true;

      final recheck = await evaluate();
      if (!recheck.updateAvailable || !recheck.forceUpdate) return true;
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  static Future<void> _showUpdateFlow(
    BuildContext context, {
    required AppUpdateStatus status,
  }) async {
    await AppUpdateDialog.show(
      context,
      title: status.title,
      message: status.message,
      currentVersion: status.currentVersion,
      latestVersion: status.latestVersion,
      forceUpdate: status.forceUpdate,
      onUpdate: () => _startUpdate(force: status.forceUpdate),
      onLater: status.forceUpdate
          ? null
          : () {
              Pref.dismissedOptionalUpdateVersion = status.latestVersion;
            },
    );
  }

  static Future<void> _startUpdate({required bool force}) async {
    if (!kIsWeb && Platform.isAndroid) {
      final usedNative = await _tryAndroidInAppUpdate(force: force);
      if (usedNative) return;
    }
    await _openStoreListing();
  }

  static Future<bool> _tryAndroidInAppUpdate({required bool force}) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate()
          .timeout(const Duration(seconds: 10));
      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }

      if (force && updateInfo.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        return result == AppUpdateResult.success;
      }

      if (updateInfo.flexibleUpdateAllowed) {
        _attachFlexibleInstallListener();
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          MyDialogs.info(
            msg: 'Update downloaded. Restart the app to finish installing.',
          );
          return true;
        }
      }

      if (!force && updateInfo.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        return result == AppUpdateResult.success;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdate] Android in-app update failed: $e');
      }
    }
    return false;
  }

  static void _attachFlexibleInstallListener() {
    if (_flexListenerAttached) return;
    _flexListenerAttached = true;
    _flexInstallSub = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) {
        InAppUpdate.completeFlexibleUpdate();
      }
    });
  }

  static Future<void> _openStoreListing() async {
    final uri = _storeUri();
    if (uri == null) {
      MyDialogs.error(
        msg: 'Store link is not configured yet. Please update from the app store.',
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      MyDialogs.error(msg: 'Could not open the app store.');
    }
  }

  static Uri? _storeUri() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      return Uri.parse(AppConfig.playStoreUrl);
    }
    if (Platform.isIOS) {
      final storeId = Config.iosAppStoreId.isNotEmpty
          ? Config.iosAppStoreId
          : AppConfig.iosAppStoreId;
      if (storeId.isEmpty) return null;
      return Uri.parse(AppConfig.appStoreUrlFor(storeId));
    }
    return null;
  }

  static void dispose() {
    _flexInstallSub?.cancel();
    _flexInstallSub = null;
    _flexListenerAttached = false;
  }
}
