import 'package:subtitle_blocker_flutter_refactor/core/error/errors.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('success exposes value and maps without a failure', () {
      const result = Result<int>.success(7);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
      expect(result.map((value) => value + 1).valueOrNull, 8);
      expect(result.fold((failure) => -1, (value) => value), 7);
    });

    test('failure exposes typed AppFailure and keeps category visible', () {
      const failure = JsonParseFailure(message: 'invalid config');
      const result = Result<int>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
      expect(result.getOrElse((failure) => 42), 42);
      expect(result.failureOrNull, isA<JsonParseFailure>());
      expect(result.failureOrNull?.category, 'json_parse');
    });
  });

  group('AppFailure', () {
    test('covers mandatory external boundary failure categories', () {
      const failures = <AppFailure>[
        StorageReadFailure(),
        StorageWriteFailure(),
        JsonParseFailure(),
        ConfigValidationFailure(),
        ConfigTransferFailure(),
        ClipboardFailure(),
        NetworkFailure(),
        PermissionDeniedFailure(),
        UnsupportedPlatformFailure(),
        InstallerFailure(),
        ExternalLauncherFailure(),
      ];

      expect(failures.map((failure) => failure.category), <String>[
        'storage_read',
        'storage_write',
        'json_parse',
        'config_validation',
        'config_transfer',
        'clipboard',
        'network',
        'permission_denied',
        'unsupported_platform',
        'installer',
        'external_launcher',
      ]);
    });
  });
}
