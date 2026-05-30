/// Premium tier: Platinum (3–5 devices) or Platinum+ (5–10 devices).
enum PremiumTier { platinum, platinumPlus }

/// Billing interval.
enum PlanInterval { weekly, monthly, yearly }

/// Full plan = tier + interval. Used for storage and display.
enum PremiumPlan {
  platinumWeekly,
  platinumMonthly,
  platinumYearly,
  platinumPlusWeekly,
  platinumPlusMonthly,
  platinumPlusYearly,
}

extension PremiumPlanX on PremiumPlan {
  PremiumTier get tier {
    switch (this) {
      case PremiumPlan.platinumWeekly:
      case PremiumPlan.platinumMonthly:
      case PremiumPlan.platinumYearly:
        return PremiumTier.platinum;
      case PremiumPlan.platinumPlusWeekly:
      case PremiumPlan.platinumPlusMonthly:
      case PremiumPlan.platinumPlusYearly:
        return PremiumTier.platinumPlus;
    }
  }

  PlanInterval get interval {
    switch (this) {
      case PremiumPlan.platinumWeekly:
      case PremiumPlan.platinumPlusWeekly:
        return PlanInterval.weekly;
      case PremiumPlan.platinumMonthly:
      case PremiumPlan.platinumPlusMonthly:
        return PlanInterval.monthly;
      case PremiumPlan.platinumYearly:
      case PremiumPlan.platinumPlusYearly:
        return PlanInterval.yearly;
    }
  }

  /// Duration of the plan in days (for expiry countdown).
  int get daysInPlan {
    switch (interval) {
      case PlanInterval.weekly:
        return 7;
      case PlanInterval.monthly:
        return 30;
      case PlanInterval.yearly:
        return 365;
    }
  }

  /// Short title for list (e.g. "Weekly", "Monthly", "Yearly").
  String get intervalLabel {
    switch (interval) {
      case PlanInterval.weekly:
        return 'Weekly';
      case PlanInterval.monthly:
        return 'Monthly';
      case PlanInterval.yearly:
        return 'Yearly';
    }
  }

  /// Number of devices allowed for this plan.
  int get devices {
    switch (this) {
      case PremiumPlan.platinumWeekly:
        return 3;
      case PremiumPlan.platinumMonthly:
      case PremiumPlan.platinumYearly:
        return 5;
      case PremiumPlan.platinumPlusWeekly:
        return 5;
      case PremiumPlan.platinumPlusMonthly:
      case PremiumPlan.platinumPlusYearly:
        return 10;
    }
  }

  /// Amount in smallest unit for payment (paise for INR, cents for USD).
  int get amountInSmallestUnit {
    switch (this) {
      case PremiumPlan.platinumWeekly:
        return 499; // $4.99
      case PremiumPlan.platinumMonthly:
        return 999; // $9.99
      case PremiumPlan.platinumYearly:
        return 3999; // $39.99
      case PremiumPlan.platinumPlusWeekly:
        return 699; // $6.99
      case PremiumPlan.platinumPlusMonthly:
        return 1499; // $14.99
      case PremiumPlan.platinumPlusYearly:
        return 5999; // $59.99
    }
  }

  /// Currency code for payment (e.g. INR, USD).
  String get currencyCode => 'INR';

  /// Price string (e.g. "\$4.99").
  String get price {
    switch (this) {
      case PremiumPlan.platinumWeekly:
        return '\$4.99';
      case PremiumPlan.platinumMonthly:
        return '\$9.99';
      case PremiumPlan.platinumYearly:
        return '\$39.99';
      case PremiumPlan.platinumPlusWeekly:
        return '\$6.99';
      case PremiumPlan.platinumPlusMonthly:
        return '\$14.99';
      case PremiumPlan.platinumPlusYearly:
        return '\$59.99';
    }
  }

  /// Period text (e.g. "per week", "per year").
  String get period {
    switch (interval) {
      case PlanInterval.weekly:
        return 'per week';
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
      case PremiumPlan.platinumPlusYearly:
        return 'Best value';
      default:
        return null;
    }
  }

  /// One-line description for the plan card.
  String get description {
    switch (this) {
      case PremiumPlan.platinumWeekly:
        return 'Full speed · 50+ locations';
      case PremiumPlan.platinumMonthly:
        return 'Best for individuals & families';
      case PremiumPlan.platinumYearly:
        return 'Save 67% · Full access';
      case PremiumPlan.platinumPlusWeekly:
        return 'Priority support · 80+ locations';
      case PremiumPlan.platinumPlusMonthly:
        return 'For power users & small teams';
      case PremiumPlan.platinumPlusYearly:
        return 'Save 71% · Family pack';
      default:
        return '';
    }
  }

  /// Full display label (e.g. "Platinum Yearly (5 devices)").
  String get planLabel => '${tier == PremiumTier.platinum ? "Platinum" : "Platinum+"} $intervalLabel ($devices devices)';
}

class Subscription {
  final PremiumPlan plan;
  final DateTime date;

  Subscription({required this.plan, required this.date});

  String get planLabel => plan.planLabel;

  Map<String, dynamic> toJson() => {
        'plan': plan.index,
        'date': date.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final idx = json['plan'] as int? ?? 0;
    final planIndex = idx >= 0 && idx < PremiumPlan.values.length ? idx : 2;
    return Subscription(
      plan: PremiumPlan.values[planIndex],
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
