import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtitle_blocker_flutter_refactor/core/application/application_command_bus.dart';
import 'package:subtitle_blocker_flutter_refactor/core/application/controller_scheduler.dart';
import 'package:subtitle_blocker_flutter_refactor/core/contracts/business_constants.dart';
import 'package:subtitle_blocker_flutter_refactor/core/error/errors.dart';
import 'package:subtitle_blocker_flutter_refactor/features/overlay/application/overlay_application.dart';
import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/application/settings_application.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/shared/models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('OverlaySessionController', () {
    test(
      'emits permission navigation instead of showing without permission',
      () async {
        final repo = _FakeSettingsRepository();
        final scheduler = _FakeScheduler();
        final container = _container(repo: repo, scheduler: scheduler);
        addTearDown(container.dispose);
        final commands = _recordCommands(container);

        await container.read(overlaySessionControllerProvider.future);
        await container
            .read(overlaySessionControllerProvider.notifier)
            .onRequestShow(hasPermission: false);

        expect(commands, contains(isA<NavigateToOverlayPermissionCommand>()));
        expect(
          container
              .read(overlaySessionControllerProvider)
              .value!
              .overlayState
              .visible,
          isFalse,
        );
      },
    );

    test(
      'hide emits sound, fade, then becomes hidden after scheduler fires',
      () async {
        final repo = _FakeSettingsRepository(
          settings: Settings.defaultValue().withSoundEnabled(true),
        );
        final scheduler = _FakeScheduler();
        final container = _container(repo: repo, scheduler: scheduler);
        addTearDown(container.dispose);
        final commands = _recordCommands(container);
        final controller = container.read(
          overlaySessionControllerProvider.notifier,
        );

        await container.read(overlaySessionControllerProvider.future);
        await controller.onRequestShow(hasPermission: true);
        commands.clear();

        await controller.onRequestHide();

        final beforeDelay = container
            .read(overlaySessionControllerProvider)
            .value!;
        expect(beforeDelay.overlayState.visible, isTrue);
        expect(beforeDelay.animationSpec?.type, OverlayAnimationType.fade);
        expect(commands[0], isA<PlayOverlaySoundCommand>());
        expect(commands[1], isA<RequestOverlayFadeCommand>());
        expect(
          scheduler.tasks.single.delay,
          OverlayAnimationDurations.hideCompletionDelay,
        );

        scheduler.tasks.single.fire();

        final afterDelay = container
            .read(overlaySessionControllerProvider)
            .value!;
        expect(afterDelay.overlayState.visible, isFalse);
        expect(commands, contains(isA<OverlayHiddenAfterFadeCommand>()));
      },
    );

    test('transparent tap is ignored when master switch is disabled', () async {
      final repo = _FakeSettingsRepository(
        settings: Settings.defaultValue().withTransparencyToggleEnabled(false),
      );
      final scheduler = _FakeScheduler();
      final container = _container(repo: repo, scheduler: scheduler);
      addTearDown(container.dispose);
      final commands = _recordCommands(container);
      final controller = container.read(
        overlaySessionControllerProvider.notifier,
      );

      await container.read(overlaySessionControllerProvider.future);
      await controller.onRequestShow(hasPermission: true);
      commands.clear();

      await controller.onTransparencyToggleRequested();

      final state = container
          .read(overlaySessionControllerProvider)
          .value!
          .overlayState;
      expect(state.transparentMode, isFalse);
      expect(commands.whereType<RequestTransparencyRestoreCommand>(), isEmpty);
    });

    test(
      'auto restore schedules on transparent entry and cancels on return',
      () async {
        final repo = _FakeSettingsRepository(
          settings: Settings.defaultValue()
              .withTransparencyAutoRestoreEnabled(true)
              .withTransparencyAutoRestoreSeconds(7),
        );
        final scheduler = _FakeScheduler();
        final container = _container(repo: repo, scheduler: scheduler);
        addTearDown(container.dispose);
        final commands = _recordCommands(container);
        final controller = container.read(
          overlaySessionControllerProvider.notifier,
        );

        await container.read(overlaySessionControllerProvider.future);
        await controller.onRequestShow(hasPermission: true);
        commands.clear();

        await controller.onTransparencyToggleRequested();

        expect(
          container
              .read(overlaySessionControllerProvider)
              .value!
              .overlayState
              .transparentMode,
          isTrue,
        );
        expect(
          commands.whereType<RequestTransparencyRestoreCommand>().single.delay,
          const Duration(seconds: 7),
        );
        expect(scheduler.tasks.single.cancelled, isFalse);

        await controller.onTransparencyToggleRequested();

        expect(
          container
              .read(overlaySessionControllerProvider)
              .value!
              .overlayState
              .transparentMode,
          isFalse,
        );
        expect(scheduler.tasks.single.cancelled, isTrue);
        expect(commands, contains(isA<CancelTransparencyRestoreCommand>()));
      },
    );

    test(
      'disabling transparency while transparent reverts and cancels restore',
      () async {
        final repo = _FakeSettingsRepository();
        final scheduler = _FakeScheduler();
        final container = _container(repo: repo, scheduler: scheduler);
        addTearDown(container.dispose);
        final commands = _recordCommands(container);
        final controller = container.read(
          overlaySessionControllerProvider.notifier,
        );

        await container.read(overlaySessionControllerProvider.future);
        await controller.onRequestShow(hasPermission: true);
        await controller.onTransparencyToggleRequested();
        commands.clear();

        await controller.onTransparencyToggleEnabledChanged(false);

        final state = container
            .read(overlaySessionControllerProvider)
            .value!
            .overlayState;
        expect(state.transparencyToggleEnabled, isFalse);
        expect(state.transparentMode, isFalse);
        expect(repo.settings.transparencyToggleEnabled, isFalse);
        expect(commands, contains(isA<CancelTransparencyRestoreCommand>()));
      },
    );

    test(
      'auto restore task makes transparent overlay opaque on timeout',
      () async {
        final repo = _FakeSettingsRepository(
          settings: Settings.defaultValue()
              .withTransparencyAutoRestoreEnabled(true)
              .withTransparencyAutoRestoreSeconds(3),
        );
        final scheduler = _FakeScheduler();
        final container = _container(repo: repo, scheduler: scheduler);
        addTearDown(container.dispose);
        final controller = container.read(
          overlaySessionControllerProvider.notifier,
        );

        await container.read(overlaySessionControllerProvider.future);
        await controller.onRequestShow(hasPermission: true);
        await controller.onTransparencyToggleRequested();

        scheduler.tasks.single.fire();

        expect(
          container
              .read(overlaySessionControllerProvider)
              .value!
              .overlayState
              .transparentMode,
          isFalse,
        );
      },
    );

    test(
      'applyImportedState preserves runtime flags and forces opacity',
      () async {
        final repo = _FakeSettingsRepository();
        final scheduler = _FakeScheduler();
        final container = _container(repo: repo, scheduler: scheduler);
        addTearDown(container.dispose);
        final commands = _recordCommands(container);
        final controller = container.read(
          overlaySessionControllerProvider.notifier,
        );

        await container.read(overlaySessionControllerProvider.future);
        await controller.onRequestShow(hasPermission: true);
        await controller.onDragStart();
        await controller.onResizeStart();
        await controller.onMinimizeToggleRequested();

        final importedSettings = Settings.defaultValue()
            .withCloseButtonPosition(CloseButtonPosition.leftTop)
            .withSoundEnabled(true)
            .withKeepAliveEnabled(true)
            .withTransparencyToggleEnabled(false)
            .withMinimizeDotSize(77);
        const importedState = OverlayState(
          widthPx: 301,
          heightPx: 91,
          xPx: 14,
          yPx: 15,
          visible: false,
          transparentMode: true,
        );

        await controller.applyImportedState(
          importedState: importedState,
          settings: importedSettings,
        );

        final state = container
            .read(overlaySessionControllerProvider)
            .value!
            .overlayState;
        expect(state.widthPx, 301);
        expect(state.heightPx, 91);
        expect(state.xPx, 14);
        expect(state.yPx, 15);
        expect(state.visible, isTrue);
        expect(state.transparentMode, isFalse);
        expect(state.isDragging, isTrue);
        expect(state.isResizing, isTrue);
        expect(state.isMinimized, isTrue);
        expect(state.closeButtonPosition, CloseButtonPosition.leftTop);
        expect(repo.saveImportedCalls, 1);
        expect(repo.settings, importedSettings);
        expect(repo.lastOverlayState, importedState);
        expect(commands, contains(isA<ConfigImportAppliedCommand>()));
      },
    );
  });
}

ProviderContainer _container({
  required _FakeSettingsRepository repo,
  required _FakeScheduler scheduler,
}) {
  return ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
      overlayScreenInfoProvider.overrideWithValue(const _FakeScreenInfo()),
      controllerSchedulerProvider.overrideWithValue(scheduler),
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

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({Settings? settings})
    : settings = settings ?? Settings.defaultValue();

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
    saveImportedCalls += 1;
    this.settings = settings;
    this.lastOverlayState = lastOverlayState;
    return const Result<void>.success(null);
  }
}

final class _FakeScreenInfo implements OverlayScreenInfoProvider {
  const _FakeScreenInfo();

  @override
  ScreenBounds getCurrentBounds() {
    return const ScreenBounds(
      widthPx: 1080,
      heightPx: 1920,
      safeInsets: ScreenInsets(left: 0, top: 24, right: 0, bottom: 0),
    );
  }

  @override
  int dpToPx(num dp) {
    return (dp * 3).round();
  }
}

final class _FakeScheduler implements ControllerScheduler {
  final List<_FakeTask> tasks = <_FakeTask>[];

  @override
  ScheduledTask schedule(Duration delay, void Function() callback) {
    final task = _FakeTask(delay: delay, callback: callback);
    tasks.add(task);
    return task;
  }
}

final class _FakeTask implements ScheduledTask {
  _FakeTask({required this.delay, required this.callback});

  final Duration delay;
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() {
    cancelled = true;
  }

  void fire() {
    if (cancelled) {
      return;
    }
    callback();
  }
}
