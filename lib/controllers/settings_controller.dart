import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/pref.dart';
import 'home_controller.dart';

/// Backs the Settings screen. Thin wrapper over [Pref] so every setting
/// survives app restarts; mirrors live-relevant values into [HomeController]
/// when it's registered so already-open screens (Home) update immediately.
class SettingsController extends GetxController {
  late final RxString protocol = Pref.selectedProtocol.obs;
  late final RxString dnsServer = (Pref.customDnsServer ?? '').obs;
  late final RxBool isDarkMode = Pref.isDarkMode.obs;

  void setProtocol(String value) {
    if (protocol.value == value) return;
    protocol.value = value;
    Pref.selectedProtocol = value;
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().selectedProtocol.value = value;
    }
  }

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

  void clearConnectionHistory() {
    Pref.clearConnectionHistory();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().reloadConnectionHistory();
    }
  }
}
