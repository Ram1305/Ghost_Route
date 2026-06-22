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

DateTime _calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// True when the subscription period ended before [now]'s calendar day.
bool isSubscriptionDateExpired(DateTime expiresAt, [DateTime? now]) {
  final n = now ?? DateTime.now();
  return _calendarDate(expiresAt).isBefore(_calendarDate(n));
}

/// Latest expiry from purchase history for [plan].
DateTime? _bestHistoryExpiry(User user, PremiumPlan plan) {
  DateTime? best;
  for (final purchase in user.subscriptionHistory) {
    if (purchase.plan != plan) continue;
    final until = purchase.validUntil;
    if (best == null || until.isAfter(best)) {
      best = until;
    }
  }
  return best;
}

/// Resolve the effective subscription expiry for [user] and [plan].
DateTime? resolveSubscriptionExpiresAt(User user, PremiumPlan? plan) {
  if (plan == null) return null;

  final historyBest = _bestHistoryExpiry(user, plan);
  final backend = user.subscriptionExpiresAt;

  if (backend != null && historyBest != null) {
    return backend.isAfter(historyBest) ? backend : historyBest;
  }
  if (backend != null) return backend;
  if (historyBest != null) return historyBest;

  // Active subscriber without stored expiry — use full plan period from now.
  if (user.activePlan == plan) {
    return DateTime.now().add(Duration(days: plan.daysInPlan));
  }
  return null;
}

/// Remaining calendar days until [expiresAt] (0 = last day / expires today).
int remainingDays(DateTime expiresAt, DateTime now) {
  final days = _calendarDate(expiresAt).difference(_calendarDate(now)).inDays;
  return days < 0 ? 0 : days;
}

/// User-facing label for profile / account screens.
String formatSubscriptionDaysLeft(int days) {
  if (days <= 0) return 'Expires today';
  if (days == 1) return '1 day left';
  return '$days days left';
}

/// Whether [user]'s [plan] is past the subscription period.
bool isUserSubscriptionExpired(User user, PremiumPlan plan, [DateTime? now]) {
  final expiresAt = resolveSubscriptionExpiresAt(user, plan);
  if (expiresAt == null) return false;
  return isSubscriptionDateExpired(expiresAt, now);
}
