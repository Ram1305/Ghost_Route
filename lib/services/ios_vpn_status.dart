import 'dart:io';

import 'package:flutter/services.dart';

import '../config/app_config.dart';

/// Reads active iOS Network Extension status across all saved VPN profiles.
class IosVpnStatus {
  IosVpnStatus._();

  static const MethodChannel _channel =
      MethodChannel('com.yencode.ghostroute/vpn_status');

  static Future<({String? protocol, String status})?> activeTunnel() async {
    if (!Platform.isIOS) return null;
    try {
      final result = await _channel.invokeMethod<Object>('activeTunnel');
      if (result is! Map) return null;
      final map = Map<Object?, Object?>.from(result);
      final bundleId = map['bundleId'] as String?;
      final status = (map['status'] as String?)?.toLowerCase();
      if (bundleId == null || status == null) return null;

      String? protocol;
      if (bundleId == AppConfig.iosWireguardExtensionBundleId) {
        protocol = 'wireguard';
      } else if (bundleId == AppConfig.iosOpenVpnExtensionBundleId) {
        protocol = 'openvpn';
      }

      return (protocol: protocol, status: status);
    } catch (_) {
      return null;
    }
  }

  static bool isActiveStatus(String status) {
    final s = status.toLowerCase();
    return s == 'connected' || s.contains('reassert');
  }

  static bool isConnectingStatus(String status) {
    final s = status.toLowerCase();
    // "disconnecting" is a teardown state — never treat it as connecting.
    return s == 'connecting' || s.contains('reconnect');
  }

  static bool isDisconnectingStatus(String status) {
    return status.toLowerCase() == 'disconnecting';
  }
}
