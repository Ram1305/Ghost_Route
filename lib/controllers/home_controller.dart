import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// TODO: Restore ads - import '../helpers/ad_helper.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';
import '../models/vpn_config.dart';
import '../services/vpn_engine.dart';
import '../theme/nexus_theme.dart';

class HomeController extends GetxController {
  final Rx<Vpn> vpn = Pref.vpn.obs;

  final vpnState = VpnEngine.vpnDisconnected.obs;

  /// Whether to show the "You're Secured" overlay (set on connect, dismissed by user).
  final showSecuredOverlay = false.obs;

  StreamSubscription<String>? _vpnStageSubscription;

  @override
  void onInit() {
    super.onInit();
    _vpnStageSubscription = VpnEngine.vpnStageSnapshot().listen((event) {
      vpnState.value = event;
      if (event == VpnEngine.vpnConnected) {
        showSecuredOverlay.value = true;
      }
    });
  }

  void dismissSecuredOverlay() {
    showSecuredOverlay.value = false;
  }

  @override
  void onClose() {
    _vpnStageSubscription?.cancel();
    super.onClose();
  }

  void connectToVpn() async {
    if (!VpnEngine.isVpnSupported) {
      MyDialogs.info(msg: 'VPN is not supported on this device.');
      return;
    }
    if (vpn.value.openVPNConfigDataBase64.isEmpty) {
      MyDialogs.info(msg: 'Select a Location by clicking \'Change Location\'');
      return;
    }

    if (vpnState.value == VpnEngine.vpnDisconnected) {
      vpnState.value = VpnEngine.vpnConnecting;

      try {
        final data =
            Base64Decoder().convert(vpn.value.openVPNConfigDataBase64);
        final config = Utf8Decoder().convert(data);
        final vpnConfig = VpnConfig(
            country: vpn.value.countryLong,
            username: 'vpn',
            password: 'vpn',
            config: config);

        await VpnEngine.startVpn(vpnConfig);
      } catch (e) {
        vpnState.value = VpnEngine.vpnDisconnected;
        final message = VpnEngine.getFriendlyError(e);
        final clean = message.replaceFirst(RegExp(r'^Exception: '), '');
        MyDialogs.error(msg: 'Failed to connect: $clean');
      }
    } else {
      await VpnEngine.stopVpn();
    }
  }

  // vpn buttons color
  Color get getButtonColor {
    switch (vpnState.value) {
      case VpnEngine.vpnDisconnected:
        return NexusTheme.blue;

      case VpnEngine.vpnConnected:
        return NexusTheme.teal;

      default:
        return NexusTheme.gold;
    }
  }

  // vpn button text
  String get getButtonText {
    switch (vpnState.value) {
      case VpnEngine.vpnDisconnected:
        return 'Tap to Connect';

      case VpnEngine.vpnConnected:
        return 'Disconnect';

      default:
        return 'Connecting...';
    }
  }
}
