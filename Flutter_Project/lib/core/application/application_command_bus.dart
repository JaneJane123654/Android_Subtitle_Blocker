import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marker interface for controller one-shot work.
///
/// Controllers publish navigation, sound, permission, installer, and transient
/// feedback as stream events instead of storing them in durable state. This is
/// the Dart equivalent of the legacy `LiveData<OneShotEffect>` consumption
/// contract: each event is delivered once to active listeners and is not
/// replayed after rebuilds.
abstract interface class ApplicationCommand {
  const ApplicationCommand();
}

final applicationCommandBusProvider = Provider<ApplicationCommandBus>((ref) {
  final bus = ApplicationCommandBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final class ApplicationCommandBus {
  ApplicationCommandBus()
    : _controller = StreamController<ApplicationCommand>.broadcast(sync: true);

  final StreamController<ApplicationCommand> _controller;

  Stream<ApplicationCommand> get stream => _controller.stream;

  void emit(ApplicationCommand command) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(command);
  }

  void dispose() {
    _controller.close();
  }
}
