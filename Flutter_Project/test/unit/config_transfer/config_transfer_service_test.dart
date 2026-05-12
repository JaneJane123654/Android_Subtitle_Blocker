import 'dart:convert';

import 'package:subtitle_blocker_flutter_refactor/core/error/errors.dart';
import 'package:subtitle_blocker_flutter_refactor/features/config_transfer/domain/config_transfer_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/shared/models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigTransferService export', () {
    test(
      'uses current runtime state before the persisted overlay state',
      () async {
        final repository = _FakeSettingsRepository(
          settings: _nonDefaultSettings(),
          lastOverlayState: const OverlayState(widthPx: 111, heightPx: 55),
        );
        final service = ConfigTransferService(repository);

        final result = await service.exportConfig(
          currentRuntimeState: const OverlayState(
            widthPx: 222,
            heightPx: 66,
            xPx: 7,
            yPx: 8,
          ),
        );

        final payload = _decodePayload(_unwrap(result));

        expect(
          payload.schemaVersion,
          ConfigTransferPayload.currentSchemaVersion,
        );
        expect(payload.widthPx, 222);
        expect(payload.heightPx, 66);
        expect(payload.xPx, 7);
        expect(payload.yPx, 8);
        expect(payload.closeButtonPosition, CloseButtonPosition.leftTop);
        expect(payload.appLanguage, AppLanguage.fr);
      },
    );

    test(
      'falls back to the persisted overlay state when runtime is null',
      () async {
        final repository = _FakeSettingsRepository(
          settings: Settings.defaultValue(),
          lastOverlayState: const OverlayState(
            widthPx: 333,
            heightPx: 77,
            xPx: 9,
            yPx: 10,
          ),
        );
        final service = ConfigTransferService(repository);

        final result = await service.exportConfig();
        final payload = _decodePayload(_unwrap(result));

        expect(payload.widthPx, 333);
        expect(payload.heightPx, 77);
        expect(payload.xPx, 9);
        expect(payload.yPx, 10);
      },
    );

    test(
      'fails clearly instead of exporting partial JSON without state',
      () async {
        final repository = _FakeSettingsRepository(
          settings: Settings.defaultValue(),
        );
        final service = ConfigTransferService(repository);

        final result = await service.exportConfig();

        expect(result.failureOrNull, isA<ConfigTransferFailure>());
        expect(repository.saveImportedCalls, 0);
      },
    );
  });

  group('ConfigTransferService import', () {
    test(
      'invalid JSON fails atomically without writing settings or state',
      () async {
        final originalSettings = Settings.defaultValue().withSoundEnabled(true);
        final originalState = const OverlayState(widthPx: 400, heightPx: 100);
        final repository = _FakeSettingsRepository(
          settings: originalSettings,
          lastOverlayState: originalState,
        );
        final service = ConfigTransferService(repository);

        final result = await service.importConfig('{broken json');

        expect(result.failureOrNull, isA<JsonParseFailure>());
        expect(repository.saveImportedCalls, 0);
        expect(repository.settings, originalSettings);
        expect(repository.lastOverlayState, originalState);
      },
    );

    test('validation failure is atomic and reports a typed failure', () async {
      final originalSettings = Settings.defaultValue().withKeepAliveEnabled(
        true,
      );
      final repository = _FakeSettingsRepository(settings: originalSettings);
      final service = ConfigTransferService(repository);

      final result = await service.importConfig(
        jsonEncode(<String, Object?>{
          'schemaVersion': 2,
          'widthPx': 120,
          'heightPx': 60,
          'xPx': 1,
          'yPx': 2,
          'closeButtonPosition': 'RIGHT_TOP',
          'soundEnabled': true,
          'keepAliveEnabled': false,
        }),
      );

      expect(result.failureOrNull, isA<ConfigValidationFailure>());
      expect(repository.saveImportedCalls, 0);
      expect(repository.settings, originalSettings);
    });

    test('successful import preserves visibility and forces opacity', () async {
      final repository = _FakeSettingsRepository(
        settings: Settings.defaultValue().withIgnoredUpdateVersion('v8.0.0'),
      );
      final service = ConfigTransferService(repository);
      final runtimeState = const OverlayState(
        visible: true,
        transparentMode: true,
        isDragging: true,
        isResizing: true,
        isMinimized: true,
      );

      final result = await service.importConfig(
        _payloadJson(
          extra: <String, Object?>{'visible': false, 'transparentMode': true},
        ),
        currentRuntimeState: runtimeState,
      );
      final imported = _unwrap(result);

      expect(
        imported.settings.closeButtonPosition,
        CloseButtonPosition.leftTop,
      );
      expect(imported.settings.soundEnabled, isTrue);
      expect(imported.settings.keepAliveEnabled, isTrue);
      expect(imported.settings.appLanguage, AppLanguage.ru);
      expect(imported.settings.transparencyToggleEnabled, isFalse);
      expect(imported.settings.transparencyAutoRestoreEnabled, isTrue);
      expect(imported.settings.transparencyAutoRestoreSeconds, 13);
      expect(imported.settings.minimizeDotSize, 77);
      expect(imported.settings.minimizeDotRotateEnabled, isTrue);
      expect(imported.settings.ignoredUpdateVersion, 'v8.0.0');
      expect(imported.overlayState.widthPx, 301);
      expect(imported.overlayState.heightPx, 91);
      expect(imported.overlayState.xPx, 14);
      expect(imported.overlayState.yPx, 15);
      expect(imported.overlayState.visible, isTrue);
      expect(imported.overlayState.transparentMode, isFalse);
      expect(imported.overlayState.isDragging, isTrue);
      expect(imported.overlayState.isResizing, isTrue);
      expect(imported.overlayState.isMinimized, isTrue);
      expect(repository.saveImportedCalls, 1);
      expect(repository.lastOverlayState?.transparentMode, isFalse);
      expect(repository.lastOverlayState?.isDragging, isFalse);
      expect(repository.lastOverlayState?.isResizing, isFalse);
      expect(repository.lastOverlayState?.isMinimized, isFalse);
    });

    test(
      'legacy payload without schema still imports as version one',
      () async {
        final repository = _FakeSettingsRepository(
          settings: Settings.defaultValue(),
        );
        final service = ConfigTransferService(repository);
        final legacy = jsonDecode(_payloadJson()) as Map<String, dynamic>;
        legacy.remove('schemaVersion');

        final result = await service.importConfig(jsonEncode(legacy));

        expect(result.failureOrNull, isNull);
        expect(repository.saveImportedCalls, 1);
        expect(_unwrap(result).overlayState.visible, isFalse);
      },
    );
  });
}

Settings _nonDefaultSettings() {
  return Settings.defaultValue()
      .withCloseButtonPosition(CloseButtonPosition.leftTop)
      .withSoundEnabled(true)
      .withKeepAliveEnabled(true)
      .withAppLanguage(AppLanguage.fr)
      .withTransparencyToggleEnabled(false)
      .withTransparencyAutoRestoreEnabled(true)
      .withTransparencyAutoRestoreSeconds(11)
      .withMinimizeDotSize(66)
      .withMinimizeDotRotateEnabled(true);
}

String _payloadJson({Map<String, Object?> extra = const <String, Object?>{}}) {
  return jsonEncode(<String, Object?>{
    'schemaVersion': ConfigTransferPayload.currentSchemaVersion,
    'widthPx': 301,
    'heightPx': 91,
    'xPx': 14,
    'yPx': 15,
    'closeButtonPosition': 'LEFT_TOP',
    'soundEnabled': true,
    'keepAliveEnabled': true,
    'appLanguage': 'RU',
    'transparencyToggleEnabled': false,
    'transparencyAutoRestoreEnabled': true,
    'transparencyAutoRestoreSeconds': 13,
    'minimizeDotSize': 77,
    'minimizeDotRotateEnabled': true,
    ...extra,
  });
}

ConfigTransferPayload _decodePayload(String source) {
  final result = ConfigTransferPayload.decode(source);
  final failure = result.failureOrNull;
  if (failure != null) {
    fail('Expected a payload but got $failure');
  }
  return result.valueOrNull!;
}

T _unwrap<T>(Result<T> result) {
  final failure = result.failureOrNull;
  if (failure != null) {
    fail('Expected success but got $failure');
  }
  return result.valueOrNull as T;
}

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({required this.settings, this.lastOverlayState});

  Settings settings;
  OverlayState? lastOverlayState;
  int saveImportedCalls = 0;

  @override
  Future<Result<Settings>> loadSettings() async {
    return Result<Settings>.success(settings);
  }

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    this.settings = settings;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<OverlayState?>> loadLastOverlayState() async {
    return Result<OverlayState?>.success(lastOverlayState);
  }

  @override
  Future<Result<void>> saveLastOverlayState(OverlayState state) async {
    lastOverlayState = state;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<String?>> loadIgnoredUpdateVersion() async {
    final ignored = settings.ignoredUpdateVersion;
    if (ignored == null || ignored.trim().isEmpty) {
      return const Result<String?>.success(null);
    }
    return Result<String?>.success(ignored);
  }

  @override
  Future<Result<void>> saveIgnoredUpdateVersion(
    String? normalizedVersion,
  ) async {
    settings = settings.withIgnoredUpdateVersion(normalizedVersion);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> saveImportedConfiguration({
    required Settings settings,
    required OverlayState lastOverlayState,
  }) async {
    saveImportedCalls += 1;
    this.settings = settings;
    this.lastOverlayState = lastOverlayState;
    return const Result<void>.success(null);
  }
}
