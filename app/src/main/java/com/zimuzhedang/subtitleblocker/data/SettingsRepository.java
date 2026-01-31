package com.zimuzhedang.subtitleblocker.data;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.domain.Settings;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;

/**
 * 设置仓库接口，定义了加载和保存应用配置及悬浮窗状态的方法。
 *
 * @author Trae
 * @since 2026-01-30
 */
public interface SettingsRepository {
    /**
     * 加载应用通用设置。
     *
     * @return 包含关闭按钮位置、声音开关等配置的 {@link Settings} 对象
     */
    Settings loadSettings();

    /**
     * 保存应用通用设置。
     *
     * @param settings 要保存的设置对象
     */
    void saveSettings(Settings settings);

    /**
     * 加载上一次显示的悬浮窗状态。
     *
     * @return 上一次的状态，如果从未保存过则返回 null
     */
    @Nullable
    OverlayState loadLastOverlayState();

    /**
     * 保存当前悬浮窗的位置和尺寸状态。
     *
     * @param state 要保存的悬浮窗状态
     */
    void saveLastOverlayState(OverlayState state);
}

