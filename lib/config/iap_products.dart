/// App Store / Play subscription product IDs (must match App Store Connect & Play Console).
class IapProducts {
  IapProducts._();

  static const String platinumMonthly = 'com.yencode.ghostroute.platinum.monthly';
  static const String platinumYearly = 'com.yencode.ghostroute.platinum.yearly';

  static const List<String> allProductIds = [
    platinumMonthly,
    platinumYearly,
  ];

  /// Product ID → plan index (0 = monthly, 1 = yearly).
  static const Map<String, int> _planIndexByProductId = {
    platinumMonthly: 0,
    platinumYearly: 1,
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
