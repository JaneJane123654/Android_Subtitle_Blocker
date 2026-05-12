import '../../../core/error/errors.dart';
import '../../overlay/domain/overlay_state.dart';
import '../domain/settings.dart';
import '../domain/settings_repository.dart';
import 'hive_settings_data_source.dart';
import 'settings_persistence_models.dart';

final class HiveSettingsRepository implements SettingsRepository {
  const HiveSettingsRepository(this._dataSource);

  final HiveSettingsDataSource _dataSource;

  @override
  Future<Result<Settings>> loadSettings() async {
    try {
      final stored = _dataSource.readSettingsJson();
      if (stored == null) {
        return const Result<Settings>.success(Settings.defaults);
      }
      final record = PersistedSettingsRecord.fromJsonString(stored);
      return Result<Settings>.success(record.toDomain());
    } catch (error, stackTrace) {
      return Result<Settings>.failure(
        StorageReadFailure(
          message: 'Failed to load persisted settings.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    try {
      final record = PersistedSettingsRecord.fromDomain(settings);
      await _dataSource.writeSettingsJson(record.toJsonString());
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      return Result<void>.failure(
        StorageWriteFailure(
          message: 'Failed to save persisted settings.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<OverlayState?>> loadLastOverlayState() async {
    try {
      final stored = _dataSource.readOverlaySnapshotJson();
      if (stored == null) {
        return const Result<OverlayState?>.success(null);
      }
      final settingsResult = await loadSettings();
      final settingsFailure = settingsResult.failureOrNull;
      if (settingsFailure != null) {
        return Result<OverlayState?>.failure(settingsFailure);
      }
      final record = PersistedOverlaySnapshotRecord.fromJsonString(stored);
      return Result<OverlayState?>.success(
        record.toDomain(settingsResult.valueOrNull!),
      );
    } catch (error, stackTrace) {
      return Result<OverlayState?>.failure(
        StorageReadFailure(
          message: 'Failed to load the last overlay state.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> saveLastOverlayState(OverlayState state) async {
    try {
      final record = PersistedOverlaySnapshotRecord.fromDomain(state);
      await _dataSource.writeOverlaySnapshotJson(record.toJsonString());
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      return Result<void>.failure(
        StorageWriteFailure(
          message: 'Failed to save the last overlay state.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<String?>> loadIgnoredUpdateVersion() async {
    final settingsResult = await loadSettings();
    final failure = settingsResult.failureOrNull;
    if (failure != null) {
      return Result<String?>.failure(failure);
    }
    final value = settingsResult.valueOrNull!.ignoredUpdateVersion;
    if (value == null || value.trim().isEmpty) {
      return const Result<String?>.success(null);
    }
    return Result<String?>.success(value);
  }

  @override
  Future<Result<void>> saveIgnoredUpdateVersion(
    String? normalizedVersion,
  ) async {
    final settingsResult = await loadSettings();
    final failure = settingsResult.failureOrNull;
    if (failure != null) {
      return Result<void>.failure(failure);
    }
    final value = normalizedVersion == null || normalizedVersion.trim().isEmpty
        ? null
        : normalizedVersion;
    return saveSettings(
      settingsResult.valueOrNull!.withIgnoredUpdateVersion(value),
    );
  }

  @override
  Future<Result<void>> saveImportedConfiguration({
    required Settings settings,
    required OverlayState lastOverlayState,
  }) async {
    final previousSnapshot = _dataSource.captureSnapshot();
    try {
      final settingsRecord = PersistedSettingsRecord.fromDomain(settings);
      final overlayRecord = PersistedOverlaySnapshotRecord.fromDomain(
        lastOverlayState,
      );
      await _dataSource.writeSettingsJson(settingsRecord.toJsonString());
      await _dataSource.writeOverlaySnapshotJson(overlayRecord.toJsonString());
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      try {
        await _dataSource.restoreSnapshot(previousSnapshot);
      } catch (_) {
        // Preserve the original write failure, matching the legacy all-or-fail
        // import intent while avoiding a second exception from hiding it.
      }
      return Result<void>.failure(
        StorageWriteFailure(
          message: 'Failed to save imported configuration.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
