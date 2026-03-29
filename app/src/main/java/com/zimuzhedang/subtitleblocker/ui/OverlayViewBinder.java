package com.zimuzhedang.subtitleblocker.ui;

import android.graphics.Rect;

import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.platform.FloatWindowController;
import com.zimuzhedang.subtitleblocker.data.SharedPreferencesSettingsRepository;
import com.zimuzhedang.subtitleblocker.domain.Settings;

/**
 * 悬浮窗视图绑定器。
 * 负责将 {@link OverlayState} 的状态应用到 {@link OverlayWindowView} 和 {@link FloatWindowController} 上。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayViewBinder {
    private final FloatWindowController windowController;
    private final OverlayWindowView overlayView;

    /**
     * 构造函数。
     *
     * @param windowController 悬浮窗控制器
     * @param overlayView 悬浮窗视图
     */
    public OverlayViewBinder(FloatWindowController windowController, OverlayWindowView overlayView) {
        this.windowController = windowController;
        this.overlayView = overlayView;
    }

    /**
     * 执行绑定逻辑。
     * 根据状态决定显示/隐藏，并更新位置、大小和子视图配置。
     *
     * @param state 最新的悬浮窗状态
     * @param anim 可选的动画规格
     */
    public void bind(OverlayState state, AnimationSpec anim) {
        overlayView.updateCloseButtonPosition(state.closeButtonPosition);
        overlayView.updateTransparencyToggleEnabled(state.transparencyToggleEnabled);
        overlayView.updateTransparentMode(state.transparentMode);
        Settings settings = new SharedPreferencesSettingsRepository(overlayView.getContext()).loadSettings();
        int dotSizeDp = settings.minimizeDotSize;
        overlayView.updateMinimized(state.isMinimized, dotSizeDp, settings.minimizeDotRotateEnabled);
        if (!state.visible) {
            if (windowController.isShowing()) {
                windowController.hide();
            }
            return;
        }
        if (!windowController.isShowing()) {
            windowController.show(overlayView);
        }
                float density = overlayView.getContext().getResources().getDisplayMetrics().density;
        int dotSizePx = (int) (dotSizeDp * density);
        int w = state.isMinimized ? dotSizePx : state.widthPx;
        int h = state.isMinimized ? dotSizePx : state.heightPx;
        Rect rect = new Rect(state.xPx, state.yPx, state.xPx + w, state.yPx + h);
        windowController.update(rect, anim);
    }
}
