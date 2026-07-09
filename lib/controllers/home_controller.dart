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
  final wgDownload = '0 kbps'.obs;
  final wgUpload = '0 kbps'.obs;

  /// Seconds elapsed since the current connect attempt started (0 when not connecting).
  final connectElapsedSeconds = 0.obs;

  /// Seconds left in today's free VPN session (non-subscribers only).
  final freeSecondsRemaining = 0.obs;

  /// Whether to show the "You're Secured" overlay (set on connect, dismissed by user).
  final showSecuredOverlay = false.obs;

  StreamSubscription<String>? _vpnStageSubscription;
  StreamSubscription<Map<String, dynamic>?>? _wgTrafficSubscription;
  Worker? _protocolWorker;
  Timer? _connectTimeout;
  Timer? _connectElapsedTimer;
  Timer? _freeSessionTimer;
  bool _userCancelledConnect = false;
  bool _freeSessionEnding = false;
  bool _manualFreeDisconnect = false;
  DateTime? _connectStartedAt;
  bool _pickingFastestFree = false;
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
    _wgTrafficSubscription?.cancel();
    _wgTrafficSubscription = null;
    if (selectedProtocol.value == 'wireguard') {
      _vpnStageSubscription =
          WireguardEngine.stageSnapshot().listen(_onVpnStage);
      _attachWireguardTrafficListener();
    } else {
      _vpnStageSubscription = VpnEngine.vpnStageSnapshot().listen(_onVpnStage);
      wgDownload.value = '0 kbps';
      wgUpload.value = '0 kbps';
    }
  }

  void _attachWireguardTrafficListener() {
    int? lastRx;
    int? lastTx;
    int? lastAtMs;
    bool loggedOnce = false;

    _wgTrafficSubscription = WireguardEngine.trafficSnapshot().listen((data) {
      if (data == null) return;

      if (kDebugMode && !loggedOnce) {
        loggedOnce = true;
        debugPrint('[TronVPN] WG traffic snapshot: $data');
      }

      dynamic pick(List<String> keys) {
        for (final k in keys) {
          if (data.containsKey(k)) return data[k];
        }
        return null;
      }

      int? toInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is num) return v.toInt();
        final s = v.toString().trim();
        return int.tryParse(s);
      }

      String? toSpeedString(dynamic v) {
        if (v == null) return null;
        if (v is String) {
          final s = v.trim();
          // If plugin already provides "12 kbps"/"1.2 Mbps" etc, use it.
          if (RegExp(r'(kbps|mbps|bps)$', caseSensitive: false).hasMatch(s)) {
            return s;
          }
        }
        return null;
      }

      // If plugin provides speed strings directly, prefer them.
      final downStr = toSpeedString(pick([
        'downloadSpeed',
        'downSpeed',
        'rxSpeed',
        'download_rate',
        'byteIn',
        'down',
      ]));
      final upStr = toSpeedString(pick([
        'uploadSpeed',
        'upSpeed',
        'txSpeed',
        'upload_rate',
        'byteOut',
        'up',
      ]));
      if (downStr != null && upStr != null) {
        wgDownload.value = downStr;
        wgUpload.value = upStr;
        return;
      }

      // If plugin provides numeric speed values, show them as kbps.
      final downNum = toInt(pick([
        'downloadSpeed',
        'downSpeed',
        'rxSpeed',
        'download_rate',
      ]));
      final upNum = toInt(pick([
        'uploadSpeed',
        'upSpeed',
        'txSpeed',
        'upload_rate',
      ]));
      if (downNum != null && upNum != null) {
        wgDownload.value = '${downNum.clamp(0, 99999)} kbps';
        wgUpload.value = '${upNum.clamp(0, 99999)} kbps';
        return;
      }

      // Otherwise, try cumulative byte counters and compute kbps deltas.
      int? rx = toInt(pick(['rx', 'received', 'bytesReceived', 'bytesIn', 'totalRx', 'totalReceived']));
      int? tx = toInt(pick(['tx', 'sent', 'bytesSent', 'bytesOut', 'totalTx', 'totalSent']));

      // wireguard_flutter_plus emits totals as totalDownload/totalUpload on some platforms.
      rx ??= toInt(pick(['totalDownload', 'downloadTotal', 'total_download']));
      tx ??= toInt(pick(['totalUpload', 'uploadTotal', 'total_upload']));

      // Some plugins nest totals under "download"/"upload" objects.
      if (rx == null) {
        final nested = pick(['download', 'downlink', 'rxTotal', 'in']);
        if (nested is Map) {
          rx = toInt(nested['bytes'] ?? nested['total'] ?? nested['value']);
        }
      }
      if (tx == null) {
        final nested = pick(['upload', 'uplink', 'txTotal', 'out']);
        if (nested is Map) {
          tx = toInt(nested['bytes'] ?? nested['total'] ?? nested['value']);
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (rx == null || tx == null) return;

      if (lastRx != null && lastTx != null && lastAtMs != null) {
        final dtMs = (now - lastAtMs!).clamp(1, 60000);
        final drx = (rx - lastRx!).clamp(0, 1 << 62);
        final dtx = (tx - lastTx!).clamp(0, 1 << 62);
        final dtS = dtMs / 1000.0;

        final downKbps = ((drx * 8) / 1000.0 / dtS).round();
        final upKbps = ((dtx * 8) / 1000.0 / dtS).round();

        wgDownload.value = '${downKbps.clamp(0, 99999)} kbps';
        wgUpload.value = '${upKbps.clamp(0, 99999)} kbps';
      }

      lastRx = rx;
      lastTx = tx;
      lastAtMs = now;
    });
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
    _stopConnectElapsedTimer(reset: true);
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
                'Connection failed. Check your Internet and then try another location.',
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
    _connectElapsedTimer?.cancel();
    _stopFreeSessionTimer();
    _vpnStageSubscription?.cancel();
    _wgTrafficSubscription?.cancel();
    _protocolWorker?.dispose();
    super.onClose();
  }

  void _startConnectElapsedTimer() {
    _connectStartedAt = DateTime.now();
    connectElapsedSeconds.value = 0;
    _connectElapsedTimer?.cancel();
    _connectElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isConnectingState(vpnState.value) || _connectStartedAt == null) {
        _stopConnectElapsedTimer(reset: true);
        return;
      }
      final elapsed =
          DateTime.now().difference(_connectStartedAt!).inSeconds.clamp(0, 3600);
      connectElapsedSeconds.value = elapsed;
    });
  }

  void _stopConnectElapsedTimer({required bool reset}) {
    _connectElapsedTimer?.cancel();
    _connectElapsedTimer = null;
    _connectStartedAt = null;
    if (reset) connectElapsedSeconds.value = 0;
  }

  void _startConnectTimeout() {
    _connectTimeout?.cancel();
    _connectTimeout = Timer(_connectTimeoutDuration, () {
      if (!_isConnectingState(vpnState.value)) return;
      _connectTimeout = null;
      vpnState.value = VpnEngine.vpnDisconnected;
      if (selectedProtocol.value == 'wireguard') {
        WireguardEngine.stopVpn();
      } else {
        VpnEngine.stopVpn();
      }
      MyDialogs.info(
          msg:
              'Connection timed out. Please try again or choose another location.');
    });
  }

  /// Cancels any in-progress connection attempt (if connecting).
  Future<void> cancelConnecting() async {
    if (!_isConnectingState(vpnState.value)) return;
    _userCancelledConnect = true;
    _connectTimeout?.cancel();
    _connectTimeout = null;
    _stopConnectElapsedTimer(reset: true);
    if (selectedProtocol.value == 'wireguard') {
      await WireguardEngine.stopVpn();
    } else {
      await VpnEngine.stopVpn();
    }
    vpnState.value = VpnEngine.vpnDisconnected;
  }

  /// Convenience: cancel and then start a fresh connect.
  Future<void> retryConnection() async {
    await cancelConnecting();
    // Small delay to let native tunnel cleanup settle.
    await Future.delayed(const Duration(milliseconds: 600));
    connectToVpn();
  }

  /// Picks the lowest-latency free OpenVPN server and connects immediately.
  /// Intended for a "Fastest Free Server" one-tap UX.
  Future<void> connectToFastestFreeServer() async {
    if (_pickingFastestFree) return;
    _pickingFastestFree = true;
    try {
      // Ensure we're on OpenVPN for free servers.
      Pref.selectedProtocol = 'openvpn';
      selectedProtocol.value = 'openvpn';

      // If already connected, disconnect first then reconnect.
      if (vpnState.value == VpnEngine.vpnConnected) {
        await VpnEngine.stopVpn();
        await Future.delayed(const Duration(milliseconds: 800));
      } else if (_isConnectingState(vpnState.value)) {
        await cancelConnecting();
        await Future.delayed(const Duration(milliseconds: 400));
      }

      final picked = await _autoSelectFastestServer();
      if (picked == null) return;

      // Start the actual tunnel connect using the picked server.
      connectToVpn();
    } finally {
      _pickingFastestFree = false;
    }
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
      _startConnectElapsedTimer();

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
      await cancelConnecting();
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
