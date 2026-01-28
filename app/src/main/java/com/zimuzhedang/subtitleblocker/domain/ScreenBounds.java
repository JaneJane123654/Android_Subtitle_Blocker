package com.zimuzhedang.subtitleblocker.domain;

import androidx.core.graphics.Insets;

public final class ScreenBounds {
    public final int widthPx;
    public final int heightPx;
    public final Insets safeInsets;

    public ScreenBounds(int widthPx, int heightPx, Insets safeInsets) {
        this.widthPx = widthPx;
        this.heightPx = heightPx;
        this.safeInsets = safeInsets;
    }
}

