import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/application_command_bus.dart';
import '../../../core/contracts/business_constants.dart';
import '../../../core/error/errors.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/close_button_position.dart';
import '../domain/settings.dart';
import '../domain/settings_repository.dart';
import 'keep_alive_permission_gate.dart';

const Object _unsetFailure = Object();

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden by the app bootstrap.',
  );
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsControllerState>(
      SettingsController.new,
    );

final class SettingsControllerState {
  const SettingsControllerState({required this.settings, this.lastFailure});

  factory SettingsControllerState.initial() {
    return const SettingsControllerState(settings: Settings.defaults);
  }

  final Settings settings;
  final AppFailure? lastFailure;

  SettingsControllerState copyWith({
    Settings? settings,
    Object? lastFailure = _unsetFailure,
  }) {
    return SettingsControllerState(
      settings: settings ?? this.settings,
      lastFailure: identical(lastFailure, _unsetFailure)
          ? this.lastFailure
          : lastFailure as AppFailure?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsControllerState &&
            other.settings == settings &&
            other.lastFailure == lastFailure;
  }

  @override
  int get hashCode => Object.hash(settings, lastFailure);
}

sealed class SettingsCommand implements ApplicationCommand {
  const SettingsCommand();
}

final class RequestPostNotificationsPermissionCommand extends SettingsCommand {
  const RequestPostNotificationsPermissionCommand();
}

final class SettingsPersistenceFailedCommand extends SettingsCommand {
  const SettingsPersistenceFailedCommand(this.failure);

  final AppFailure failure;
}

final class SettingsController extends AsyncNotifier<SettingsControllerState> {
  @override
  Future<SettingsControllerState> build() async {
    final result = await ref.read(settingsRepositoryProvider).loadSettings();
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(applicationCommandBusProvider)
          .emit(SettingsPersistenceFailedCommand(failure));
      return SettingsControllerState(
        settings: Settings.defaults,
        lastFailure: failure,
      );
    }
    return SettingsControllerState(settings: result.valueOrNull!);
  }

  Future<void> setCloseButtonPosition(CloseButtonPosition position) async {
    final current = await _requireState();
    await _save(current.settings.withCloseButtonPosition(position));
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final current = await _requireState();
    await _save(current.settings.withSoundEnabled(enabled));
  }

  Future<void> setKeepAliveEnabled(bool enabled) async {
    final current = await _requireState();
    if (enabled) {
      final permissionResult = await ref
          .read(keepAlivePermissionGateProvider)
          .hasRequiredNotificationPermission();
      final permissionFailure = permissionResult.failureOrNull;
      if (permissionFailure != null) {
        _emitFailure(permissionFailure);
        state = AsyncData(current.copyWith(lastFailure: permissionFailure));
        return;
      }
      if (!permissionResult.valueOrNull!) {
        ref
            .read(applicationCommandBusProvider)
            .emit(const RequestPostNotificationsPermissionCommand());
        await _save(current.settings.withKeepAliveEnabled(false));
        return;
      }
    }
    await _save(current.settings.withKeepAliveEnabled(enabled));
  }

  Future<void> onPostNotificationsPermissionResult(bool granted) async {
    final current = await _requireState();
    await _save(current.settings.withKeepAliveEnabled(granted));
  }

  Future<void> setAppLanguage(AppLanguage language) async {
    final current = await _requireState();
    await _save(current.settings.withAppLanguage(language));
  }

  Future<void> setTransparencyToggleEnabled(bool enabled) async {
    final current = await _requireState();
    await _save(current.settings.withTransparencyToggleEnabled(enabled));
  }

  Future<void> setTransparencyAutoRestoreEnabled(bool enabled) async {
    final current = await _requireState();
    await _save(current.settings.withTransparencyAutoRestoreEnabled(enabled));
  }

  Future<void> setTransparencyAutoRestoreSeconds(int seconds) async {
    final current = await _requireState();
    await _save(
      current.settings.withTransparencyAutoRestoreSeconds(
        normalizeAutoRestoreSeconds(seconds),
      ),
    );
  }

  Future<void> setTransparencyAutoRestoreSecondsText(String? raw) async {
    await setTransparencyAutoRestoreSeconds(parseAutoRestoreSeconds(raw));
  }

  Future<void> setMinimizeDotSize(int sizeDp) async {
    final current = await _requireState();
    await _save(
      current.settings.withMinimizeDotSize(normalizeMinimizeDotSize(sizeDp)),
    );
  }

  Future<void> setMinimizeDotRotateEnabled(bool enabled) async {
    final current = await _requireState();
    await _save(current.settings.withMinimizeDotRotateEnabled(enabled));
  }

  Future<void> setIgnoredUpdateVersion(String? normalizedVersion) async {
    final current = await _requireState();
    await _save(current.settings.withIgnoredUpdateVersion(normalizedVersion));
  }

  int parseAutoRestoreSeconds(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return TransparencyBusinessConstants.fallbackAutoRestoreSeconds;
    }
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) {
      return TransparencyBusinessConstants.fallbackAutoRestoreSeconds;
    }
    return parsed;
  }

  int normalizeAutoRestoreSeconds(int seconds) {
    return OverlaySettingsNormalizers.normalizeAutoRestoreSeconds(seconds);
  }

  int normalizeMinimizeDotSize(int sizeDp) {
    return OverlaySettingsNormalizers.normalizeMinimizeDotSize(sizeDp);
  }

  int progressToMinimizeDotSize(int progress) {
    final range =
        MinimizedDotBusinessConstants.maxSizeDp -
        MinimizedDotBusinessConstants.minSizeDp;
    final safeProgress = progress.clamp(0, range).toInt();
    return MinimizedDotBusinessConstants.minSizeDp + safeProgress;
  }

  int minimizeDotSizeToProgress(int sizeDp) {
    return normalizeMinimizeDotSize(sizeDp) -
        MinimizedDotBusinessConstants.minSizeDp;
  }

  Future<void> _save(Settings settings) async {
    final previous = await _requireState();
    final result = await ref
        .read(settingsRepositoryProvider)
        .saveSettings(settings);
    final failure = result.failureOrNull;
    if (failure != null) {
      _emitFailure(failure);
      state = AsyncData(previous.copyWith(lastFailure: failure));
      return;
    }
    state = AsyncData(previous.copyWith(settings: settings, lastFailure: null));
  }

  Future<SettingsControllerState> _requireState() async {
    final value = state.value;
    if (value != null) {
      return value;
    }
    return future;
  }

  void _emitFailure(AppFailure failure) {
    ref
        .read(applicationCommandBusProvider)
        .emit(SettingsPersistenceFailedCommand(failure));
  }
}

abstract final class OverlaySettingsNormalizers {
  static int normalizeAutoRestoreSeconds(int seconds) {
    if (seconds < TransparencyBusinessConstants.minAutoRestoreSeconds) {
      return TransparencyBusinessConstants.minAutoRestoreSeconds;
    }
    if (seconds > TransparencyBusinessConstants.maxAutoRestoreSeconds) {
      return TransparencyBusinessConstants.maxAutoRestoreSeconds;
    }
    return seconds;
  }

  static int normalizeMinimizeDotSize(int sizeDp) {
    return sizeDp
        .clamp(
          MinimizedDotBusinessConstants.minSizeDp,
          MinimizedDotBusinessConstants.maxSizeDp,
        )
        .toInt();
  }
}
