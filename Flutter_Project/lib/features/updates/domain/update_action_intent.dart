import '../../../core/error/errors.dart';

enum UpdateActionTarget { android, ios, releasePageOnly }

sealed class UpdateActionIntent {
  const UpdateActionIntent();
}

final class DownloadAndroidPackageIntent extends UpdateActionIntent {
  const DownloadAndroidPackageIntent({
    required this.packageUrl,
    this.fallbackReleasePageUrl,
  });

  final String packageUrl;
  final String? fallbackReleasePageUrl;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DownloadAndroidPackageIntent &&
            other.packageUrl == packageUrl &&
            other.fallbackReleasePageUrl == fallbackReleasePageUrl;
  }

  @override
  int get hashCode => Object.hash(packageUrl, fallbackReleasePageUrl);
}

final class OpenReleasePageIntent extends UpdateActionIntent {
  const OpenReleasePageIntent(this.releasePageUrl);

  final String releasePageUrl;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpenReleasePageIntent &&
            other.releasePageUrl == releasePageUrl;
  }

  @override
  int get hashCode => Object.hash(OpenReleasePageIntent, releasePageUrl);
}

final class OpenIosStorePageIntent extends UpdateActionIntent {
  const OpenIosStorePageIntent(this.storeUrl);

  final String storeUrl;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpenIosStorePageIntent && other.storeUrl == storeUrl;
  }

  @override
  int get hashCode => Object.hash(OpenIosStorePageIntent, storeUrl);
}

final class UpdateActionPlan {
  const UpdateActionPlan({required this.intent, this.degradedBecause});

  final UpdateActionIntent intent;
  final AppFailure? degradedBecause;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpdateActionPlan &&
            other.intent == intent &&
            other.degradedBecause == degradedBecause;
  }

  @override
  int get hashCode => Object.hash(intent, degradedBecause);
}
