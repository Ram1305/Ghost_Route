import '../helpers/currency_helper.dart';

/// Premium tier: Platinum only.
enum PremiumTier { platinum }

/// Billing interval.
enum PlanInterval { monthly, yearly }

/// Platinum plans: monthly or yearly.
enum PremiumPlan {
  platinumMonthly,
  platinumYearly,
}

extension PremiumPlanX on PremiumPlan {
  /// Normalize legacy plan indices (old 2–5 scheme) to current index (0–1).
  /// Indices 0–1 are used as-is (0 = monthly, 1 = yearly).
  static int normalizeStoredIndex(int idx) {
    if (idx >= 0 && idx < PremiumPlan.values.length) return idx;
    switch (idx) {
      case 2: // old yearly
      case 5: // old platinum+ yearly
        return 1;
      case 3: // old platinum+ weekly
      case 4: // old platinum+ monthly
        return 0;
      default:
        return 1;
    }
  }

  /// Map pre-migration stored indices (old 0–5) to current indices. Run once on backend DB.
  static int migrateLegacyStoredIndex(int idx) {
    switch (idx) {
      case 0: // old weekly
      case 1: // old monthly
      case 3: // old platinum+ weekly
      case 4: // old platinum+ monthly
        return 0;
      case 2: // old yearly
      case 5: // old platinum+ yearly
        return 1;
      default:
        return idx >= 0 && idx < PremiumPlan.values.length ? idx : 1;
    }
  }

  static PremiumPlan fromStoredIndex(int idx) =>
      PremiumPlan.values[normalizeStoredIndex(idx)];

  PremiumTier get tier => PremiumTier.platinum;

  PlanInterval get interval {
    switch (this) {
      case PremiumPlan.platinumMonthly:
        return PlanInterval.monthly;
      case PremiumPlan.platinumYearly:
        return PlanInterval.yearly;
    }
  }

  /// Duration of the plan in days (for expiry countdown).
  int get daysInPlan {
    switch (interval) {
      case PlanInterval.monthly:
        return 30;
      case PlanInterval.yearly:
        return 365;
    }
  }

  /// Short title for list (e.g. "Monthly", "Yearly").
  String get intervalLabel {
    switch (interval) {
      case PlanInterval.monthly:
        return 'Monthly';
      case PlanInterval.yearly:
        return 'Yearly';
    }
  }

  /// Number of devices allowed for this plan.
  int get devices => 5;

  /// Amount in smallest unit for payment (USD cents).
  int get amountInSmallestUnit {
    switch (this) {
      case PremiumPlan.platinumMonthly:
        return 500; // $5.00
      case PremiumPlan.platinumYearly:
        return 3500; // $35.00
    }
  }

  /// Currency code for payment.
  String get currencyCode => 'USD';

  /// Price string (e.g. "\$5.00").
  String get price {
    switch (this) {
      case PremiumPlan.platinumMonthly:
        return '\$5.00';
      case PremiumPlan.platinumYearly:
        return '\$35.00';
    }
  }

  /// Period text (e.g. "per month", "per year").
  String get period {
    switch (interval) {
      case PlanInterval.monthly:
        return 'per month';
      case PlanInterval.yearly:
        return 'per year';
    }
  }

  /// Optional badge (e.g. "Best value").
  String? get badge {
    switch (this) {
      case PremiumPlan.platinumYearly:
        return 'Best value';
      default:
        return null;
    }
  }

  /// One-line description for the plan card.
  String get description {
    switch (this) {
      case PremiumPlan.platinumMonthly:
        return 'Best for individuals & families';
      case PremiumPlan.platinumYearly:
        return 'Save 42% · Full access';
    }
  }

  /// Full display label (e.g. "Platinum Yearly").
  String get planLabel => 'Platinum $intervalLabel';
}

class Subscription {
  final PremiumPlan plan;
  final DateTime date;
  final String? transactionId;
  final String? productId;
  final String? platform;
  final String? amount;
  final String? currency;

  Subscription({
    required this.plan,
    required this.date,
    this.transactionId,
    this.productId,
    this.platform,
    this.amount,
    this.currency,
  });

  String get planLabel => plan.planLabel;

  String get displayAmount => CurrencyHelper.displayAmount(
        amount: amount,
        currency: currency,
        fallbackCents: plan.amountInSmallestUnit,
      );

  String get displayCurrency => CurrencyHelper.displayCurrencyCode;

  String get paymentMethodLabel {
    switch (platform) {
      case 'ios':
        return 'App Store';
      case 'android':
        return 'Google Play';
      default:
        return 'In-app purchase';
    }
  }

  String get invoiceNumber {
    final d = date;
    final suffix = transactionId != null && transactionId!.length >= 4
        ? transactionId!.substring(transactionId!.length - 4).toUpperCase()
        : '${plan.index}${d.millisecond}';
    return 'GR-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}-$suffix';
  }

  DateTime get validUntil => date.add(Duration(days: plan.daysInPlan));

  Map<String, dynamic> toJson() => {
        'plan': plan.index,
        'date': date.toIso8601String(),
        if (transactionId != null) 'transactionId': transactionId,
        if (productId != null) 'productId': productId,
        if (platform != null) 'platform': platform,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
      };

  static DateTime _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    return DateTime.now();
  }

  static String? _parseAmount(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is num) return raw.toString();
    return raw.toString();
  }

  static String? _parseString(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    return raw.toString();
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final idx = json['plan'] is int
        ? json['plan'] as int
        : int.tryParse('${json['plan']}') ?? 0;
    return Subscription(
      plan: PremiumPlanX.fromStoredIndex(idx),
      date: _parseDate(json['date']),
      transactionId: _parseString(json['transactionId']),
      productId: _parseString(json['productId']),
      platform: _parseString(json['platform']),
      amount: _parseAmount(json['amount']),
      currency: _parseString(json['currency']),
    );
  }
}
