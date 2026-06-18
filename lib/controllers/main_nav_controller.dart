import 'package:get/get.dart';

/// Bottom navigation tab indices for [MainShellScreen].
abstract final class MainTab {
  static const int home = 0;
  static const int servers = 1;
  static const int premium = 2;
  static const int account = 3;
}

class MainNavController extends GetxController {
  final currentIndex = MainTab.home.obs;

  void goToTab(int index) {
    if (index >= MainTab.home && index <= MainTab.account) {
      currentIndex.value = index;
    }
  }

  static void switchTo(int index) {
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().goToTab(index);
    }
  }
}
