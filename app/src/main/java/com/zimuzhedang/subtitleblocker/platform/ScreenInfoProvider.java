package com.zimuzhedang.subtitleblocker.platform;

import com.zimuzhedang.subtitleblocker.domain.ScreenBounds;

/**
 * 屏幕信息提供者接口。
 * 用于获取当前屏幕的物理边界、安全区域以及单位转换。
 *
 * @author Trae
 * @since 2026-01-30
 */
public interface ScreenInfoProvider {
    /**
     * 获取当前屏幕的边界信息。
     *
     * @return 包含宽度、高度和安全区域内边距的 {@link ScreenBounds} 对象
     */
    ScreenBounds getCurrentBounds();

    /**
     * 将 dp 单位转换为 px (像素)。
     *
     * @param dp dp 数值
     * @return 转换后的像素值
     */
    int dpToPx(float dp);
}

