enum CloseButtonPosition {
  leftTop('LEFT_TOP'),
  rightTop('RIGHT_TOP');

  const CloseButtonPosition(this.legacyName);

  final String legacyName;

  static CloseButtonPosition fromLegacyName(String? raw) {
    if (raw == null || raw.isEmpty) {
      return CloseButtonPosition.rightTop;
    }
    for (final position in CloseButtonPosition.values) {
      if (position.legacyName.toLowerCase() == raw.toLowerCase()) {
        return position;
      }
    }
    return CloseButtonPosition.rightTop;
  }
}
