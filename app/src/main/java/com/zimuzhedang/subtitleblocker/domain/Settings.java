package com.zimuzhedang.subtitleblocker.domain;

/**
 * 应用配置模型类。
 * 包含关闭按钮位置、声音开关和常驻后台开关等持久化设置。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class Settings {
    /** 关闭按钮在悬浮窗上的位置 */
    public final CloseButtonPosition closeButtonPosition;
    /** 是否启用交互提示音 */
    public final boolean soundEnabled;
    /** 是否启用常驻后台服务 */
    public final boolean keepAliveEnabled;

    /**
     * 构造函数。
     *
     * @param closeButtonPosition 关闭按钮位置
     * @param soundEnabled 声音开关
     * @param keepAliveEnabled 常驻后台开关
     */
    public Settings(
            CloseButtonPosition closeButtonPosition,
            boolean soundEnabled,
            boolean keepAliveEnabled
    ) {
        this.closeButtonPosition = closeButtonPosition;
        this.soundEnabled = soundEnabled;
        this.keepAliveEnabled = keepAliveEnabled;
    }

    /**
     * 获取默认配置。
     *
     * @return 默认设置对象
     */
    public static Settings defaultValue() {
        return new Settings(CloseButtonPosition.RIGHT_TOP, false, false);
    }

    public Settings withCloseButtonPosition(CloseButtonPosition position) {
        return new Settings(position, soundEnabled, keepAliveEnabled);
    }

    public Settings withSoundEnabled(boolean enabled) {
        return new Settings(closeButtonPosition, enabled, keepAliveEnabled);
    }

    public Settings withKeepAliveEnabled(boolean enabled) {
        return new Settings(closeButtonPosition, soundEnabled, enabled);
    }
}

