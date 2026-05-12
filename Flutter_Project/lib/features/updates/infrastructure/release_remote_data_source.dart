import '../../../core/error/errors.dart';
import '../domain/release_info.dart';

abstract interface class ReleaseRemoteDataSource {
  Future<Result<ReleaseInfo>> fetchLatestRelease();
}
