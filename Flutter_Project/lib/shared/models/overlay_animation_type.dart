enum OverlayAnimationType {
  move('MOVE'),
  resize('RESIZE'),
  fade('FADE');

  const OverlayAnimationType(this.legacyName);

  final String legacyName;
}
