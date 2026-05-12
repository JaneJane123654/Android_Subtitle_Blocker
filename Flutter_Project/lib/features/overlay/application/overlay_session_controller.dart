import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/application_command_bus.dart';
import '../../../core/application/controller_scheduler.dart';
import '../../../core/contracts/business_constants.dart';
import '../../../core/error/errors.dart';
import '../../../shared/models/close_button_position.dart';
import '../../../shared/models/overlay_animation_type.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/settings.dart';
import '../domain/animation_spec.dart';
import '../domain/overlay_constraints.dart';
import '../domain/overlay_state.dart';
import 'overlay_screen_info.dart';

const Object _unsetAnimationSpec = Object();
const Object _unsetOverlayFailure = Object();

final overlaySessionControllerProvider =
    AsyncNotifierProvider<OverlaySessionController, OverlaySessionState>(
      OverlaySessionController.new,
    );

final class OverlaySessionState {
  const OverlaySessionState({
    required this.overlayState,
    this.animationSpec,
    this.lastFailure,
  });

  final OverlayState overlayState;
  final AnimationSpec? animationSpec;
  final AppFailure? lastFailure;

  OverlaySessionState copyWith({
    OverlayState? overlayState,
    Object? animationSpec = _unsetAnimationSpec,
    Object? lastFailure = _unsetOverlayFailure,
  }) {
    return OverlaySessionState(
      overlayState: overlayState ?? this.overlayState,
      animationSpec: identical(animationSpec, _unsetAnimationSpec)
          ? this.animationSpec
          : animationSpec as AnimationSpec?,
      lastFailure: identical(lastFailure, _unsetOverlayFailure)
          ? this.lastFailure
          : lastFailure as AppFailure?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OverlaySessionState &&
            other.overlayState == overlayState &&
            other.animationSpec == animationSpec &&
            other.lastFailure == lastFailure;
  }

  @override
  int get hashCode => Object.hash(overlayState, animationSpec, lastFailure);
}

sealed class OverlayCommand implements ApplicationCommand {
  const OverlayCommand();
}

final class NavigateToOverlayPermissionCommand extends OverlayCommand {
  const NavigateToOverlayPermissionCommand();
}

final class PlayOverlaySoundCommand extends OverlayCommand {
  const PlayOverlaySoundCommand();
}

final class RequestOverlayFadeCommand extends OverlayCommand {
  const RequestOverlayFadeCommand({
    required this.animationSpec,
    required this.hideDelay,
  });

  final AnimationSpec animationSpec;
  final Duration hideDelay;
}

final class OverlayHiddenAfterFadeCommand extends OverlayCommand {
  const OverlayHiddenAfterFadeCommand();
}

final class RequestTransparencyRestoreCommand extends OverlayCommand {
  const RequestTransparencyRestoreCommand(this.delay);

  final Duration delay;
}

final class CancelTransparencyRestoreCommand extends OverlayCommand {
  const CancelTransparencyRestoreCommand();
}

final class OverlayFailureCommand extends OverlayCommand {
  const OverlayFailureCommand(this.failure);

  final AppFailure failure;
}

final class ConfigImportAppliedCommand extends OverlayCommand {
  const ConfigImportAppliedCommand();
}

final class OverlaySessionController
    extends AsyncNotifier<OverlaySessionState> {
  ScheduledTask? _hideTask;
  ScheduledTask? _restoreTask;
  int _lastKnownMinimizeDotSizeDp = SettingsDefaults.minimizeDotSizeDp;

  @override
  Future<OverlaySessionState> build() async {
    ref.onDispose(() {
      _hideTask?.cancel();
      _restoreTask?.cancel();
    });

    final settingsResult = await ref
        .read(settingsRepositoryProvider)
        .loadSettings();
    final settingsFailure = settingsResult.failureOrNull;
    final settings = settingsFailure == null
        ? settingsResult.valueOrNull!
        : Settings.defaults;
    _lastKnownMinimizeDotSizeDp = settings.minimizeDotSize;
    if (settingsFailure != null) {
      _emitFailure(settingsFailure);
    }
    return OverlaySessionState(
      overlayState: _buildDefaultState(settings),
      lastFailure: settingsFailure,
    );
  }

  Future<void> onRequestShow({required bool hasPermission}) async {
    if (!hasPermission) {
      _commandBus.emit(const NavigateToOverlayPermissionCommand());
      return;
    }

    final settings = await _loadSettings();
    if (settings == null) {
      return;
    }

    final lastStateResult = await ref
        .read(settingsRepositoryProvider)
        .loadLastOverlayState();
    final lastStateFailure = lastStateResult.failureOrNull;
    if (lastStateFailure != null) {
      _emitFailure(lastStateFailure);
      final current = await _requireState();
      state = AsyncData(current.copyWith(lastFailure: lastStateFailure));
      return;
    }

    _hideTask?.cancel();
    _hideTask = null;
    _restoreTask?.cancel();
    _restoreTask = null;

    final base = lastStateResult.valueOrNull ?? _buildDefaultState(settings);
    var updated = base
        .withCloseButtonPosition(settings.closeButtonPosition)
        .withSoundEnabled(settings.soundEnabled)
        .withKeepAliveEnabled(settings.keepAliveEnabled)
        .withTransparencyToggleEnabled(settings.transparencyToggleEnabled)
        .withTransparentMode(false)
        .withVisibility(true);
    updated = _clampPositionForCurrentMode(updated);
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: updated,
        animationSpec: null,
        lastFailure: null,
      ),
    );
  }

  Future<void> onRequestHide() async {
    await _startHideFlow();
  }

  Future<void> onCloseClick() async {
    await _startHideFlow();
  }

  Future<void> onOverlayHidden() async {
    _hideTask?.cancel();
    _hideTask = null;
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withVisibility(false),
      ),
    );
  }

  Future<void> onDragStart() async {
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withDragging(true),
        animationSpec: null,
      ),
    );
  }

  Future<void> onDragMove(int dxPx, int dyPx) async {
    final current = await _requireState();
    final moved = current.overlayState.withPosition(
      current.overlayState.xPx + dxPx,
      current.overlayState.yPx + dyPx,
    );
    final clamped = _clampPositionForCurrentMode(moved).withDragging(true);
    state = AsyncData(
      current.copyWith(overlayState: clamped, animationSpec: null),
    );
  }

  Future<void> onDragEnd() async {
    final current = await _requireState();
    var updated = current.overlayState.withDragging(false);
    final threshold = _screenInfo.dpToPx(
      OverlayBusinessConstants.snapThresholdDp,
    );
    updated = _snapToEdgeIfNeededForCurrentMode(updated, threshold);
    updated = _clampPositionForCurrentMode(updated);
    state = AsyncData(
      current.copyWith(
        overlayState: updated,
        animationSpec: const AnimationSpec(
          duration: OverlayAnimationDurations.move,
          type: OverlayAnimationType.move,
        ),
        lastFailure: null,
      ),
    );
    await _saveLastOverlayState(updated);
  }

  Future<void> onResizeStart() async {
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withResizing(true),
        animationSpec: null,
      ),
    );
  }

  Future<void> onResizeMove(int dwPx, int dhPx) async {
    final current = await _requireState();
    var resized = current.overlayState.withSize(
      current.overlayState.widthPx + dwPx,
      current.overlayState.heightPx + dhPx,
    );
    final bounds = _screenInfo.getCurrentBounds();
    final minWidth = _screenInfo.dpToPx(
      OverlayBusinessConstants.minOverlayWidthDp,
    );
    final minHeight = _screenInfo.dpToPx(
      OverlayBusinessConstants.minOverlayHeightDp,
    );
    resized = OverlayConstraints.clampSize(
      resized,
      bounds,
      minWidth,
      minHeight,
    );
    resized = OverlayConstraints.clampPosition(
      resized,
      bounds,
    ).withResizing(true);
    state = AsyncData(
      current.copyWith(overlayState: resized, animationSpec: null),
    );
  }

  Future<void> onResizeEnd() async {
    final current = await _requireState();
    final updated = current.overlayState.withResizing(false);
    state = AsyncData(
      current.copyWith(
        overlayState: updated,
        animationSpec: const AnimationSpec(
          duration: OverlayAnimationDurations.resize,
          type: OverlayAnimationType.resize,
        ),
        lastFailure: null,
      ),
    );
    await _saveLastOverlayState(updated);
  }

  Future<void> onBoundsChanged() async {
    final current = await _requireState();
    final bounds = _screenInfo.getCurrentBounds();
    final minWidth = _screenInfo.dpToPx(
      OverlayBusinessConstants.minOverlayWidthDp,
    );
    final minHeight = _screenInfo.dpToPx(
      OverlayBusinessConstants.minOverlayHeightDp,
    );
    var clamped = OverlayConstraints.clampSize(
      current.overlayState,
      bounds,
      minWidth,
      minHeight,
    );
    clamped = _clampPositionForCurrentMode(clamped);
    state = AsyncData(
      current.copyWith(
        overlayState: clamped,
        animationSpec: const AnimationSpec(
          duration: OverlayAnimationDurations.move,
          type: OverlayAnimationType.move,
        ),
      ),
    );
  }

  Future<void> onCloseButtonPositionChanged(
    CloseButtonPosition position,
  ) async {
    final settings = await _updateSettings(
      (settings) => settings.withCloseButtonPosition(position),
    );
    if (settings == null) {
      return;
    }
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withCloseButtonPosition(position),
        lastFailure: null,
      ),
    );
  }

  Future<void> onSoundEnabledChanged(bool enabled) async {
    final settings = await _updateSettings(
      (settings) => settings.withSoundEnabled(enabled),
    );
    if (settings == null) {
      return;
    }
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withSoundEnabled(enabled),
        lastFailure: null,
      ),
    );
  }

  Future<void> onKeepAliveChanged(bool enabled) async {
    final settings = await _updateSettings(
      (settings) => settings.withKeepAliveEnabled(enabled),
    );
    if (settings == null) {
      return;
    }
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withKeepAliveEnabled(enabled),
        lastFailure: null,
      ),
    );
  }

  Future<void> onTransparencyToggleEnabledChanged(bool enabled) async {
    final settings = await _updateSettings(
      (settings) => settings.withTransparencyToggleEnabled(enabled),
    );
    if (settings == null) {
      return;
    }
    final current = await _requireState();
    var updated = current.overlayState.withTransparencyToggleEnabled(enabled);
    if (!enabled && current.overlayState.transparentMode) {
      updated = updated.withTransparentMode(false);
      _cancelTransparencyRestore();
    }
    state = AsyncData(
      current.copyWith(overlayState: updated, lastFailure: null),
    );
  }

  Future<void> onTransparencyAutoRestoreEnabledChanged(bool enabled) async {
    final settings = await _updateSettings(
      (settings) => settings.withTransparencyAutoRestoreEnabled(enabled),
    );
    if (settings == null) {
      return;
    }
    if (!enabled) {
      _cancelTransparencyRestore();
    }
  }

  Future<void> onTransparencyAutoRestoreSecondsChanged(int seconds) async {
    final normalized = OverlaySettingsNormalizers.normalizeAutoRestoreSeconds(
      seconds,
    );
    final settings = await _updateSettings(
      (settings) => settings.withTransparencyAutoRestoreSeconds(normalized),
    );
    if (settings == null) {
      return;
    }
    final current = await _requireState();
    if (current.overlayState.transparentMode &&
        settings.transparencyAutoRestoreEnabled) {
      _scheduleTransparencyRestore(Duration(seconds: normalized));
    }
  }

  Future<void> onMinimizeDotSizeChanged(int sizeDp) async {
    final normalized = OverlaySettingsNormalizers.normalizeMinimizeDotSize(
      sizeDp,
    );
    final settings = await _updateSettings(
      (settings) => settings.withMinimizeDotSize(normalized),
    );
    if (settings == null) {
      return;
    }
    _lastKnownMinimizeDotSizeDp = normalized;
    final current = await _requireState();
    var updated = current.overlayState.withMinimized(
      current.overlayState.isMinimized,
    );
    if (updated.isMinimized) {
      updated = _clampPositionForCurrentMode(updated);
    }
    state = AsyncData(
      current.copyWith(overlayState: updated, lastFailure: null),
    );
    if (updated.visible) {
      await _saveLastOverlayState(updated);
    }
  }

  Future<void> onMinimizeDotRotateEnabledChanged(bool enabled) async {
    final settings = await _updateSettings(
      (settings) => settings.withMinimizeDotRotateEnabled(enabled),
    );
    if (settings == null) {
      return;
    }
    final current = await _requireState();
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withMinimized(
          current.overlayState.isMinimized,
        ),
        lastFailure: null,
      ),
    );
  }

  Future<void> onMinimizeToggleRequested() async {
    final current = await _requireState();
    var updated = current.overlayState.withMinimized(
      !current.overlayState.isMinimized,
    );
    updated = _clampPositionForCurrentMode(updated);
    state = AsyncData(
      current.copyWith(overlayState: updated, lastFailure: null),
    );
    if (updated.visible) {
      await _saveLastOverlayState(updated);
    }
  }

  Future<void> onTransparencyToggleRequested() async {
    final current = await _requireState();
    final settings = await _loadSettings();
    if (settings == null) {
      return;
    }
    if (!settings.transparencyToggleEnabled) {
      return;
    }
    final nextTransparent = !current.overlayState.transparentMode;
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withTransparentMode(nextTransparent),
        lastFailure: null,
      ),
    );
    if (nextTransparent) {
      if (settings.transparencyAutoRestoreEnabled) {
        final seconds = OverlaySettingsNormalizers.normalizeAutoRestoreSeconds(
          settings.transparencyAutoRestoreSeconds,
        );
        _scheduleTransparencyRestore(Duration(seconds: seconds));
      }
    } else {
      _cancelTransparencyRestore();
    }
  }

  Future<void> onTransparencyAutoRestoreTimeout() async {
    final current = await _requireState();
    if (!current.overlayState.transparentMode) {
      return;
    }
    _restoreTask = null;
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withTransparentMode(false),
      ),
    );
  }

  Future<void> applyImportedState({
    required OverlayState importedState,
    required Settings settings,
  }) async {
    final current = await _requireState();
    final saveResult = await ref
        .read(settingsRepositoryProvider)
        .saveImportedConfiguration(
          settings: settings,
          lastOverlayState: importedState,
        );
    final saveFailure = saveResult.failureOrNull;
    if (saveFailure != null) {
      _emitFailure(saveFailure);
      state = AsyncData(current.copyWith(lastFailure: saveFailure));
      return;
    }

    _lastKnownMinimizeDotSizeDp = settings.minimizeDotSize;
    final updated = OverlayState(
      widthPx: importedState.widthPx,
      heightPx: importedState.heightPx,
      xPx: importedState.xPx,
      yPx: importedState.yPx,
      visible: current.overlayState.visible,
      closeButtonPosition: settings.closeButtonPosition,
      soundEnabled: settings.soundEnabled,
      keepAliveEnabled: settings.keepAliveEnabled,
      transparencyToggleEnabled: settings.transparencyToggleEnabled,
      transparentMode: false,
      isDragging: current.overlayState.isDragging,
      isResizing: current.overlayState.isResizing,
      isMinimized: current.overlayState.isMinimized,
    );
    _cancelTransparencyRestore(emitCommand: false);
    state = AsyncData(
      current.copyWith(
        overlayState: updated,
        animationSpec: null,
        lastFailure: null,
      ),
    );
    _commandBus.emit(const ConfigImportAppliedCommand());
  }

  Future<void> _startHideFlow() async {
    final current = await _requireState();
    if (current.overlayState.soundEnabled) {
      _commandBus.emit(const PlayOverlaySoundCommand());
    }
    _restoreTask?.cancel();
    _restoreTask = null;
    _hideTask?.cancel();
    final fade = const AnimationSpec(
      duration: OverlayAnimationDurations.fadeOut,
      type: OverlayAnimationType.fade,
    );
    state = AsyncData(
      current.copyWith(
        overlayState: current.overlayState.withVisibility(true),
        animationSpec: fade,
        lastFailure: null,
      ),
    );
    _commandBus.emit(
      RequestOverlayFadeCommand(
        animationSpec: fade,
        hideDelay: OverlayAnimationDurations.hideCompletionDelay,
      ),
    );
    _hideTask = ref.read(controllerSchedulerProvider).schedule(
      OverlayAnimationDurations.hideCompletionDelay,
      () {
        final latest = state.value;
        if (latest == null) {
          return;
        }
        state = AsyncData(
          latest.copyWith(
            overlayState: latest.overlayState.withVisibility(false),
          ),
        );
        _hideTask = null;
        _commandBus.emit(const OverlayHiddenAfterFadeCommand());
      },
    );
  }

  Future<OverlaySessionState> _requireState() async {
    final value = state.value;
    if (value != null) {
      return value;
    }
    return future;
  }

  Future<Settings?> _loadSettings() async {
    final result = await ref.read(settingsRepositoryProvider).loadSettings();
    final failure = result.failureOrNull;
    if (failure != null) {
      _emitFailure(failure);
      final current = await _requireState();
      state = AsyncData(current.copyWith(lastFailure: failure));
      return null;
    }
    _lastKnownMinimizeDotSizeDp = result.valueOrNull!.minimizeDotSize;
    return result.valueOrNull!;
  }

  Future<Settings?> _updateSettings(
    Settings Function(Settings settings) update,
  ) async {
    final currentSettings = await _loadSettings();
    if (currentSettings == null) {
      return null;
    }
    final updated = update(currentSettings);
    final saveResult = await ref
        .read(settingsRepositoryProvider)
        .saveSettings(updated);
    final saveFailure = saveResult.failureOrNull;
    if (saveFailure != null) {
      _emitFailure(saveFailure);
      final current = await _requireState();
      state = AsyncData(current.copyWith(lastFailure: saveFailure));
      return null;
    }
    return updated;
  }

  Future<void> _saveLastOverlayState(OverlayState overlayState) async {
    final result = await ref
        .read(settingsRepositoryProvider)
        .saveLastOverlayState(overlayState);
    final failure = result.failureOrNull;
    if (failure != null) {
      _emitFailure(failure);
      final current = await _requireState();
      state = AsyncData(current.copyWith(lastFailure: failure));
    }
  }

  OverlayState _buildDefaultState(Settings settings) {
    final bounds = _screenInfo.getCurrentBounds();
    final width = _screenInfo.dpToPx(
      OverlayBusinessConstants.defaultOverlayWidthDp,
    );
    final height = _screenInfo.dpToPx(
      OverlayBusinessConstants.defaultOverlayHeightDp,
    );
    final x = bounds.safeInsets.left > (bounds.widthPx - width) ~/ 2
        ? bounds.safeInsets.left
        : (bounds.widthPx - width) ~/ 2;
    final y =
        bounds.safeInsets.top >
            (bounds.heightPx *
                    OverlayBusinessConstants.defaultVerticalPositionRatio)
                .toInt()
        ? bounds.safeInsets.top
        : (bounds.heightPx *
                  OverlayBusinessConstants.defaultVerticalPositionRatio)
              .toInt();
    return OverlayState.fromSettings(
      settings,
      widthPx: width,
      heightPx: height,
      xPx: x,
      yPx: y,
      visible: false,
    );
  }

  OverlayState _clampPositionForCurrentMode(OverlayState overlayState) {
    final bounds = _screenInfo.getCurrentBounds();
    if (!overlayState.isMinimized) {
      return OverlayConstraints.clampPosition(overlayState, bounds);
    }
    final dotSizePx = _getMinimizedDotSizePx();
    return OverlayConstraints.clampPositionWithSize(
      overlayState,
      bounds,
      dotSizePx,
      dotSizePx,
    );
  }

  OverlayState _snapToEdgeIfNeededForCurrentMode(
    OverlayState overlayState,
    int thresholdPx,
  ) {
    final bounds = _screenInfo.getCurrentBounds();
    if (!overlayState.isMinimized) {
      return OverlayConstraints.snapToEdgeIfNeeded(
        overlayState,
        bounds,
        thresholdPx,
      );
    }
    final dotSizePx = _getMinimizedDotSizePx();
    return OverlayConstraints.snapToEdgeWithSize(
      overlayState,
      bounds,
      dotSizePx,
      thresholdPx,
    );
  }

  int _getMinimizedDotSizePx() {
    final normalizedDp = OverlaySettingsNormalizers.normalizeMinimizeDotSize(
      _lastKnownMinimizeDotSizeDp,
    );
    return _screenInfo.dpToPx(normalizedDp);
  }

  void _scheduleTransparencyRestore(Duration delay) {
    _restoreTask?.cancel();
    _commandBus.emit(RequestTransparencyRestoreCommand(delay));
    _restoreTask = ref.read(controllerSchedulerProvider).schedule(delay, () {
      final latest = state.value;
      if (latest == null || !latest.overlayState.transparentMode) {
        _restoreTask = null;
        return;
      }
      state = AsyncData(
        latest.copyWith(
          overlayState: latest.overlayState.withTransparentMode(false),
        ),
      );
      _restoreTask = null;
    });
  }

  void _cancelTransparencyRestore({bool emitCommand = true}) {
    _restoreTask?.cancel();
    _restoreTask = null;
    if (emitCommand) {
      _commandBus.emit(const CancelTransparencyRestoreCommand());
    }
  }

  void _emitFailure(AppFailure failure) {
    _commandBus.emit(OverlayFailureCommand(failure));
  }

  OverlayScreenInfoProvider get _screenInfo {
    return ref.read(overlayScreenInfoProvider);
  }

  ApplicationCommandBus get _commandBus {
    return ref.read(applicationCommandBusProvider);
  }
}
