import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../config/app_config.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';
import '../models/vpn_config.dart';
import '../services/server_speed_test.dart';
import '../services/vpn_engine.dart';
import '../services/free_vpn_session_service.dart';
import '../screens/premium_screen.dart';
import '../controllers/main_nav_controller.dart';
import '../theme/nexus_theme.dart';

class HomeController extends GetxController {
  final Rx<Vpn> vpn = Pref.vpn.obs;

  final vpnState = VpnEngine.vpnDisconnected.obs;

  /// Seconds left in today's free VPN session (non-subscribers only).
  final freeSecondsRemaining = 0.obs;

  /// Whether to show the "You're Secured" overlay (set on connect, dismissed by user).
  final showSecuredOverlay = false.obs;

  StreamSubscription<String>? _vpnStageSubscription;
  Timer? _connectTimeout;
  Timer? _freeSessionTimer;
  bool _userCancelledConnect = false;
  bool _freeSessionEnding = false;
  bool _manualFreeDisconnect = false;
  /// True once we've seen a non-disconnected stage this connect attempt (avoids false "connection failed" on plugin cleanup).
  bool _sawConnectingStageThisAttempt = false;
  /// Avoids spamming "connection failed" during VPN reconnect/disconnect cycles.
  bool _connectFailureNotified = false;

  /// Max time to wait for "connected" before showing timeout error.
  static const Duration _connectTimeoutDuration = Duration(seconds: 60);

  @override
  void onInit() {
    super.onInit();
    _vpnStageSubscription = VpnEngine.vpnStageSnapshot().listen(_onVpnStage);
    _initFreeSessionState();
  }

  Future<void> _initFreeSessionState() async {
    await FreeVpnSessionService.syncFromServer();
    _restoreFreeSessionIfNeeded();
  }

  void _onVpnStage(String event) {
    _connectTimeout?.cancel();
    _connectTimeout = null;
    final wasConnecting = _isConnectingState(vpnState.value);
    final wasConnected = vpnState.value == VpnEngine.vpnConnected;
    if (event != VpnEngine.vpnDisconnected) {
      _sawConnectingStageThisAttempt = true;
    }
    vpnState.value = event;

    if (event == VpnEngine.vpnConnected) {
      showSecuredOverlay.value = true;
      MainNavController.switchTo(MainTab.home);
      _onVpnConnected();
    }

    if (event == VpnEngine.vpnDisconnected) {
      if (wasConnected) {
        _onVpnDisconnectedAfterConnect();
      }
      if (wasConnecting &&
          !_userCancelledConnect &&
          !_freeSessionEnding &&
          _sawConnectingStageThisAttempt &&
          !_connectFailureNotified) {
        _connectFailureNotified = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MyDialogs.info(
            msg:
                'Connection failed. Check your network and credentials, then try another location.',
          );
        });
      }
      _sawConnectingStageThisAttempt = false;
    }
    _userCancelledConnect = false;
  }

  void _onVpnConnected() {
    if (Pref.hasActiveSubscription) return;
    if (!Pref.hasUsedFreeVpnSessionToday) {
      Pref.markFreeVpnSessionUsed();
      FreeVpnSessionService.markUsedOnServer(
        startedAt: Pref.freeVpnSessionStartedAt,
      );
    }
    _syncFreeSecondsRemaining();
    _startFreeSessionTimer();
  }

  void _onVpnDisconnectedAfterConnect() {
    _stopFreeSessionTimer();
    Pref.clearFreeVpnSessionStart();
    freeSecondsRemaining.value = 0;

    if (_freeSessionEnding) {
      _freeSessionEnding = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFreeSessionEndedDialog();
      });
      return;
    }

    if (_manualFreeDisconnect && !Pref.hasActiveSubscription) {
      _manualFreeDisconnect = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MyDialogs.info(msg: AppConfig.freeSessionUsedMessage);
      });
    }
  }

  void _restoreFreeSessionIfNeeded() {
    if (Pref.hasActiveSubscription) return;
    if (Pref.freeVpnSessionStartedAt == null) return;

    VpnEngine.stage().then((stage) {
      if (stage?.toLowerCase() != VpnEngine.vpnConnected) return;
      vpnState.value = VpnEngine.vpnConnected;
      final remaining = Pref.freeSessionRemainingSeconds;
      if (remaining <= 0) {
        _endFreeSession();
        return;
      }
      freeSecondsRemaining.value = remaining;
      _startFreeSessionTimer();
    });
  }

  void _syncFreeSecondsRemaining() {
    freeSecondsRemaining.value = Pref.freeSessionRemainingSeconds;
  }

  void _startFreeSessionTimer() {
    _freeSessionTimer?.cancel();
    _syncFreeSecondsRemaining();
    if (freeSecondsRemaining.value <= 0) {
      _endFreeSession();
      return;
    }
    _freeSessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (Pref.hasActiveSubscription) {
        _stopFreeSessionTimer();
        return;
      }
      _syncFreeSecondsRemaining();
      if (freeSecondsRemaining.value <= 0) {
        _endFreeSession();
      }
    });
  }

  void _stopFreeSessionTimer() {
    _freeSessionTimer?.cancel();
    _freeSessionTimer = null;
  }

  Future<void> _endFreeSession() async {
    if (_freeSessionEnding) return;
    _freeSessionEnding = true;
    _stopFreeSessionTimer();
    await VpnEngine.stopVpn();
  }

  void _showFreeSessionEndedDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: NexusTheme.bg2,
        title: const Text(
          'Free session ended',
          style: TextStyle(color: NexusTheme.text),
        ),
        content: Text(
          AppConfig.freeSessionEndedMessage,
          style: const TextStyle(color: NexusTheme.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK', style: TextStyle(color: NexusTheme.text2)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => const PremiumScreen());
            },
            child: const Text('Subscribe', style: TextStyle(color: NexusTheme.teal)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
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
    _stopFreeSessionTimer();
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
    if (vpnState.value == VpnEngine.vpnDisconnected) {
      if (vpn.value.openVPNConfigDataBase64.isEmpty) {
        debugPrint(
            '[TronVPN] connectToVpn: No config selected - auto-picking fastest server.');
        final picked = await _autoSelectFastestServer();
        if (picked == null) return;
      }

      if (!Pref.hasActiveSubscription) {
        await FreeVpnSessionService.syncFromServer();
        if (!Pref.canStartFreeVpnSession) {
          if (kDebugMode) {
            debugPrint(
              '[TronVPN] connectToVpn: Free session used today — opening Premium.',
            );
          }
          MyDialogs.info(msg: AppConfig.freeSessionExhaustedMessage);
          Get.to(() => const PremiumScreen());
          return;
        }
      }

      debugPrint(
          '[TronVPN] connectToVpn: Starting connect to ${vpn.value.countryLong} (${vpn.value.hostname})');
      _sawConnectingStageThisAttempt = false;
      _connectFailureNotified = false;
      _manualFreeDisconnect = false;
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
      if (!Pref.hasActiveSubscription) {
        _manualFreeDisconnect = true;
      }
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

  /// Auto-picks the lowest-latency server when the user taps Connect without
  /// choosing a location first. Reuses vpnConnecting so the orb shows its
  /// normal spinner while servers are probed. Returns the picked server, or
  /// null if none could be found (or the user cancelled while this ran).
  Future<Vpn?> _autoSelectFastestServer() async {
    vpnState.value = VpnEngine.vpnConnecting;
    try {
      var servers = Pref.vpnList;
      if (servers.isEmpty) {
        servers = await APIs.getVPNServers();
      }
      servers = servers
          .where((v) => v.openVPNConfigDataBase64.trim().isNotEmpty)
          .toList();

      if (vpnState.value != VpnEngine.vpnConnecting) return null;
      if (servers.isEmpty) {
        vpnState.value = VpnEngine.vpnDisconnected;
        MyDialogs.info(msg: 'Select a Location by clicking \'Change Location\'');
        return null;
      }

      final fastest = await ServerSpeedTest.findFastest(servers);
      if (vpnState.value != VpnEngine.vpnConnecting) return null;
      if (fastest == null) {
        vpnState.value = VpnEngine.vpnDisconnected;
        MyDialogs.info(msg: 'Select a Location by clicking \'Change Location\'');
        return null;
      }

      vpn.value = fastest;
      Pref.vpn = fastest;
      debugPrint(
          '[TronVPN] _autoSelectFastestServer: picked ${fastest.countryLong} (${fastest.hostname})');
      return fastest;
    } catch (e) {
      debugPrint('[TronVPN] _autoSelectFastestServer: error $e');
      vpnState.value = VpnEngine.vpnDisconnected;
      MyDialogs.info(msg: 'Select a Location by clicking \'Change Location\'');
      return null;
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
