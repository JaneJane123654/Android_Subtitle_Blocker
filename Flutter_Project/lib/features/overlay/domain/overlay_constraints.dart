import 'dart:math' as math;

import '../../../core/contracts/business_constants.dart';
import 'overlay_geometry.dart';
import 'overlay_state.dart';

abstract final class OverlayConstraints {
  static const OverlaySize defaultSize = OverlaySize(
    widthPx: OverlayBusinessConstants.defaultOverlayWidthDp,
    heightPx: OverlayBusinessConstants.defaultOverlayHeightDp,
  );

  static int clamp(int value, int min, int max) {
    return math.max(min, math.min(max, value));
  }

  static OverlayPosition defaultPosition({
    required ScreenBounds bounds,
    OverlaySize size = defaultSize,
  }) {
    final xPx = math.max(
      bounds.safeInsets.left,
      (bounds.widthPx - size.widthPx) ~/ 2,
    );
    final yPx = math.max(
      bounds.safeInsets.top,
      (bounds.heightPx * OverlayBusinessConstants.defaultVerticalPositionRatio)
          .toInt(),
    );
    final state = OverlayState(
      widthPx: size.widthPx,
      heightPx: size.heightPx,
      xPx: xPx,
      yPx: yPx,
    );
    return clampPosition(state, bounds).position;
  }

  static OverlayState defaultState({required ScreenBounds bounds}) {
    final position = defaultPosition(bounds: bounds, size: defaultSize);
    return const OverlayState().withPosition(position.xPx, position.yPx);
  }

  static OverlayState sanitizeGeometry({
    required OverlayState state,
    required ScreenBounds bounds,
    bool snapToHorizontalEdges = false,
    int minWidth = OverlayBusinessConstants.minOverlayWidthDp,
    int minHeight = OverlayBusinessConstants.minOverlayHeightDp,
    int snapThreshold = OverlayBusinessConstants.snapThresholdDp,
  }) {
    final sized = clampSize(state, bounds, minWidth, minHeight);
    final positioned = clampPosition(sized, bounds);
    if (!snapToHorizontalEdges) {
      return positioned;
    }
    final snapped = snapToEdgeIfNeeded(positioned, bounds, snapThreshold);
    return clampPosition(snapped, bounds);
  }

  static OverlayState clampPosition(OverlayState state, ScreenBounds bounds) {
    final insets = bounds.safeInsets;
    final minX = insets.left;
    final minY = insets.top;
    final maxX = bounds.widthPx - insets.right - state.widthPx;
    final maxY = bounds.heightPx - insets.bottom - state.heightPx;
    final clampedX = clamp(state.xPx, minX, math.max(minX, maxX));
    final clampedY = clamp(state.yPx, minY, math.max(minY, maxY));
    return state.withPosition(clampedX, clampedY);
  }

  static OverlayState clampSize(
    OverlayState state,
    ScreenBounds bounds,
    int minWidth,
    int minHeight,
  ) {
    final maxWidth =
        (bounds.widthPx * OverlayBusinessConstants.maxOverlayScreenFraction)
            .toInt();
    final maxHeight =
        (bounds.heightPx * OverlayBusinessConstants.maxOverlayScreenFraction)
            .toInt();
    final clampedWidth = clamp(
      state.widthPx,
      minWidth,
      math.max(minWidth, maxWidth),
    );
    final clampedHeight = clamp(
      state.heightPx,
      minHeight,
      math.max(minHeight, maxHeight),
    );
    return state.withSize(clampedWidth, clampedHeight);
  }

  static OverlayState snapToEdgeIfNeeded(
    OverlayState state,
    ScreenBounds bounds,
    int thresholdPx,
  ) {
    final insets = bounds.safeInsets;
    final leftEdge = insets.left;
    final rightEdge = bounds.widthPx - insets.right - state.widthPx;
    final distanceLeft = (state.xPx - leftEdge).abs();
    final distanceRight = (state.xPx - rightEdge).abs();
    if (distanceLeft <= thresholdPx || distanceRight <= thresholdPx) {
      final targetX = distanceLeft <= distanceRight ? leftEdge : rightEdge;
      return state.withPosition(targetX, state.yPx);
    }
    return state;
  }

  static int clampMinimizedDotSize(int sizeDp) {
    return clamp(
      sizeDp,
      MinimizedDotBusinessConstants.minSizeDp,
      MinimizedDotBusinessConstants.maxSizeDp,
    );
  }

  static OverlayState clampPositionWithSize(
    OverlayState state,
    ScreenBounds bounds,
    int widthPx,
    int heightPx,
  ) {
    final insets = bounds.safeInsets;
    final minX = insets.left;
    final minY = insets.top;
    final maxX = bounds.widthPx - insets.right - widthPx;
    final maxY = bounds.heightPx - insets.bottom - heightPx;
    final clampedX = clamp(state.xPx, minX, math.max(minX, maxX));
    final clampedY = clamp(state.yPx, minY, math.max(minY, maxY));
    return state.withPosition(clampedX, clampedY);
  }

  static OverlayState snapToEdgeWithSize(
    OverlayState state,
    ScreenBounds bounds,
    int widthPx,
    int thresholdPx,
  ) {
    final insets = bounds.safeInsets;
    final leftEdge = insets.left;
    final rightEdge = bounds.widthPx - insets.right - widthPx;
    final distanceLeft = (state.xPx - leftEdge).abs();
    final distanceRight = (state.xPx - rightEdge).abs();
    if (distanceLeft <= thresholdPx || distanceRight <= thresholdPx) {
      final targetX = distanceLeft <= distanceRight ? leftEdge : rightEdge;
      return state.withPosition(targetX, state.yPx);
    }
    return state;
  }
}
