package com.zimuzhedang.subtitleblocker.domain;

import androidx.core.graphics.Insets;

public final class OverlayConstraints {
    private OverlayConstraints() {
    }

    public static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    public static OverlayState clampPosition(OverlayState state, ScreenBounds bounds) {
        Insets insets = bounds.safeInsets;
        // 使用安全区内边距保证遮挡层始终位于可视区域内
        int minX = insets.left;
        int minY = insets.top;
        int maxX = bounds.widthPx - insets.right - state.widthPx;
        int maxY = bounds.heightPx - insets.bottom - state.heightPx;
        int clampedX = clamp(state.xPx, minX, Math.max(minX, maxX));
        int clampedY = clamp(state.yPx, minY, Math.max(minY, maxY));
        return state.withPosition(clampedX, clampedY);
    }

    public static OverlayState clampSize(OverlayState state, ScreenBounds bounds, int minWidth, int minHeight) {
        int maxWidth = (int) (bounds.widthPx * 0.8f);
        int maxHeight = (int) (bounds.heightPx * 0.8f);
        int clampedWidth = clamp(state.widthPx, minWidth, Math.max(minWidth, maxWidth));
        int clampedHeight = clamp(state.heightPx, minHeight, Math.max(minHeight, maxHeight));
        return state.withSize(clampedWidth, clampedHeight);
    }

    public static OverlayState snapToEdgeIfNeeded(OverlayState state, ScreenBounds bounds, int thresholdPx) {
        Insets insets = bounds.safeInsets;
        int leftEdge = insets.left;
        int rightEdge = bounds.widthPx - insets.right - state.widthPx;
        int distanceLeft = Math.abs(state.xPx - leftEdge);
        int distanceRight = Math.abs(state.xPx - rightEdge);
        if (distanceLeft <= thresholdPx || distanceRight <= thresholdPx) {
            // 距离哪侧边缘更近就吸附哪侧，提升操作可预期性
            int targetX = distanceLeft <= distanceRight ? leftEdge : rightEdge;
            return state.withPosition(targetX, state.yPx);
        }
        return state;
    }
}
