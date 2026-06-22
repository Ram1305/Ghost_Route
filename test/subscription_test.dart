import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/models/subscription.dart';

void main() {
  group('Subscription.fromJson', () {
    test('parses ISO date and string amount', () {
      final sub = Subscription.fromJson({
        'plan': 0,
        'date': '2026-06-12T10:00:00.000Z',
        'amount': '\$5.00',
        'currency': 'USD',
        'transactionId': 'tx-123',
        'platform': 'ios',
      });

      expect(sub.plan, PremiumPlan.platinumMonthly);
      expect(sub.date.toUtc().hour, 10);
      expect(sub.amount, '\$5.00');
      expect(sub.transactionId, 'tx-123');
    });

    test('parses millisecond date and numeric amount', () {
      final ms = DateTime.utc(2026, 6, 12).millisecondsSinceEpoch;
      final sub = Subscription.fromJson({
        'plan': 1,
        'date': ms,
        'amount': 35.00,
      });

      expect(sub.plan, PremiumPlan.platinumYearly);
      expect(sub.date.millisecondsSinceEpoch, ms);
      expect(sub.amount, '35.0');
    });

    test('maps legacy plan indices via migration helper', () {
      expect(PremiumPlanX.migrateLegacyStoredIndex(1), 0);
      expect(PremiumPlanX.migrateLegacyStoredIndex(2), 1);
      expect(PremiumPlanX.migrateLegacyStoredIndex(5), 1);
      expect(
        Subscription.fromJson({'plan': 2, 'date': '2026-01-01T00:00:00.000Z'}).plan,
        PremiumPlan.platinumYearly,
      );
    });
  });

  group('PremiumPlan pricing', () {
    test('monthly is five dollars and yearly is thirty-five', () {
      expect(PremiumPlan.platinumMonthly.price, '\$5.00');
      expect(PremiumPlan.platinumMonthly.amountInSmallestUnit, 500);
      expect(PremiumPlan.platinumYearly.price, '\$35.00');
      expect(PremiumPlan.platinumYearly.amountInSmallestUnit, 3500);
    });
  });
}
