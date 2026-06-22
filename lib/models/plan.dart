import '../helpers/currency_helper.dart';
import 'subscription.dart';

/// Plan from backend API (GET /api/payments/plans). Used for display and payment.
class Plan {
  final int index;
  final String name;
  final String tier;
  final String interval;
  final int durationDays;
  final int amount;
  final String currency;
  final int devices;
  final String displayName;
  final String intervalLabel;
  final String period;
  final String price;
  final String description;
  final String? badge;

  const Plan({
    required this.index,
    required this.name,
    required this.tier,
    required this.interval,
    required this.durationDays,
    required this.amount,
    required this.currency,
    required this.devices,
    required this.displayName,
    required this.intervalLabel,
    required this.period,
    required this.price,
    this.description = '',
    this.badge,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    final index = (json['index'] as num).toInt();
    final apiAmount = (json['amount'] as num?)?.toInt() ?? 0;
    final apiCurrency = (json['currency'] as String? ?? 'USD').toUpperCase();
    final apiPrice = json['price'] as String? ?? '';

    // Always show USD from app plan definitions when index is known.
    final amount = index >= 0 && index < PremiumPlan.values.length
        ? PremiumPlan.values[index].amountInSmallestUnit
        : apiAmount;

    final price = CurrencyHelper.displayPrice(
      price: apiPrice,
      currency: apiCurrency,
      amount: amount,
    );

    return Plan(
      index: index,
      name: json['name'] as String? ?? '',
      tier: json['tier'] as String? ?? 'platinum',
      interval: json['interval'] as String? ?? 'monthly',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      amount: amount,
      currency: CurrencyHelper.displayCurrencyCode,
      devices: (json['devices'] as num?)?.toInt() ?? 5,
      displayName: json['displayName'] as String? ?? '',
      intervalLabel: json['intervalLabel'] as String? ?? 'Monthly',
      period: json['period'] as String? ?? 'per month',
      price: price,
      description: json['description'] as String? ?? '',
      badge: json['badge'] as String?,
    );
  }

  /// Price for UI (always USD, e.g. `$5.00`).
  String get displayPrice => price;

  bool get isPlatinum => tier == 'platinum';
  bool get isPlatinumPlus => tier == 'platinumPlus';
}
