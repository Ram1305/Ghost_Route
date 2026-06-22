import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/version_compare.dart';

void main() {
  group('VersionCompare', () {
    test('compares dotted versions', () {
      expect(VersionCompare.compare('2.0.2', '2.0.3'), -1);
      expect(VersionCompare.compare('2.1.0', '2.0.9'), 1);
      expect(VersionCompare.compare('1.0', '1.0.0'), 0);
    });

    test('ignores build suffix after plus', () {
      expect(VersionCompare.compare('2.0.2+10', '2.0.2+99'), 0);
      expect(VersionCompare.isLessThan('2.0.1+5', '2.0.2'), true);
    });

    test('handles missing patch segments', () {
      expect(VersionCompare.compare('2.0', '2.0.1'), -1);
      expect(VersionCompare.compare('3', '2.9.9'), 1);
    });
  });
}
