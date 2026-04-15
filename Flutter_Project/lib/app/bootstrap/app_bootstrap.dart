/// Centralizes asynchronous startup work so `main.dart` stays narrow and
/// future shell concerns such as Hive, dependency registration, and generated
/// platform bindings can be added without rewriting the entry point.
final class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {}
}
