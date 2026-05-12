import 'package:subtitle_blocker_flutter_refactor/core/error/errors.dart';
import 'package:subtitle_blocker_flutter_refactor/core/platform/app_info_port.dart';
import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_state.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_repository.dart';
import 'package:subtitle_blocker_flutter_refactor/features/updates/domain/updates_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/updates/infrastructure/updates_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubReleaseDto', () {
    test('maps latest release and picks the first non-empty APK asset', () {
      final dto = GitHubReleaseDto.fromJson(<String, Object?>{
        'tag_name': 'v2.1.0-beta+7',
        'html_url': 'https://github.test/releases/tag/v2.1.0',
        'published_at': '2026-04-20T12:30:00Z',
        'body': 'Release notes',
        'assets': <Object?>[
          <String, Object?>{
            'name': 'subtitle-blocker.txt',
            'browser_download_url': 'https://github.test/readme.txt',
          },
          <String, Object?>{'name': 'broken.apk', 'browser_download_url': ''},
          <String, Object?>{
            'name': 'subtitle-blocker-latest.APK',
            'browser_download_url': 'https://github.test/app.apk',
          },
        ],
      });

      final release = dto.toDomain();

      expect(release.tagName, 'v2.1.0-beta+7');
      expect(release.normalizedVersion, '2.1.0');
      expect(release.releasePageUrl, 'https://github.test/releases/tag/v2.1.0');
      expect(release.androidPackageUrl, 'https://github.test/app.apk');
      expect(release.notes, 'Release notes');
      expect(release.publishedAt, DateTime.utc(2026, 4, 20, 12, 30));
    });

    test('maps missing assets to a null Android package URL', () {
      final dto = GitHubReleaseDto.fromJson(<String, Object?>{
        'tag_name': 'v3.0.0',
        'html_url': 'https://github.test/releases/tag/v3.0.0',
      });

      final release = dto.toDomain();

      expect(release.androidPackageUrl, isNull);
      expect(release.assets, isEmpty);
    });

    test('fails malformed or missing release tag instead of hiding it', () {
      expect(
        () => GitHubReleaseDto.fromJson(<String, Object?>{'tag_name': 'beta'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => GitHubReleaseDto.fromJson(<String, Object?>{}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('UpdateRepositoryImpl', () {
    test(
      'returns an Android package intent when a newer release has an APK',
      () async {
        final release = _release(
          tagName: 'v2.0.0',
          apkUrl: 'https://github.test/app.apk',
          releasePageUrl: 'https://github.test/releases/tag/v2.0.0',
        );
        final repository = _repository(
          release: release,
          currentVersionName: 'v1.9.9',
        );

        final result = await repository.checkForUpdates(
          trigger: UpdateCheckTrigger.automatic,
          target: UpdateActionTarget.android,
        );
        final availability = _unwrap(result);

        expect(availability.status, UpdateAvailabilityStatus.updateAvailable);
        expect(availability.normalizedCurrentVersion, '1.9.9');
        expect(availability.releaseInfo, release);
        expect(availability.shouldPromptUser, isTrue);
        final actionPlan = availability.actionPlan!;
        expect(actionPlan.degradedBecause, isNull);
        expect(actionPlan.intent, isA<DownloadAndroidPackageIntent>());
        final intent = actionPlan.intent as DownloadAndroidPackageIntent;
        expect(intent.packageUrl, 'https://github.test/app.apk');
        expect(
          intent.fallbackReleasePageUrl,
          'https://github.test/releases/tag/v2.0.0',
        );
      },
    );

    test(
      'manual and automatic up-to-date checks carry different semantics',
      () async {
        final release = _release(tagName: 'v1.0.0');
        final manualRepository = _repository(
          release: release,
          currentVersionName: '1.0.0',
        );
        final automaticRepository = _repository(
          release: release,
          currentVersionName: '1.0.0',
        );

        final manual = _unwrap(
          await manualRepository.checkForUpdates(
            trigger: UpdateCheckTrigger.manual,
            target: UpdateActionTarget.android,
          ),
        );
        final automatic = _unwrap(
          await automaticRepository.checkForUpdates(
            trigger: UpdateCheckTrigger.automatic,
            target: UpdateActionTarget.android,
          ),
        );

        expect(manual.status, UpdateAvailabilityStatus.upToDateWithUserMessage);
        expect(automatic.status, UpdateAvailabilityStatus.upToDateSilently);
      },
    );

    test('suppresses an ignored version equal to the latest release', () async {
      final repository = _repository(
        release: _release(tagName: 'v2.0.0'),
        currentVersionName: '1.0.0',
        ignoredVersion: '2.0.0',
      );

      final result = await repository.checkForUpdates(
        trigger: UpdateCheckTrigger.manual,
        target: UpdateActionTarget.android,
      );
      final availability = _unwrap(result);

      expect(
        availability.status,
        UpdateAvailabilityStatus.suppressedByIgnoredVersion,
      );
      expect(availability.ignoredVersion, '2.0.0');
      expect(availability.actionPlan, isNull);
    });

    test(
      'prompts again when a version higher than the ignored version appears',
      () async {
        final repository = _repository(
          release: _release(
            tagName: 'v2.0.1',
            apkUrl: 'https://github.test/app.apk',
          ),
          currentVersionName: '1.0.0',
          ignoredVersion: '2.0.0',
        );

        final result = await repository.checkForUpdates(
          trigger: UpdateCheckTrigger.automatic,
          target: UpdateActionTarget.android,
        );
        final availability = _unwrap(result);

        expect(availability.status, UpdateAvailabilityStatus.updateAvailable);
        expect(availability.ignoredVersion, '2.0.0');
        expect(
          availability.actionPlan!.intent,
          isA<DownloadAndroidPackageIntent>(),
        );
      },
    );

    test(
      'falls back to the release page when no Android APK asset exists',
      () async {
        final repository = _repository(
          release: _release(
            tagName: 'v2.0.0',
            releasePageUrl: 'https://github.test/releases/tag/v2.0.0',
          ),
          currentVersionName: '1.0.0',
        );

        final result = await repository.checkForUpdates(
          trigger: UpdateCheckTrigger.automatic,
          target: UpdateActionTarget.android,
        );
        final availability = _unwrap(result);

        expect(availability.status, UpdateAvailabilityStatus.updateAvailable);
        final actionPlan = availability.actionPlan!;
        expect(actionPlan.intent, isA<OpenReleasePageIntent>());
        expect(actionPlan.degradedBecause, isA<ReleaseAssetFailure>());
        final intent = actionPlan.intent as OpenReleasePageIntent;
        expect(
          intent.releasePageUrl,
          'https://github.test/releases/tag/v2.0.0',
        );
      },
    );

    test(
      'fails clearly when no APK and no release page can be prepared',
      () async {
        final repository = _repository(
          release: _release(tagName: 'v2.0.0'),
          currentVersionName: '1.0.0',
        );

        final result = await repository.checkForUpdates(
          trigger: UpdateCheckTrigger.manual,
          target: UpdateActionTarget.android,
        );

        expect(result.failureOrNull, isA<ExternalLauncherFailure>());
      },
    );

    test(
      'returns a typed failure for malformed current version names',
      () async {
        final repository = _repository(
          release: _release(tagName: 'v2.0.0'),
          currentVersionName: 'preview',
        );

        final result = await repository.checkForUpdates(
          trigger: UpdateCheckTrigger.manual,
          target: UpdateActionTarget.android,
        );

        expect(result.failureOrNull, isA<ReleaseDataFailure>());
      },
    );
  });
}

UpdateRepositoryImpl _repository({
  required ReleaseInfo release,
  required String currentVersionName,
  String? ignoredVersion,
}) {
  return UpdateRepositoryImpl(
    remoteDataSource: _FakeReleaseRemoteDataSource(release),
    appInfoPort: _FakeAppInfoPort(currentVersionName),
    settingsRepository: _FakeSettingsRepository(ignoredVersion),
  );
}

ReleaseInfo _release({
  required String tagName,
  String? apkUrl,
  String? releasePageUrl,
}) {
  return ReleaseInfo.fromLegacyFields(
    tagName: tagName,
    apkDownloadUrl: apkUrl,
    releasePageUrl: releasePageUrl,
  );
}

T _unwrap<T>(Result<T> result) {
  final failure = result.failureOrNull;
  if (failure != null) {
    fail('Expected success, got $failure');
  }
  return result.valueOrNull as T;
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
  _FakeSettingsRepository(this.ignoredVersion);

  String? ignoredVersion;

  @override
  Future<Result<Settings>> loadSettings() async {
    return Result<Settings>.success(
      Settings.defaultValue().withIgnoredUpdateVersion(ignoredVersion),
    );
  }

  @override
  Future<Result<void>> saveSettings(Settings settings) async {
    ignoredVersion = settings.ignoredUpdateVersion;
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
    if (ignoredVersion == null || ignoredVersion!.trim().isEmpty) {
      return const Result<String?>.success(null);
    }
    return Result<String?>.success(ignoredVersion);
  }

  @override
  Future<Result<void>> saveIgnoredUpdateVersion(
    String? normalizedVersion,
  ) async {
    ignoredVersion =
        normalizedVersion == null || normalizedVersion.trim().isEmpty
        ? null
        : normalizedVersion;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> saveImportedConfiguration({
    required Settings settings,
    required OverlayState lastOverlayState,
  }) async {
    ignoredVersion = settings.ignoredUpdateVersion;
    return const Result<void>.success(null);
  }
}
