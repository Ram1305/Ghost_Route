import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../config/app_config.dart';
import '../helpers/connection_history.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';
import '../models/vpn_config.dart';
import '../models/vpn_connection_session.dart';
import '../models/wireguard_server.dart';
import '../services/ios_vpn_status.dart';
import '../services/server_speed_test.dart';
import '../services/vpn_engine.dart';
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

  /// Whether to show the "You're Secured" overlay (set on connect, dismissed by user).
  final showSecuredOverlay = false.obs;

  /// Local connection history — reactive so the home section updates immediately.
  final connectionHistory = <VpnConnectionSession>[].obs;

  /// Live active-session fields for the history UI while connected.
  final activeSessionStartedAt = Rxn<DateTime>();
  final activeSessionCountry = ''.obs;
  final activeSessionElapsedSeconds = 0.obs;

  /// Bumps when connection history is updated so UI can react.
  final connectionHistoryRevision = 0.obs;

  StreamSubscription<String>? _vpnStageSubscription;
  StreamSubscription<Map<String, dynamic>?>? _wgTrafficSubscription;
  Worker? _protocolWorker;
  Timer? _connectTimeout;
  Timer? _disconnectTimeout;
  Timer? _connectElapsedTimer;
  Timer? _activeSessionTicker;
  bool _userCancelledConnect = false;
  DateTime? _connectStartedAt;
  bool _pickingFastestFree = false;
  /// True once we've seen a non-disconnected stage this connect attempt (avoids false "connection failed" on plugin cleanup).
  bool _sawConnectingStageThisAttempt = false;
  /// Avoids spamming "connection failed" during VPN reconnect/disconnect cycles.
  bool _connectFailureNotified = false;
  int _connectRetryCount = 0;
  static const int _maxConnectRetries = 2;
  /// True while [_syncVpnStateFromEngine] is polling native state.
  bool _syncingVpnState = false;
  /// True while the user tapped Disconnect and we await native confirmation.
  bool _disconnecting = false;

  /// Max time to wait for "connected" before showing timeout error.
  static const Duration _connectTimeoutDuration = Duration(seconds: 60);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _reloadConnectionHistory();
    _syncActiveSessionUi();
    _attachStageListener();
    _protocolWorker = ever<String>(selectedProtocol, (_) {
      Pref.selectedProtocol = selectedProtocol.value;
      _attachStageListener();
      _syncVpnStateFromEngine();
    });
    _syncVpnStateFromEngine();
  }

  void _reloadConnectionHistory() {
    connectionHistory.assignAll(Pref.connectionHistory);
    connectionHistoryRevision.value++;
  }

  void _syncActiveSessionUi() {
    activeSessionStartedAt.value = Pref.activeConnectionSessionStart;
    activeSessionCountry.value = Pref.activeConnectionCountry ?? '';
    final start = Pref.activeConnectionSessionStart;
    if (start != null && vpnState.value == VpnEngine.vpnConnected) {
      activeSessionElapsedSeconds.value =
          DateTime.now().difference(start).inSeconds.clamp(0, 86400 * 7);
      _startActiveSessionTicker();
    } else {
      activeSessionElapsedSeconds.value = 0;
      _stopActiveSessionTicker();
    }
  }

  void _startActiveSessionTicker() {
    if (_activeSessionTicker != null) return;
    _activeSessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = Pref.activeConnectionSessionStart;
      if (start == null || vpnState.value != VpnEngine.vpnConnected) {
        _stopActiveSessionTicker();
        return;
      }
      activeSessionElapsedSeconds.value =
          DateTime.now().difference(start).inSeconds.clamp(0, 86400 * 7);
    });
  }

  void _stopActiveSessionTicker() {
    _activeSessionTicker?.cancel();
    _activeSessionTicker = null;
  }

  void _attachStageListener() {
    _vpnStageSubscription?.cancel();
    _wgTrafficSubscription?.cancel();
    _wgTrafficSubscription = null;
    if (selectedProtocol.value == 'wireguard') {
      _vpnStageSubscription =
          WireguardEngine.stageSnapshot().listen(_onVpnStage);
      if (vpnState.value == VpnEngine.vpnConnected) {
        _attachWireguardTrafficListener();
      }
    } else {
      _vpnStageSubscription = VpnEngine.vpnStageSnapshot().listen(_onVpnStage);
      wgDownload.value = '0 kbps';
      wgUpload.value = '0 kbps';
    }
  }

  void _detachWireguardTrafficListener() {
    _wgTrafficSubscription?.cancel();
    _wgTrafficSubscription = null;
  }

  void _attachWireguardTrafficListener() {
    if (_wgTrafficSubscription != null) return;
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
      _syncVpnStateFromEngine().then((_) {
        _ensureActiveSessionIfConnected();
        _syncActiveSessionUi();
      });
    }
  }

  String _currentConnectionCountry() {
    if (selectedProtocol.value == 'wireguard') {
      final s = wireguardServer.value;
      final country = s.country.trim();
      if (country.isNotEmpty) return country;
      final name = s.serverName.trim();
      return name.isNotEmpty ? name : 'Unknown';
    }
    final country = vpn.value.countryLong.trim();
    return country.isNotEmpty ? country : 'Unknown';
  }

  void _ensureActiveSessionIfConnected() {
    if (vpnState.value != VpnEngine.vpnConnected) return;
    startActiveConnectionSession(
      country: _currentConnectionCountry(),
      protocol: selectedProtocol.value,
    );
    _syncActiveSessionUi();
  }

  void _beginConnectionSession() {
    startActiveConnectionSession(
      country: _currentConnectionCountry(),
      protocol: selectedProtocol.value,
    );
    _syncActiveSessionUi();
  }

  void _endConnectionSession() {
    if (Pref.activeConnectionSessionStart == null) {
      _syncActiveSessionUi();
      return;
    }
    finalizeActiveConnectionSession();
    _reloadConnectionHistory();
    _syncActiveSessionUi();
  }

  /// Seeds [vpnState] from the native tunnel when the app starts or resumes.
  /// Stage-change events are not re-emitted for an already-running tunnel.
  Future<void> _syncVpnStateFromEngine() async {
    if (selectedProtocol.value != 'wireguard' && !VpnEngine.isVpnSupported) {
      return;
    }
    // Never re-promote UI to connected while a user-initiated disconnect is
    // still tearing the native tunnel down — that is the main "Disconnect takes
    // forever" feel (UI flips back to Connected until the tunnel fully dies).
    if (_disconnecting) return;

    _syncingVpnState = true;
    try {
      if (Platform.isIOS) {
        final tunnel = await IosVpnStatus.activeTunnel();
        if (_disconnecting) return;
        if (tunnel != null) {
          if (tunnel.protocol != null &&
              IosVpnStatus.isActiveStatus(tunnel.status)) {
            await _prepareEngineForProtocol(tunnel.protocol!);
            if (_disconnecting) return;
            _adoptProtocol(tunnel.protocol!);
            _applyConnectedRestoreState();
            return;
          }
          if (tunnel.protocol != null &&
              IosVpnStatus.isConnectingStatus(tunnel.status)) {
            await _prepareEngineForProtocol(tunnel.protocol!);
            if (_disconnecting) return;
            _adoptProtocol(tunnel.protocol!);
            if (vpnState.value == VpnEngine.vpnDisconnected) {
              vpnState.value = VpnEngine.vpnConnecting;
            }
            return;
          }
        }
      }

      final activeProtocol = await _probeConnectedProtocol();
      if (_disconnecting) return;
      if (activeProtocol != null) {
        _adoptProtocol(activeProtocol);
        _applyConnectedRestoreState();
        return;
      }

      final isWireguard = selectedProtocol.value == 'wireguard';
      await _prepareEngineForProtocol(selectedProtocol.value);
      if (_disconnecting) return;

      final stage =
          isWireguard ? await WireguardEngine.stage() : await VpnEngine.stage();
      final normalizedStage =
          (stage ?? VpnEngine.vpnDisconnected).toLowerCase();

      if (normalizedStage == VpnEngine.vpnConnected) {
        _applyConnectedRestoreState();
        return;
      }

      if (_isConnectingState(normalizedStage) &&
          normalizedStage != 'disconnecting') {
        if (vpnState.value == VpnEngine.vpnDisconnected) {
          vpnState.value = normalizedStage;
        }
        return;
      }

      if (!_isConnectingState(vpnState.value)) {
        // Tunnel is gone — finalize any dangling active session so history
        // survives app restarts / background kills.
        if (Pref.activeConnectionSessionStart != null) {
          _endConnectionSession();
        }
        vpnState.value = VpnEngine.vpnDisconnected;
        _resetSpeedStats();
        _syncActiveSessionUi();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TronVPN] _syncVpnStateFromEngine: stage query failed $e');
      }
    } finally {
      _syncingVpnState = false;
    }
  }

  Future<void> _prepareEngineForProtocol(String protocol) async {
    if (protocol == 'wireguard') {
      await WireguardEngine.initialize(
        interfaceName: 'wg0',
        vpnName: 'Ghost Route',
        iosAppGroup: AppConfig.iosAppGroup,
      );
      return;
    }
    await VpnEngine.initialize();
  }

  void _adoptProtocol(String protocol) {
    if (selectedProtocol.value == protocol) return;
    selectedProtocol.value = protocol;
    Pref.selectedProtocol = protocol;
    _attachStageListener();
  }

  Future<String?> _probeConnectedProtocol() async {
    Future<String?> checkWireguard() async {
      try {
        await WireguardEngine.initialize(
          interfaceName: 'wg0',
          vpnName: 'Ghost Route',
          iosAppGroup: AppConfig.iosAppGroup,
        );
        if (await WireguardEngine.isConnected()) return 'wireguard';
        final stage = await WireguardEngine.stage();
        if (stage == VpnEngine.vpnConnected) return 'wireguard';
      } catch (_) {}
      return null;
    }

    Future<String?> checkOpenvpn() async {
      try {
        await VpnEngine.initialize();
        if (await VpnEngine.isConnected()) return 'openvpn';
        final raw = await VpnEngine.stageRaw();
        if (VpnEngine.isTunnelActiveStage(raw)) return 'openvpn';
        final stage = await VpnEngine.stage();
        if (stage == VpnEngine.vpnConnected) return 'openvpn';
      } catch (_) {}
      return null;
    }

    if (selectedProtocol.value == 'wireguard') {
      return await checkWireguard() ?? await checkOpenvpn();
    }
    return await checkOpenvpn() ?? await checkWireguard();
  }

  void _applyConnectedRestoreState() {
    if (_disconnecting) return;
    if (vpnState.value != VpnEngine.vpnConnected) {
      vpnState.value = VpnEngine.vpnConnected;
    }
    _ensureActiveSessionIfConnected();
    if (selectedProtocol.value == 'wireguard') {
      _attachWireguardTrafficListener();
    }
  }

  void _applyDisconnectedUi() {
    _endConnectionSession();
    showSecuredOverlay.value = false;
    vpnState.value = VpnEngine.vpnDisconnected;
    if (selectedProtocol.value == 'wireguard') {
      _detachWireguardTrafficListener();
    }
    _resetSpeedStats();
    _stopConnectElapsedTimer(reset: true);
  }

  Future<void> _stopActiveVpn() async {
    try {
      if (selectedProtocol.value == 'wireguard') {
        await WireguardEngine.stopVpn();
      } else {
        await VpnEngine.stopVpn();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TronVPN] _stopActiveVpn: $e');
      }
    }
  }

  void _onVpnStage(String event) {
    // Always accept real disconnects — dropping them during sync left the UI
    // stuck on Connected while native was already disconnected.
    if (_syncingVpnState && _isConnectingState(event) && !_disconnecting) {
      return;
    }

    if (_disconnecting && event == VpnEngine.vpnConnected) {
      return;
    }

    final userDisconnecting = _disconnecting;
    // WireGuard emits "disconnecting" as its own stage; treat it as done for UI,
    // but keep `_disconnecting` until fully disconnected so sync cannot flip back.
    final isGone = event == VpnEngine.vpnDisconnected || event == 'disconnecting';

    _connectTimeout?.cancel();
    _connectTimeout = null;
    if (event == VpnEngine.vpnDisconnected) {
      _disconnectTimeout?.cancel();
      _disconnectTimeout = null;
      _disconnecting = false;
    }
    final wasConnecting = _isConnectingState(vpnState.value);
    final wasConnected = vpnState.value == VpnEngine.vpnConnected;
    if (isGone || userDisconnecting) {
      _stopConnectElapsedTimer(reset: true);
    }
    if (!isGone && !userDisconnecting) {
      _sawConnectingStageThisAttempt = true;
    }

    if (isGone || userDisconnecting) {
      _applyDisconnectedUi();
    } else {
      vpnState.value = event;
    }

    if (event == VpnEngine.vpnConnected && !userDisconnecting) {
      _connectRetryCount = 0;
      if (!wasConnected) {
        showSecuredOverlay.value = true;
        _beginConnectionSession();
      }
      if (selectedProtocol.value == 'wireguard') {
        _attachWireguardTrafficListener();
      }
      MainNavController.switchTo(MainTab.home);
    } else if (_isConnectingState(event) && !userDisconnecting && !isGone) {
      // Re-arm the recovery timeout for ANY transient/terminal-ish stage
      // (reconnect, denied, no_connection, etc), not just the stage right
      // after connectToVpn() first fires it. Without this, a stray stage
      // arriving after the initial timer was cancelled leaves the UI stuck
      // on "Connecting..." forever with no self-healing.
      _startConnectTimeout();
    }

    if (isGone) {
      if (wasConnecting &&
          !userDisconnecting &&
          !_userCancelledConnect &&
          _sawConnectingStageThisAttempt &&
          !_connectFailureNotified) {
        if (selectedProtocol.value == 'openvpn' &&
            _connectRetryCount < _maxConnectRetries &&
            _retryWithAlternateServer()) {
          return;
        }
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

  bool _isConnectingState(String state) {
    return state != VpnEngine.vpnConnected &&
        state != VpnEngine.vpnDisconnected;
  }

  void _resetSpeedStats() {
    wgDownload.value = '0 kbps';
    wgUpload.value = '0 kbps';
  }

  void dismissSecuredOverlay() {
    showSecuredOverlay.value = false;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectTimeout?.cancel();
    _disconnectTimeout?.cancel();
    _connectElapsedTimer?.cancel();
    _stopActiveSessionTicker();
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

  /// Brief grace period after an optimistic disconnect so a stale "connected"
  /// stage / sync probe cannot flip the UI back while the tunnel is dying.
  static const Duration _disconnectTimeoutDuration = Duration(seconds: 3);

  void _startDisconnectTimeout() {
    _disconnectTimeout?.cancel();
    _disconnectTimeout = Timer(_disconnectTimeoutDuration, () {
      _disconnectTimeout = null;
      if (!_disconnecting) return;
      _disconnecting = false;
      _applyDisconnectedUi();
    });
  }

  /// Cancels any in-progress connection attempt (if connecting).
  Future<void> cancelConnecting() async {
    if (!_isConnectingState(vpnState.value)) return;
    _userCancelledConnect = true;
    _disconnecting = true;
    _connectTimeout?.cancel();
    _connectTimeout = null;
    _applyDisconnectedUi();
    _startDisconnectTimeout();
    // Native stop can be slow — do not block UI on it.
    unawaited(_stopActiveVpn());
  }

  /// Convenience: cancel and then start a fresh connect.
  Future<void> retryConnection() async {
    await cancelConnecting();
    // Small delay to let native tunnel cleanup settle.
    await Future.delayed(const Duration(milliseconds: 600));
    connectToVpn();
  }

  /// Tears down whatever tunnel is currently active (on its own protocol
  /// engine) and waits for native teardown to actually finish before
  /// returning. The UI flips to disconnected immediately (optimistic), but
  /// unlike a plain "tap Disconnect" — where nothing follows, so a
  /// fire-and-forget stop is fine — a switch immediately starts a NEW
  /// tunnel afterward. Starting before the old tunnel has actually closed
  /// races the OS VPN layer (NetworkExtension/VpnService can't run two
  /// tunnels at once), which silently drops the new connect: the UI shows
  /// "disconnected then connecting" but never reaches "connected".
  Future<void> _disconnectActiveIfNeeded() async {
    if (vpnState.value == VpnEngine.vpnConnected) {
      _disconnecting = true;
      _sawConnectingStageThisAttempt = false;
      _connectTimeout?.cancel();
      _connectTimeout = null;
      _applyDisconnectedUi();
      _startDisconnectTimeout();
      await _stopActiveVpn();
      // Give the OS VPN layer a moment to fully release the old tunnel
      // before a new startVpn() is accepted.
      await Future.delayed(const Duration(milliseconds: 500));
    } else if (_isConnectingState(vpnState.value)) {
      await cancelConnecting();
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  /// Switches to a different OpenVPN server: disconnects whatever is
  /// currently active first, then starts connecting to [newVpn]. Safe to
  /// call while connected, connecting, or disconnected.
  Future<void> switchToServer(Vpn newVpn) async {
    if (Platform.isWindows) {
      MyDialogs.info(
        msg: 'OpenVPN servers aren\'t available on Windows yet. '
            'Please choose a Premium (WireGuard) server from the Premium tab instead.',
      );
      return;
    }
    await _disconnectActiveIfNeeded();
    Pref.selectedProtocol = 'openvpn';
    selectedProtocol.value = 'openvpn';
    vpn.value = newVpn;
    Pref.vpn = newVpn;
    connectToVpn();
  }

  /// Switches to a different WireGuard server: disconnects whatever is
  /// currently active first, then starts connecting to [newServer]. Safe to
  /// call while connected, connecting, or disconnected.
  Future<void> switchToWireguardServer(WireguardServer newServer) async {
    await _disconnectActiveIfNeeded();
    Pref.selectedProtocol = 'wireguard';
    selectedProtocol.value = 'wireguard';
    wireguardServer.value = newServer;
    Pref.wireguardServer = newServer;
    connectToVpn();
  }

  /// Picks the lowest-latency free OpenVPN server and connects immediately.
  /// Intended for a "Fastest Free Server" one-tap UX. Works for non-subscribers
  /// too — connectToVpn() below applies the usual daily free-session gate.
  Future<void> connectToFastestFreeServer() async {
    if (Platform.isWindows) {
      MyDialogs.info(
        msg: 'Free OpenVPN servers aren\'t available on Windows yet. '
            'Please choose a Premium (WireGuard) server from the Premium tab instead.',
      );
      return;
    }
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

      // _autoSelectFastestServer() leaves vpnState as "connecting" (to keep
      // the spinner running through the probe phase). connectToVpn() below
      // treats any non-disconnected/non-connected state as "cancel the
      // in-progress attempt" — without resetting here it would immediately
      // cancel instead of starting the real tunnel connect to the picked
      // server.
      vpnState.value = VpnEngine.vpnDisconnected;

      // Start the actual tunnel connect using the picked server.
      connectToVpn();
    } finally {
      _pickingFastestFree = false;
    }
  }

  void connectToVpn({bool isAutoRetry = false}) async {
    debugPrint('[TronVPN] connectToVpn() called. state=${vpnState.value}');
    if (!isAutoRetry) _connectRetryCount = 0;
    if (selectedProtocol.value != 'wireguard' && !VpnEngine.isVpnSupported) {
      debugPrint('[TronVPN] connectToVpn: VPN not supported on this device');
      MyDialogs.info(
        msg: Platform.isWindows
            ? 'OpenVPN servers aren\'t available on Windows yet. '
                'Please choose a Premium (WireGuard) server from the Premium tab instead.'
            : 'VPN is not supported on this device.',
      );
      return;
    }
    if (vpnState.value == VpnEngine.vpnDisconnected) {
      if (selectedProtocol.value == 'wireguard' && !Pref.hasActiveSubscription) {
        debugPrint(
            '[TronVPN] connectToVpn: Active subscription required for Premium (WireGuard) — opening Premium.');
        Get.to(() => const PremiumScreen());
        return;
      }

      if (selectedProtocol.value == 'openvpn' &&
          vpn.value.openVPNConfigDataBase64.isEmpty) {
        debugPrint(
            '[TronVPN] connectToVpn: No config selected - auto-picking fastest server.');
        final picked = await _autoSelectFastestServer();
        if (picked == null) return;
      }

      debugPrint('[TronVPN] connectToVpn: Starting connect protocol=${selectedProtocol.value}');
      _sawConnectingStageThisAttempt = false;
      _connectFailureNotified = false;
      _disconnecting = false;
      vpnState.value = VpnEngine.vpnConnecting;
      _startConnectTimeout();
      _startConnectElapsedTimer();

      try {
        if (selectedProtocol.value == 'wireguard') {
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
      _disconnecting = true;
      _sawConnectingStageThisAttempt = false;
      _connectTimeout?.cancel();
      _connectTimeout = null;
      // Optimistic UI: flip to disconnected immediately. Native teardown can
      // take several seconds on iOS; awaiting it made Disconnect feel broken.
      _applyDisconnectedUi();
      _startDisconnectTimeout();
      unawaited(_stopActiveVpn());
    } else {
      // Intermediate state (e.g. connecting, authenticating): tap cancels the connection.
      debugPrint(
          '[TronVPN] connectToVpn: Cancelling connection (state "${vpnState.value}")');
      await cancelConnecting();
    }
  }

  /// Tries another free OpenVPN server after a failed connect attempt.
  bool _retryWithAlternateServer() {
    final current = vpn.value;
    var servers = Pref.vpnListFree
        .where((v) =>
            !v.premiumOnly && v.openVPNConfigDataBase64.trim().isNotEmpty)
        .toList();
    if (servers.isEmpty) servers = Pref.vpnList;
    servers.removeWhere((v) {
      final sameHost = v.hostname.isNotEmpty &&
          v.hostname == current.hostname;
      final sameIp = v.ip.isNotEmpty && v.ip == current.ip;
      return sameHost || sameIp;
    });
    if (servers.isEmpty) return false;

    final next = servers[_connectRetryCount % servers.length];
    vpn.value = next;
    Pref.vpn = next;
    _connectRetryCount++;
    _connectFailureNotified = false;
    _sawConnectingStageThisAttempt = false;
    debugPrint(
        '[TronVPN] Retrying connect with ${next.countryLong} (${next.hostname})');
    connectToVpn(isAutoRetry: true);
    return true;
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
