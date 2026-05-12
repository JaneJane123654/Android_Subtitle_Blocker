import 'package:dio/dio.dart';

import '../../../core/error/errors.dart';
import '../domain/release_info.dart';
import 'github_release_config.dart';
import 'github_release_dtos.dart';
import 'release_remote_data_source.dart';

final class GitHubReleaseRemoteDataSource implements ReleaseRemoteDataSource {
  GitHubReleaseRemoteDataSource({
    required Dio dio,
    GitHubReleaseConfig config = GitHubReleaseConfig.legacyDefault,
  }) : _dio = dio,
       _config = config;

  factory GitHubReleaseRemoteDataSource.create({
    GitHubReleaseConfig config = GitHubReleaseConfig.legacyDefault,
  }) {
    return GitHubReleaseRemoteDataSource(
      config: config,
      dio: Dio(
        BaseOptions(
          connectTimeout: config.connectTimeout,
          receiveTimeout: config.readTimeout,
        ),
      ),
    );
  }

  final Dio _dio;
  final GitHubReleaseConfig _config;

  @override
  Future<Result<ReleaseInfo>> fetchLatestRelease() async {
    if (!_config.isConfigured) {
      return const Result<ReleaseInfo>.failure(
        ProductConfigurationFailure(
          message: 'GitHub release repository is not configured.',
          configurationName: 'github_release_repository',
        ),
      );
    }

    try {
      final response = await _dio.getUri<Object?>(
        _config.latestReleaseUri,
        options: Options(
          headers: _config.headers,
          receiveTimeout: _config.readTimeout,
        ),
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        return Result<ReleaseInfo>.failure(
          NetworkFailure(
            message: 'GitHub API http code=$statusCode',
            statusCode: statusCode,
          ),
        );
      }

      final data = response.data;
      if (data is! Map) {
        return Result<ReleaseInfo>.failure(
          JsonParseFailure(
            message: 'GitHub release response must be a JSON object.',
            cause: data,
          ),
        );
      }

      final dto = GitHubReleaseDto.fromJson(data.cast<String, Object?>());
      return Result<ReleaseInfo>.success(dto.toDomain());
    } on DioException catch (error, stackTrace) {
      return Result<ReleaseInfo>.failure(
        NetworkFailure(
          message: 'Failed to fetch latest GitHub release.',
          cause: error,
          stackTrace: stackTrace,
          statusCode: error.response?.statusCode,
        ),
      );
    } on FormatException catch (error, stackTrace) {
      return Result<ReleaseInfo>.failure(releaseDataFailure(error, stackTrace));
    } catch (error, stackTrace) {
      return Result<ReleaseInfo>.failure(
        JsonParseFailure(
          message: 'Failed to parse latest GitHub release response.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
