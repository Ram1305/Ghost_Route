import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/free_vpn_session.dart';

void main() {
  final noon = DateTime(2026, 6, 22, 12, 0, 0);

  group('FreeVpnSession', () {
    test('localDateKey formats yyyy-MM-dd', () {
      expect(FreeVpnSession.localDateKey(noon), '2026-06-22');
      expect(
        FreeVpnSession.localDateKey(DateTime(2026, 1, 5)),
        '2026-01-05',
      );
    });

    test('can start session on a fresh day', () {
      expect(FreeVpnSession.canStartSession(null, noon), isTrue);
      expect(
        FreeVpnSession.canStartSession('2026-06-21', noon),
        isTrue,
      );
    });

    test('marks session used for the same calendar day', () {
      expect(
        FreeVpnSession.hasUsedSessionToday('2026-06-22', noon),
        isTrue,
      );
      expect(
        FreeVpnSession.canStartSession('2026-06-22', noon),
        isFalse,
      );
    });

    test('remaining time decreases from session start', () {
      final started = noon;
      expect(
        FreeVpnSession.remainingSecondsFromStart(started, noon),
        300,
      );
      expect(
        FreeVpnSession.remainingSecondsFromStart(
          started,
          noon.add(const Duration(minutes: 2)),
        ),
        180,
      );
      expect(
        FreeVpnSession.remainingSecondsFromStart(
          started,
          noon.add(const Duration(minutes: 5)),
        ),
        0,
      );
      expect(
        FreeVpnSession.remainingSecondsFromStart(
          started,
          noon.add(const Duration(minutes: 6)),
        ),
        0,
      );
    });

    test('next calendar day resets session availability', () {
      final tomorrow = DateTime(2026, 6, 23, 8, 0, 0);
      expect(
        FreeVpnSession.canStartSession('2026-06-22', tomorrow),
        isTrue,
      );
      expect(
        FreeVpnSession.hasUsedSessionToday('2026-06-22', tomorrow),
        isFalse,
      );
    });

    test('remaining defaults to full limit when start is null', () {
      expect(
        FreeVpnSession.remainingFromStart(null, noon),
        FreeVpnSession.limit,
      );
      expect(
        FreeVpnSession.remainingSecondsFromStart(null, noon),
        300,
      );
    });
  });
}
