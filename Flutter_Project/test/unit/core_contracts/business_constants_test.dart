import 'package:subtitle_blocker_flutter_refactor/core/contracts/contracts.dart';
import 'package:subtitle_blocker_flutter_refactor/shared/models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('OverlayBusinessConstants', () {
    test('locks documented overlay geometry defaults', () {
      expect(OverlayBusinessConstants.defaultOverlayWidthDp, 220);
      expect(OverlayBusinessConstants.defaultOverlayHeightDp, 80);
      expect(OverlayBusinessConstants.minOverlayWidthDp, 100);
      expect(OverlayBusinessConstants.minOverlayHeightDp, 40);
      expect(OverlayBusinessConstants.defaultVerticalPositionRatio, 0.65);
      expect(OverlayBusinessConstants.maxOverlayScreenFraction, 0.8);
      expect(OverlayBusinessConstants.snapThresholdDp, 15);
    });

    test('locks documented animation durations', () {
      expect(OverlayAnimationDurations.move.inMilliseconds, 150);
      expect(OverlayAnimationDurations.resize.inMilliseconds, 200);
      expect(OverlayAnimationDurations.fadeOut.inMilliseconds, 300);
      expect(OverlayAnimationDurations.hideCompletionDelay.inMilliseconds, 320);
    });

    test('locks documented transparency and minimized dot ranges', () {
      expect(TransparencyBusinessConstants.minAutoRestoreSeconds, 1);
      expect(TransparencyBusinessConstants.maxAutoRestoreSeconds, 60);
      expect(TransparencyBusinessConstants.fallbackAutoRestoreSeconds, 5);
      expect(MinimizedDotBusinessConstants.minSizeDp, 10);
      expect(MinimizedDotBusinessConstants.maxSizeDp, 200);
      expect(MinimizedDotBusinessConstants.defaultSizeDp, 40);
    });
  });

  group('SettingsDefaults', () {
    test('matches the legacy Settings.defaultValue contract', () {
      expect(
        SettingsDefaults.closeButtonPosition,
        CloseButtonPosition.rightTop,
      );
      expect(SettingsDefaults.appLanguage, AppLanguage.system);
      expect(SettingsDefaults.soundEnabled, isFalse);
      expect(SettingsDefaults.keepAliveEnabled, isFalse);
      expect(SettingsDefaults.transparencyToggleEnabled, isTrue);
      expect(SettingsDefaults.transparencyAutoRestoreEnabled, isFalse);
      expect(SettingsDefaults.transparencyAutoRestoreSeconds, 5);
      expect(SettingsDefaults.minimizeDotSizeDp, 40);
      expect(SettingsDefaults.minimizeDotRotateEnabled, isFalse);
      expect(SettingsDefaults.ignoredUpdateVersion, isNull);
    });
  });
}
