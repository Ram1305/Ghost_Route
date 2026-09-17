import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../apis/auth_api.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../services/push_notification_service.dart';
import 'auth_controller.dart';
import 'home_controller.dart';

/// Backs the Settings screen. Thin wrapper over [Pref] so every setting
/// survives app restarts; mirrors live-relevant values into [HomeController]
/// when it's registered so already-open screens (Home) update immediately.
class SettingsController extends GetxController {
  late final RxString dnsServer = (Pref.customDnsServer ?? '').obs;
  late final RxBool isDarkMode = Pref.isDarkMode.obs;
  late final RxBool pushEnabled = (Pref.currentUser?.pushEnabled ?? true).obs;
  final RxBool pushUpdating = false.obs;

  /// [value] is trimmed and persisted; pass null/empty to clear (use the
  /// server-provided DNS again). Applies on the next connect.
  void setCustomDnsServer(String? value) {
    final trimmed = value?.trim() ?? '';
    dnsServer.value = trimmed;
    Pref.customDnsServer = trimmed.isEmpty ? null : trimmed;
  }

  void setDarkMode(bool dark) {
    if (isDarkMode.value == dark) return;
    isDarkMode.value = dark;
    Pref.isDarkMode = dark;
    Get.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
    // NexusTheme's colors are plain static getters (not part of the widget
    // tree's reactive graph), so a full rebuild is needed for already-built
    // screens to pick up the new palette.
    Get.forceAppUpdate();
  }

  /// Persists Settings > Push notifications on/off with the backend (the
  /// actual sender — see notifyAdminsOfNewSubscription) and rolls the UI
  /// back if the request fails.
  Future<void> setPushEnabled(bool enabled) async {
    if (pushEnabled.value == enabled || pushUpdating.value) return;
    if (!Pref.isLoggedIn) {
      MyDialogs.error(msg: 'Log in to change notification settings');
      return;
    }
    final previous = pushEnabled.value;
    pushEnabled.value = enabled;
    pushUpdating.value = true;
    try {
      await AuthApi.setPushEnabled(enabled);
      final user = Pref.currentUser;
      if (user != null) {
        final updated = user.copyWith(pushEnabled: enabled);
        Pref.currentUser = updated;
        final users = Pref.users;
        final idx = users.indexWhere((u) => u.email.toLowerCase() == updated.email.toLowerCase());
        if (idx >= 0) {
          users[idx] = updated;
          Pref.users = users;
        }
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().currentUser.value = updated;
        }
      }
      if (enabled) {
        PushNotificationService.registerAfterLogin();
      }
    } catch (e) {
      pushEnabled.value = previous;
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      pushUpdating.value = false;
    }
  }

  void clearConnectionHistory() {
    Pref.clearConnectionHistory();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().reloadConnectionHistory();
    }
  }
}
