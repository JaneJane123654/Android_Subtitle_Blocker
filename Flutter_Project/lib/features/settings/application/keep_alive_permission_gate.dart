import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/errors.dart';

final keepAlivePermissionGateProvider = Provider<KeepAlivePermissionGate>((
  ref,
) {
  return const AllowKeepAlivePermissionGate();
});

abstract interface class KeepAlivePermissionGate {
  Future<Result<bool>> hasRequiredNotificationPermission();
}

final class AllowKeepAlivePermissionGate implements KeepAlivePermissionGate {
  const AllowKeepAlivePermissionGate();

  @override
  Future<Result<bool>> hasRequiredNotificationPermission() async {
    return const Result<bool>.success(true);
  }
}
