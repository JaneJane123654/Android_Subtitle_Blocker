import '../../../core/error/errors.dart';
import '../../overlay/domain/overlay_state.dart';
import 'settings.dart';

abstract interface class SettingsRepository {
  Future<Result<Settings>> loadSettings();

  Future<Result<void>> saveSettings(Settings settings);

  Future<Result<OverlayState?>> loadLastOverlayState();

  Future<Result<void>> saveLastOverlayState(OverlayState state);

  Future<Result<String?>> loadIgnoredUpdateVersion();

  Future<Result<void>> saveIgnoredUpdateVersion(String? normalizedVersion);

  Future<Result<void>> saveImportedConfiguration({
    required Settings settings,
    required OverlayState lastOverlayState,
  });
}
