package com.zimuzhedang.subtitleblocker.ui;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;

import androidx.annotation.NonNull;

import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;

public final class OverlayWindowView extends FrameLayout {
    public interface Listener {
        void onClose();

        void onDragStart();

        void onDragMove(int dxPx, int dyPx);

        void onDragEnd();

        void onResizeStart();

        void onResizeMove(int dwPx, int dhPx);

        void onResizeEnd();
    }

    private Listener listener;
    private final ImageButton closeButton;
    private final View resizeHandle;
    private final View resizeHandleRight;
    private final View resizeHandleBottom;
    private boolean draggingActive;
    private boolean resizingActive;
    private float lastRawX;
    private float lastRawY;
    private float lastResizeX;
    private float lastResizeY;

    public OverlayWindowView(@NonNull Context context) {
        super(context);
        LayoutInflater.from(context).inflate(R.layout.view_overlay_window, this, true);
        closeButton = findViewById(R.id.btnClose);
        resizeHandle = findViewById(R.id.resizeHandle);
        resizeHandleRight = findViewById(R.id.resizeHandleRight);
        resizeHandleBottom = findViewById(R.id.resizeHandleBottom);
        closeButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onClose();
            }
        });
        setOnTouchListener(this::handleDragTouch);
        resizeHandle.setOnTouchListener(this::handleResizeTouch);
        resizeHandleRight.setOnTouchListener(this::handleResizeRightTouch);
        resizeHandleBottom.setOnTouchListener(this::handleResizeBottomTouch);
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

    private boolean handleDragTouch(View view, MotionEvent event) {
        if (resizingActive) {
            return false;
        }
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                draggingActive = true;
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
                lastRawX = event.getRawX();
                lastRawY = event.getRawY();
                if (listener != null) {
                    listener.onDragMove(dx, dy);
                }
                return true;
            case MotionEvent.ACTION_UP:
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
}
