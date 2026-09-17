import 'package:get/get.dart';

import '../apis/admin_api.dart';
import '../models/admin_stats.dart';

class AdminController extends GetxController {
  final Rx<AdminStats?> stats = Rx<AdminStats?>(null);
  final RxList<AdminSubscriptionEvent> recentSubscriptions =
      <AdminSubscriptionEvent>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    error.value = '';
    try {
      final statsFuture = AdminApi.getStats();
      final recentFuture = AdminApi.getRecentSubscriptions(limit: 20);
      stats.value = await statsFuture;
      recentSubscriptions.assignAll(await recentFuture);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}
