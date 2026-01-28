package com.zimuzhedang.subtitleblocker.data;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.domain.Settings;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;

public interface SettingsRepository {
    Settings loadSettings();

    void saveSettings(Settings settings);

    @Nullable
    OverlayState loadLastOverlayState();

    void saveLastOverlayState(OverlayState state);
}

