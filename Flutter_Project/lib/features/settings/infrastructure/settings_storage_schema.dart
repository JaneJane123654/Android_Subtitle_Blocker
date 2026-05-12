abstract final class SettingsStorageSchema {
  static const String boxName = 'subtitle_blocker_settings_box';
  static const String settingsKey = 'settings_key';
  static const String overlaySnapshotKey = 'overlay_snapshot_key';
}

abstract final class SettingsJsonFields {
  static const String closeButtonPosition = 'closeButtonPosition';
  static const String soundEnabled = 'soundEnabled';
  static const String keepAliveEnabled = 'keepAliveEnabled';
  static const String appLanguage = 'appLanguage';
  static const String transparencyToggleEnabled = 'transparencyToggleEnabled';
  static const String transparencyAutoRestoreEnabled =
      'transparencyAutoRestoreEnabled';
  static const String transparencyAutoRestoreSeconds =
      'transparencyAutoRestoreSeconds';
  static const String minimizeDotSize = 'minimizeDotSize';
  static const String minimizeDotRotateEnabled = 'minimizeDotRotateEnabled';
  static const String ignoredUpdateVersion = 'ignoredUpdateVersion';
}

abstract final class OverlaySnapshotJsonFields {
  static const String widthPx = 'widthPx';
  static const String heightPx = 'heightPx';
  static const String xPx = 'xPx';
  static const String yPx = 'yPx';
}
