import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';

import '../config/app_config.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/ip_details.dart';
import '../models/vpn.dart';
import 'http_client.dart';

class APIs {
  static String get _base => AppConfig.apiBaseUrl;

  static Future<List<Vpn>> getVPNServers() async {
    final List<Vpn> vpnList = [];

    try {
      final res = await ApiHttp.get(Uri.parse('$_base/api/servers'));
      if (res.statusCode != 200) {
        final data = ApiHttp.decodeJsonMap(res);
        throw ApiException(data['error'] as String? ?? 'Failed to load servers');
      }

      final list = jsonDecode(res.body) as List<dynamic>;
      for (final item in list) {
        if (item is Map) {
          vpnList.add(Vpn.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      MyDialogs.error(msg: msg);
      log('\ngetVPNServersE: $e');
    }

    if (vpnList.isNotEmpty) Pref.vpnList = vpnList;

    return vpnList;
  }

  static Future<void> getIPDetails({required Rx<IPDetails> ipData}) async {
    try {
      final res = await ApiHttp.get(Uri.parse('https://ip-api.com/json/'));
      final data = jsonDecode(res.body);
      log(data.toString());
      ipData.value = IPDetails.fromJson(data);
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      MyDialogs.error(msg: msg);
      log('\ngetIPDetailsE: $e');
    }
  }
}
