import 'dart:convert';

import '../../../core/contracts/business_constants.dart';
import '../../../core/error/errors.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/close_button_position.dart';
import '../../overlay/domain/overlay_state.dart';
import '../../settings/domain/settings.dart';
import '../../settings/infrastructure/settings_storage_schema.dart';

abstract final class ConfigTransferJsonFields {
  static const String schemaVersion = 'schemaVersion';
}

final class ConfigTransferPayload {
  const ConfigTransferPayload({
    required this.schemaVersion,
    required this.widthPx,
    required this.heightPx,
    required this.xPx,
    required this.yPx,
    required this.closeButtonPosition,
    required this.soundEnabled,
    required this.keepAliveEnabled,
    required this.appLanguage,
    required this.transparencyToggleEnabled,
    required this.transparencyAutoRestoreEnabled,
    required this.transparencyAutoRestoreSeconds,
    required this.minimizeDotSize,
    required this.minimizeDotRotateEnabled,
  });

  static const int currentSchemaVersion = 1;
  static const String clipboardLabel = 'overlay_config';

  factory ConfigTransferPayload.fromDomain({
    required Settings settings,
    required OverlayState overlayState,
  }) {
    return ConfigTransferPayload(
      schemaVersion: currentSchemaVersion,
      widthPx: overlayState.widthPx,
      heightPx: overlayState.heightPx,
      xPx: overlayState.xPx,
      yPx: overlayState.yPx,
      closeButtonPosition: settings.closeButtonPosition,
      soundEnabled: settings.soundEnabled,
      keepAliveEnabled: settings.keepAliveEnabled,
      appLanguage: settings.appLanguage,
      transparencyToggleEnabled: settings.transparencyToggleEnabled,
      transparencyAutoRestoreEnabled: settings.transparencyAutoRestoreEnabled,
      transparencyAutoRestoreSeconds: settings.transparencyAutoRestoreSeconds,
      minimizeDotSize: settings.minimizeDotSize,
      minimizeDotRotateEnabled: settings.minimizeDotRotateEnabled,
    );
  }

  factory ConfigTransferPayload.fromJson(Map<String, Object?> json) {
    final schemaVersion = _schemaVersion(json);
    if (schemaVersion != currentSchemaVersion) {
      throw _PayloadValidationException(
        'unsupported schemaVersion: $schemaVersion',
      );
    }
    return ConfigTransferPayload(
      schemaVersion: schemaVersion,
      widthPx: _requiredInt(json, OverlaySnapshotJsonFields.widthPx),
      heightPx: _requiredInt(json, OverlaySnapshotJsonFields.heightPx),
      xPx: _requiredInt(json, OverlaySnapshotJsonFields.xPx),
      yPx: _requiredInt(json, OverlaySnapshotJsonFields.yPx),
      closeButtonPosition: _requiredCloseButtonPosition(
        json,
        SettingsJsonFields.closeButtonPosition,
      ),
      soundEnabled: _requiredBool(json, SettingsJsonFields.soundEnabled),
      keepAliveEnabled: _requiredBool(
        json,
        SettingsJsonFields.keepAliveEnabled,
      ),
      appLanguage: AppLanguage.fromValue(
        _optionalString(json, SettingsJsonFields.appLanguage),
      ),
      transparencyToggleEnabled: _optionalBool(
        json,
        SettingsJsonFields.transparencyToggleEnabled,
        SettingsDefaults.transparencyToggleEnabled,
      ),
      transparencyAutoRestoreEnabled: _optionalBool(
        json,
        SettingsJsonFields.transparencyAutoRestoreEnabled,
        SettingsDefaults.transparencyAutoRestoreEnabled,
      ),
      transparencyAutoRestoreSeconds: _optionalInt(
        json,
        SettingsJsonFields.transparencyAutoRestoreSeconds,
        SettingsDefaults.transparencyAutoRestoreSeconds,
      ),
      minimizeDotSize: _optionalInt(
        json,
        SettingsJsonFields.minimizeDotSize,
        SettingsDefaults.minimizeDotSizeDp,
      ),
      minimizeDotRotateEnabled: _optionalBool(
        json,
        SettingsJsonFields.minimizeDotRotateEnabled,
        SettingsDefaults.minimizeDotRotateEnabled,
      ),
    );
  }

  static Result<ConfigTransferPayload> decode(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return const Result<ConfigTransferPayload>.failure(
          ConfigValidationFailure(
            message: 'Config payload must be a JSON object.',
          ),
        );
      }
      return Result<ConfigTransferPayload>.success(
        ConfigTransferPayload.fromJson(decoded.cast<String, Object?>()),
      );
    } on FormatException catch (error, stackTrace) {
      return Result<ConfigTransferPayload>.failure(
        JsonParseFailure(
          message: 'Config payload is not valid JSON.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on _PayloadValidationException catch (error, stackTrace) {
      return Result<ConfigTransferPayload>.failure(
        ConfigValidationFailure(
          message: error.message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Result<ConfigTransferPayload>.failure(
        ConfigValidationFailure(
          message: 'Config payload validation failed.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  final int schemaVersion;
  final int widthPx;
  final int heightPx;
  final int xPx;
  final int yPx;
  final CloseButtonPosition closeButtonPosition;
  final bool soundEnabled;
  final bool keepAliveEnabled;
  final AppLanguage appLanguage;
  final bool transparencyToggleEnabled;
  final bool transparencyAutoRestoreEnabled;
  final int transparencyAutoRestoreSeconds;
  final int minimizeDotSize;
  final bool minimizeDotRotateEnabled;

  Settings toSettings({required String? ignoredUpdateVersion}) {
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

  OverlayState toImportedOverlayState({
    required bool visible,
    required bool isDragging,
    required bool isResizing,
    required bool isMinimized,
  }) {
    return OverlayState(
      widthPx: widthPx,
      heightPx: heightPx,
      xPx: xPx,
      yPx: yPx,
      visible: visible,
      closeButtonPosition: closeButtonPosition,
      soundEnabled: soundEnabled,
      keepAliveEnabled: keepAliveEnabled,
      transparencyToggleEnabled: transparencyToggleEnabled,
      transparentMode: false,
      isDragging: isDragging,
      isResizing: isResizing,
      isMinimized: isMinimized,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      ConfigTransferJsonFields.schemaVersion: schemaVersion,
      OverlaySnapshotJsonFields.widthPx: widthPx,
      OverlaySnapshotJsonFields.heightPx: heightPx,
      OverlaySnapshotJsonFields.xPx: xPx,
      OverlaySnapshotJsonFields.yPx: yPx,
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
    };
  }

  String encode() {
    return jsonEncode(toJson());
  }
}

int _schemaVersion(Map<String, Object?> json) {
  if (!json.containsKey(ConfigTransferJsonFields.schemaVersion)) {
    return ConfigTransferPayload.currentSchemaVersion;
  }
  return _requiredInt(json, ConfigTransferJsonFields.schemaVersion);
}

int _requiredInt(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw _PayloadValidationException('required integer is missing: $key');
  }
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw _PayloadValidationException('required integer is invalid: $key');
}

int _optionalInt(Map<String, Object?> json, String key, int defaultValue) {
  if (!json.containsKey(key) || json[key] == null) {
    return defaultValue;
  }
  try {
    return _requiredInt(json, key);
  } catch (_) {
    return defaultValue;
  }
}

bool _requiredBool(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw _PayloadValidationException('required boolean is missing: $key');
  }
  final value = json[key];
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
  throw _PayloadValidationException('required boolean is invalid: $key');
}

bool _optionalBool(Map<String, Object?> json, String key, bool defaultValue) {
  if (!json.containsKey(key) || json[key] == null) {
    return defaultValue;
  }
  try {
    return _requiredBool(json, key);
  } catch (_) {
    return defaultValue;
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  if (!json.containsKey(key) || json[key] == null) {
    throw _PayloadValidationException('required string is missing: $key');
  }
  return json[key].toString();
}

String _optionalString(Map<String, Object?> json, String key) {
  if (!json.containsKey(key) || json[key] == null) {
    return '';
  }
  return json[key].toString();
}

CloseButtonPosition _requiredCloseButtonPosition(
  Map<String, Object?> json,
  String key,
) {
  final raw = _requiredString(json, key);
  for (final position in CloseButtonPosition.values) {
    if (position.legacyName == raw) {
      return position;
    }
  }
  throw _PayloadValidationException('invalid close button position: $raw');
}

final class _PayloadValidationException implements Exception {
  const _PayloadValidationException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
