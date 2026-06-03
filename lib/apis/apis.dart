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
  /// Loads VPN servers from VPN Gate (large public list) and merges managed backend servers.
  static Future<List<Vpn>> getVPNServers() async {
    final List<Vpn> vpnList = [];

    try {
      vpnList.addAll(await _fetchVpnGateServers());
    } catch (e) {
      log('\ngetVPNServers VPN Gate: $e');
    }

    try {
      vpnList.addAll(await _fetchManagedServers());
    } catch (e) {
      log('\ngetVPNServers managed: $e');
    }

    if (vpnList.isEmpty) {
      MyDialogs.error(
        msg:
            'Could not load VPN servers. Check your internet connection and try again.',
      );
      return vpnList;
    }

    _dedupeByHostname(vpnList);
    vpnList.removeWhere((v) => v.openVPNConfigDataBase64.trim().isEmpty);
    vpnList.shuffle();

    if (vpnList.isNotEmpty) Pref.vpnList = vpnList;

    return vpnList;
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

  static Future<List<Vpn>> _fetchManagedServers() async {
    final List<Vpn> vpnList = [];

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
