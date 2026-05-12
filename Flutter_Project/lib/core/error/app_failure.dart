sealed class AppFailure {
  const AppFailure({required this.message, this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  String get category;

  @override
  String toString() {
    final causeText = cause == null ? '' : ', cause: $cause';
    return '$category(message: $message$causeText)';
  }
}

final class StorageReadFailure extends AppFailure {
  const StorageReadFailure({
    super.message = 'Failed to read local storage.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'storage_read';
}

final class StorageWriteFailure extends AppFailure {
  const StorageWriteFailure({
    super.message = 'Failed to write local storage.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'storage_write';
}

final class JsonParseFailure extends AppFailure {
  const JsonParseFailure({
    super.message = 'Failed to parse JSON payload.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'json_parse';
}

final class ProductConfigurationFailure extends AppFailure {
  const ProductConfigurationFailure({
    super.message = 'Required product configuration is missing.',
    super.cause,
    super.stackTrace,
    this.configurationName,
  });

  final String? configurationName;

  @override
  String get category => 'product_configuration';
}

final class ReleaseDataFailure extends AppFailure {
  const ReleaseDataFailure({
    super.message = 'Release data is invalid.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'release_data';
}

final class ReleaseAssetFailure extends AppFailure {
  const ReleaseAssetFailure({
    super.message = 'Required release asset is unavailable.',
    super.cause,
    super.stackTrace,
    this.assetPattern,
  });

  final String? assetPattern;

  @override
  String get category => 'release_asset';
}

final class ConfigValidationFailure extends AppFailure {
  const ConfigValidationFailure({
    super.message = 'Config payload validation failed.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'config_validation';
}

final class ConfigTransferFailure extends AppFailure {
  const ConfigTransferFailure({
    super.message = 'Config transfer failed.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'config_transfer';
}

final class ClipboardFailure extends AppFailure {
  const ClipboardFailure({
    super.message = 'Clipboard operation failed.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'clipboard';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Network request failed.',
    super.cause,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;

  @override
  String get category => 'network';
}

final class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure({
    super.message = 'Required permission was denied.',
    super.cause,
    super.stackTrace,
    this.permissionName,
  });

  final String? permissionName;

  @override
  String get category => 'permission_denied';
}

final class UnsupportedPlatformFailure extends AppFailure {
  const UnsupportedPlatformFailure({
    super.message = 'The current platform does not support this behavior.',
    super.cause,
    super.stackTrace,
    this.platformName,
  });

  final String? platformName;

  @override
  String get category => 'unsupported_platform';
}

final class InstallerFailure extends AppFailure {
  const InstallerFailure({
    super.message = 'Installer launch failed.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'installer';
}

final class ExternalLauncherFailure extends AppFailure {
  const ExternalLauncherFailure({
    super.message = 'External launcher failed.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'external_launcher';
}

final class PlatformFailure extends AppFailure {
  const PlatformFailure({
    super.message = 'Platform operation failed.',
    super.cause,
    super.stackTrace,
  });

  @override
  String get category => 'platform';
}
