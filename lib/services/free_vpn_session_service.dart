import 'package:flutter/foundation.dart';

import '../apis/free_vpn_api.dart';
import '../helpers/pref.dart';

/// Syncs local free VPN session state with the backend (survives reinstall).
class FreeVpnSessionService {
  FreeVpnSessionService._();

  static Future<void> syncFromServer() async {
    if (Pref.hasActiveSubscription) return;

    try {
      final remote = await FreeVpnApi.getStatus();
      if (remote.usedToday && remote.sessionDate != null) {
        Pref.applyRemoteFreeSession(
          sessionDate: remote.sessionDate!,
          startedAt: remote.startedAt,
        );
        if (kDebugMode) {
          debugPrint(
            '[FreeVpnSession] Synced used session from server for ${remote.sessionDate}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FreeVpnSession] syncFromServer failed: $e');
      }
    }
  }

  static Future<void> markUsedOnServer({DateTime? startedAt}) async {
    if (Pref.hasActiveSubscription) return;

    try {
      await FreeVpnApi.markUsed(startedAt: startedAt);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FreeVpnSession] markUsedOnServer failed: $e');
      }
    }
  }
}
