import '../models/subscription.dart';
import '../models/user.dart';

/// Parse subscription expiry / date fields from JSON (String, int, or num).
DateTime? parseSubscriptionDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  if (raw is num) {
    return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  }
  return null;
}

/// Resolve the effective subscription expiry for [user] and [plan].
DateTime? resolveSubscriptionExpiresAt(User user, PremiumPlan? plan) {
  if (plan == null) return null;

  final backendExpiry = user.subscriptionExpiresAt;
  if (backendExpiry != null) return backendExpiry;

  // Only infer from history when the user has an active plan (backend or local).
  if (user.activePlan == null) return null;

  Subscription? latestMatch;
  for (final purchase in user.subscriptionHistory.reversed) {
    if (purchase.plan == plan) {
      latestMatch = purchase;
      break;
    }
  }
  return latestMatch?.validUntil;
}

/// Remaining whole days until [expiresAt], ceiling-based so partial days count as 1.
int remainingDays(DateTime expiresAt, DateTime now) {
  final diff = expiresAt.difference(now);
  if (diff.isNegative) return 0;
  return (diff.inHours + 23) ~/ 24;
}
