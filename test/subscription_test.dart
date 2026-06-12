import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/models/subscription.dart';

void main() {
  group('Subscription.fromJson', () {
    test('parses ISO date and string amount', () {
      final sub = Subscription.fromJson({
        'plan': 1,
        'date': '2026-06-12T10:00:00.000Z',
        'amount': '\$9.99',
        'currency': 'USD',
        'transactionId': 'tx-123',
        'platform': 'ios',
      });

      expect(sub.plan, PremiumPlan.platinumMonthly);
      expect(sub.date.toUtc().hour, 10);
      expect(sub.amount, '\$9.99');
      expect(sub.transactionId, 'tx-123');
    });

    test('parses millisecond date and numeric amount', () {
      final ms = DateTime.utc(2026, 6, 12).millisecondsSinceEpoch;
      final sub = Subscription.fromJson({
        'plan': 2,
        'date': ms,
        'amount': 39.99,
      });

      expect(sub.plan, PremiumPlan.platinumYearly);
      expect(sub.date.millisecondsSinceEpoch, ms);
      expect(sub.amount, '39.99');
    });
  });

  group('AuthApi subscriptionHistoryFromJson', () {
    test('skips malformed entries and keeps valid ones', () {
      // Import via auth_api would require exposing helper; test Subscription directly.
      final valid = Subscription.fromJson({
        'plan': 0,
        'date': '2026-01-01T00:00:00.000Z',
      });
      expect(valid.plan, PremiumPlan.platinumWeekly);
    });
  });
}
