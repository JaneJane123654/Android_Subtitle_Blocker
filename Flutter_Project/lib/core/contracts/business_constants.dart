import '../../shared/models/app_language.dart';
import '../../shared/models/close_button_position.dart';

abstract final class OverlayBusinessConstants {
  static const int defaultOverlayWidthDp = 220;
  static const int defaultOverlayHeightDp = 80;
  static const int minOverlayWidthDp = 100;
  static const int minOverlayHeightDp = 40;
  static const double defaultVerticalPositionRatio = 0.65;
  static const double maxOverlayScreenFraction = 0.8;
  static const int snapThresholdDp = 15;
}

abstract final class OverlayAnimationDurations {
  static const Duration move = Duration(milliseconds: 150);
  static const Duration resize = Duration(milliseconds: 200);
  static const Duration fadeOut = Duration(milliseconds: 300);
  static const Duration hideCompletionDelay = Duration(milliseconds: 320);
}

abstract final class TransparencyBusinessConstants {
  static const int minAutoRestoreSeconds = 1;
  static const int maxAutoRestoreSeconds = 60;
  static const int fallbackAutoRestoreSeconds = 5;
}

abstract final class MinimizedDotBusinessConstants {
  static const int minSizeDp = 10;
  static const int maxSizeDp = 200;
  static const int defaultSizeDp = 40;
}

abstract final class SettingsDefaults {
  static const CloseButtonPosition closeButtonPosition =
      CloseButtonPosition.rightTop;
  static const AppLanguage appLanguage = AppLanguage.system;
  static const bool soundEnabled = false;
  static const bool keepAliveEnabled = false;
  static const bool transparencyToggleEnabled = true;
  static const bool transparencyAutoRestoreEnabled = false;
  static const int transparencyAutoRestoreSeconds =
      TransparencyBusinessConstants.fallbackAutoRestoreSeconds;
  static const int minimizeDotSizeDp =
      MinimizedDotBusinessConstants.defaultSizeDp;
  static const bool minimizeDotRotateEnabled = false;
  static const String? ignoredUpdateVersion = null;
}
