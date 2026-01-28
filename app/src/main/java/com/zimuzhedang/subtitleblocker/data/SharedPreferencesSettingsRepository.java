package com.zimuzhedang.subtitleblocker.data;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.domain.Settings;

public final class SharedPreferencesSettingsRepository implements SettingsRepository {
    private static final String PREFS_NAME = "subtitle_blocker_prefs";
    private static final String KEY_CLOSE_POSITION = "close_button_position";
    private static final String KEY_SOUND_ENABLED = "sound_enabled";
    private static final String KEY_KEEP_ALIVE = "keep_alive_enabled";
    private static final String KEY_LAST_WIDTH = "last_width_px";
    private static final String KEY_LAST_HEIGHT = "last_height_px";
    private static final String KEY_LAST_X = "last_x_px";
    private static final String KEY_LAST_Y = "last_y_px";

    private final SharedPreferences sharedPreferences;

    public SharedPreferencesSettingsRepository(Context context) {
        this.sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    @Override
    public Settings loadSettings() {
        String positionRaw = sharedPreferences.getString(KEY_CLOSE_POSITION, CloseButtonPosition.RIGHT_TOP.name());
        CloseButtonPosition position = CloseButtonPosition.valueOf(positionRaw);
        boolean soundEnabled = sharedPreferences.getBoolean(KEY_SOUND_ENABLED, false);
        boolean keepAlive = sharedPreferences.getBoolean(KEY_KEEP_ALIVE, false);
        return new Settings(position, soundEnabled, keepAlive);
    }

    @Override
    public void saveSettings(Settings settings) {
        sharedPreferences.edit()
                .putString(KEY_CLOSE_POSITION, settings.closeButtonPosition.name())
                .putBoolean(KEY_SOUND_ENABLED, settings.soundEnabled)
                .putBoolean(KEY_KEEP_ALIVE, settings.keepAliveEnabled)
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

