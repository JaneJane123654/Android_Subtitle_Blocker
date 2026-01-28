package com.zimuzhedang.subtitleblocker.domain;

public final class Settings {
    public final CloseButtonPosition closeButtonPosition;
    public final boolean soundEnabled;
    public final boolean keepAliveEnabled;

    public Settings(
            CloseButtonPosition closeButtonPosition,
            boolean soundEnabled,
            boolean keepAliveEnabled
    ) {
        this.closeButtonPosition = closeButtonPosition;
        this.soundEnabled = soundEnabled;
        this.keepAliveEnabled = keepAliveEnabled;
    }

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

