package com.zimuzhedang.subtitleblocker.platform;

import android.graphics.Rect;
import android.view.View;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;

public interface FloatWindowController {
    void show(View contentView);

    void hide();

    boolean isShowing();

    void update(Rect rectPx, @Nullable AnimationSpec anim);
}

