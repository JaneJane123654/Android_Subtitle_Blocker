import '../../../core/contracts/business_constants.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/close_button_position.dart';

const Object _unsetIgnoredVersion = Object();

final class Settings {
  const Settings({
    this.closeButtonPosition = SettingsDefaults.closeButtonPosition,
    this.soundEnabled = SettingsDefaults.soundEnabled,
    this.keepAliveEnabled = SettingsDefaults.keepAliveEnabled,
    this.appLanguage = SettingsDefaults.appLanguage,
    this.transparencyToggleEnabled = SettingsDefaults.transparencyToggleEnabled,
    this.transparencyAutoRestoreEnabled =
        SettingsDefaults.transparencyAutoRestoreEnabled,
    this.transparencyAutoRestoreSeconds =
        SettingsDefaults.transparencyAutoRestoreSeconds,
    this.minimizeDotSize = SettingsDefaults.minimizeDotSizeDp,
    this.minimizeDotRotateEnabled = SettingsDefaults.minimizeDotRotateEnabled,
    this.ignoredUpdateVersion = SettingsDefaults.ignoredUpdateVersion,
  });

  static const Settings defaults = Settings();

  factory Settings.defaultValue() {
    return defaults;
  }

  final CloseButtonPosition closeButtonPosition;
  final bool soundEnabled;
  final bool keepAliveEnabled;
  final AppLanguage appLanguage;
  final bool transparencyToggleEnabled;
  final bool transparencyAutoRestoreEnabled;
  final int transparencyAutoRestoreSeconds;
  final int minimizeDotSize;
  final bool minimizeDotRotateEnabled;
  final String? ignoredUpdateVersion;

  Settings copyWith({
    CloseButtonPosition? closeButtonPosition,
    bool? soundEnabled,
    bool? keepAliveEnabled,
    AppLanguage? appLanguage,
    bool? transparencyToggleEnabled,
    bool? transparencyAutoRestoreEnabled,
    int? transparencyAutoRestoreSeconds,
    int? minimizeDotSize,
    bool? minimizeDotRotateEnabled,
    Object? ignoredUpdateVersion = _unsetIgnoredVersion,
  }) {
    return Settings(
      closeButtonPosition: closeButtonPosition ?? this.closeButtonPosition,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
      appLanguage: appLanguage ?? this.appLanguage,
      transparencyToggleEnabled:
          transparencyToggleEnabled ?? this.transparencyToggleEnabled,
      transparencyAutoRestoreEnabled:
          transparencyAutoRestoreEnabled ?? this.transparencyAutoRestoreEnabled,
      transparencyAutoRestoreSeconds:
          transparencyAutoRestoreSeconds ?? this.transparencyAutoRestoreSeconds,
      minimizeDotSize: minimizeDotSize ?? this.minimizeDotSize,
      minimizeDotRotateEnabled:
          minimizeDotRotateEnabled ?? this.minimizeDotRotateEnabled,
      ignoredUpdateVersion:
          identical(ignoredUpdateVersion, _unsetIgnoredVersion)
          ? this.ignoredUpdateVersion
          : ignoredUpdateVersion as String?,
    );
  }

  Settings withCloseButtonPosition(CloseButtonPosition position) {
    return copyWith(closeButtonPosition: position);
  }

  Settings withSoundEnabled(bool enabled) {
    return copyWith(soundEnabled: enabled);
  }

  Settings withKeepAliveEnabled(bool enabled) {
    return copyWith(keepAliveEnabled: enabled);
  }

  Settings withAppLanguage(AppLanguage language) {
    return copyWith(appLanguage: language);
  }

  Settings withTransparencyToggleEnabled(bool enabled) {
    return copyWith(transparencyToggleEnabled: enabled);
  }

  Settings withTransparencyAutoRestoreEnabled(bool enabled) {
    return copyWith(transparencyAutoRestoreEnabled: enabled);
  }

  Settings withTransparencyAutoRestoreSeconds(int seconds) {
    return copyWith(transparencyAutoRestoreSeconds: seconds);
  }

  Settings withMinimizeDotSize(int size) {
    return copyWith(minimizeDotSize: size);
  }

  Settings withMinimizeDotRotateEnabled(bool enabled) {
    return copyWith(minimizeDotRotateEnabled: enabled);
  }

  Settings withIgnoredUpdateVersion(String? version) {
    return copyWith(ignoredUpdateVersion: version);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Settings &&
            other.closeButtonPosition == closeButtonPosition &&
            other.soundEnabled == soundEnabled &&
            other.keepAliveEnabled == keepAliveEnabled &&
            other.appLanguage == appLanguage &&
            other.transparencyToggleEnabled == transparencyToggleEnabled &&
            other.transparencyAutoRestoreEnabled ==
                transparencyAutoRestoreEnabled &&
            other.transparencyAutoRestoreSeconds ==
                transparencyAutoRestoreSeconds &&
            other.minimizeDotSize == minimizeDotSize &&
            other.minimizeDotRotateEnabled == minimizeDotRotateEnabled &&
            other.ignoredUpdateVersion == ignoredUpdateVersion;
  }

  @override
  int get hashCode {
    return Object.hash(
      closeButtonPosition,
      soundEnabled,
      keepAliveEnabled,
      appLanguage,
      transparencyToggleEnabled,
      transparencyAutoRestoreEnabled,
      transparencyAutoRestoreSeconds,
      minimizeDotSize,
      minimizeDotRotateEnabled,
      ignoredUpdateVersion,
    );
  }

  @override
  String toString() {
    return 'Settings('
        'closeButtonPosition: $closeButtonPosition, '
        'soundEnabled: $soundEnabled, '
        'keepAliveEnabled: $keepAliveEnabled, '
        'appLanguage: $appLanguage, '
        'transparencyToggleEnabled: $transparencyToggleEnabled, '
        'transparencyAutoRestoreEnabled: $transparencyAutoRestoreEnabled, '
        'transparencyAutoRestoreSeconds: $transparencyAutoRestoreSeconds, '
        'minimizeDotSize: $minimizeDotSize, '
        'minimizeDotRotateEnabled: $minimizeDotRotateEnabled, '
        'ignoredUpdateVersion: $ignoredUpdateVersion'
        ')';
  }
}
