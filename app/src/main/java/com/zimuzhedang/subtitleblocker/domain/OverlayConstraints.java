package com.zimuzhedang.subtitleblocker.domain;

import androidx.core.graphics.Insets;

/**
 * 悬浮窗约束工具类。
 * 包含处理悬浮窗位置限制、尺寸限制以及边缘吸附逻辑。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayConstraints {
    private OverlayConstraints() {
    }

    /**
     * 将数值限制在指定范围内。
     *
     * @param value 原始值
     * @param min 最小值
     * @param max 最大值
     * @return 限制后的值
     */
    public static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    /**
     * 根据屏幕边界限制悬浮窗位置，确保其始终在安全区域内。
     *
     * @param state 原始悬浮窗状态
     * @param bounds 屏幕边界信息
     * @return 限制位置后的新状态
     */
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

    /**
     * 限制悬浮窗的尺寸，避免其过大或过小。
     *
     * @param state 原始悬浮窗状态
     * @param bounds 屏幕边界信息
     * @param minWidth 允许的最小宽度
     * @param minHeight 允许的最小高度
     * @return 限制尺寸后的新状态
     */
    public static OverlayState clampSize(OverlayState state, ScreenBounds bounds, int minWidth, int minHeight) {
        int maxWidth = (int) (bounds.widthPx * 0.8f);
        int maxHeight = (int) (bounds.heightPx * 0.8f);
        int clampedWidth = clamp(state.widthPx, minWidth, Math.max(minWidth, maxWidth));
        int clampedHeight = clamp(state.heightPx, minHeight, Math.max(minHeight, maxHeight));
        return state.withSize(clampedWidth, clampedHeight);
    }

    /**
     * 边缘吸附算法逻辑。
     * 当悬浮窗距离左右边缘在阈值范围内时，自动吸附到边缘。
     *
     * @param state 原始悬浮窗状态
     * @param bounds 屏幕边界信息
     * @param thresholdPx 吸附阈值 (像素)
     * @return 吸附处理后的新状态
     */
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
