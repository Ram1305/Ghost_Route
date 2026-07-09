import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_platform_interface.dart';

import '../config/app_config.dart';

/// Wraps wireguard_flutter_plus for in-app WireGuard tunnels.
class WireguardEngine {
  static final WireGuardFlutterInterface _wg = WireGuardFlutter.instance;
  static bool _initialized = false;

  static final _stageController = StreamController<String>.broadcast();
  static final _trafficController =
      StreamController<Map<String, dynamic>?>.broadcast();

  static StreamSubscription? _stageSub;
  static StreamSubscription? _trafficSub;

  /// WireGuard is supported where the plugin supports it.
  /// iOS requires a Network Extension target (providerBundleIdentifier).
  static bool get isWireguardSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  static Future<void> initialize({
    required String interfaceName,
    required String vpnName,
    String? iosAppGroup,
  }) async {
    if (_initialized) return;

    await _wg.initialize(
      interfaceName: interfaceName,
      vpnName: vpnName,
      iosAppGroup: iosAppGroup ?? (Platform.isIOS ? AppConfig.iosAppGroup : null),
    );

    _stageSub = _wg.vpnStageSnapshot.listen((event) {
      final normalized = event.code.toLowerCase();
      if (kDebugMode) {
        debugPrint('[TronVPN] WG stage: $normalized');
      }
      _stageController.add(normalized);
    });

    _trafficSub = _wg.trafficSnapshot.listen((data) {
      _trafficController.add(Map<String, dynamic>.from(data));
    });

    _initialized = true;
  }

  static Stream<String> stageSnapshot() => _stageController.stream;

  static Stream<Map<String, dynamic>?> trafficSnapshot() =>
      _trafficController.stream;

  static Future<void> startVpn({
    required String serverAddress,
    required String wgQuickConfig,
    String? providerBundleIdentifier,
  }) async {
    if (!_initialized) {
      await initialize(
        interfaceName: 'wg0',
        vpnName: 'Ghost Route',
        iosAppGroup: Platform.isIOS ? AppConfig.iosAppGroup : null,
      );
    }

    await _wg.startVpn(
      serverAddress: serverAddress,
      wgQuickConfig: wgQuickConfig,
      providerBundleIdentifier: providerBundleIdentifier ?? '',
    );
  }

  static Future<void> stopVpn() async {
    if (!_initialized) return;
    try {
      await _wg.stopVpn();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _stageSub?.cancel();
    await _trafficSub?.cancel();
    _stageSub = null;
    _trafficSub = null;
    _initialized = false;
  }
}

