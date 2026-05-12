import 'version_name_comparator.dart';

final class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.browserDownloadUrl});

  final String name;
  final String browserDownloadUrl;

  bool get isAndroidPackage {
    return name.toLowerCase().endsWith('.apk') &&
        browserDownloadUrl.trim().isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReleaseAsset &&
            other.name == name &&
            other.browserDownloadUrl == browserDownloadUrl;
  }

  @override
  int get hashCode => Object.hash(name, browserDownloadUrl);
}

final class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.normalizedVersion,
    required this.assets,
    this.androidPackageUrl,
    this.releasePageUrl,
    this.publishedAt,
    this.notes,
  });

  factory ReleaseInfo.fromLegacyFields({
    required String tagName,
    String? apkDownloadUrl,
    String? releasePageUrl,
    DateTime? publishedAt,
    String? notes,
    List<ReleaseAsset> assets = const <ReleaseAsset>[],
  }) {
    return ReleaseInfo(
      tagName: tagName,
      normalizedVersion: VersionNameComparator.normalize(tagName),
      androidPackageUrl: _blankToNull(apkDownloadUrl),
      releasePageUrl: _blankToNull(releasePageUrl),
      publishedAt: publishedAt,
      notes: _blankToNull(notes),
      assets: List<ReleaseAsset>.unmodifiable(assets),
    );
  }

  final String tagName;
  final String normalizedVersion;
  final String? androidPackageUrl;
  final String? releasePageUrl;
  final DateTime? publishedAt;
  final String? notes;
  final List<ReleaseAsset> assets;

  String get displayVersion {
    if (tagName.trim().isNotEmpty) {
      return tagName;
    }
    return normalizedVersion;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReleaseInfo &&
            other.tagName == tagName &&
            other.normalizedVersion == normalizedVersion &&
            other.androidPackageUrl == androidPackageUrl &&
            other.releasePageUrl == releasePageUrl &&
            other.publishedAt == publishedAt &&
            other.notes == notes &&
            _listsEqual(other.assets, assets);
  }

  @override
  int get hashCode {
    return Object.hash(
      tagName,
      normalizedVersion,
      androidPackageUrl,
      releasePageUrl,
      publishedAt,
      notes,
      Object.hashAll(assets),
    );
  }
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value;
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
