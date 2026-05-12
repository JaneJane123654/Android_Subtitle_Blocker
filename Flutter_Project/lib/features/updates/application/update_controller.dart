import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/application_command_bus.dart';
import '../../../core/error/errors.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/update_action_intent.dart';
import '../domain/update_availability.dart';
import '../domain/update_repository.dart';

const Object _unsetUpdateFailure = Object();

final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  throw UnimplementedError(
    'updateRepositoryProvider must be overridden by the app bootstrap.',
  );
});

final updateControllerProvider =
    AsyncNotifierProvider<UpdateController, UpdateControllerState>(
      UpdateController.new,
    );

final class UpdateControllerState {
  const UpdateControllerState({
    this.checking = false,
    this.lastAvailability,
    this.lastFailure,
  });

  final bool checking;
  final UpdateAvailability? lastAvailability;
  final AppFailure? lastFailure;

  UpdateControllerState copyWith({
    bool? checking,
    UpdateAvailability? lastAvailability,
    Object? lastFailure = _unsetUpdateFailure,
  }) {
    return UpdateControllerState(
      checking: checking ?? this.checking,
      lastAvailability: lastAvailability ?? this.lastAvailability,
      lastFailure: identical(lastFailure, _unsetUpdateFailure)
          ? this.lastFailure
          : lastFailure as AppFailure?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpdateControllerState &&
            other.checking == checking &&
            other.lastAvailability == lastAvailability &&
            other.lastFailure == lastFailure;
  }

  @override
  int get hashCode => Object.hash(checking, lastAvailability, lastFailure);
}

sealed class UpdateCommand implements ApplicationCommand {
  const UpdateCommand();
}

final class ShowUpdateCheckingCommand extends UpdateCommand {
  const ShowUpdateCheckingCommand(this.trigger);

  final UpdateCheckTrigger trigger;
}

final class ShowUpdateAlreadyCheckingCommand extends UpdateCommand {
  const ShowUpdateAlreadyCheckingCommand();
}

final class ShowUpdateCheckFailedCommand extends UpdateCommand {
  const ShowUpdateCheckFailedCommand({
    required this.failure,
    required this.trigger,
  });

  final AppFailure failure;
  final UpdateCheckTrigger trigger;
}

final class ShowUpdateUpToDateCommand extends UpdateCommand {
  const ShowUpdateUpToDateCommand(this.availability);

  final UpdateAvailability availability;
}

final class ShowUpdateIgnoredUntilNewerCommand extends UpdateCommand {
  const ShowUpdateIgnoredUntilNewerCommand(this.availability);

  final UpdateAvailability availability;
}

final class ShowUpdateDialogCommand extends UpdateCommand {
  const ShowUpdateDialogCommand(this.availability);

  final UpdateAvailability availability;
}

final class LaunchUpdateActionCommand extends UpdateCommand {
  const LaunchUpdateActionCommand(this.actionPlan);

  final UpdateActionPlan actionPlan;
}

final class ShowUpdateIgnoreSetCommand extends UpdateCommand {
  const ShowUpdateIgnoreSetCommand(this.ignoredVersion);

  final String ignoredVersion;
}

final class UpdateController extends AsyncNotifier<UpdateControllerState> {
  @override
  Future<UpdateControllerState> build() async {
    return const UpdateControllerState();
  }

  Future<void> checkForUpdates({
    required UpdateCheckTrigger trigger,
    required UpdateActionTarget target,
  }) async {
    final current = await _requireState();
    if (current.checking) {
      if (trigger == UpdateCheckTrigger.manual) {
        _commandBus.emit(const ShowUpdateAlreadyCheckingCommand());
      }
      return;
    }

    state = AsyncData(current.copyWith(checking: true, lastFailure: null));
    if (trigger == UpdateCheckTrigger.manual) {
      _commandBus.emit(ShowUpdateCheckingCommand(trigger));
    }

    final result = await ref
        .read(updateRepositoryProvider)
        .checkForUpdates(trigger: trigger, target: target);
    final failure = result.failureOrNull;
    if (failure != null) {
      final latest = await _requireState();
      state = AsyncData(latest.copyWith(checking: false, lastFailure: failure));
      if (trigger == UpdateCheckTrigger.manual) {
        _commandBus.emit(
          ShowUpdateCheckFailedCommand(failure: failure, trigger: trigger),
        );
      }
      return;
    }

    final availability = result.valueOrNull!;
    final latest = await _requireState();
    state = AsyncData(
      latest.copyWith(
        checking: false,
        lastAvailability: availability,
        lastFailure: null,
      ),
    );
    _emitAvailabilityCommand(availability);
  }

  Future<void> acceptAvailableUpdate() async {
    final current = await _requireState();
    final availability = current.lastAvailability;
    final actionPlan = availability?.actionPlan;
    if (availability == null ||
        availability.status != UpdateAvailabilityStatus.updateAvailable ||
        actionPlan == null) {
      return;
    }

    final saveResult = await ref
        .read(settingsRepositoryProvider)
        .saveIgnoredUpdateVersion(null);
    final saveFailure = saveResult.failureOrNull;
    if (saveFailure != null) {
      state = AsyncData(current.copyWith(lastFailure: saveFailure));
      _commandBus.emit(
        ShowUpdateCheckFailedCommand(
          failure: saveFailure,
          trigger: availability.trigger,
        ),
      );
      return;
    }

    _commandBus.emit(LaunchUpdateActionCommand(actionPlan));
  }

  Future<void> remindOnNextVersion() async {
    final current = await _requireState();
    final availability = current.lastAvailability;
    final releaseInfo = availability?.releaseInfo;
    if (availability == null ||
        availability.status != UpdateAvailabilityStatus.updateAvailable ||
        releaseInfo == null) {
      return;
    }

    final ignoredVersion = releaseInfo.normalizedVersion;
    final saveResult = await ref
        .read(settingsRepositoryProvider)
        .saveIgnoredUpdateVersion(ignoredVersion);
    final saveFailure = saveResult.failureOrNull;
    if (saveFailure != null) {
      state = AsyncData(current.copyWith(lastFailure: saveFailure));
      _commandBus.emit(
        ShowUpdateCheckFailedCommand(
          failure: saveFailure,
          trigger: availability.trigger,
        ),
      );
      return;
    }

    _commandBus.emit(ShowUpdateIgnoreSetCommand(ignoredVersion));
  }

  void _emitAvailabilityCommand(UpdateAvailability availability) {
    switch (availability.status) {
      case UpdateAvailabilityStatus.upToDateSilently:
        return;
      case UpdateAvailabilityStatus.upToDateWithUserMessage:
        _commandBus.emit(ShowUpdateUpToDateCommand(availability));
        return;
      case UpdateAvailabilityStatus.suppressedByIgnoredVersion:
        if (availability.trigger == UpdateCheckTrigger.manual) {
          _commandBus.emit(ShowUpdateIgnoredUntilNewerCommand(availability));
        }
        return;
      case UpdateAvailabilityStatus.updateAvailable:
        _commandBus.emit(ShowUpdateDialogCommand(availability));
        return;
    }
  }

  Future<UpdateControllerState> _requireState() async {
    final value = state.value;
    if (value != null) {
      return value;
    }
    return future;
  }

  ApplicationCommandBus get _commandBus {
    return ref.read(applicationCommandBusProvider);
  }
}
