import '../../../core/error/errors.dart';
import '../../overlay/domain/overlay_state.dart';
import '../../settings/domain/settings.dart';

abstract interface class ConfigTransferRepository {
  Future<Result<String>> exportConfig({OverlayState? currentRuntimeState});

  Future<Result<ConfigImportResult>> importConfig(
    String payload, {
    OverlayState? currentRuntimeState,
  });
}

final class ConfigImportResult {
  const ConfigImportResult({
    required this.settings,
    required this.overlayState,
  });

  final Settings settings;
  final OverlayState overlayState;
}
