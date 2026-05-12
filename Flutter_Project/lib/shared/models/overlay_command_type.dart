enum OverlayCommandType {
  playSound('PLAY_SOUND'),
  requestHideAfterFade('REQUEST_HIDE_AFTER_FADE'),
  navigateToPermission('NAVIGATE_TO_PERMISSION'),
  requestRestoreAfterDelay('REQUEST_RESTORE_AFTER_DELAY'),
  cancelRestoreDelay('CANCEL_RESTORE_DELAY');

  const OverlayCommandType(this.legacyName);

  final String legacyName;
}
