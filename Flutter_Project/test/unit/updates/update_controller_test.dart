import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtitle_blocker_flutter_refactor/core/application/application_command_bus.dart';
import 'package:subtitle_blocker_flutter_refactor/core/error/errors.dart';
import 'package:subtitle_blocker_flutter_refactor/core/platform/app_info_port.dart';
import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_state.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/application/settings_application.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/updates/application/updates_application.dart';
import 'package:subtitle_blocker_flutter_refactor/features/updates/domain/updates_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/updates/infrastructure/updates_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateController', () {
    test(
      'manual up-to-date emits a user message while automatic stays silent',
      () async {
        final manualRepo = _FakeUpdateRepository(
          availability: _availability(
            status: UpdateAvailabilityStatus.upToDateWithUserMessage,
            trigger: UpdateCheckTrigger.manual,
          ),
        );
        final manualContainer = _container(
          updateRepository: manualRepo,
          settingsRepository: _FakeSettingsRepository(),
        );
        addTearDown(manualContainer.dispose);
        final manualCommands = _recordCommands(manualContainer);

        await manualContainer.read(updateControllerProvider.future);
        await manualContainer
            .read(updateControllerProvider.notifier)
            .checkForUpdates(
              trigger: UpdateCheckTrigger.manual,
              target: UpdateActionTarget.android,
            );

        expect(manualCommands[0], isA<ShowUpdateCheckingCommand>());
        expect(manualCommands, contains(isA<ShowUpdateUpToDateCommand>()));

        final autoRepo = _FakeUpdateRepository(
          availability: _availability(
            status: UpdateAvailabilityStatus.upToDateSilently,
            trigger: UpdateCheckTrigger.automatic,
          ),
        );
        final autoContainer = _container(
          updateRepository: autoRepo,
          settingsRepository: _FakeSettingsRepository(),
        );
        addTearDown(autoContainer.dispose);
        final autoCommands = _recordCommands(autoContainer);

        await autoContainer.read(updateControllerProvider.future);
        await autoContainer
            .read(updateControllerProvider.notifier)
            .checkForUpdates(
              trigger: UpdateCheckTrigger.automatic,
              target: UpdateActionTarget.android,
            );

        expect(autoCommands.whereType<ShowUpdateUpToDateCommand>(), isEmpty);
      },
    );

    test('manual ignored version emits ignored-until-newer command', () async {
      final settingsRepository = _FakeSettingsRepository(
        settings: Settings.defaultValue().withIgnoredUpdateVersion('2.0.0'),
      );
      final updateRepository = UpdateRepositoryImpl(
        remoteDataSource: _FakeReleaseRemoteDataSource(_release('v2.0.0')),
        appInfoPort: const _FakeAppInfoPort('1.0.0'),
        settingsRepository: settingsRepository,
      );
      final container = _container(
        updateRepository: updateRepository,
        settingsRepository: settingsRepository,
      );
      addTearDown(container.dispose);
      final commands = _recordCommands(container);

      await container.read(updateControllerProvider.future);
      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates(
            trigger: UpdateCheckTrigger.manual,
            target: UpdateActionTarget.android,
          );

      expect(commands, contains(isA<ShowUpdateIgnoredUntilNewerCommand>()));
      expect(
        container
            .read(updateControllerProvider)
            .value!
            .lastAvailability!
            .status,
        UpdateAvailabilityStatus.suppressedByIgnoredVersion,
      );
    });

    test('higher version than ignored prompts with update dialog', () async {
      final settingsRepository = _FakeSettingsRepository(
        settings: Settings.defaultValue().withIgnoredUpdateVersion('2.0.0'),
      );
      final updateRepository = UpdateRepositoryImpl(
        remoteDataSource: _FakeReleaseRemoteDataSource(
          _release(
            'v2.0.1',
            apkUrl: 'https://github.test/app.apk',
            releasePageUrl: 'https://github.test/releases/tag/v2.0.1',
          ),
        ),
        appInfoPort: const _FakeAppInfoPort('1.0.0'),
        settingsRepository: settingsRepository,
      );
      final container = _container(
        updateRepository: updateRepository,
        settingsRepository: settingsRepository,
      );
      addTearDown(container.dispose);
      final commands = _recordCommands(container);

      await container.read(updateControllerProvider.future);
      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates(
            trigger: UpdateCheckTrigger.automatic,
            target: UpdateActionTarget.android,
          );

      final dialog = commands.whereType<ShowUpdateDialogCommand>().single;
      expect(
        dialog.availability.status,
        UpdateAvailabilityStatus.updateAvailable,
      );
      expect(dialog.availability.ignoredVersion, '2.0.0');
      expect(
        dialog.availability.actionPlan!.intent,
        isA<DownloadAndroidPackageIntent>(),
      );
    });

    test(
      'dialog actions clear or save ignored versions through settings repo',
      () async {
        final settingsRepository = _FakeSettingsRepository(
          settings: Settings.defaultValue().withIgnoredUpdateVersion('2.0.0'),
        );
        final availability = _availability(
          status: UpdateAvailabilityStatus.updateAvailable,
          trigger: UpdateCheckTrigger.manual,
          release: _release(
            'v2.1.0',
            apkUrl: 'https://github.test/app.apk',
            releasePageUrl: 'https://github.test/releases/tag/v2.1.0',
          ),
          actionPlan: const UpdateActionPlan(
            intent: DownloadAndroidPackageIntent(
              packageUrl: 'https://github.test/app.apk',
              fallbackReleasePageUrl: 'https://github.test/releases/tag/v2.1.0',
            ),
          ),
        );
        final container = _container(
          updateRepository: _FakeUpdateRepository(availability: availability),
          settingsRepository: settingsRepository,
        );
        addTearDown(container.dispose);
        final commands = _recordCommands(container);
        final controller = container.read(updateControllerProvider.notifier);

        await container.read(updateControllerProvider.future);
        await controller.checkForUpdates(
          trigger: UpdateCheckTrigger.manual,
          target: UpdateActionTarget.android,
        );
        await controller.remindOnNextVersion();

        expect(settingsRepository.settings.ignoredUpdateVersion, '2.1.0');
        expect(commands, contains(isA<ShowUpdateIgnoreSetCommand>()));

        await controller.acceptAvailableUpdate();

        expect(settingsRepository.settings.ignoredUpdateVersion, isNull);
        expect(commands, contains(isA<LaunchUpdateActionCommand>()));
      },
    );

    test(
      'manual failure emits failed command and clears checking flag',
      () async {
        final updateRepository = _FakeUpdateRepository(
          failure: const NetworkFailure(message: 'check update failed'),
        );
        final container = _container(
          updateRepository: updateRepository,
          settingsRepository: _FakeSettingsRepository(),
        );
        addTearDown(container.dispose);
        final commands = _recordCommands(container);

        await container.read(updateControllerProvider.future);
        await container
            .read(updateControllerProvider.notifier)
            .checkForUpdates(
              trigger: UpdateCheckTrigger.manual,
              target: UpdateActionTarget.android,
            );

        final state = container.read(updateControllerProvider).value!;
        expect(state.checking, isFalse);
        expect(state.lastFailure, isA<NetworkFailure>());
        expect(commands, contains(isA<ShowUpdateCheckFailedCommand>()));
      },
    );
  });
}

ProviderContainer _container({
  required UpdateRepository updateRepository,
  required _FakeSettingsRepository settingsRepository,
}) {
  return ProviderContainer(
    overrides: [
      updateRepositoryProvider.overrideWithValue(updateRepository),
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
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

UpdateAvailability _availability({
  required UpdateAvailabilityStatus status,
  required UpdateCheckTrigger trigger,
  ReleaseInfo? release,
  String? ignoredVersion,
  UpdateActionPlan? actionPlan,
}) {
  return UpdateAvailability(
    status: status,
    trigger: trigger,
    currentVersionName: '1.0.0',
    normalizedCurrentVersion: '1.0.0',
    releaseInfo: release ?? _release('v1.0.0'),
    ignoredVersion: ignoredVersion,
    actionPlan: actionPlan,
  );
}

ReleaseInfo _release(String tagName, {String? apkUrl, String? releasePageUrl}) {
  return ReleaseInfo.fromLegacyFields(
    tagName: tagName,
    apkDownloadUrl: apkUrl,
    releasePageUrl: releasePageUrl,
  );
}

final class _FakeUpdateRepository implements UpdateRepository {
  const _FakeUpdateRepository({this.availability, this.failure});

  final UpdateAvailability? availability;
  final AppFailure? failure;

  @override
  Future<Result<UpdateAvailability>> checkForUpdates({
    required UpdateCheckTrigger trigger,
    required UpdateActionTarget target,
  }) async {
    if (failure != null) {
      return Result<UpdateAvailability>.failure(failure!);
    }
    return Result<UpdateAvailability>.success(availability!);
  }
}

final class _FakeReleaseRemoteDataSource implements ReleaseRemoteDataSource {
  const _FakeReleaseRemoteDataSource(this.release);

  final ReleaseInfo release;

  @override
  Future<Result<ReleaseInfo>> fetchLatestRelease() async {
    return Result<ReleaseInfo>.success(release);
  }
}

final class _FakeAppInfoPort implements AppInfoPort {
  const _FakeAppInfoPort(this.versionName);

  final String versionName;

  @override
  Future<Result<String>> currentVersionName() async {
    return Result<String>.success(versionName);
  }
}

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({Settings? settings})
    : settings = settings ?? Settings.defaultValue();

  Settings settings;

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
    return const Result<OverlayState?>.success(null);
  }

  @override
  Future<Result<void>> saveLastOverlayState(OverlayState state) async {
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
    settings = settings.withIgnoredUpdateVersion(
      normalizedVersion == null || normalizedVersion.trim().isEmpty
          ? null
          : normalizedVersion,
    );
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> saveImportedConfiguration({
    required Settings settings,
    required OverlayState lastOverlayState,
  }) async {
    this.settings = settings;
    return const Result<void>.success(null);
  }
}
