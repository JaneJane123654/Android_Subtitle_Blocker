import 'package:package_info_plus/package_info_plus.dart';

import '../error/errors.dart';

abstract interface class AppInfoPort {
  Future<Result<String>> currentVersionName();
}

final class PackageInfoAppInfoPort implements AppInfoPort {
  const PackageInfoAppInfoPort();

  @override
  Future<Result<String>> currentVersionName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final versionName = info.version.trim();
      if (versionName.isEmpty) {
        return const Result<String>.failure(
          ReleaseDataFailure(message: 'Current app version is empty.'),
        );
      }
      return Result<String>.success(versionName);
    } catch (error, stackTrace) {
      return Result<String>.failure(
        PlatformFailure(
          message: 'Failed to read current app version.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
