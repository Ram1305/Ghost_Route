/// Daily free VPN session rules (one 5-minute session per calendar day).
class FreeVpnSession {
  FreeVpnSession._();

  static const Duration limit = Duration(minutes: 5);

  /// Local calendar date key `yyyy-MM-dd`.
  static String localDateKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static bool hasUsedSessionToday(String? sessionDate, [DateTime? now]) {
    if (sessionDate == null || sessionDate.isEmpty) return false;
    return sessionDate == localDateKey(now);
  }

  static bool canStartSession(String? sessionDate, [DateTime? now]) {
    return !hasUsedSessionToday(sessionDate, now);
  }

  /// Remaining time in the active free session, clamped to `0..limit`.
  static Duration remainingFromStart(DateTime? startedAt, [DateTime? now]) {
    if (startedAt == null) return limit;
    final elapsed = (now ?? DateTime.now()).difference(startedAt);
    final rem = limit - elapsed;
    if (rem <= Duration.zero) return Duration.zero;
    if (rem > limit) return limit;
    return rem;
  }

  static int remainingSecondsFromStart(DateTime? startedAt, [DateTime? now]) {
    final rem = remainingFromStart(startedAt, now);
    final secs = rem.inSeconds;
    if (secs < 0) return 0;
    final maxSecs = limit.inSeconds;
    return secs > maxSecs ? maxSecs : secs;
  }
}
