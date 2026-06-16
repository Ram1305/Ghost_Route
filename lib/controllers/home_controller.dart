import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';
import '../models/vpn_config.dart';
import '../models/subscription.dart';
import '../services/vpn_engine.dart';
import '../screens/premium_screen.dart';
import '../theme/nexus_theme.dart';

class HomeController extends GetxController {
  final Rx<Vpn> vpn = Pref.vpn.obs;

  final vpnState = VpnEngine.vpnDisconnected.obs;

  /// Whether to show the "You're Secured" overlay (set on connect, dismissed by user).
  final showSecuredOverlay = false.obs;

  StreamSubscription<String>? _vpnStageSubscription;
  Timer? _connectTimeout;
  bool _userCancelledConnect = false;
  /// True once we've seen a non-disconnected stage this connect attempt (avoids false "connection failed" on plugin cleanup).
  bool _sawConnectingStageThisAttempt = false;

  /// Max time to wait for "connected" before showing timeout error.
  static const Duration _connectTimeoutDuration = Duration(seconds: 60);

  @override
  void onInit() {
    super.onInit();
    _vpnStageSubscription = VpnEngine.vpnStageSnapshot().listen((event) {
      _connectTimeout?.cancel();
      _connectTimeout = null;
      final wasConnecting = _isConnectingState(vpnState.value);
      if (event != VpnEngine.vpnDisconnected) {
        _sawConnectingStageThisAttempt = true;
      }
      vpnState.value = event;
      if (event == VpnEngine.vpnConnected) {
        showSecuredOverlay.value = true;
      }
      if (event == VpnEngine.vpnDisconnected && wasConnecting && !_userCancelledConnect && _sawConnectingStageThisAttempt) {
        // Connection failed (native reported disconnect after we actually started connecting).
        _connectTimeout?.cancel();
        _connectTimeout = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MyDialogs.info(
            msg:
                'Connection failed. Check your network and credentials, then try another location.',
          );
        });
      }
      if (event == VpnEngine.vpnDisconnected) {
        _sawConnectingStageThisAttempt = false;
      }
      _userCancelledConnect = false;
    });
  }

  bool _isConnectingState(String state) {
    return state != VpnEngine.vpnConnected &&
        state != VpnEngine.vpnDisconnected;
  }

  void dismissSecuredOverlay() {
    showSecuredOverlay.value = false;
  }

  @override
  void onClose() {
    _connectTimeout?.cancel();
    _vpnStageSubscription?.cancel();
    super.onClose();
  }

  void _startConnectTimeout() {
    _connectTimeout?.cancel();
    _connectTimeout = Timer(_connectTimeoutDuration, () {
      if (!_isConnectingState(vpnState.value)) return;
      _connectTimeout = null;
      vpnState.value = VpnEngine.vpnDisconnected;
      VpnEngine.stopVpn();
      MyDialogs.info(
          msg:
              'Connection timed out. Please try again or choose another location.');
    });
  }

  void connectToVpn() async {
    debugPrint('[TronVPN] connectToVpn() called. state=${vpnState.value}');
    if (!VpnEngine.isVpnSupported) {
      debugPrint('[TronVPN] connectToVpn: VPN not supported on this device');
      MyDialogs.info(msg: 'VPN is not supported on this device.');
      return;
    }
    if (vpn.value.openVPNConfigDataBase64.isEmpty) {
      debugPrint(
          '[TronVPN] connectToVpn: No config - openVPNConfigDataBase64 is empty. Select a location first.');
      MyDialogs.info(msg: 'Select a Location by clicking \'Change Location\'');
      return;
    }

    if (vpnState.value == VpnEngine.vpnDisconnected) {
      // Enforce active subscription check (logged-in user or guest).
      final user = Pref.currentUser;
      final userPlan = Pref.currentUserActivePlan;
      final guestPlan = Pref.guestActivePlan;
      final plan = userPlan ?? guestPlan;
      final expiresAt = user?.subscriptionExpiresAt ??
          (user != null && user.subscriptionHistory.isNotEmpty && userPlan != null
              ? user.subscriptionHistory.last.date.add(Duration(days: userPlan.daysInPlan))
              : Pref.guestSubscriptionExpiresAt);
      final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

      if (plan == null || isExpired) {
        if (kDebugMode) {
          debugPrint('[TronVPN] connectToVpn: Subscription check failed, but bypassing in debug mode.');
        } else {
          Get.to(() => const PremiumScreen());
          return;
        }
      }

      debugPrint(
          '[TronVPN] connectToVpn: Starting connect to ${vpn.value.countryLong} (${vpn.value.hostname})');
      _sawConnectingStageThisAttempt = false;
      vpnState.value = VpnEngine.vpnConnecting;
      _startConnectTimeout();

      try {
        final data =
            Base64Decoder().convert(vpn.value.openVPNConfigDataBase64);
        final config = Utf8Decoder().convert(data);
        final vpnConfig = VpnConfig(
            country: vpn.value.countryLong,
            username: 'vpn',
            password: 'vpn',
            config: config);
        debugPrint('[TronVPN] connectToVpn: Calling VpnEngine.startVpn()');
        await VpnEngine.startVpn(vpnConfig);
        debugPrint('[TronVPN] connectToVpn: VpnEngine.startVpn() returned');
      } catch (e) {
        _connectTimeout?.cancel();
        _connectTimeout = null;
        debugPrint('[TronVPN] connectToVpn: Error: $e');
        vpnState.value = VpnEngine.vpnDisconnected;
        final message = VpnEngine.getFriendlyError(e);
        final clean = message.replaceFirst(RegExp(r'^Exception: '), '');
        MyDialogs.error(msg: 'Failed to connect: $clean');
      }
    } else if (vpnState.value == VpnEngine.vpnConnected) {
      debugPrint('[TronVPN] connectToVpn: Disconnecting (stopVpn)');
      await VpnEngine.stopVpn();
    } else {
      // Intermediate state (e.g. connecting, authenticating): tap cancels the connection.
      debugPrint(
          '[TronVPN] connectToVpn: Cancelling connection (state "${vpnState.value}")');
      _userCancelledConnect = true;
      _connectTimeout?.cancel();
      _connectTimeout = null;
      await VpnEngine.stopVpn();
      vpnState.value = VpnEngine.vpnDisconnected;
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
