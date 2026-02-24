package com.zimuzhedang.subtitleblocker.data;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.domain.Settings;

/**
 * 基于 {@link SharedPreferences} 实现的设置仓库。
 * 将应用配置和悬浮窗状态持久化到本地 XML 文件中。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class SharedPreferencesSettingsRepository implements SettingsRepository {
    /** SharedPreferences 文件名 */
    private static final String PREFS_NAME = "subtitle_blocker_prefs";
    /** 关闭按钮位置的键名 */
    private static final String KEY_CLOSE_POSITION = "close_button_position";
    /** 声音开关的键名 */
    private static final String KEY_SOUND_ENABLED = "sound_enabled";
    /** 常驻通知开关的键名 */
    private static final String KEY_KEEP_ALIVE = "keep_alive_enabled";
    private static final String KEY_LANGUAGE = "app_language";
    private static final String KEY_TRANSPARENCY_TOGGLE_ENABLED = "transparency_toggle_enabled";
    private static final String KEY_TRANSPARENCY_AUTO_RESTORE_ENABLED = "transparency_auto_restore_enabled";
    private static final String KEY_TRANSPARENCY_AUTO_RESTORE_SECONDS = "transparency_auto_restore_seconds";
    /** 上次宽度的键名 */
    private static final String KEY_LAST_WIDTH = "last_width_px";
    /** 上次高度的键名 */
    private static final String KEY_LAST_HEIGHT = "last_height_px";
    /** 上次 X 坐标的键名 */
    private static final String KEY_LAST_X = "last_x_px";
    /** 上次 Y 坐标的键名 */
    private static final String KEY_LAST_Y = "last_y_px";

    private final SharedPreferences sharedPreferences;

    /**
     * 构造函数。
     *
     * @param context Android 上下文，用于获取 SharedPreferences
     */
    public SharedPreferencesSettingsRepository(Context context) {
        this.sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    @Override
    public Settings loadSettings() {
        String positionRaw = sharedPreferences.getString(KEY_CLOSE_POSITION, CloseButtonPosition.RIGHT_TOP.name());
        CloseButtonPosition position = CloseButtonPosition.valueOf(positionRaw);
        boolean soundEnabled = sharedPreferences.getBoolean(KEY_SOUND_ENABLED, false);
        boolean keepAlive = sharedPreferences.getBoolean(KEY_KEEP_ALIVE, false);
        Settings.AppLanguage appLanguage = Settings.AppLanguage.fromValue(
                sharedPreferences.getString(KEY_LANGUAGE, Settings.AppLanguage.SYSTEM.value)
        );
        boolean transparencyToggleEnabled = sharedPreferences.getBoolean(KEY_TRANSPARENCY_TOGGLE_ENABLED, false);
        boolean transparencyAutoRestoreEnabled = sharedPreferences.getBoolean(KEY_TRANSPARENCY_AUTO_RESTORE_ENABLED, false);
        int transparencyAutoRestoreSeconds = sharedPreferences.getInt(KEY_TRANSPARENCY_AUTO_RESTORE_SECONDS, 5);
        return new Settings(
                position,
                soundEnabled,
                keepAlive,
                appLanguage,
                transparencyToggleEnabled,
                transparencyAutoRestoreEnabled,
                transparencyAutoRestoreSeconds
        );
    }

    @Override
    public void saveSettings(Settings settings) {
        sharedPreferences.edit()
                .putString(KEY_CLOSE_POSITION, settings.closeButtonPosition.name())
                .putBoolean(KEY_SOUND_ENABLED, settings.soundEnabled)
                .putBoolean(KEY_KEEP_ALIVE, settings.keepAliveEnabled)
                .putString(KEY_LANGUAGE, settings.appLanguage.value)
                .putBoolean(KEY_TRANSPARENCY_TOGGLE_ENABLED, settings.transparencyToggleEnabled)
                .putBoolean(KEY_TRANSPARENCY_AUTO_RESTORE_ENABLED, settings.transparencyAutoRestoreEnabled)
                .putInt(KEY_TRANSPARENCY_AUTO_RESTORE_SECONDS, settings.transparencyAutoRestoreSeconds)
                .apply();
    }

    @Override
    @Nullable
    public OverlayState loadLastOverlayState() {
        if (!sharedPreferences.contains(KEY_LAST_WIDTH)) {
            return null;
        }
        int width = sharedPreferences.getInt(KEY_LAST_WIDTH, 0);
        int height = sharedPreferences.getInt(KEY_LAST_HEIGHT, 0);
        int x = sharedPreferences.getInt(KEY_LAST_X, 0);
        int y = sharedPreferences.getInt(KEY_LAST_Y, 0);
        Settings settings = loadSettings();
        return new OverlayState(
                width,
                height,
                x,
                y,
                false,
                settings.closeButtonPosition,
                settings.soundEnabled,
                settings.keepAliveEnabled,
                settings.transparencyToggleEnabled,
                false,
                false,
                false
        );
    }

    @Override
    public void saveLastOverlayState(OverlayState state) {
        sharedPreferences.edit()
                .putInt(KEY_LAST_WIDTH, state.widthPx)
                .putInt(KEY_LAST_HEIGHT, state.heightPx)
                .putInt(KEY_LAST_X, state.xPx)
                .putInt(KEY_LAST_Y, state.yPx)
                .apply();
    }
}
