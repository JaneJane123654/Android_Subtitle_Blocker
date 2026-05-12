import '../../../core/contracts/business_constants.dart';
import '../../../shared/models/close_button_position.dart';
import '../../settings/domain/settings.dart';
import 'overlay_geometry.dart';

final class OverlayState {
  const OverlayState({
    this.widthPx = OverlayBusinessConstants.defaultOverlayWidthDp,
    this.heightPx = OverlayBusinessConstants.defaultOverlayHeightDp,
    this.xPx = 0,
    this.yPx = 0,
    this.visible = false,
    this.closeButtonPosition = SettingsDefaults.closeButtonPosition,
    this.soundEnabled = SettingsDefaults.soundEnabled,
    this.keepAliveEnabled = SettingsDefaults.keepAliveEnabled,
    this.transparencyToggleEnabled = SettingsDefaults.transparencyToggleEnabled,
    this.transparentMode = false,
    this.isDragging = false,
    this.isResizing = false,
    this.isMinimized = false,
  });

  factory OverlayState.fromSettings(
    Settings settings, {
    int widthPx = OverlayBusinessConstants.defaultOverlayWidthDp,
    int heightPx = OverlayBusinessConstants.defaultOverlayHeightDp,
    int xPx = 0,
    int yPx = 0,
    bool visible = false,
  }) {
    return OverlayState(
      widthPx: widthPx,
      heightPx: heightPx,
      xPx: xPx,
      yPx: yPx,
      visible: visible,
      closeButtonPosition: settings.closeButtonPosition,
      soundEnabled: settings.soundEnabled,
      keepAliveEnabled: settings.keepAliveEnabled,
      transparencyToggleEnabled: settings.transparencyToggleEnabled,
      transparentMode: false,
      isDragging: false,
      isResizing: false,
      isMinimized: false,
    );
  }

  final int widthPx;
  final int heightPx;
  final int xPx;
  final int yPx;
  final bool visible;
  final CloseButtonPosition closeButtonPosition;
  final bool soundEnabled;
  final bool keepAliveEnabled;
  final bool transparencyToggleEnabled;
  final bool transparentMode;
  final bool isDragging;
  final bool isResizing;
  final bool isMinimized;

  OverlaySize get size => OverlaySize(widthPx: widthPx, heightPx: heightPx);

  OverlayPosition get position => OverlayPosition(xPx: xPx, yPx: yPx);

  bool get isVisible => visible;

  bool get isTransparent => transparentMode;

  OverlayState copyWith({
    int? widthPx,
    int? heightPx,
    int? xPx,
    int? yPx,
    bool? visible,
    CloseButtonPosition? closeButtonPosition,
    bool? soundEnabled,
    bool? keepAliveEnabled,
    bool? transparencyToggleEnabled,
    bool? transparentMode,
    bool? isDragging,
    bool? isResizing,
    bool? isMinimized,
  }) {
    return OverlayState(
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      xPx: xPx ?? this.xPx,
      yPx: yPx ?? this.yPx,
      visible: visible ?? this.visible,
      closeButtonPosition: closeButtonPosition ?? this.closeButtonPosition,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
      transparencyToggleEnabled:
          transparencyToggleEnabled ?? this.transparencyToggleEnabled,
      transparentMode: transparentMode ?? this.transparentMode,
      isDragging: isDragging ?? this.isDragging,
      isResizing: isResizing ?? this.isResizing,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }

  OverlayState withMinimized(bool minimized) {
    return copyWith(isMinimized: minimized);
  }

  OverlayState withPosition(int xPx, int yPx) {
    return copyWith(xPx: xPx, yPx: yPx);
  }

  OverlayState withSize(int widthPx, int heightPx) {
    return copyWith(widthPx: widthPx, heightPx: heightPx);
  }

  OverlayState withVisibility(bool visible) {
    return copyWith(visible: visible);
  }

  OverlayState withCloseButtonPosition(CloseButtonPosition position) {
    return copyWith(closeButtonPosition: position);
  }

  OverlayState withSoundEnabled(bool enabled) {
    return copyWith(soundEnabled: enabled);
  }

  OverlayState withKeepAliveEnabled(bool enabled) {
    return copyWith(keepAliveEnabled: enabled);
  }

  OverlayState withTransparencyToggleEnabled(bool enabled) {
    return copyWith(transparencyToggleEnabled: enabled);
  }

  OverlayState withTransparentMode(bool enabled) {
    return copyWith(transparentMode: enabled);
  }

  OverlayState withDragging(bool dragging) {
    return copyWith(isDragging: dragging);
  }

  OverlayState withResizing(bool resizing) {
    return copyWith(isResizing: resizing);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OverlayState &&
            other.widthPx == widthPx &&
            other.heightPx == heightPx &&
            other.xPx == xPx &&
            other.yPx == yPx &&
            other.visible == visible &&
            other.closeButtonPosition == closeButtonPosition &&
            other.soundEnabled == soundEnabled &&
            other.keepAliveEnabled == keepAliveEnabled &&
            other.transparencyToggleEnabled == transparencyToggleEnabled &&
            other.transparentMode == transparentMode &&
            other.isDragging == isDragging &&
            other.isResizing == isResizing &&
            other.isMinimized == isMinimized;
  }

  @override
  int get hashCode {
    return Object.hash(
      widthPx,
      heightPx,
      xPx,
      yPx,
      visible,
      closeButtonPosition,
      soundEnabled,
      keepAliveEnabled,
      transparencyToggleEnabled,
      transparentMode,
      isDragging,
      isResizing,
      isMinimized,
    );
  }
}
