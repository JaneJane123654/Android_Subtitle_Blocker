package com.zimuzhedang.subtitleblocker.domain;

public final class AnimationSpec {
    public final long durationMs;
    public final AnimType type;

    public AnimationSpec(long durationMs, AnimType type) {
        this.durationMs = durationMs;
        this.type = type;
    }
}

