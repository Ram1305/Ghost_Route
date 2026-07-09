import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../config/app_config.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';
import '../models/vpn_config.dart';
import '../models/wireguard_server.dart';
import '../services/server_speed_test.dart';
import '../services/vpn_engine.dart';
import '../services/free_vpn_session_service.dart';
import '../services/wireguard_engine.dart';
import '../services/wireguard_service.dart';
import '../screens/premium_screen.dart';
import '../controllers/main_nav_controller.dart';
import '../theme/nexus_theme.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final Rx<Vpn> vpn = Pref.vpn.obs;
  final Rx<WireguardServer> wireguardServer = Pref.wireguardServer.obs;
  final selectedProtocol = Pref.selectedProtocol.obs; // 'openvpn' | 'wireguard'

  final vpnState = VpnEngine.vpnDisconnected.obs;

  /// Seconds left in today's free VPN session (non-subscribers only).
  final freeSecondsRemaining = 0.obs;

  /// Whether to show the "You're Secured" overlay (set on connect, dismissed by user).
  final showSecuredOverlay = false.obs;

  StreamSubscription<String>? _vpnStageSubscription;
  Worker? _protocolWorker;
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
    WidgetsBinding.instance.addObserver(this);
    _attachStageListener();
    _protocolWorker = ever<String>(selectedProtocol, (_) {
      Pref.selectedProtocol = selectedProtocol.value;
      _attachStageListener();
      _syncVpnStateFromEngine();
    });
    _initFreeSessionState();
  }

  void _attachStageListener() {
    _vpnStageSubscription?.cancel();
    if (selectedProtocol.value == 'wireguard') {
      _vpnStageSubscription =
          WireguardEngine.stageSnapshot().listen(_onVpnStage);
    } else {
      _vpnStageSubscription = VpnEngine.vpnStageSnapshot().listen(_onVpnStage);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncVpnStateFromEngine();
    }
  }

  Future<void> _initFreeSessionState() async {
    await FreeVpnSessionService.syncFromServer();
    await _syncVpnStateFromEngine();
  }

  /// Seeds [vpnState] from the native tunnel when the app starts or resumes.
  /// Stage-change events are not re-emitted for an already-running tunnel.
  Future<void> _syncVpnStateFromEngine() async {
    if (selectedProtocol.value != 'wireguard' && !VpnEngine.isVpnSupported) {
      return;
    }

    try {
      if (selectedProtocol.value == 'wireguard') {
        await WireguardEngine.initialize(
          interfaceName: 'wg0',
          vpnName: 'Ghost Route',
          iosAppGroup: AppConfig.iosAppGroup,
        );
      } else {
        await VpnEngine.initialize();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TronVPN] _syncVpnStateFromEngine: init failed $e');
      }
      return;
    }

    try {
      final stage = selectedProtocol.value == 'wireguard'
          ? null
          : await VpnEngine.stage();
      final normalizedStage = (stage ?? vpnState.value).toLowerCase();

      if (normalizedStage == VpnEngine.vpnConnected) {
        if (vpnState.value != VpnEngine.vpnConnected) {
          vpnState.value = VpnEngine.vpnConnected;
        }
        _restoreFreeSessionTimerIfNeeded();
        return;
      }

      if (normalizedStage == VpnEngine.vpnDisconnected &&
          !_isConnectingState(vpnState.value)) {
        vpnState.value = VpnEngine.vpnDisconnected;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TronVPN] _syncVpnStateFromEngine: stage query failed $e');
      }
    }
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

  /// Restores the free-session countdown when the native tunnel is still up.
  void _restoreFreeSessionTimerIfNeeded() {
    if (Pref.hasActiveSubscription) return;
    if (Pref.freeVpnSessionStartedAt == null) return;

    final remaining = Pref.freeSessionRemainingSeconds;
    if (remaining <= 0) {
      _endFreeSession();
      return;
    }
    freeSecondsRemaining.value = remaining;
    _startFreeSessionTimer();
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
    WidgetsBinding.instance.removeObserver(this);
    _connectTimeout?.cancel();
    _stopFreeSessionTimer();
    _vpnStageSubscription?.cancel();
    _protocolWorker?.dispose();
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
    if (selectedProtocol.value != 'wireguard' && !VpnEngine.isVpnSupported) {
      debugPrint('[TronVPN] connectToVpn: VPN not supported on this device');
      MyDialogs.info(msg: 'VPN is not supported on this device.');
      return;
    }
    if (vpnState.value == VpnEngine.vpnDisconnected) {
      if (selectedProtocol.value == 'openvpn' &&
          vpn.value.openVPNConfigDataBase64.isEmpty) {
        debugPrint(
            '[TronVPN] connectToVpn: No config selected - auto-picking fastest server.');
        final picked = await _autoSelectFastestServer();
        if (picked == null) return;
      }

      if (selectedProtocol.value == 'openvpn' &&
          vpn.value.premiumOnly &&
          !Pref.hasActiveSubscription) {
        debugPrint(
            '[TronVPN] connectToVpn: Premium server requires subscription.');
        Get.to(() => const PremiumScreen());
        return;
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

      debugPrint('[TronVPN] connectToVpn: Starting connect protocol=${selectedProtocol.value}');
      _sawConnectingStageThisAttempt = false;
      _connectFailureNotified = false;
      _manualFreeDisconnect = false;
      vpnState.value = VpnEngine.vpnConnecting;
      _startConnectTimeout();

      try {
        if (selectedProtocol.value == 'wireguard') {
          // WireGuard servers are premium-only in this app.
          if (!Pref.hasActiveSubscription) {
            Get.to(() => const PremiumScreen());
            return;
          }
          final s = wireguardServer.value;
          if (!s.isConnectable) {
            _connectTimeout?.cancel();
            _connectTimeout = null;
            vpnState.value = VpnEngine.vpnDisconnected;
            MyDialogs.info(
              msg:
                  'This WireGuard location is not configured yet. Choose US New Jersey or Singapore, or pick an OpenVPN server.',
            );
            return;
          }
          final cfg = WireguardService.buildConfig(s);
          await WireguardEngine.startVpn(
            serverAddress: '${s.host}:${s.port}',
            wgQuickConfig: cfg,
            providerBundleIdentifier: Platform.isIOS
                ? AppConfig.iosWireguardExtensionBundleId
                : null,
          );
        } else {
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
        }
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
      if (selectedProtocol.value == 'wireguard') {
        await WireguardEngine.stopVpn();
      } else {
        await VpnEngine.stopVpn();
      }
    } else {
      // Intermediate state (e.g. connecting, authenticating): tap cancels the connection.
      debugPrint(
          '[TronVPN] connectToVpn: Cancelling connection (state "${vpnState.value}")');
      _userCancelledConnect = true;
      _connectTimeout?.cancel();
      _connectTimeout = null;
      if (selectedProtocol.value == 'wireguard') {
        await WireguardEngine.stopVpn();
      } else {
        await VpnEngine.stopVpn();
      }
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
      var servers = Pref.vpnListFree;
      if (servers.isEmpty) {
        servers = await APIs.getFreeServers();
      }
      servers = servers
          .where((v) =>
              !v.premiumOnly && v.openVPNConfigDataBase64.trim().isNotEmpty)
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
