import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/currency_helper.dart';
import 'package:ghost_route/models/plan.dart';

void main() {
  group('CurrencyHelper', () {
    test('formats cents as USD', () {
      expect(CurrencyHelper.formatUsdFromCents(500), '\$5.00');
      expect(CurrencyHelper.formatUsdFromCents(3500), '\$35.00');
    });

    test('converts INR API fields to USD from cents', () {
      expect(
        CurrencyHelper.displayPrice(
          price: '₹499',
          currency: 'INR',
          amount: 500,
        ),
        '\$5.00',
      );
    });

    test('normalizes legacy rupee amount strings', () {
      expect(
        CurrencyHelper.displayAmount(
          amount: '₹999',
          currency: 'INR',
          fallbackCents: 500,
        ),
        '\$5.00',
      );
    });
  });

  group('Plan.fromJson', () {
    test('always returns USD prices from plan index', () {
      final monthly = Plan.fromJson({
        'index': 0,
        'amount': 99900,
        'currency': 'INR',
        'price': '₹999',
        'name': 'platinumMonthly',
        'tier': 'platinum',
        'interval': 'monthly',
        'durationDays': 30,
        'devices': 5,
        'displayName': 'Platinum Monthly',
        'intervalLabel': 'Monthly',
        'period': 'per month',
      });

      expect(monthly.currency, 'USD');
      expect(monthly.displayPrice, '\$5.00');
    });
  });
}
