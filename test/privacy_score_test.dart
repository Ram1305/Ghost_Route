import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/privacy_score.dart';

void main() {
  group('privacyScoreForConnected', () {
    test('returns 0 when disconnected', () {
      expect(privacyScoreForConnected(false), 0);
    });

    test('returns 94 when connected', () {
      expect(privacyScoreForConnected(true), kConnectedPrivacyScore);
      expect(kConnectedPrivacyScore, 94);
    });
  });

  group('protectionProgressForConnected', () {
    test('returns 0 when disconnected', () {
      expect(protectionProgressForConnected(false), 0);
    });

    test('returns 1 when connected', () {
      expect(protectionProgressForConnected(true), 1.0);
    });
  });

  group('kPrivacyProtectionLabels', () {
    test('includes four protection items', () {
      expect(kPrivacyProtectionLabels, hasLength(4));
      expect(kPrivacyProtectionLabels, contains('IP Protected'));
      expect(kPrivacyProtectionLabels, contains('DNS Protected'));
      expect(kPrivacyProtectionLabels, contains('No Tracking'));
      expect(kPrivacyProtectionLabels, contains('Encrypted'));
    });
  });
}
