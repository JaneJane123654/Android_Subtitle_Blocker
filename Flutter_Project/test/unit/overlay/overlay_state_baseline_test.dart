import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/shared/models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('OverlayState', () {
    test('default baseline keeps documented size and hidden runtime flags', () {
      const state = OverlayState();

      expect(state.widthPx, 220);
      expect(state.heightPx, 80);
      expect(state.xPx, 0);
      expect(state.yPx, 0);
      expect(state.visible, isFalse);
      expect(state.closeButtonPosition, CloseButtonPosition.rightTop);
      expect(state.soundEnabled, isFalse);
      expect(state.keepAliveEnabled, isFalse);
      expect(state.transparencyToggleEnabled, isTrue);
      expect(state.transparentMode, isFalse);
      expect(state.isDragging, isFalse);
      expect(state.isResizing, isFalse);
      expect(state.isMinimized, isFalse);
    });

    test('fromSettings copies settings fields and resets transient state', () {
      final settings = Settings.defaultValue()
          .withCloseButtonPosition(CloseButtonPosition.leftTop)
          .withSoundEnabled(true)
          .withKeepAliveEnabled(true)
          .withTransparencyToggleEnabled(false);

      final state = OverlayState.fromSettings(
        settings,
        widthPx: 300,
        heightPx: 120,
        xPx: 40,
        yPx: 50,
        visible: true,
      );

      expect(state.widthPx, 300);
      expect(state.heightPx, 120);
      expect(state.xPx, 40);
      expect(state.yPx, 50);
      expect(state.visible, isTrue);
      expect(state.closeButtonPosition, CloseButtonPosition.leftTop);
      expect(state.soundEnabled, isTrue);
      expect(state.keepAliveEnabled, isTrue);
      expect(state.transparencyToggleEnabled, isFalse);
      expect(state.transparentMode, isFalse);
      expect(state.isDragging, isFalse);
      expect(state.isResizing, isFalse);
      expect(state.isMinimized, isFalse);
    });

    test('legacy with methods return a new immutable state', () {
      const original = OverlayState();
      final updated = original
          .withPosition(10, 20)
          .withSize(120, 60)
          .withVisibility(true)
          .withCloseButtonPosition(CloseButtonPosition.leftTop)
          .withSoundEnabled(true)
          .withKeepAliveEnabled(true)
          .withTransparencyToggleEnabled(false)
          .withTransparentMode(true)
          .withDragging(true)
          .withResizing(true)
          .withMinimized(true);

      expect(original.visible, isFalse);
      expect(updated.xPx, 10);
      expect(updated.yPx, 20);
      expect(updated.widthPx, 120);
      expect(updated.heightPx, 60);
      expect(updated.visible, isTrue);
      expect(updated.closeButtonPosition, CloseButtonPosition.leftTop);
      expect(updated.soundEnabled, isTrue);
      expect(updated.keepAliveEnabled, isTrue);
      expect(updated.transparencyToggleEnabled, isFalse);
      expect(updated.transparentMode, isTrue);
      expect(updated.isDragging, isTrue);
      expect(updated.isResizing, isTrue);
      expect(updated.isMinimized, isTrue);
    });
  });

  group('Overlay geometry value types', () {
    test(
      'carry size, position, bounds, and safe insets without Flutter UI types',
      () {
        const state = OverlayState(widthPx: 200, heightPx: 100, xPx: 8, yPx: 9);
        const bounds = ScreenBounds(
          widthPx: 1080,
          heightPx: 1920,
          safeInsets: ScreenInsets(left: 0, top: 24, right: 0, bottom: 48),
        );

        expect(state.size, const OverlaySize(widthPx: 200, heightPx: 100));
        expect(state.position, const OverlayPosition(xPx: 8, yPx: 9));
        expect(bounds.safeInsets.top, 24);
        expect(bounds.safeInsets.bottom, 48);
      },
    );
  });

  group('AnimationSpec', () {
    test('preserves legacy durationMs and animation type fields', () {
      final spec = AnimationSpec.fromMilliseconds(
        durationMs: 300,
        type: OverlayAnimationType.fade,
      );

      expect(spec.duration, const Duration(milliseconds: 300));
      expect(spec.durationMs, 300);
      expect(spec.type.legacyName, 'FADE');
    });
  });
}
