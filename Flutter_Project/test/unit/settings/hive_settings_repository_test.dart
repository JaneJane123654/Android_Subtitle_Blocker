import 'dart:io';

import 'package:hive/hive.dart';
import 'package:subtitle_blocker_flutter_refactor/core/error/errors.dart';
import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/infrastructure/settings_infrastructure.dart';
import 'package:subtitle_blocker_flutter_refactor/shared/models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('HiveSettingsRepository', () {
    late Directory tempDir;
    late HiveSettingsRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'hive_settings_repository_test_',
      );
      Hive.init(tempDir.path);
      final dataSource = await HiveSettingsDataSource.open(
        boxName: 'settings_test_${DateTime.now().microsecondsSinceEpoch}',
      );
      repository = HiveSettingsRepository(dataSource);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'loads default settings and no last overlay state from empty Hive',
      () async {
        final settings = _unwrap(await repository.loadSettings());
        final lastState = _unwrap(await repository.loadLastOverlayState());

        expect(settings, Settings.defaultValue());
        expect(lastState, isNull);
      },
    );

    test(
      'round-trips settings and restores last overlay like Java prefs',
      () async {
        final settings = Settings.defaultValue()
            .withCloseButtonPosition(CloseButtonPosition.leftTop)
            .withSoundEnabled(true)
            .withKeepAliveEnabled(true)
            .withAppLanguage(AppLanguage.es)
            .withTransparencyToggleEnabled(false)
            .withTransparencyAutoRestoreEnabled(true)
            .withTransparencyAutoRestoreSeconds(23)
            .withMinimizeDotSize(88)
            .withMinimizeDotRotateEnabled(true)
            .withIgnoredUpdateVersion('v9.9.9');
        final state = OverlayState.fromSettings(
          settings,
          widthPx: 320,
          heightPx: 140,
          xPx: 17,
          yPx: 44,
          visible: true,
        ).withTransparentMode(true).withDragging(true).withResizing(true);

        _expectSuccess(await repository.saveSettings(settings));
        _expectSuccess(await repository.saveLastOverlayState(state));

        final loadedSettings = _unwrap(await repository.loadSettings());
        final loadedState = _unwrap(await repository.loadLastOverlayState());

        expect(loadedSettings, settings);
        expect(loadedState, isNotNull);
        expect(loadedState!.widthPx, 320);
        expect(loadedState.heightPx, 140);
        expect(loadedState.xPx, 17);
        expect(loadedState.yPx, 44);
        expect(loadedState.visible, isFalse);
        expect(loadedState.closeButtonPosition, CloseButtonPosition.leftTop);
        expect(loadedState.soundEnabled, isTrue);
        expect(loadedState.keepAliveEnabled, isTrue);
        expect(loadedState.transparencyToggleEnabled, isFalse);
        expect(loadedState.transparentMode, isFalse);
        expect(loadedState.isDragging, isFalse);
        expect(loadedState.isResizing, isFalse);
        expect(loadedState.isMinimized, isFalse);
      },
    );

    test('ignored update version trims empty values to null', () async {
      final settings = Settings.defaultValue().withIgnoredUpdateVersion(
        'v1.2.3',
      );

      _expectSuccess(await repository.saveSettings(settings));
      _expectSuccess(await repository.saveIgnoredUpdateVersion('  '));

      expect(_unwrap(await repository.loadIgnoredUpdateVersion()), isNull);
      expect(
        _unwrap(await repository.loadSettings()).ignoredUpdateVersion,
        isNull,
      );
    });
  });
}

T _unwrap<T>(Result<T> result) {
  final failure = result.failureOrNull;
  if (failure != null) {
    fail('Expected success but got $failure');
  }
  return result.valueOrNull as T;
}

void _expectSuccess(Result<void> result) {
  final failure = result.failureOrNull;
  if (failure != null) {
    fail('Expected success but got $failure');
  }
}
