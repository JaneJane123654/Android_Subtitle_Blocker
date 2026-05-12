import 'package:share_plus/share_plus.dart';

import '../error/errors.dart';

abstract interface class ShareTextPort {
  Future<Result<void>> shareText({required String text, String? subject});
}

final class SharePlusTextPort implements ShareTextPort {
  const SharePlusTextPort();

  @override
  Future<Result<void>> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      return Result<void>.failure(
        PlatformFailure(
          message: 'Failed to share text.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
