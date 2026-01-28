package com.zimuzhedang.subtitleblocker.domain;

public final class OverlayState {
    public final int widthPx;
    public final int heightPx;
    public final int xPx;
    public final int yPx;
    public final boolean visible;
    public final CloseButtonPosition closeButtonPosition;
    public final boolean soundEnabled;
    public final boolean keepAliveEnabled;
    public final boolean isDragging;
    public final boolean isResizing;

    public OverlayState(
            int widthPx,
            int heightPx,
            int xPx,
            int yPx,
            boolean visible,
            CloseButtonPosition closeButtonPosition,
            boolean soundEnabled,
            boolean keepAliveEnabled,
            boolean isDragging,
            boolean isResizing
    ) {
        this.widthPx = widthPx;
        this.heightPx = heightPx;
        this.xPx = xPx;
        this.yPx = yPx;
        this.visible = visible;
        this.closeButtonPosition = closeButtonPosition;
        this.soundEnabled = soundEnabled;
        this.keepAliveEnabled = keepAliveEnabled;
        this.isDragging = isDragging;
        this.isResizing = isResizing;
    }

    public OverlayState withPosition(int xPx, int yPx) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                closeButtonPosition,
                soundEnabled,
                keepAliveEnabled,
                isDragging,
                isResizing
        );
    }

    public OverlayState withSize(int widthPx, int heightPx) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                closeButtonPosition,
                soundEnabled,
                keepAliveEnabled,
                isDragging,
                isResizing
        );
    }

    public OverlayState withVisibility(boolean visible) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                closeButtonPosition,
                soundEnabled,
                keepAliveEnabled,
                isDragging,
                isResizing
        );
    }

    public OverlayState withCloseButtonPosition(CloseButtonPosition position) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                position,
                soundEnabled,
                keepAliveEnabled,
                isDragging,
                isResizing
        );
    }

    public OverlayState withSoundEnabled(boolean enabled) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                closeButtonPosition,
                enabled,
                keepAliveEnabled,
                isDragging,
                isResizing
        );
    }

    public OverlayState withKeepAliveEnabled(boolean enabled) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                closeButtonPosition,
                soundEnabled,
                enabled,
                isDragging,
                isResizing
        );
    }

    public OverlayState withDragging(boolean dragging) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                closeButtonPosition,
                soundEnabled,
                keepAliveEnabled,
                dragging,
                isResizing
        );
    }

    public OverlayState withResizing(boolean resizing) {
        return new OverlayState(
                widthPx,
                heightPx,
                xPx,
                yPx,
                visible,
                closeButtonPosition,
                soundEnabled,
                keepAliveEnabled,
                isDragging,
                resizing
        );
    }
}

