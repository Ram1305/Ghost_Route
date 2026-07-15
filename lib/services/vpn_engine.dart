import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

import '../models/vpn_config.dart';
import '../models/vpn_status.dart' as app_models;

/// Wraps openvpn_flutter for cross-platform VPN (Android + iOS).
class VpnEngine {
  static const MethodChannel _channelControl = MethodChannel(
    'id.laskarmedia.openvpn_flutter/vpncontrol',
  );

  static OpenVPN? _openVpn;
  static final _stageController = StreamController<String>.broadcast();
  static final _statusController =
      StreamController<app_models.VpnStatus?>.broadcast();
  static bool _initialized = false;

  /// Whether VPN is supported on the current platform (Android and iOS).
  static bool get isVpnSupported => Platform.isAndroid || Platform.isIOS;

  /// Initialize the VPN engine. Must be called before connecting.
  /// On failure (e.g. iOS Simulator), _openVpn is cleared so stopVpn won't crash.
  static Future<void> initialize() async {
    if (_initialized) return;

    _openVpn = OpenVPN(
      onVpnStatusChanged: (status) {
        _statusController.add(_mapVpnStatus(status));
      },
      onVpnStageChanged: (stage, rawStage) {
        final stageStr = _mapStageToString(stage, rawStage);
        if (kDebugMode) {
          debugPrint('[TronVPN] VPN stage: $stageStr (raw: $rawStage, enum: ${stage.name})');
        }
        _stageController.add(stageStr);
      },
    );

    try {
      await _openVpn!.initialize(
        groupIdentifier: Platform.isIOS ? 'group.com.yencode.ghostroute' : null,
        providerBundleIdentifier: Platform.isIOS
            ? 'com.yencode.ghostroute.VPNExtension'
            : null,
        localizedDescription: Platform.isIOS ? 'Ghost Route' : null,
      );
      _initialized = true;
    } catch (e) {
      _openVpn = null; // Native init failed — avoid calling disconnect/stopVPN
      rethrow;
    }
  }

  /// Snapshot of VPN connection stage.
  static Stream<String> vpnStageSnapshot() {
    if (!isVpnSupported) return Stream.value(vpnDisconnected);
    return _stageController.stream;
  }

  /// Snapshot of VPN connection status (bytes, duration, etc).
  static Stream<app_models.VpnStatus?> vpnStatusSnapshot() {
    if (!isVpnSupported) return Stream.value(app_models.VpnStatus());
    return _statusController.stream;
  }

  /// User-friendly message for known plugin errors (platform IPC / null check).
  static String getFriendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('ipc') ||
        msg.contains('null check') ||
        msg.contains('platform exception')) {
      return 'VPN service was not ready. Please try again.';
    }
    return error.toString();
  }

  /// Start VPN connection.
  /// Retries once on Android when plugin reports IPC or null-check errors (activity not attached yet).
  static Future<void> startVpn(VpnConfig vpnConfig) async {
    if (!isVpnSupported) return;
    if (_openVpn == null || !_openVpn!.initialized) {
      await initialize();
    }

    Future<void> doConnect() => _openVpn!.connect(
          vpnConfig.config,
          vpnConfig.country,
          username: vpnConfig.username,
          password: vpnConfig.password,
          bypassPackages: [],
          certIsRequired: false,
        );

    try {
      await doConnect();
    } on PlatformException catch (e) {
      final msg = (e.message ?? e.code).toLowerCase();
      final isIpcOrNull =
          msg.contains('ipc') || msg.contains('null check') || msg.contains('platform');
      if (Platform.isAndroid && isIpcOrNull) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        try {
          await doConnect();
          return;
        } catch (e2) {
          throw Exception(getFriendlyError(e2));
        }
      }
      throw Exception(getFriendlyError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(getFriendlyError(e));
    }
  }

  /// Stop VPN. Safe to call even when init failed (e.g. on iOS Simulator).
  static Future<void> stopVpn() async {
    if (!isVpnSupported) return;
    if (_openVpn == null || !_initialized) return;
    try {
      _openVpn!.disconnect();
    } catch (_) {
      // Native stopVPN can crash when providerManager is nil (init failed on simulator).
    }
  }

  /// Open VPN settings (Android only). No-op on iOS.
  static Future<void> openKillSwitch() async {
    if (!isVpnSupported) return;
    try {
      if (Platform.isAndroid) {
        await MethodChannel('vpnControl').invokeMethod('kill_switch');
      }
    } catch (_) {}
  }

  /// Native stage string before plugin enum mapping (e.g. iOS "reasserting").
  static Future<String?> stageRaw() async {
    if (!isVpnSupported) return vpnDisconnected;
    if (_openVpn == null || !_initialized) return null;
    try {
      final raw = await _channelControl.invokeMethod<String>('stage');
      return raw?.trim().toLowerCase();
    } catch (_) {
      return null;
    }
  }

  /// Get latest connection stage.
  static Future<String?> stage() async {
    if (!isVpnSupported) return vpnDisconnected;
    final raw = await stageRaw();
    if (raw == null || raw.isEmpty) {
      final s = await _openVpn?.stage();
      return s != null ? _mapStageToString(s) : vpnDisconnected;
    }
    final s = await _openVpn?.stage();
    return s != null
        ? _mapStageToString(s, raw)
        : _mapRawStageString(raw);
  }

  /// Check if VPN is connected.
  static Future<bool> isConnected() async {
    if (!isVpnSupported) return false;
    final raw = await stageRaw();
    if (raw != null && _isActiveTunnelRawStage(raw)) return true;
    final s = await stage();
    return s?.toLowerCase() == vpnConnected;
  }

  /// Stage constants.
  static const String vpnConnected = 'connected';
  static const String vpnDisconnected = 'disconnected';
  static const String vpnWaitConnection = 'wait_connection';
  static const String vpnAuthenticating = 'authenticating';
  static const String vpnReconnect = 'reconnect';
  static const String vpnNoConnection = 'no_connection';
  static const String vpnConnecting = 'connecting';
  static const String vpnPrepare = 'prepare';
  static const String vpnDenied = 'denied';

  static bool isTunnelActiveStage(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    final normalized = raw.trim().toLowerCase();
    if (normalized == vpnConnected) return true;
    return normalized.contains('reassert') || normalized.contains('reconnect');
  }

  static bool _isActiveTunnelRawStage(String raw) => isTunnelActiveStage(raw);

  static String _mapRawStageString(String raw) {
    if (_isActiveTunnelRawStage(raw)) {
      return raw.contains('reconnect') && !raw.contains('reassert')
          ? vpnConnecting
          : vpnConnected;
    }
    if (raw == vpnDisconnected ||
        raw == 'idle' ||
        raw == 'invalid' ||
        raw == 'disconnecting') {
      return vpnDisconnected;
    }
    if (raw == vpnConnecting || raw == vpnPrepare) return vpnConnecting;
    return vpnConnecting;
  }

  static String _mapStageToString(VPNStage stage, [String? rawStage]) {
    // The plugin's VPNStage enum has no "reasserting" case, so a native
    // mid-session reassert (network handoff, keepalive blip — see
    // PacketTunnelProvider's .reconnecting case) falls through its
    // substring-based matcher to `unknown`, which we'd otherwise treat as a
    // hard disconnect. Catch it here from the raw string before that happens,
    // since a reconnect is not a failure.
    final raw = rawStage?.trim().toLowerCase() ?? '';
    if (raw.contains('reassert')) {
      return vpnConnected;
    }
    if (raw.contains('reconnect')) {
      return vpnConnecting;
    }
    switch (stage) {
      case VPNStage.connected:
        return vpnConnected;
      case VPNStage.disconnected:
        return vpnDisconnected;
      case VPNStage.connecting:
      case VPNStage.prepare:
        return vpnConnecting;
      case VPNStage.authenticating:
      case VPNStage.authentication:
        return vpnAuthenticating;
      case VPNStage.wait_connection:
        return vpnWaitConnection;
      case VPNStage.denied:
        return vpnDenied;
      case VPNStage.disconnecting:
      case VPNStage.error:
      case VPNStage.exiting:
        return vpnDisconnected;
      default:
        if (stage.name == 'unknown') {
          if (_isActiveTunnelRawStage(raw)) {
            return raw.contains('reassert') ? vpnConnected : vpnConnecting;
          }
          if (kDebugMode) {
            debugPrint(
              '[TronVPN] VPN stage unknown (connection failed). '
              'Check credentials (username/password), server, and network.',
            );
          }
          return vpnDisconnected;
        }
        // Any other in-progress stage (get_config, assign_ip, resolve, tcp_connect, etc.) show as connecting.
        return vpnConnecting;
    }
  }

  static app_models.VpnStatus _mapVpnStatus(VpnStatus? status) {
    if (status == null) return app_models.VpnStatus();
    return app_models.VpnStatus(
      duration: status.duration ?? '00:00:00',
      lastPacketReceive: status.packetsIn ?? '0',
      byteIn: status.byteIn ?? '0 kbps',
      byteOut: status.byteOut ?? '0 kbps',
    );
  }
}
