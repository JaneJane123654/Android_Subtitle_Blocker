package com.zimuzhedang.subtitleblocker.ui;

import android.graphics.Rect;

import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.platform.FloatWindowController;

public final class OverlayViewBinder {
    private final FloatWindowController windowController;
    private final OverlayWindowView overlayView;

    public OverlayViewBinder(FloatWindowController windowController, OverlayWindowView overlayView) {
        this.windowController = windowController;
        this.overlayView = overlayView;
    }

    public void bind(OverlayState state, AnimationSpec anim) {
        overlayView.updateCloseButtonPosition(state.closeButtonPosition);
        if (!state.visible) {
            if (windowController.isShowing()) {
                windowController.hide();
            }
            return;
        }
        if (!windowController.isShowing()) {
            windowController.show(overlayView);
        }
        Rect rect = new Rect(state.xPx, state.yPx, state.xPx + state.widthPx, state.yPx + state.heightPx);
        windowController.update(rect, anim);
    }
}

