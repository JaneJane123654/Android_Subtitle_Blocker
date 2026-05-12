import '../../../core/error/errors.dart';
import '../../overlay/domain/overlay_state.dart';
import '../../settings/domain/settings_repository.dart';
import 'config_transfer_payload.dart';
import 'config_transfer_repository.dart';

final class ConfigTransferService implements ConfigTransferRepository {
  const ConfigTransferService(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  @override
  Future<Result<String>> exportConfig({
    OverlayState? currentRuntimeState,
  }) async {
    try {
      final settingsResult = await _settingsRepository.loadSettings();
      final settingsFailure = settingsResult.failureOrNull;
      if (settingsFailure != null) {
        return Result<String>.failure(settingsFailure);
      }

      OverlayState? state = currentRuntimeState;
      if (state == null) {
        final savedStateResult = await _settingsRepository
            .loadLastOverlayState();
        final savedStateFailure = savedStateResult.failureOrNull;
        if (savedStateFailure != null) {
          return Result<String>.failure(savedStateFailure);
        }
        state = savedStateResult.valueOrNull;
      }

      if (state == null) {
        return const Result<String>.failure(
          ConfigTransferFailure(
            message: 'No overlay state is available for export.',
          ),
        );
      }

      final payload = ConfigTransferPayload.fromDomain(
        settings: settingsResult.valueOrNull!,
        overlayState: state,
      );
      return Result<String>.success(payload.encode());
    } catch (error, stackTrace) {
      return Result<String>.failure(
        ConfigTransferFailure(
          message: 'Failed to export config payload.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<ConfigImportResult>> importConfig(
    String payload, {
    OverlayState? currentRuntimeState,
  }) async {
    final payloadResult = ConfigTransferPayload.decode(payload);
    final payloadFailure = payloadResult.failureOrNull;
    if (payloadFailure != null) {
      return Result<ConfigImportResult>.failure(payloadFailure);
    }

    final ignoredVersionResult = await _settingsRepository
        .loadIgnoredUpdateVersion();
    final ignoredVersionFailure = ignoredVersionResult.failureOrNull;
    if (ignoredVersionFailure != null) {
      return Result<ConfigImportResult>.failure(ignoredVersionFailure);
    }

    final parsedPayload = payloadResult.valueOrNull!;
    final settings = parsedPayload.toSettings(
      ignoredUpdateVersion: ignoredVersionResult.valueOrNull,
    );
    final visible = currentRuntimeState?.visible ?? false;
    final stateForPersistence = parsedPayload.toImportedOverlayState(
      visible: visible,
      isDragging: false,
      isResizing: false,
      isMinimized: false,
    );
    final mergedState = parsedPayload.toImportedOverlayState(
      visible: visible,
      isDragging: currentRuntimeState?.isDragging ?? false,
      isResizing: currentRuntimeState?.isResizing ?? false,
      isMinimized: currentRuntimeState?.isMinimized ?? false,
    );

    final saveResult = await _settingsRepository.saveImportedConfiguration(
      settings: settings,
      lastOverlayState: stateForPersistence,
    );
    final saveFailure = saveResult.failureOrNull;
    if (saveFailure != null) {
      return Result<ConfigImportResult>.failure(saveFailure);
    }

    return Result<ConfigImportResult>.success(
      ConfigImportResult(settings: settings, overlayState: mergedState),
    );
  }
}
