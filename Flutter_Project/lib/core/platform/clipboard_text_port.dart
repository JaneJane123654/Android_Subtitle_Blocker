import 'package:flutter/services.dart';

import '../error/errors.dart';

abstract interface class ClipboardTextPort {
  Future<Result<String?>> readText();

  Future<Result<void>> writeText({required String label, required String text});
}

final class FlutterClipboardTextPort implements ClipboardTextPort {
  const FlutterClipboardTextPort();

  @override
  Future<Result<String?>> readText() async {
    try {
      final data = await Clipboard.getData('text/plain');
      return Result<String?>.success(data?.text);
    } catch (error, stackTrace) {
      return Result<String?>.failure(
        ClipboardFailure(
          message: 'Failed to read text from clipboard.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> writeText({
    required String label,
    required String text,
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      return Result<void>.failure(
        ClipboardFailure(
          message: 'Failed to write text to clipboard.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
