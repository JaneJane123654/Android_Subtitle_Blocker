package com.zimuzhedang.subtitleblocker.platform;

import android.graphics.Rect;
import android.view.View;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;

/**
 * 悬浮窗控制器接口，定义了操作系统级悬浮窗的方法。
 *
 * @author Trae
 * @since 2026-01-30
 */
public interface FloatWindowController {
    /**
     * 显示悬浮窗。
     *
     * @param contentView 悬浮窗中要显示的 View
     */
    void show(View contentView);

    /** 隐藏并移除悬浮窗。 */
    void hide();

    /** @return 悬浮窗当前是否正在显示 */
    boolean isShowing();

    /**
     * 更新悬浮窗的位置和大小。
     *
     * @param rectPx 新的边界矩形 (像素)
     * @param anim 动画规格，如果为 null 则立即更新
     */
    void update(Rect rectPx, @Nullable AnimationSpec anim);
}

