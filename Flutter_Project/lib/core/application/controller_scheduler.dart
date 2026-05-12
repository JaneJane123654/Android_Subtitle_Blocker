import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final controllerSchedulerProvider = Provider<ControllerScheduler>((ref) {
  return const TimerControllerScheduler();
});

abstract interface class ControllerScheduler {
  ScheduledTask schedule(Duration delay, void Function() callback);
}

abstract interface class ScheduledTask {
  void cancel();
}

final class TimerControllerScheduler implements ControllerScheduler {
  const TimerControllerScheduler();

  @override
  ScheduledTask schedule(Duration delay, void Function() callback) {
    return _TimerScheduledTask(Timer(delay, callback));
  }
}

final class _TimerScheduledTask implements ScheduledTask {
  _TimerScheduledTask(this._timer);

  Timer? _timer;

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
