import '../../../core/error/errors.dart';
import '../domain/release_info.dart';
import '../domain/version_name_comparator.dart';

final class GitHubReleaseDto {
  const GitHubReleaseDto({
    required this.tagName,
    required this.htmlUrl,
    required this.assets,
    this.publishedAt,
    this.body,
  });

  factory GitHubReleaseDto.fromJson(Map<String, Object?> json) {
    final tagName = _stringOrDefault(json['tag_name'], '0');
    final normalizedVersion = VersionNameComparator.normalize(tagName);
    if (!_containsDigit(tagName) || normalizedVersion == '0') {
      throw const FormatException('release tag_name is missing or malformed');
    }

    final rawAssets = json['assets'];
    final assets = <GitHubReleaseAssetDto>[];
    if (rawAssets is Iterable<Object?>) {
      for (final rawAsset in rawAssets) {
        if (rawAsset is! Map) {
          continue;
        }
        assets.add(
          GitHubReleaseAssetDto.fromJson(rawAsset.cast<String, Object?>()),
        );
      }
    }

    return GitHubReleaseDto(
      tagName: tagName,
      htmlUrl: _nullableString(json['html_url']),
      publishedAt: _dateTimeOrNull(json['published_at']),
      body: _nullableString(json['body']),
      assets: List<GitHubReleaseAssetDto>.unmodifiable(assets),
    );
  }

  final String tagName;
  final String? htmlUrl;
  final DateTime? publishedAt;
  final String? body;
  final List<GitHubReleaseAssetDto> assets;

  ReleaseInfo toDomain() {
    final domainAssets = <ReleaseAsset>[
      for (final asset in assets)
        ReleaseAsset(
          name: asset.name,
          browserDownloadUrl: asset.browserDownloadUrl,
        ),
    ];
    return ReleaseInfo.fromLegacyFields(
      tagName: tagName,
      apkDownloadUrl: findApkDownloadUrl(assets),
      releasePageUrl: htmlUrl,
      publishedAt: publishedAt,
      notes: body,
      assets: domainAssets,
    );
  }

  static String? findApkDownloadUrl(List<GitHubReleaseAssetDto>? assets) {
    if (assets == null) {
      return null;
    }
    for (final item in assets) {
      final name = item.name;
      if (!name.toLowerCase().endsWith('.apk')) {
        continue;
      }
      final url = item.browserDownloadUrl;
      if (url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }
}

final class GitHubReleaseAssetDto {
  const GitHubReleaseAssetDto({
    required this.name,
    required this.browserDownloadUrl,
  });

  factory GitHubReleaseAssetDto.fromJson(Map<String, Object?> json) {
    return GitHubReleaseAssetDto(
      name: _stringOrDefault(json['name'], ''),
      browserDownloadUrl: _stringOrDefault(json['browser_download_url'], ''),
    );
  }

  final String name;
  final String browserDownloadUrl;
}

ReleaseDataFailure releaseDataFailure(Object error, StackTrace stackTrace) {
  return ReleaseDataFailure(
    message: 'Failed to map GitHub release data.',
    cause: error,
    stackTrace: stackTrace,
  );
}

String _stringOrDefault(Object? value, String defaultValue) {
  if (value == null) {
    return defaultValue;
  }
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final stringValue = value.toString();
  if (stringValue.trim().isEmpty) {
    return null;
  }
  return stringValue;
}

DateTime? _dateTimeOrNull(Object? value) {
  final stringValue = _nullableString(value);
  if (stringValue == null) {
    return null;
  }
  return DateTime.tryParse(stringValue);
}

bool _containsDigit(String value) {
  for (var i = 0; i < value.length; i++) {
    final codeUnit = value.codeUnitAt(i);
    if (codeUnit >= 48 && codeUnit <= 57) {
      return true;
    }
  }
  return false;
}
