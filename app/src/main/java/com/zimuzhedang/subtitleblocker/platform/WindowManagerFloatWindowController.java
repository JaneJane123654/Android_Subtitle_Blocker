package com.zimuzhedang.subtitleblocker.platform;

import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Rect;
import android.os.Build;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.domain.AnimType;
import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;
import com.zimuzhedang.subtitleblocker.infra.Logger;

/**
 * 基于 {@link WindowManager} 实现的悬浮窗控制器。
 * 使用系统的 WindowManager API 来添加、更新和移除悬浮窗视图。
 * 支持平移动画、缩放动画和淡出动画。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class WindowManagerFloatWindowController implements FloatWindowController {
    private final Context context;
    private final WindowManager windowManager;
    private View contentView;
    private WindowManager.LayoutParams layoutParams;

    /**
     * 构造函数。
     *
     * @param context Android 上下文，用于获取 WindowManager 服务
     */
    public WindowManagerFloatWindowController(Context context) {
        this.context = context.getApplicationContext();
        this.windowManager = (WindowManager) this.context.getSystemService(Context.WINDOW_SERVICE);
    }

    @Override
    public void show(View contentView) {
        if (isShowing()) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            Logger.w("window addView blocked: overlay permission missing");
            return;
        }
        this.contentView = contentView;
        int type = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                : WindowManager.LayoutParams.TYPE_PHONE;
        layoutParams = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                android.graphics.PixelFormat.TRANSLUCENT
        );
        layoutParams.gravity = Gravity.TOP | Gravity.START;
        layoutParams.x = 0;
        layoutParams.y = 0;
        try {
            windowManager.addView(contentView, layoutParams);
        } catch (Exception e) {
            this.contentView = null;
            layoutParams = null;
            Logger.e("window addView failed", e);
        }
    }

    @Override
    public void hide() {
        if (!isShowing()) {
            return;
        }
        try {
            windowManager.removeView(contentView);
        } catch (Exception e) {
            Logger.e("window removeView failed", e);
        }
        contentView = null;
        layoutParams = null;
    }

    @Override
    public boolean isShowing() {
        return contentView != null;
    }

    @Override
    public void update(Rect rectPx, @Nullable AnimationSpec anim) {
        if (!isShowing() || layoutParams == null) {
            return;
        }
        if (anim == null || anim.durationMs <= 0) {
            applyRect(rectPx);
            return;
        }
        if (anim.type == AnimType.FADE) {
            animateFade(rectPx, anim.durationMs);
            return;
        }
        animateRect(rectPx, anim.durationMs);
    }

    private void applyRect(Rect rect) {
        layoutParams.width = rect.width();
        layoutParams.height = rect.height();
        layoutParams.x = rect.left;
        layoutParams.y = rect.top;
        try {
            windowManager.updateViewLayout(contentView, layoutParams);
        } catch (Exception e) {
            Logger.e("window updateViewLayout failed", e);
        }
    }

    private void animateRect(Rect target, long durationMs) {
        Rect start = new Rect(layoutParams.x, layoutParams.y,
                layoutParams.x + layoutParams.width,
                layoutParams.y + layoutParams.height);
        ValueAnimator animator = ValueAnimator.ofFloat(0f, 1f);
        animator.setDuration(durationMs);
        animator.addUpdateListener(animation -> {
            float fraction = (float) animation.getAnimatedValue();
            Rect current = new Rect(
                    lerp(start.left, target.left, fraction),
                    lerp(start.top, target.top, fraction),
                    lerp(start.right, target.right, fraction),
                    lerp(start.bottom, target.bottom, fraction)
            );
            applyRect(current);
        });
        animator.start();
    }

    private void animateFade(Rect rect, long durationMs) {
        applyRect(rect);
        if (contentView == null) {
            return;
        }
        contentView.animate()
                .alpha(0f)
                .setDuration(durationMs)
                .withEndAction(() -> contentView.setAlpha(1f))
                .start();
    }

    private int lerp(int start, int end, float fraction) {
        return start + Math.round((end - start) * fraction);
    }
}
