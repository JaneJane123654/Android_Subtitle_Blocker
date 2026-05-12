import '../../../core/error/errors.dart';
import '../../../core/platform/app_info_port.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/release_info.dart';
import '../domain/update_action_intent.dart';
import '../domain/update_availability.dart';
import '../domain/update_repository.dart';
import '../domain/version_name_comparator.dart';
import 'release_remote_data_source.dart';

final class UpdateRepositoryImpl implements UpdateRepository {
  const UpdateRepositoryImpl({
    required ReleaseRemoteDataSource remoteDataSource,
    required AppInfoPort appInfoPort,
    required SettingsRepository settingsRepository,
    this.iosStoreUrl,
  }) : _remoteDataSource = remoteDataSource,
       _appInfoPort = appInfoPort,
       _settingsRepository = settingsRepository;

  final ReleaseRemoteDataSource _remoteDataSource;
  final AppInfoPort _appInfoPort;
  final SettingsRepository _settingsRepository;
  final String? iosStoreUrl;

  @override
  Future<Result<UpdateAvailability>> checkForUpdates({
    required UpdateCheckTrigger trigger,
    required UpdateActionTarget target,
  }) async {
    final releaseResult = await _remoteDataSource.fetchLatestRelease();
    final releaseFailure = releaseResult.failureOrNull;
    if (releaseFailure != null) {
      return Result<UpdateAvailability>.failure(releaseFailure);
    }
    final releaseInfo = releaseResult.valueOrNull!;
    final releaseVersionValidation = _validateVersionString(
      releaseInfo.tagName,
      fieldName: 'remote release version',
    );
    if (releaseVersionValidation != null) {
      return Result<UpdateAvailability>.failure(releaseVersionValidation);
    }

    final versionResult = await _appInfoPort.currentVersionName();
    final versionFailure = versionResult.failureOrNull;
    if (versionFailure != null) {
      return Result<UpdateAvailability>.failure(versionFailure);
    }
    final currentVersionName = versionResult.valueOrNull!;
    final currentVersionValidation = _validateVersionString(
      currentVersionName,
      fieldName: 'current app version',
    );
    if (currentVersionValidation != null) {
      return Result<UpdateAvailability>.failure(currentVersionValidation);
    }

    final normalizedCurrentVersion = VersionNameComparator.normalize(
      currentVersionName,
    );
    if (!VersionNameComparator.isNewer(
      releaseInfo.normalizedVersion,
      normalizedCurrentVersion,
    )) {
      return Result<UpdateAvailability>.success(
        UpdateAvailability(
          status: trigger == UpdateCheckTrigger.manual
              ? UpdateAvailabilityStatus.upToDateWithUserMessage
              : UpdateAvailabilityStatus.upToDateSilently,
          trigger: trigger,
          currentVersionName: currentVersionName,
          normalizedCurrentVersion: normalizedCurrentVersion,
          releaseInfo: releaseInfo,
        ),
      );
    }

    final ignoredResult = await _settingsRepository.loadIgnoredUpdateVersion();
    final ignoredFailure = ignoredResult.failureOrNull;
    if (ignoredFailure != null) {
      return Result<UpdateAvailability>.failure(ignoredFailure);
    }
    final ignoredVersion = ignoredResult.valueOrNull;
    if (ignoredVersion != null) {
      final ignoredVersionValidation = _validateVersionString(
        ignoredVersion,
        fieldName: 'ignored update version',
      );
      if (ignoredVersionValidation != null) {
        return Result<UpdateAvailability>.failure(ignoredVersionValidation);
      }
    }
    if (ignoredVersion != null &&
        VersionNameComparator.compare(
              releaseInfo.normalizedVersion,
              ignoredVersion,
            ) <=
            0) {
      return Result<UpdateAvailability>.success(
        UpdateAvailability(
          status: UpdateAvailabilityStatus.suppressedByIgnoredVersion,
          trigger: trigger,
          currentVersionName: currentVersionName,
          normalizedCurrentVersion: normalizedCurrentVersion,
          releaseInfo: releaseInfo,
          ignoredVersion: ignoredVersion,
        ),
      );
    }

    final actionPlanResult = prepareUpdateAction(
      releaseInfo: releaseInfo,
      target: target,
    );
    final actionPlanFailure = actionPlanResult.failureOrNull;
    if (actionPlanFailure != null) {
      return Result<UpdateAvailability>.failure(actionPlanFailure);
    }

    return Result<UpdateAvailability>.success(
      UpdateAvailability(
        status: UpdateAvailabilityStatus.updateAvailable,
        trigger: trigger,
        currentVersionName: currentVersionName,
        normalizedCurrentVersion: normalizedCurrentVersion,
        releaseInfo: releaseInfo,
        ignoredVersion: ignoredVersion,
        actionPlan: actionPlanResult.valueOrNull!,
      ),
    );
  }

  Result<UpdateActionPlan> prepareUpdateAction({
    required ReleaseInfo releaseInfo,
    required UpdateActionTarget target,
  }) {
    return switch (target) {
      UpdateActionTarget.android => _prepareAndroidAction(releaseInfo),
      UpdateActionTarget.ios => _prepareIosAction(releaseInfo),
      UpdateActionTarget.releasePageOnly => _prepareReleasePageAction(
        releaseInfo,
        degradedBecause: null,
      ),
    };
  }

  Result<UpdateActionPlan> _prepareAndroidAction(ReleaseInfo releaseInfo) {
    final apkUrl = releaseInfo.androidPackageUrl;
    if (apkUrl != null && apkUrl.trim().isNotEmpty) {
      return Result<UpdateActionPlan>.success(
        UpdateActionPlan(
          intent: DownloadAndroidPackageIntent(
            packageUrl: apkUrl,
            fallbackReleasePageUrl: _blankToNull(releaseInfo.releasePageUrl),
          ),
        ),
      );
    }
    return _prepareReleasePageAction(
      releaseInfo,
      degradedBecause: const ReleaseAssetFailure(
        message: 'No Android APK asset exists in the latest release.',
        assetPattern: '*.apk',
      ),
    );
  }

  Result<UpdateActionPlan> _prepareIosAction(ReleaseInfo releaseInfo) {
    final storeUrl = _blankToNull(iosStoreUrl);
    if (storeUrl != null) {
      return Result<UpdateActionPlan>.success(
        UpdateActionPlan(intent: OpenIosStorePageIntent(storeUrl)),
      );
    }
    return _prepareReleasePageAction(releaseInfo, degradedBecause: null);
  }

  Result<UpdateActionPlan> _prepareReleasePageAction(
    ReleaseInfo releaseInfo, {
    required AppFailure? degradedBecause,
  }) {
    final releasePageUrl = _blankToNull(releaseInfo.releasePageUrl);
    if (releasePageUrl == null) {
      return const Result<UpdateActionPlan>.failure(
        ExternalLauncherFailure(
          message: 'No release page URL is available for update fallback.',
        ),
      );
    }
    return Result<UpdateActionPlan>.success(
      UpdateActionPlan(
        intent: OpenReleasePageIntent(releasePageUrl),
        degradedBecause: degradedBecause,
      ),
    );
  }
}

ReleaseDataFailure? _validateVersionString(
  String? version, {
  required String fieldName,
}) {
  if (version == null || version.trim().isEmpty) {
    return ReleaseDataFailure(message: '$fieldName is empty.');
  }
  if (!_containsDigit(version)) {
    return ReleaseDataFailure(message: '$fieldName is malformed.');
  }
  return null;
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value;
}

bool _containsDigit(String value) {
  for (var i = 0; i < value.length; i++) {
    final codeUnit = value.codeUnitAt(i);
    if (codeUnit >= 48 && codeUnit <= 57) {
      return true;
    }
  }
  return false;
}
