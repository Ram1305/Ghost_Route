import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:http/http.dart';

import '../config/app_config.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/ip_details.dart';
import '../models/vpn.dart';

class APIs {
  /// Loads VPN servers from Ghost Route managed backend API.
  static Future<List<Vpn>> getVPNServers() async {
    final List<Vpn> vpnList = [];

    try {
      final res = await get(
        Uri.parse(AppConfig.serversApiUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': AppConfig.userAgent,
        },
      );
      if (res.statusCode != 200) {
        throw Exception('Server API returned ${res.statusCode}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        throw Exception('Server API returned invalid JSON');
      }
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          vpnList.add(Vpn.fromJson(item));
        } else if (item is Map) {
          vpnList.add(Vpn.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (e) {
      MyDialogs.error(msg: e.toString());
      log('\ngetVPNServersE: $e');
      return vpnList;
    }

    vpnList.removeWhere((v) => v.openVPNConfigDataBase64.trim().isEmpty);
    vpnList.shuffle();

    if (vpnList.isNotEmpty) Pref.vpnList = vpnList;

    return vpnList;
  }

  static Future<void> getIPDetails({required Rx<IPDetails> ipData}) async {
    try {
      final res = await get(
        Uri.parse(AppConfig.ipApiUrl),
        headers: {'User-Agent': AppConfig.userAgent},
      );
      if (res.statusCode != 200) {
        throw Exception('IP API returned ${res.statusCode}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      ipData.value = IPDetails.fromJson(data);
    } catch (e) {
      MyDialogs.error(msg: e.toString());
      log('\ngetIPDetailsE: $e');
    }
  }
}
