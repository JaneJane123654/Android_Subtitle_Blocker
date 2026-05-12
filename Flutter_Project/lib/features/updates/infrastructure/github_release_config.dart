final class GitHubReleaseConfig {
  const GitHubReleaseConfig({
    required this.owner,
    required this.repository,
    this.apiBaseUrl = 'https://api.github.com',
    this.userAgent = 'subtitle-blocker-android',
    this.connectTimeout = const Duration(seconds: 10),
    this.readTimeout = const Duration(seconds: 15),
  });

  static const GitHubReleaseConfig legacyDefault = GitHubReleaseConfig(
    owner: 'JaneJane123654',
    repository: 'zimuzhedang',
  );

  static const GitHubReleaseConfig requiredProductConfiguration =
      GitHubReleaseConfig(owner: '', repository: '');

  final String owner;
  final String repository;
  final String apiBaseUrl;
  final String userAgent;
  final Duration connectTimeout;
  final Duration readTimeout;

  bool get isConfigured {
    return owner.trim().isNotEmpty &&
        repository.trim().isNotEmpty &&
        apiBaseUrl.trim().isNotEmpty;
  }

  Uri get latestReleaseUri {
    final base = Uri.parse(apiBaseUrl);
    return base.replace(
      pathSegments: <String>[
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        'repos',
        owner,
        repository,
        'releases',
        'latest',
      ],
    );
  }

  Map<String, String> get headers {
    return <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': userAgent,
    };
  }
}
