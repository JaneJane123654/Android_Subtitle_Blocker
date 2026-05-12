import 'dart:math' as math;

abstract final class VersionNameComparator {
  static bool isNewer(String? candidate, String? baseline) {
    return compare(candidate, baseline) > 0;
  }

  static int compare(String? leftRaw, String? rightRaw) {
    final left = normalize(leftRaw);
    final right = normalize(rightRaw);
    final leftParts = _toParts(left);
    final rightParts = _toParts(right);
    final size = math.max(leftParts.length, rightParts.length);
    for (var i = 0; i < size; i++) {
      final lv = i < leftParts.length ? leftParts[i] : 0;
      final rv = i < rightParts.length ? rightParts[i] : 0;
      if (lv != rv) {
        return lv > rv ? 1 : -1;
      }
    }
    return 0;
  }

  static String normalize(String? raw) {
    if (raw == null) {
      return '0';
    }
    var value = raw.trim();
    while (value.isNotEmpty && !_isDigit(value[0])) {
      value = value.substring(1);
    }
    if (value.isEmpty) {
      return '0';
    }
    var qualifierStart = value.length;
    final dashIndex = value.indexOf('-');
    final plusIndex = value.indexOf('+');
    if (dashIndex >= 0) {
      qualifierStart = math.min(qualifierStart, dashIndex);
    }
    if (plusIndex >= 0) {
      qualifierStart = math.min(qualifierStart, plusIndex);
    }
    final core = value.substring(0, qualifierStart);
    return core.isEmpty ? '0' : core;
  }

  static List<int> _toParts(String normalized) {
    final parts = <int>[];
    final blocks = normalized.split('.');
    for (final block in blocks) {
      if (block.isEmpty) {
        parts.add(0);
        continue;
      }
      final digits = block.replaceAll(RegExp('[^0-9]'), '');
      if (digits.isEmpty) {
        parts.add(0);
      } else {
        try {
          parts.add(int.parse(digits));
        } on FormatException {
          parts.add(0);
        }
      }
    }
    if (parts.isEmpty) {
      parts.add(0);
    }
    return parts;
  }

  static bool _isDigit(String char) {
    if (char.isEmpty) {
      return false;
    }
    final codeUnit = char.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }
}
