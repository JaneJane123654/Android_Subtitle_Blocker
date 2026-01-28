package com.zimuzhedang.subtitleblocker.domain;

public final class OneShotEffect {
    public enum Type {
        PLAY_SOUND,
        REQUEST_HIDE_AFTER_FADE,
        NAVIGATE_TO_PERMISSION
    }

    public final Type type;

    public OneShotEffect(Type type) {
        this.type = type;
    }
}

