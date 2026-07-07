import 'dart:convert';
import 'dart:developer';

import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';

import '../config/app_config.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/ip_details.dart';
import '../models/vpn.dart';

class APIs {
  /// Free VPN servers from VPN Gate public API.
  static Future<List<Vpn>> getFreeServers() async {
    try {
      final vpnList = await _fetchVpnGateServers();
      _dedupeByHostname(vpnList);
      vpnList.removeWhere((v) => v.openVPNConfigDataBase64.trim().isEmpty);
      vpnList.shuffle();

      if (vpnList.isNotEmpty) {
        Pref.vpnListFree = vpnList;
        Pref.vpnList = vpnList;
      }

      return vpnList;
    } catch (e) {
      log('\ngetFreeServers: $e');
      final cached = Pref.vpnListFree;
      if (cached.isEmpty) {
        MyDialogs.error(
          msg:
              'Could not load free VPN servers. Check your internet connection and try again.',
        );
      }
      return cached;
    }
  }

  /// Premium VPN servers from backend (premiumOnly=true).
  static Future<List<Vpn>> getPremiumServers() async {
    try {
      final vpnList = await _fetchPremiumServers();
      _dedupeByHostname(vpnList);
      vpnList.removeWhere((v) => v.openVPNConfigDataBase64.trim().isEmpty);

      if (vpnList.isNotEmpty) {
        Pref.vpnListPremium = vpnList;
      }

      return vpnList;
    } catch (e) {
      log('\ngetPremiumServers: $e');
      return Pref.vpnListPremium;
    }
  }

  static Future<List<Vpn>> _fetchVpnGateServers() async {
    final List<Vpn> vpnList = [];

    final res = await get(
      Uri.parse(AppConfig.vpnGateApiUrl),
      headers: {'User-Agent': AppConfig.userAgent},
    );
    if (res.statusCode != 200) {
      throw Exception('VPN Gate API returned ${res.statusCode}');
    }
    final parts = res.body.split('#');
    if (parts.length < 2) {
      throw Exception('VPN Gate API response missing CSV data');
    }
    final csvString = parts[1].replaceAll('*', '');

    final list = const CsvToListConverter().convert(csvString);
    if (list.isEmpty) {
      throw Exception('VPN Gate API returned empty CSV');
    }

    final header = list[0];

    for (int i = 1; i < list.length - 1; ++i) {
      final Map<String, dynamic> tempJson = {};
      for (int j = 0; j < header.length; ++j) {
        tempJson.addAll({header[j].toString(): list[i][j]});
      }
      vpnList.add(Vpn.fromJson(tempJson));
    }

    return vpnList;
  }

  static Future<List<Vpn>> _fetchPremiumServers() async {
    final List<Vpn> vpnList = [];

    final res = await get(
      Uri.parse(AppConfig.premiumServersApiUrl),
      headers: {
        'Accept': 'application/json',
        'User-Agent': AppConfig.userAgent,
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Premium server API returned ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('Premium server API returned invalid JSON');
    }
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        vpnList.add(Vpn.fromJson(item));
      } else if (item is Map) {
        vpnList.add(Vpn.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return vpnList;
  }

  static void _dedupeByHostname(List<Vpn> vpnList) {
    final seen = <String>{};
    vpnList.retainWhere((v) {
      final key = v.hostname.isEmpty ? v.ip : v.hostname;
      if (key.isEmpty || seen.contains(key)) return false;
      seen.add(key);
      return true;
    });
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
