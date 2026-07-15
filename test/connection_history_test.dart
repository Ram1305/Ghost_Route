import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/connection_history.dart';
import 'package:ghost_route/models/vpn_connection_session.dart';

void main() {
  group('formatDurationCompact', () {
    test('formats minutes', () {
      expect(formatDurationCompact(const Duration(minutes: 32)), '32 minutes');
      expect(formatDurationCompact(const Duration(minutes: 1)), '1 minute');
    });

    test('formats hours and minutes', () {
      expect(formatDurationCompact(const Duration(hours: 1, minutes: 12)), '1h 12m');
      expect(formatDurationCompact(const Duration(hours: 2)), '2h');
    });

    test('formats sub-minute durations', () {
      expect(formatDurationCompact(const Duration(minutes: 48)), '48 minutes');
      expect(formatDurationCompact(const Duration(seconds: 45)), '45s');
    });
  });

  group('dayGroupLabel', () {
    test('returns Today and Yesterday', () {
      final now = DateTime(2026, 7, 15, 14, 30);
      expect(dayGroupLabel(now, now: now), 'Today');
      expect(
        dayGroupLabel(now.subtract(const Duration(days: 1)), now: now),
        'Yesterday',
      );
    });

    test('returns formatted date for older sessions', () {
      final now = DateTime(2026, 7, 15);
      expect(
        dayGroupLabel(DateTime(2026, 7, 10), now: now),
        'Jul 10, 2026',
      );
    });
  });

  group('groupSessionsByDay', () {
    test('groups and orders by recency', () {
      final now = DateTime(2026, 7, 15, 12);
      final sessions = [
        VpnConnectionSession(
          country: 'Japan',
          startedAt: now.subtract(const Duration(hours: 2)),
          endedAt: now.subtract(const Duration(hours: 1)),
          protocol: 'openvpn',
        ),
        VpnConnectionSession(
          country: 'Singapore',
          startedAt: now.subtract(const Duration(minutes: 40)),
          endedAt: now.subtract(const Duration(minutes: 8)),
          protocol: 'wireguard',
        ),
        VpnConnectionSession(
          country: 'United States',
          startedAt: now.subtract(const Duration(days: 1, hours: 2)),
          endedAt: now.subtract(const Duration(days: 1, hours: 1)),
          protocol: 'openvpn',
        ),
      ];

      final grouped = groupSessionsByDay(sessions, now: now);

      expect(grouped.keys.toList(), ['Today', 'Yesterday']);
      expect(grouped['Today']!.map((s) => s.country).toList(),
          ['Singapore', 'Japan']);
      expect(grouped['Yesterday']!.single.country, 'United States');
    });
  });

  group('saveConnectionSession minimum duration', () {
    test('kMinSessionDuration is 5 seconds', () {
      expect(kMinSessionDuration, const Duration(seconds: 5));
    });
  });
}
