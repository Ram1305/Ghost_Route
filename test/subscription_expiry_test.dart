import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/subscription_expiry.dart';
import 'package:ghost_route/models/subscription.dart';
import 'package:ghost_route/models/user.dart';

void main() {
  group('parseSubscriptionDate', () {
    test('parses ISO string', () {
      final d = parseSubscriptionDate('2026-07-01T12:00:00.000Z');
      expect(d, isNotNull);
      expect(d!.toUtc().year, 2026);
    });

    test('parses millisecond timestamp', () {
      final ms = DateTime.utc(2026, 7, 1).millisecondsSinceEpoch;
      expect(parseSubscriptionDate(ms)?.millisecondsSinceEpoch, ms);
    });

    test('returns null for invalid input', () {
      expect(parseSubscriptionDate(null), isNull);
      expect(parseSubscriptionDate(''), isNull);
    });
  });

  group('remainingDays', () {
    test('ceil partial days to at least 1', () {
      final now = DateTime(2026, 6, 1, 12);
      final expires = now.add(const Duration(hours: 18));
      expect(remainingDays(expires, now), 1);
    });

    test('returns 0 when expired', () {
      final now = DateTime(2026, 6, 2);
      final expires = DateTime(2026, 6, 1);
      expect(remainingDays(expires, now), 0);
    });

    test('counts full days', () {
      final now = DateTime(2026, 6, 1);
      final expires = now.add(const Duration(days: 30));
      expect(remainingDays(expires, now), 30);
    });
  });

  group('resolveSubscriptionExpiresAt', () {
    test('prefers backend subscriptionExpiresAt', () {
      final backendExpiry = DateTime(2026, 12, 1);
      final user = User(
        username: 'u',
        email: 'u@test.com',
        phone: '',
        password: 'p',
        activePlan: PremiumPlan.platinumMonthly,
        subscriptionExpiresAt: backendExpiry,
        subscriptionHistory: [
          Subscription(
            plan: PremiumPlan.platinumMonthly,
            date: DateTime(2026, 6, 1),
          ),
        ],
      );
      expect(
        resolveSubscriptionExpiresAt(user, PremiumPlan.platinumMonthly),
        backendExpiry,
      );
    });

    test('falls back to latest matching history when activePlan set', () {
      final purchaseDate = DateTime(2026, 6, 1);
      final user = User(
        username: 'u',
        email: 'u@test.com',
        phone: '',
        password: 'p',
        activePlan: PremiumPlan.platinumMonthly,
        subscriptionHistory: [
          Subscription(plan: PremiumPlan.platinumMonthly, date: purchaseDate),
        ],
      );
      expect(
        resolveSubscriptionExpiresAt(user, PremiumPlan.platinumMonthly),
        purchaseDate.add(const Duration(days: 30)),
      );
    });

    test('does not infer from history when activePlan is null', () {
      final user = User(
        username: 'u',
        email: 'u@test.com',
        phone: '',
        password: 'p',
        subscriptionHistory: [
          Subscription(
            plan: PremiumPlan.platinumMonthly,
            date: DateTime(2026, 6, 1),
          ),
        ],
      );
      expect(
        resolveSubscriptionExpiresAt(user, PremiumPlan.platinumMonthly),
        isNull,
      );
    });
  });
}
