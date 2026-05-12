import 'dart:convert';

import '../../../core/contracts/business_constants.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/close_button_position.dart';
import '../../overlay/domain/overlay_state.dart';
import '../domain/settings.dart';
import 'settings_storage_schema.dart';

final class PersistedSettingsRecord {
  const PersistedSettingsRecord({
    required this.closeButtonPosition,
    required this.soundEnabled,
    required this.keepAliveEnabled,
    required this.appLanguage,
    required this.transparencyToggleEnabled,
    required this.transparencyAutoRestoreEnabled,
    required this.transparencyAutoRestoreSeconds,
    required this.minimizeDotSize,
    required this.minimizeDotRotateEnabled,
    required this.ignoredUpdateVersion,
  });

  factory PersistedSettingsRecord.fromDomain(Settings settings) {
    return PersistedSettingsRecord(
      closeButtonPosition: settings.closeButtonPosition,
      soundEnabled: settings.soundEnabled,
      keepAliveEnabled: settings.keepAliveEnabled,
      appLanguage: settings.appLanguage,
      transparencyToggleEnabled: settings.transparencyToggleEnabled,
      transparencyAutoRestoreEnabled: settings.transparencyAutoRestoreEnabled,
      transparencyAutoRestoreSeconds: settings.transparencyAutoRestoreSeconds,
      minimizeDotSize: settings.minimizeDotSize,
      minimizeDotRotateEnabled: settings.minimizeDotRotateEnabled,
      ignoredUpdateVersion: settings.ignoredUpdateVersion,
    );
  }

  factory PersistedSettingsRecord.fromJson(Map<String, Object?> json) {
    return PersistedSettingsRecord(
      closeButtonPosition: CloseButtonPosition.fromLegacyName(
        _stringOrDefault(
          json[SettingsJsonFields.closeButtonPosition],
          SettingsDefaults.closeButtonPosition.legacyName,
        ),
      ),
      soundEnabled: _boolOrDefault(
        json[SettingsJsonFields.soundEnabled],
        SettingsDefaults.soundEnabled,
      ),
      keepAliveEnabled: _boolOrDefault(
        json[SettingsJsonFields.keepAliveEnabled],
        SettingsDefaults.keepAliveEnabled,
      ),
      appLanguage: AppLanguage.fromValue(
        _stringOrDefault(
          json[SettingsJsonFields.appLanguage],
          SettingsDefaults.appLanguage.value,
        ),
      ),
      transparencyToggleEnabled: _boolOrDefault(
        json[SettingsJsonFields.transparencyToggleEnabled],
        SettingsDefaults.transparencyToggleEnabled,
      ),
      transparencyAutoRestoreEnabled: _boolOrDefault(
        json[SettingsJsonFields.transparencyAutoRestoreEnabled],
        SettingsDefaults.transparencyAutoRestoreEnabled,
      ),
      transparencyAutoRestoreSeconds: _intOrDefault(
        json[SettingsJsonFields.transparencyAutoRestoreSeconds],
        SettingsDefaults.transparencyAutoRestoreSeconds,
      ),
      minimizeDotSize: _intOrDefault(
        json[SettingsJsonFields.minimizeDotSize],
        SettingsDefaults.minimizeDotSizeDp,
      ),
      minimizeDotRotateEnabled: _boolOrDefault(
        json[SettingsJsonFields.minimizeDotRotateEnabled],
        SettingsDefaults.minimizeDotRotateEnabled,
      ),
      ignoredUpdateVersion: _nullableString(
        json[SettingsJsonFields.ignoredUpdateVersion],
      ),
    );
  }

  factory PersistedSettingsRecord.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('settings payload must be a JSON object');
    }
    return PersistedSettingsRecord.fromJson(decoded.cast<String, Object?>());
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

  Settings toDomain() {
    return Settings(
      closeButtonPosition: closeButtonPosition,
      soundEnabled: soundEnabled,
      keepAliveEnabled: keepAliveEnabled,
      appLanguage: appLanguage,
      transparencyToggleEnabled: transparencyToggleEnabled,
      transparencyAutoRestoreEnabled: transparencyAutoRestoreEnabled,
      transparencyAutoRestoreSeconds: transparencyAutoRestoreSeconds,
      minimizeDotSize: minimizeDotSize,
      minimizeDotRotateEnabled: minimizeDotRotateEnabled,
      ignoredUpdateVersion: ignoredUpdateVersion,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      SettingsJsonFields.closeButtonPosition: closeButtonPosition.legacyName,
      SettingsJsonFields.soundEnabled: soundEnabled,
      SettingsJsonFields.keepAliveEnabled: keepAliveEnabled,
      SettingsJsonFields.appLanguage: appLanguage.value,
      SettingsJsonFields.transparencyToggleEnabled: transparencyToggleEnabled,
      SettingsJsonFields.transparencyAutoRestoreEnabled:
          transparencyAutoRestoreEnabled,
      SettingsJsonFields.transparencyAutoRestoreSeconds:
          transparencyAutoRestoreSeconds,
      SettingsJsonFields.minimizeDotSize: minimizeDotSize,
      SettingsJsonFields.minimizeDotRotateEnabled: minimizeDotRotateEnabled,
      SettingsJsonFields.ignoredUpdateVersion: ignoredUpdateVersion,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

final class PersistedOverlaySnapshotRecord {
  const PersistedOverlaySnapshotRecord({
    required this.widthPx,
    required this.heightPx,
    required this.xPx,
    required this.yPx,
  });

  factory PersistedOverlaySnapshotRecord.fromDomain(OverlayState state) {
    return PersistedOverlaySnapshotRecord(
      widthPx: state.widthPx,
      heightPx: state.heightPx,
      xPx: state.xPx,
      yPx: state.yPx,
    );
  }

  factory PersistedOverlaySnapshotRecord.fromJson(Map<String, Object?> json) {
    return PersistedOverlaySnapshotRecord(
      widthPx: _requiredInt(json, OverlaySnapshotJsonFields.widthPx),
      heightPx: _requiredInt(json, OverlaySnapshotJsonFields.heightPx),
      xPx: _requiredInt(json, OverlaySnapshotJsonFields.xPx),
      yPx: _requiredInt(json, OverlaySnapshotJsonFields.yPx),
    );
  }

  factory PersistedOverlaySnapshotRecord.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('overlay snapshot must be a JSON object');
    }
    return PersistedOverlaySnapshotRecord.fromJson(
      decoded.cast<String, Object?>(),
    );
  }

  final int widthPx;
  final int heightPx;
  final int xPx;
  final int yPx;

  OverlayState toDomain(Settings settings) {
    return OverlayState(
      widthPx: widthPx,
      heightPx: heightPx,
      xPx: xPx,
      yPx: yPx,
      visible: false,
      closeButtonPosition: settings.closeButtonPosition,
      soundEnabled: settings.soundEnabled,
      keepAliveEnabled: settings.keepAliveEnabled,
      transparencyToggleEnabled: settings.transparencyToggleEnabled,
      transparentMode: false,
      isDragging: false,
      isResizing: false,
      isMinimized: false,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      OverlaySnapshotJsonFields.widthPx: widthPx,
      OverlaySnapshotJsonFields.heightPx: heightPx,
      OverlaySnapshotJsonFields.xPx: xPx,
      OverlaySnapshotJsonFields.yPx: yPx,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

String _stringOrDefault(Object? value, String defaultValue) {
  if (value == null) {
    return defaultValue;
  }
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  return value.toString();
}

bool _boolOrDefault(Object? value, bool defaultValue) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    if (value.toLowerCase() == 'true') {
      return true;
    }
    if (value.toLowerCase() == 'false') {
      return false;
    }
  }
  return defaultValue;
}

int _intOrDefault(Object? value, int defaultValue) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.parse(value);
  }
  throw FormatException('required integer field is missing: $key');
}
