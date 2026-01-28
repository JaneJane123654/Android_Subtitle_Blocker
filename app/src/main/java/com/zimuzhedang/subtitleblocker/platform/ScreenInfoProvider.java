package com.zimuzhedang.subtitleblocker.platform;

import com.zimuzhedang.subtitleblocker.domain.ScreenBounds;

public interface ScreenInfoProvider {
    ScreenBounds getCurrentBounds();

    int dpToPx(float dp);
}

