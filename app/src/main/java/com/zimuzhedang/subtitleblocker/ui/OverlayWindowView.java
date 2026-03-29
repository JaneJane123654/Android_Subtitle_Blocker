package com.zimuzhedang.subtitleblocker.ui;

import android.content.Context;
import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.animation.LinearInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageButton;

import androidx.annotation.NonNull;

import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;

/**
 * 悬浮窗自定义视图类。
 * 负责渲染悬浮窗 UI（遮挡区域、关闭按钮、缩放手柄）并分发触摸事件（拖拽、缩放）。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayWindowView extends FrameLayout {
    /**
     * 悬浮窗交互事件监听器接口。
     */
    public interface Listener {
        /** 点击关闭按钮时触发 */
        void onClose();
        void onTransparencyToggle();
        void onMinimizeToggle();

        /** 开始拖拽悬浮窗时触发 */
        void onDragStart();

        /**
         * 正在拖拽悬浮窗时触发。
         *
         * @param dxPx X 轴偏移量 (像素)
         * @param dyPx Y 轴偏移量 (像素)
         */
        void onDragMove(int dxPx, int dyPx);

        /** 结束拖拽悬浮窗时触发 */
        void onDragEnd();

        /** 开始缩放悬浮窗时触发 */
        void onResizeStart();

        /**
         * 正在缩放悬浮窗时触发。
         *
         * @param dwPx 宽度变化量 (像素)
         * @param dhPx 高度变化量 (像素)
         */
        void onResizeMove(int dwPx, int dhPx);

        /** 结束缩放悬浮窗时触发 */
        void onResizeEnd();
    }

    private Listener listener;
    private final ImageButton closeButton;
    private final ImageButton transparencyButton;
    private final ImageButton minimizeButton;
    private final GlowDotView minimizedDot;
    private final View overlayRoot;
    private final View resizeHandle;
    private final View resizeHandleRight;
    private final View resizeHandleBottom;
    private boolean draggingActive;
    private boolean resizingActive;
    private boolean transparencyToggleEnabled;
    private boolean minimized;
    private boolean possibleClick;
    private float downRawX;
    private float downRawY;
    private float lastRawX;
    private float lastRawY;
    private float lastResizeX;
    private float lastResizeY;
    private final int touchSlop;
    private ObjectAnimator glowScaleXAnimator;
    private ObjectAnimator glowScaleYAnimator;
    private ObjectAnimator glowAlphaAnimator;
    private ObjectAnimator glowRotationAnimator;
    private ValueAnimator glowFlickerAnimator;
    private boolean minimizeDotRotateEnabled = false;

    /**
     * 构造函数。
     * 初始化布局、查找子控件并设置触摸监听器。
     *
     * @param context Android 上下文
     */
    public OverlayWindowView(@NonNull Context context) {
        super(context);
        LayoutInflater.from(context).inflate(R.layout.view_overlay_window, this, true);
        overlayRoot = findViewById(R.id.overlayRoot);
        closeButton = findViewById(R.id.btnClose);
        transparencyButton = findViewById(R.id.btnTransparency);
        minimizeButton = findViewById(R.id.btnMinimize);
        minimizedDot = findViewById(R.id.minimizedDot);
        minimizeButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onMinimizeToggle();
            }
        });
        resizeHandle = findViewById(R.id.resizeHandle);
        resizeHandleRight = findViewById(R.id.resizeHandleRight);
        resizeHandleBottom = findViewById(R.id.resizeHandleBottom);
        closeButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onClose();
            }
        });
        transparencyButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onTransparencyToggle();
            }
        });
        setOnTouchListener(this::handleDragTouch);
        minimizedDot.setOnTouchListener(this::handleDragTouch);
        resizeHandle.setOnTouchListener(this::handleResizeTouch);
        resizeHandleRight.setOnTouchListener(this::handleResizeRightTouch);
        resizeHandleBottom.setOnTouchListener(this::handleResizeBottomTouch);
        touchSlop = ViewConfiguration.get(context).getScaledTouchSlop();
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public void updateCloseButtonPosition(CloseButtonPosition position) {
        FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) closeButton.getLayoutParams();
        if (position == CloseButtonPosition.LEFT_TOP) {
            params.gravity = android.view.Gravity.START | android.view.Gravity.TOP;
        } else {
            params.gravity = android.view.Gravity.END | android.view.Gravity.TOP;
        }
        closeButton.setLayoutParams(params);
    }

    public void updateTransparencyToggleEnabled(boolean enabled) {
        transparencyToggleEnabled = enabled;
        transparencyButton.setVisibility(enabled ? View.VISIBLE : View.GONE);
    }

    public void updateTransparentMode(boolean enabled) {
        overlayRoot.setBackgroundResource(enabled ? R.drawable.overlay_background_transparent : R.drawable.overlay_background);
    }

    private boolean handleDragTouch(View view, MotionEvent event) {
        if (resizingActive) {
            return false;
        }
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                draggingActive = true;
                possibleClick = true;
                downRawX = event.getRawX();
                downRawY = event.getRawY();
                lastRawX = event.getRawX();
                lastRawY = event.getRawY();
                if (listener != null) {
                    listener.onDragStart();
                }
                return true;
            case MotionEvent.ACTION_MOVE:
                if (!draggingActive) {
                    return true;
                }
                int dx = Math.round(event.getRawX() - lastRawX);
                int dy = Math.round(event.getRawY() - lastRawY);
                float totalDx = event.getRawX() - downRawX;
                float totalDy = event.getRawY() - downRawY;
                if (possibleClick && Math.hypot(totalDx, totalDy) > touchSlop) {
                    possibleClick = false;
                }
                lastRawX = event.getRawX();
                lastRawY = event.getRawY();
                if (listener != null) {
                    listener.onDragMove(dx, dy);
                }
                return true;
            case MotionEvent.ACTION_UP:
                if (draggingActive && listener != null) {
                    listener.onDragEnd();
                }
                if (possibleClick && listener != null) {
                    if (minimized) {
                        listener.onMinimizeToggle();
                    } else if (transparencyToggleEnabled) {
                        listener.onTransparencyToggle();
                    }
                }
                draggingActive = false;
                return true;
            case MotionEvent.ACTION_CANCEL:
                if (draggingActive && listener != null) {
                    listener.onDragEnd();
                }
                draggingActive = false;
                return true;
            default:
                return false;
        }
    }

    private boolean handleResizeTouch(View view, MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                lastResizeX = event.getRawX();
                lastResizeY = event.getRawY();
                resizingActive = true;
                if (listener != null) {
                    listener.onResizeStart();
                }
                return true;
            case MotionEvent.ACTION_MOVE:
                int dw = Math.round(event.getRawX() - lastResizeX);
                int dh = Math.round(event.getRawY() - lastResizeY);
                lastResizeX = event.getRawX();
                lastResizeY = event.getRawY();
                if (listener != null) {
                    listener.onResizeMove(dw, dh);
                }
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                if (listener != null) {
                    listener.onResizeEnd();
                }
                resizingActive = false;
                return true;
            default:
                return false;
        }
    }

    private boolean handleResizeRightTouch(View view, MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                lastResizeX = event.getRawX();
                resizingActive = true;
                if (listener != null) {
                    listener.onResizeStart();
                }
                return true;
            case MotionEvent.ACTION_MOVE:
                int dw = Math.round(event.getRawX() - lastResizeX);
                lastResizeX = event.getRawX();
                if (listener != null) {
                    listener.onResizeMove(dw, 0);
                }
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                if (listener != null) {
                    listener.onResizeEnd();
                }
                resizingActive = false;
                return true;
            default:
                return false;
        }
    }

    private boolean handleResizeBottomTouch(View view, MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                lastResizeY = event.getRawY();
                resizingActive = true;
                if (listener != null) {
                    listener.onResizeStart();
                }
                return true;
            case MotionEvent.ACTION_MOVE:
                int dh = Math.round(event.getRawY() - lastResizeY);
                lastResizeY = event.getRawY();
                if (listener != null) {
                    listener.onResizeMove(0, dh);
                }
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                if (listener != null) {
                    listener.onResizeEnd();
                }
                resizingActive = false;
                return true;
            default:
                return false;
        }
    }

    public void updateMinimized(boolean isMinimized, int dotSizeDp, boolean rotateEnabled) {
        minimized = isMinimized;
        minimizeDotRotateEnabled = rotateEnabled;
        if (isMinimized) {
            overlayRoot.setVisibility(View.GONE);
            minimizedDot.setVisibility(View.VISIBLE);

            float density = getContext().getResources().getDisplayMetrics().density;
            int sizePx = Math.round(dotSizeDp * density);
            FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) minimizedDot.getLayoutParams();
            if (lp.width != sizePx || lp.height != sizePx) {
                lp.width = sizePx;
                lp.height = sizePx;
                minimizedDot.setLayoutParams(lp);
            }
            startGlowAnimation();
        } else {
            stopGlowAnimation();
            overlayRoot.setVisibility(View.VISIBLE);
            updateTransparencyToggleEnabled(transparencyToggleEnabled);
            minimizedDot.setVisibility(View.GONE);
        }
    }

    private void startGlowAnimation() {
        if (glowScaleXAnimator == null) {
            glowScaleXAnimator = ObjectAnimator.ofFloat(minimizedDot, View.SCALE_X, 1.0f, 1.06f, 1.0f);
            glowScaleXAnimator.setDuration(1500L);
            glowScaleXAnimator.setRepeatCount(ValueAnimator.INFINITE);
        }
        if (glowScaleYAnimator == null) {
            glowScaleYAnimator = ObjectAnimator.ofFloat(minimizedDot, View.SCALE_Y, 1.0f, 1.06f, 1.0f);
            glowScaleYAnimator.setDuration(1500L);
            glowScaleYAnimator.setRepeatCount(ValueAnimator.INFINITE);
        }
        if (glowAlphaAnimator == null) {
            glowAlphaAnimator = ObjectAnimator.ofFloat(minimizedDot, View.ALPHA, 0.92f, 1.0f, 0.92f);
            glowAlphaAnimator.setDuration(1500L);
            glowAlphaAnimator.setRepeatCount(ValueAnimator.INFINITE);
        }
        if (glowRotationAnimator == null) {
            glowRotationAnimator = ObjectAnimator.ofFloat(minimizedDot, "rayRotation", 0.0f, 360.0f);
            glowRotationAnimator.setInterpolator(new LinearInterpolator());
            glowRotationAnimator.setDuration(9000L);
            glowRotationAnimator.setRepeatCount(ValueAnimator.INFINITE);
        }
        if (glowFlickerAnimator == null) {
            glowFlickerAnimator = ValueAnimator.ofFloat(0.96f, 1.08f, 0.88f, 1.12f, 0.94f);
            glowFlickerAnimator.setDuration(1800L);
            glowFlickerAnimator.setRepeatCount(ValueAnimator.INFINITE);
            glowFlickerAnimator.addUpdateListener(animation ->
                    minimizedDot.setFlickerStrength((float) animation.getAnimatedValue())
            );
        }

        minimizedDot.setRayTwinkleEnabled(minimizeDotRotateEnabled);

        if (!glowAlphaAnimator.isRunning()) {
            glowAlphaAnimator.start();
        }

        if (minimizeDotRotateEnabled) {
            if (!glowScaleXAnimator.isRunning()) {
                glowScaleXAnimator.start();
            }
            if (!glowScaleYAnimator.isRunning()) {
                glowScaleYAnimator.start();
            }
            if (!glowRotationAnimator.isRunning()) {
                glowRotationAnimator.start();
            }
            if (!glowFlickerAnimator.isRunning()) {
                glowFlickerAnimator.start();
            }
        } else {
            glowScaleXAnimator.cancel();
            glowScaleYAnimator.cancel();
            glowRotationAnimator.cancel();
            glowFlickerAnimator.cancel();
            minimizedDot.setScaleX(1.0f);
            minimizedDot.setScaleY(1.0f);
            minimizedDot.setRayRotation(0.0f);
            minimizedDot.setFlickerStrength(1.0f);
        }
    }

    private void stopGlowAnimation() {
        if (glowScaleXAnimator != null) {
            glowScaleXAnimator.cancel();
            glowScaleXAnimator = null;
        }
        if (glowScaleYAnimator != null) {
            glowScaleYAnimator.cancel();
            glowScaleYAnimator = null;
        }
        if (glowAlphaAnimator != null) {
            glowAlphaAnimator.cancel();
            glowAlphaAnimator = null;
        }
        if (glowRotationAnimator != null) {
            glowRotationAnimator.cancel();
            glowRotationAnimator = null;
        }
        if (glowFlickerAnimator != null) {
            glowFlickerAnimator.cancel();
            glowFlickerAnimator = null;
        }
        minimizedDot.setScaleX(1.0f);
        minimizedDot.setScaleY(1.0f);
        minimizedDot.setAlpha(1.0f);
        minimizedDot.setRayRotation(0.0f);
        minimizedDot.setFlickerStrength(1.0f);
    }

    @Override
    protected void onDetachedFromWindow() {
        stopGlowAnimation();
        super.onDetachedFromWindow();
    }

}
