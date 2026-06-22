/// App Store / Play subscription product IDs (must match App Store Connect & Play Console).
class IapProducts {
  IapProducts._();

  static const String platinumMonthly = 'com.yencode.ghostroute.platinum.monthly';
  static const String platinumYearly = 'com.yencode.ghostroute.platinum.yearly';

  static const List<String> allProductIds = [
    platinumMonthly,
    platinumYearly,
  ];

  /// Product ID → current plan index (0 = monthly, 1 = yearly).
  /// Includes legacy IDs so restore purchases still work.
  static const Map<String, int> _planIndexByProductId = {
    // Current products
    platinumMonthly: 0,
    platinumYearly: 1,
    // Legacy products (mapped to nearest current plan)
    'com.yencode.ghostroute.platinum.weekly': 0,
    'com.yencode.ghostroute.platinumplus.weekly': 0,
    'com.yencode.ghostroute.platinumplus.monthly': 0,
    'com.yencode.ghostroute.platinumplus.yearly': 1,
  };

  /// PremiumPlan index 0–1 for backend [Plan.index], or null if unknown.
  static int? planIndexForProductId(String productId) =>
      _planIndexByProductId[productId];

  static String? productIdForPlanIndex(int index) {
    switch (index) {
      case 0:
        return platinumMonthly;
      case 1:
        return platinumYearly;
      default:
        return null;
    }
  }
}
