import 'package:get/get.dart';

import '../controllers/main_nav_controller.dart';
import '../screens/main_shell_screen.dart';

/// Pops when the auth screen was opened on top of another route; otherwise
/// returns to the main shell (e.g. after logout replaced the whole stack).
void popAuthScreenOrGoHome({int shellTab = MainTab.home}) {
  if (Get.key.currentState?.canPop() ?? false) {
    Get.back();
  } else {
    Get.offAll(() => MainShellScreen(initialIndex: shellTab));
  }
}
