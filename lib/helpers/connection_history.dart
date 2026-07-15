import '../models/vpn_connection_session.dart';
import 'pref.dart';

/// Minimum session length to record in history.
const Duration kMinSessionDuration = Duration(seconds: 5);

/// Maximum number of sessions kept in local storage.
const int kMaxConnectionHistory = 50;

String formatDurationCompact(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final totalMinutes = totalSeconds ~/ 60;
  if (totalMinutes >= 60) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
  if (totalMinutes == 1) return '1 minute';
  if (totalMinutes > 1) return '$totalMinutes minutes';
  if (totalSeconds <= 0) return '0s';
  return '${totalSeconds}s';
}

String dayGroupLabel(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final local = DateTime(date.year, date.month, date.day);
  final today = DateTime(reference.year, reference.month, reference.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (local == today) return 'Today';
  if (local == yesterday) return 'Yesterday';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// Groups sessions by day label, newest sessions first within each group.
/// Group order: Today, Yesterday, then older dates descending.
Map<String, List<VpnConnectionSession>> groupSessionsByDay(
  List<VpnConnectionSession> sessions, {
  DateTime? now,
}) {
  final sorted = List<VpnConnectionSession>.from(sessions)
    ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

  final grouped = <String, List<VpnConnectionSession>>{};
  for (final session in sorted) {
    final label = dayGroupLabel(session.endedAt, now: now);
    grouped.putIfAbsent(label, () => []).add(session);
  }

  final ordered = <String, List<VpnConnectionSession>>{};
  for (final key in ['Today', 'Yesterday']) {
    if (grouped.containsKey(key)) {
      ordered[key] = grouped.remove(key)!;
    }
  }

  final olderKeys = grouped.keys.toList()
    ..sort((a, b) {
      final aDate = grouped[a]!.first.endedAt;
      final bDate = grouped[b]!.first.endedAt;
      return bDate.compareTo(aDate);
    });
  for (final key in olderKeys) {
    ordered[key] = grouped[key]!;
  }

  return ordered;
}

void saveConnectionSession(VpnConnectionSession session) {
  if (session.duration < kMinSessionDuration) return;

  final history = List<VpnConnectionSession>.from(Pref.connectionHistory)
    ..insert(0, session);

  if (history.length > kMaxConnectionHistory) {
    history.removeRange(kMaxConnectionHistory, history.length);
  }

  Pref.connectionHistory = history;
}

void finalizeActiveConnectionSession({DateTime? endedAt}) {
  final startedAt = Pref.activeConnectionSessionStart;
  final country = Pref.activeConnectionCountry;
  final protocol = Pref.activeConnectionProtocol;

  if (startedAt == null || country == null || country.isEmpty) {
    clearActiveConnectionSession();
    return;
  }

  final end = endedAt ?? DateTime.now();
  saveConnectionSession(
    VpnConnectionSession(
      country: country,
      startedAt: startedAt,
      endedAt: end,
      protocol: protocol ?? 'openvpn',
    ),
  );
  clearActiveConnectionSession();
}

void clearActiveConnectionSession() {
  Pref.activeConnectionSessionStart = null;
  Pref.activeConnectionCountry = null;
  Pref.activeConnectionProtocol = null;
}

void startActiveConnectionSession({
  required String country,
  required String protocol,
  DateTime? startedAt,
  bool forceRestart = false,
}) {
  if (Pref.activeConnectionSessionStart != null && !forceRestart) {
    // Fill missing metadata from a stale/partial marker.
    if ((Pref.activeConnectionCountry ?? '').trim().isEmpty) {
      Pref.activeConnectionCountry = country;
    }
    if ((Pref.activeConnectionProtocol ?? '').trim().isEmpty) {
      Pref.activeConnectionProtocol = protocol;
    }
    return;
  }
  Pref.activeConnectionSessionStart = startedAt ?? DateTime.now();
  Pref.activeConnectionCountry = country;
  Pref.activeConnectionProtocol = protocol;
}
