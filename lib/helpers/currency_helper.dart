/// Display formatting for subscription prices (USD only).
class CurrencyHelper {
  CurrencyHelper._();

  static const String displayCurrencyCode = 'USD';

  static String formatUsdFromCents(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  static bool isNonUsdPrice({required String price, required String currency}) {
    final c = currency.toUpperCase();
    if (c == 'INR') return true;
    if (price.contains('₹') || price.toUpperCase().contains('INR')) return true;
    if (RegExp(r'^Rs\.?\s', caseSensitive: false).hasMatch(price.trim())) {
      return true;
    }
    return false;
  }

  /// Ensures UI shows USD even if API or store returns legacy INR/₹ fields.
  static String displayPrice({
    required String price,
    required String currency,
    required int amount,
  }) {
    if (amount > 0) {
      return formatUsdFromCents(amount);
    }
    if (isNonUsdPrice(price: price, currency: currency)) {
      return formatUsdFromCents(0);
    }
    if (price.startsWith('\$')) return price;
    return price.isEmpty ? formatUsdFromCents(0) : price;
  }

  /// Normalize a stored amount string (invoice/history) to USD.
  static String displayAmount({
    required String? amount,
    required String? currency,
    required int fallbackCents,
  }) {
    if (amount == null || amount.isEmpty) {
      return formatUsdFromCents(fallbackCents);
    }
    if (isNonUsdPrice(price: amount, currency: currency ?? '')) {
      return formatUsdFromCents(fallbackCents);
    }
    if (amount.startsWith('\$')) return amount;
    final parsed = double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
    if (parsed != null && parsed > 0) {
      return '\$${parsed.toStringAsFixed(2)}';
    }
    return formatUsdFromCents(fallbackCents);
  }
}
