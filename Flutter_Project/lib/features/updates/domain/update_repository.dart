import '../../../core/error/errors.dart';
import 'update_action_intent.dart';
import 'update_availability.dart';

abstract interface class UpdateRepository {
  Future<Result<UpdateAvailability>> checkForUpdates({
    required UpdateCheckTrigger trigger,
    required UpdateActionTarget target,
  });
}
