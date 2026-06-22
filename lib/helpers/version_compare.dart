/// Semantic version comparison for strings like `2.0.2` or `2.0.2+15`.
class VersionCompare {
  VersionCompare._();

  static List<int> parseParts(String version) {
    final base = version.trim().split('+').first;
    if (base.isEmpty) return [0];
    return base
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }

  /// Negative if [a] < [b], zero if equal, positive if [a] > [b].
  static int compare(String a, String b) {
    final left = parseParts(a);
    final right = parseParts(b);
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final av = i < left.length ? left[i] : 0;
      final bv = i < right.length ? right[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  static bool isLessThan(String current, String target) =>
      compare(current, target) < 0;

  static bool isLessThanOrEqual(String current, String target) =>
      compare(current, target) <= 0;
}
