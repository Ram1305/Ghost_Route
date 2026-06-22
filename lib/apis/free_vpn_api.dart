import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../helpers/device_id_helper.dart';
import '../helpers/free_vpn_session.dart';
import '../helpers/pref.dart';

class FreeVpnRemoteStatus {
  final bool usedToday;
  final String? sessionDate;
  final DateTime? startedAt;

  const FreeVpnRemoteStatus({
    required this.usedToday,
    this.sessionDate,
    this.startedAt,
  });
}

/// Backend API for daily free VPN session (survives reinstall).
class FreeVpnApi {
  static String get _base => AppConfig.apiBaseUrl;

  static Future<FreeVpnRemoteStatus> getStatus() async {
    final deviceId = await DeviceIdHelper.getDeviceId();
    final localDate = FreeVpnSession.localDateKey();
    final userId = Pref.currentUser?.backendUserId;

    final query = {
      'deviceId': deviceId,
      'localDate': localDate,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };

    final uri = Uri.parse('$_base/api/free-vpn/status').replace(
      queryParameters: query,
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200) {
      throw Exception(data['error'] as String? ?? 'Failed to load free VPN status');
    }

    final startedMs = data['startedAt'];
    return FreeVpnRemoteStatus(
      usedToday: data['usedToday'] == true,
      sessionDate: data['sessionDate'] as String?,
      startedAt: startedMs is num && startedMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(startedMs.toInt())
          : null,
    );
  }

  static Future<void> markUsed({DateTime? startedAt}) async {
    final deviceId = await DeviceIdHelper.getDeviceId();
    final localDate = FreeVpnSession.localDateKey();
    final userId = Pref.currentUser?.backendUserId;
    final started = startedAt ?? DateTime.now();

    final res = await http
        .post(
          Uri.parse('$_base/api/free-vpn/mark-used'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceId': deviceId,
            'localDate': localDate,
            'startedAt': started.millisecondsSinceEpoch,
            if (userId != null && userId.isNotEmpty) 'userId': userId,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(data['error'] as String? ?? 'Failed to mark free VPN session');
    }
  }
}
