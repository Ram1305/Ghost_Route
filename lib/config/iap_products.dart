/// App Store / Play subscription product IDs (must match App Store Connect & Play Console).
class IapProducts {
  IapProducts._();

  static const String platinumWeekly = 'com.yencode.ghostroute.platinum.weekly';
  static const String platinumMonthly = 'com.yencode.ghostroute.platinum.monthly';
  static const String platinumYearly = 'com.yencode.ghostroute.platinum.yearly';
  static const String platinumPlusWeekly = 'com.yencode.ghostroute.platinumplus.weekly';
  static const String platinumPlusMonthly = 'com.yencode.ghostroute.platinumplus.monthly';
  static const String platinumPlusYearly = 'com.yencode.ghostroute.platinumplus.yearly';

  static const List<String> allProductIds = [
    platinumWeekly,
    platinumMonthly,
    platinumYearly,
    platinumPlusWeekly,
    platinumPlusMonthly,
    platinumPlusYearly,
  ];

  static const Map<String, int> _planIndexByProductId = {
    platinumWeekly: 0,
    platinumMonthly: 1,
    platinumYearly: 2,
    platinumPlusWeekly: 3,
    platinumPlusMonthly: 4,
    platinumPlusYearly: 5,
  };

  /// PremiumPlan index 0–5 for backend [Plan.index], or null if unknown.
  static int? planIndexForProductId(String productId) =>
      _planIndexByProductId[productId];

  static String? productIdForPlanIndex(int index) {
    for (final e in _planIndexByProductId.entries) {
      if (e.value == index) return e.key;
    }
    return null;
  }
}
