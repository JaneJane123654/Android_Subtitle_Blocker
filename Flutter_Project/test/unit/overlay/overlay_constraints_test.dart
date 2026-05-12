import 'package:subtitle_blocker_flutter_refactor/features/overlay/domain/overlay_domain.dart';
import 'package:test/test.dart';

void main() {
  group('OverlayConstraints', () {
    test('clamp matches the legacy min/max helper', () {
      expect(OverlayConstraints.clamp(-1, 0, 10), 0);
      expect(OverlayConstraints.clamp(5, 0, 10), 5);
      expect(OverlayConstraints.clamp(11, 0, 10), 10);
    });

    test('clampPosition_respectsInsets', () {
      const bounds = ScreenBounds(
        widthPx: 1000,
        heightPx: 2000,
        safeInsets: ScreenInsets(left: 10, top: 20, right: 30, bottom: 40),
      );
      const state = OverlayState(
        widthPx: 200,
        heightPx: 200,
        xPx: -100,
        yPx: 10,
        visible: true,
      );

      final clamped = OverlayConstraints.clampPosition(state, bounds);

      expect(clamped.xPx, 10);
      expect(clamped.yPx, 20);
    });

    test('clampPosition_usesSafeMaximumsForRightAndBottomInsets', () {
      const bounds = ScreenBounds(
        widthPx: 1000,
        heightPx: 2000,
        safeInsets: ScreenInsets(left: 10, top: 20, right: 30, bottom: 40),
      );
      const state = OverlayState(
        widthPx: 200,
        heightPx: 300,
        xPx: 1200,
        yPx: 2200,
      );

      final clamped = OverlayConstraints.clampPosition(state, bounds);

      expect(clamped.xPx, 770);
      expect(clamped.yPx, 1660);
    });

    test('clampSize_respectsMinMax', () {
      const bounds = ScreenBounds(widthPx: 1000, heightPx: 2000);
      const state = OverlayState(widthPx: 10, heightPx: 10);

      final clamped = OverlayConstraints.clampSize(state, bounds, 100, 40);

      expect(clamped.widthPx, 100);
      expect(clamped.heightPx, 40);
    });

    test('clampSize_capsDimensionsAtEightyPercentOfScreen', () {
      const bounds = ScreenBounds(widthPx: 1000, heightPx: 2000);
      const state = OverlayState(widthPx: 900, heightPx: 1900);

      final clamped = OverlayConstraints.clampSize(state, bounds, 100, 40);

      expect(clamped.widthPx, 800);
      expect(clamped.heightPx, 1600);
    });

    test('snapToEdge_prefersNearest', () {
      const bounds = ScreenBounds(widthPx: 1000, heightPx: 2000);
      const state = OverlayState(widthPx: 200, heightPx: 200, xPx: 5);

      final snapped = OverlayConstraints.snapToEdgeIfNeeded(state, bounds, 15);

      expect(snapped.xPx, 0);
    });

    test('snapToEdge_snapsToRightEdgeWithinThreshold', () {
      const bounds = ScreenBounds(
        widthPx: 1000,
        heightPx: 2000,
        safeInsets: ScreenInsets(left: 10, top: 0, right: 30, bottom: 0),
      );
      const state = OverlayState(widthPx: 200, heightPx: 200, xPx: 775);

      final snapped = OverlayConstraints.snapToEdgeIfNeeded(state, bounds, 15);

      expect(snapped.xPx, 770);
    });

    test('snapToEdge_keepsPositionWhenOutsideThreshold', () {
      const bounds = ScreenBounds(widthPx: 1000, heightPx: 2000);
      const state = OverlayState(widthPx: 200, heightPx: 200, xPx: 400);

      final snapped = OverlayConstraints.snapToEdgeIfNeeded(state, bounds, 15);

      expect(snapped, state);
    });

    test('defaultPosition_matchesLegacyCenteredXAndRatioY', () {
      const bounds = ScreenBounds(
        widthPx: 1000,
        heightPx: 2000,
        safeInsets: ScreenInsets(left: 10, top: 20, right: 30, bottom: 40),
      );

      final position = OverlayConstraints.defaultPosition(bounds: bounds);

      expect(position.xPx, 390);
      expect(position.yPx, 1300);
    });

    test('defaultPosition_respectsSafeTopWhenItIsLargerThanRatioY', () {
      const bounds = ScreenBounds(
        widthPx: 1000,
        heightPx: 2000,
        safeInsets: ScreenInsets(left: 0, top: 1500, right: 0, bottom: 0),
      );

      final position = OverlayConstraints.defaultPosition(bounds: bounds);

      expect(position.yPx, 1500);
    });

    test('defaultState_preservesDocumentedDefaultSize', () {
      const bounds = ScreenBounds(widthPx: 1000, heightPx: 2000);

      final state = OverlayConstraints.defaultState(bounds: bounds);

      expect(state.widthPx, 220);
      expect(state.heightPx, 80);
      expect(state.xPx, 390);
      expect(state.yPx, 1300);
    });

    test('clampMinimizedDotSize_respectsDocumentedRange', () {
      expect(OverlayConstraints.clampMinimizedDotSize(5), 10);
      expect(OverlayConstraints.clampMinimizedDotSize(40), 40);
      expect(OverlayConstraints.clampMinimizedDotSize(240), 200);
    });

    test('clampPositionWithSize_usesMinimizedDotDimensions', () {
      const bounds = ScreenBounds(
        widthPx: 300,
        heightPx: 500,
        safeInsets: ScreenInsets(left: 5, top: 7, right: 11, bottom: 13),
      );
      const state = OverlayState(
        widthPx: 200,
        heightPx: 200,
        xPx: 999,
        yPx: 999,
        isMinimized: true,
      );

      final clamped = OverlayConstraints.clampPositionWithSize(
        state,
        bounds,
        40,
        40,
      );

      expect(clamped.xPx, 249);
      expect(clamped.yPx, 447);
    });

    test('snapToEdgeWithSize_usesMinimizedDotWidth', () {
      const bounds = ScreenBounds(
        widthPx: 300,
        heightPx: 500,
        safeInsets: ScreenInsets(left: 5, top: 7, right: 11, bottom: 13),
      );
      const state = OverlayState(
        widthPx: 200,
        heightPx: 200,
        xPx: 246,
        yPx: 90,
        isMinimized: true,
      );

      final snapped = OverlayConstraints.snapToEdgeWithSize(
        state,
        bounds,
        40,
        15,
      );

      expect(snapped.xPx, 249);
      expect(snapped.yPx, 90);
    });

    test('sanitizeGeometry_clampsSizePositionAndOptionalSnap', () {
      const bounds = ScreenBounds(widthPx: 1000, heightPx: 2000);
      const state = OverlayState(
        widthPx: 900,
        heightPx: 10,
        xPx: 790,
        yPx: -20,
      );

      final sanitized = OverlayConstraints.sanitizeGeometry(
        state: state,
        bounds: bounds,
        snapToHorizontalEdges: true,
      );

      expect(sanitized.widthPx, 800);
      expect(sanitized.heightPx, 40);
      expect(sanitized.xPx, 200);
      expect(sanitized.yPx, 0);
    });
  });

  group('OverlayRect', () {
    test('derives edges, size, and position from integer geometry', () {
      const rect = OverlayRect(xPx: 10, yPx: 20, widthPx: 30, heightPx: 40);

      expect(rect.leftPx, 10);
      expect(rect.topPx, 20);
      expect(rect.rightPx, 40);
      expect(rect.bottomPx, 60);
      expect(rect.position, const OverlayPosition(xPx: 10, yPx: 20));
      expect(rect.size, const OverlaySize(widthPx: 30, heightPx: 40));
    });
  });
}
