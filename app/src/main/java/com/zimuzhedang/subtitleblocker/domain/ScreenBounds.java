package com.zimuzhedang.subtitleblocker.domain;

import androidx.core.graphics.Insets;

/**
 * 屏幕边界信息模型类。
 * 包含屏幕尺寸及安全区域（如刘海屏、导航栏等）的内边距。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class ScreenBounds {
    /** 屏幕总宽度 (像素) */
    public final int widthPx;
    /** 屏幕总高度 (像素) */
    public final int heightPx;
    /** 系统安全区域内边距 */
    public final Insets safeInsets;

    /**
     * 构造函数。
     *
     * @param widthPx 屏幕宽度
     * @param heightPx 屏幕高度
     * @param safeInsets 安全区域内边距
     */
    public ScreenBounds(int widthPx, int heightPx, Insets safeInsets) {
        this.widthPx = widthPx;
        this.heightPx = heightPx;
        this.safeInsets = safeInsets;
    }
}

