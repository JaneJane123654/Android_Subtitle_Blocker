import 'release_info.dart';
import 'update_action_intent.dart';

enum UpdateCheckTrigger { manual, automatic }

enum UpdateAvailabilityStatus {
  upToDateSilently,
  upToDateWithUserMessage,
  updateAvailable,
  suppressedByIgnoredVersion,
}

final class UpdateAvailability {
  const UpdateAvailability({
    required this.status,
    required this.trigger,
    required this.currentVersionName,
    required this.normalizedCurrentVersion,
    this.releaseInfo,
    this.ignoredVersion,
    this.actionPlan,
  });

  final UpdateAvailabilityStatus status;
  final UpdateCheckTrigger trigger;
  final String currentVersionName;
  final String normalizedCurrentVersion;
  final ReleaseInfo? releaseInfo;
  final String? ignoredVersion;
  final UpdateActionPlan? actionPlan;

  bool get shouldPromptUser {
    return status == UpdateAvailabilityStatus.updateAvailable;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpdateAvailability &&
            other.status == status &&
            other.trigger == trigger &&
            other.currentVersionName == currentVersionName &&
            other.normalizedCurrentVersion == normalizedCurrentVersion &&
            other.releaseInfo == releaseInfo &&
            other.ignoredVersion == ignoredVersion &&
            other.actionPlan == actionPlan;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      trigger,
      currentVersionName,
      normalizedCurrentVersion,
      releaseInfo,
      ignoredVersion,
      actionPlan,
    );
  }
}
