import '../../../core/error/errors.dart';
import '../../../core/platform/clipboard_text_port.dart';
import '../../../core/platform/share_text_port.dart';
import '../../overlay/domain/overlay_state.dart';
import 'config_transfer_payload.dart';
import 'config_transfer_repository.dart';

final class ConfigTransferClipboardService {
  const ConfigTransferClipboardService({
    required ConfigTransferRepository repository,
    required ClipboardTextPort clipboardPort,
    ShareTextPort? sharePort,
  }) : _repository = repository,
       _clipboardPort = clipboardPort,
       _sharePort = sharePort;

  final ConfigTransferRepository _repository;
  final ClipboardTextPort _clipboardPort;
  final ShareTextPort? _sharePort;

  Future<Result<String>> exportToClipboard({
    OverlayState? currentRuntimeState,
  }) async {
    final exportResult = await _repository.exportConfig(
      currentRuntimeState: currentRuntimeState,
    );
    final exportFailure = exportResult.failureOrNull;
    if (exportFailure != null) {
      return Result<String>.failure(exportFailure);
    }

    final payload = exportResult.valueOrNull!;
    final writeResult = await _clipboardPort.writeText(
      label: ConfigTransferPayload.clipboardLabel,
      text: payload,
    );
    final writeFailure = writeResult.failureOrNull;
    if (writeFailure != null) {
      return Result<String>.failure(writeFailure);
    }
    return Result<String>.success(payload);
  }

  Future<Result<ConfigImportResult>> importFromClipboard({
    OverlayState? currentRuntimeState,
  }) async {
    final readResult = await _clipboardPort.readText();
    final readFailure = readResult.failureOrNull;
    if (readFailure != null) {
      return Result<ConfigImportResult>.failure(readFailure);
    }

    final payload = readResult.valueOrNull;
    if (payload == null || payload.trim().isEmpty) {
      return const Result<ConfigImportResult>.failure(
        ClipboardFailure(message: 'Clipboard does not contain config text.'),
      );
    }
    return _repository.importConfig(
      payload,
      currentRuntimeState: currentRuntimeState,
    );
  }

  Future<Result<String>> shareExport({
    OverlayState? currentRuntimeState,
    String? subject,
  }) async {
    if (_sharePort == null) {
      return const Result<String>.failure(
        PlatformFailure(message: 'No share port was provided.'),
      );
    }

    final exportResult = await _repository.exportConfig(
      currentRuntimeState: currentRuntimeState,
    );
    final exportFailure = exportResult.failureOrNull;
    if (exportFailure != null) {
      return Result<String>.failure(exportFailure);
    }

    final payload = exportResult.valueOrNull!;
    final shareResult = await _sharePort.shareText(
      text: payload,
      subject: subject,
    );
    final shareFailure = shareResult.failureOrNull;
    if (shareFailure != null) {
      return Result<String>.failure(shareFailure);
    }
    return Result<String>.success(payload);
  }
}
