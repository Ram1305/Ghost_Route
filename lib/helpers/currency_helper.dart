/// Display formatting for subscription prices (USD).
class CurrencyHelper {
  CurrencyHelper._();

  static String formatUsdFromCents(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Ensures UI shows USD even if API still returns legacy INR/₹ fields.
  static String displayPrice({
    required String price,
    required String currency,
    required int amount,
  }) {
    final c = currency.toUpperCase();
    if (c == 'USD' && price.startsWith('\$')) return price;
    if (c == 'INR' || price.startsWith('₹') || price.contains('₹')) {
      return formatUsdFromCents(amount);
    }
    if (amount > 0) return formatUsdFromCents(amount);
    if (price.startsWith('\$')) return price;
    return price.isEmpty ? formatUsdFromCents(0) : price;
  }
}
