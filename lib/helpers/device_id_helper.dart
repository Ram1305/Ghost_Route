import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stable install/device identifier for server-side free-session tracking.
///
/// Priority: secure storage (may survive iOS reinstall) → platform id
/// (Android ID survives reinstall on Android 8+) → generated fallback.
class DeviceIdHelper {
  DeviceIdHelper._();

  static const _storageKey = 'ghost_route_device_install_id';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static String? _cached;

  static Future<String> getDeviceId() async {
    if (_cached != null && _cached!.isNotEmpty) return _cached!;

    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored != null && stored.isNotEmpty) {
        _cached = stored;
        return stored;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceId] secure storage read failed: $e');
      }
    }

    String? platformId;
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final androidId = info.id.trim();
        if (androidId.isNotEmpty && androidId != 'unknown') {
          platformId = 'android:$androidId';
        }
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final idfv = info.identifierForVendor?.trim();
        if (idfv != null && idfv.isNotEmpty) {
          platformId = 'ios:$idfv';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceId] platform id read failed: $e');
      }
    }

    final id = platformId ?? _generateFallbackId();
    _cached = id;

    try {
      await _storage.write(key: _storageKey, value: id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceId] secure storage write failed: $e');
      }
    }

    return id;
  }

  static String _generateFallbackId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'gen:${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
