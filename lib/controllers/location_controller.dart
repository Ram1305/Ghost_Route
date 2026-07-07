import 'package:get/get.dart';

import '../apis/apis.dart';
import '../helpers/pref.dart';
import '../models/vpn.dart';

class LocationController extends GetxController {
  final RxList<Vpn> freeVpnList = <Vpn>[].obs;
  final RxList<Vpn> premiumVpnList = <Vpn>[].obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    freeVpnList.assignAll(Pref.vpnListFree);
    premiumVpnList.assignAll(Pref.vpnListPremium);
  }

  Future<void> getVpnData() async {
    isLoading.value = true;
    final cachedFree = List<Vpn>.from(freeVpnList);
    final cachedPremium = List<Vpn>.from(premiumVpnList);
    try {
      final results = await Future.wait([
        APIs.getFreeServers(),
        APIs.getPremiumServers(),
      ]);
      final free = results[0];
      final premium = results[1];

      if (free.isNotEmpty) {
        freeVpnList.assignAll(free);
      } else if (cachedFree.isNotEmpty) {
        freeVpnList.assignAll(cachedFree);
      }

      if (premium.isNotEmpty) {
        premiumVpnList.assignAll(premium);
      } else if (cachedPremium.isNotEmpty) {
        premiumVpnList.assignAll(cachedPremium);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
