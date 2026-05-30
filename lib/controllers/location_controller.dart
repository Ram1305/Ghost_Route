import 'package:get/get.dart';

import '../apis/apis.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';

class LocationController extends GetxController {
  final RxList<Vpn> vpnList = <Vpn>[].obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    vpnList.assignAll(Pref.vpnList);
  }

  Future<void> getVpnData() async {
    isLoading.value = true;
    vpnList.clear();
    try {
      final list = await APIs.getVPNServers();
      vpnList.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }
}
