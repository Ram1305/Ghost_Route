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
    test('same calendar day counts as 0', () {
      final now = DateTime(2026, 6, 1, 12);
      final expires = DateTime(2026, 6, 1, 23);
      expect(remainingDays(expires, now), 0);
    });

    test('returns 0 when expired', () {
      final now = DateTime(2026, 6, 2);
      final expires = DateTime(2026, 6, 1);
      expect(remainingDays(expires, now), 0);
    });

    test('counts full calendar days', () {
      final now = DateTime(2026, 6, 1);
      final expires = now.add(const Duration(days: 30));
      expect(remainingDays(expires, now), 30);
    });
  });

  group('isSubscriptionDateExpired', () {
    test('expires today is still active until tomorrow', () {
      final now = DateTime(2026, 6, 22, 18);
      final expires = DateTime(2026, 6, 22, 8);
      expect(isSubscriptionDateExpired(expires, now), isFalse);
    });

    test('yesterday is expired', () {
      final now = DateTime(2026, 6, 22);
      final expires = DateTime(2026, 6, 21, 23);
      expect(isSubscriptionDateExpired(expires, now), isTrue);
    });
  });

  group('isUserSubscriptionExpired', () {
    test('new monthly purchase today is not expired', () {
      final today = DateTime(2026, 6, 22, 15);
      final user = User(
        username: 'u',
        email: 'u@test.com',
        phone: '',
        password: 'p',
        activePlan: PremiumPlan.platinumMonthly,
        subscriptionHistory: [
          Subscription(plan: PremiumPlan.platinumMonthly, date: today),
        ],
      );
      expect(
        isUserSubscriptionExpired(user, PremiumPlan.platinumMonthly, today),
        isFalse,
      );
      expect(remainingDays(resolveSubscriptionExpiresAt(user, PremiumPlan.platinumMonthly)!, today), 30);
    });
  });

  group('formatSubscriptionDaysLeft', () {
    test('formats singular and plural labels', () {
      expect(formatSubscriptionDaysLeft(0), 'Expires today');
      expect(formatSubscriptionDaysLeft(1), '1 day left');
      expect(formatSubscriptionDaysLeft(14), '14 days left');
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

    test('falls back to latest matching history when backend expiry missing', () {
      final purchaseDate = DateTime(2026, 6, 1);
      final user = User(
        username: 'u',
        email: 'u@test.com',
        phone: '',
        password: 'p',
        subscriptionHistory: [
          Subscription(plan: PremiumPlan.platinumMonthly, date: purchaseDate),
        ],
      );
      expect(
        resolveSubscriptionExpiresAt(user, PremiumPlan.platinumMonthly),
        purchaseDate.add(const Duration(days: 30)),
      );
    });

    test('prefers newer history expiry over stale backend expiry', () {
      final purchaseDate = DateTime(2026, 6, 22);
      final user = User(
        username: 'u',
        email: 'u@test.com',
        phone: '',
        password: 'p',
        activePlan: PremiumPlan.platinumMonthly,
        subscriptionExpiresAt: DateTime(2026, 6, 22),
        subscriptionHistory: [
          Subscription(plan: PremiumPlan.platinumMonthly, date: purchaseDate),
        ],
      );
      expect(
        resolveSubscriptionExpiresAt(user, PremiumPlan.platinumMonthly),
        purchaseDate.add(const Duration(days: 30)),
      );
    });
  });
}
