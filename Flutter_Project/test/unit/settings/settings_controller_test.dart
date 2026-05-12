import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtitle_blocker_flutter_refactor/core/application/application_command_bus.dart';
import 'package:subtitle_blocker_flutter_refactor/core/error/errors.dart';
import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/application/settings_application.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/shared/models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('SettingsController', () {
    test('loads settings and persists individual field changes', () async {
      final repo = _FakeSettingsRepository(
        settings: Settings.defaultValue().withAppLanguage(AppLanguage.fr),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      final controller = container.read(settingsControllerProvider.notifier);

      final initial = await container.read(settingsControllerProvider.future);
      expect(initial.settings.appLanguage, AppLanguage.fr);

      await controller.setCloseButtonPosition(CloseButtonPosition.leftTop);
      await controller.setSoundEnabled(true);
      await controller.setTransparencyAutoRestoreSeconds(99);
      await controller.setMinimizeDotSize(-3);

      final state = container.read(settingsControllerProvider).value!;
      expect(state.settings.closeButtonPosition, CloseButtonPosition.leftTop);
      expect(state.settings.soundEnabled, isTrue);
      expect(state.settings.transparencyAutoRestoreSeconds, 60);
      expect(state.settings.minimizeDotSize, 10);
      expect(repo.saveSettingsCalls, 4);
    });

    test(
      'keep alive requests notification permission and reverts when absent',
      () async {
        final repo = _FakeSettingsRepository();
        final gate = _FakeKeepAlivePermissionGate(hasPermission: false);
        final container = _container(repo: repo, gate: gate);
        addTearDown(container.dispose);
        final commands = _recordCommands(container);
        final controller = container.read(settingsControllerProvider.notifier);

        await container.read(settingsControllerProvider.future);
        await controller.setKeepAliveEnabled(true);

        expect(
          commands,
          contains(isA<RequestPostNotificationsPermissionCommand>()),
        );
        expect(repo.settings.keepAliveEnabled, isFalse);
        expect(
          container
              .read(settingsControllerProvider)
              .value!
              .settings
              .keepAliveEnabled,
          isFalse,
        );

        await controller.onPostNotificationsPermissionResult(false);

        expect(repo.settings.keepAliveEnabled, isFalse);
      },
    );

    test(
      'permission result can enable keep alive after Android grant',
      () async {
        final repo = _FakeSettingsRepository();
        final gate = _FakeKeepAlivePermissionGate(hasPermission: false);
        final container = _container(repo: repo, gate: gate);
        addTearDown(container.dispose);
        final controller = container.read(settingsControllerProvider.notifier);

        await container.read(settingsControllerProvider.future);
        await controller.setKeepAliveEnabled(true);
        await controller.onPostNotificationsPermissionResult(true);

        expect(repo.settings.keepAliveEnabled, isTrue);
        expect(
          container
              .read(settingsControllerProvider)
              .value!
              .settings
              .keepAliveEnabled,
          isTrue,
        );
      },
    );

    test(
      'parses empty and malformed auto-restore text as legacy fallback',
      () async {
        final repo = _FakeSettingsRepository();
        final container = _container(repo: repo);
        addTearDown(container.dispose);
        final controller = container.read(settingsControllerProvider.notifier);

        await container.read(settingsControllerProvider.future);
        await controller.setTransparencyAutoRestoreSecondsText('');
        expect(repo.settings.transparencyAutoRestoreSeconds, 5);

        await controller.setTransparencyAutoRestoreSecondsText('bad');
        expect(repo.settings.transparencyAutoRestoreSeconds, 5);

        await controller.setTransparencyAutoRestoreSecondsText('0');
        expect(repo.settings.transparencyAutoRestoreSeconds, 1);
      },
    );
  });
}

ProviderContainer _container({
  required _FakeSettingsRepository repo,
  _FakeKeepAlivePermissionGate? gate,
}) {
  return ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
      if (gate != null) keepAlivePermissionGateProvider.overrideWithValue(gate),
    ],
  );
}

List<ApplicationCommand> _recordCommands(ProviderContainer container) {
  final commands = <ApplicationCommand>[];
  final subscription = container
      .read(applicationCommandBusProvider)
      .stream
      .listen(commands.add);
  addTearDown(subscription.cancel);
  return commands;
}

final class _FakeKeepAlivePermissionGate implements KeepAlivePermissionGate {
  const _FakeKeepAlivePermissionGate({required this.hasPermission});

  final bool hasPermission;

  @override
  Future<Result<bool>> hasRequiredNotificationPermission() async {
    return Result<bool>.success(hasPermission);
  }
}

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({Settings? settings})
    : settings = settings ?? Settings.defaultValue();

  Settings settings;
  OverlayState? lastOverlayState;
  int saveSettingsCalls = 0;

  @override
  Future<Result<Settings>> loadSettings() async {
    return Result<Settings>.success(settings);
  }

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    saveSettingsCalls += 1;
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
    return Result<String?>.success(settings.ignoredUpdateVersion);
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
    this.settings = settings;
    this.lastOverlayState = lastOverlayState;
    return const Result<void>.success(null);
  }
}
