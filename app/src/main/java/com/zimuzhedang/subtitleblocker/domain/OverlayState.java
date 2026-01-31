package com.zimuzhedang.subtitleblocker.domain;

/**
 * 悬浮窗状态的不可变模型类。
 * 包含位置、大小、可见性、配置项以及交互状态（拖拽/缩放）。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayState {
    /** 悬浮窗宽度 (像素) */
    public final int widthPx;
    /** 悬浮窗高度 (像素) */
    public final int heightPx;
    /** 悬浮窗左上角 X 坐标 (像素) */
    public final int xPx;
    /** 悬浮窗左上角 Y 坐标 (像素) */
    public final int yPx;
    /** 悬浮窗是否可见 */
    public final boolean visible;
    /** 关闭按钮在悬浮窗上的位置 */
    public final CloseButtonPosition closeButtonPosition;
    /** 是否开启交互提示音 */
    public final boolean soundEnabled;
    /** 是否开启常驻通知保持活跃 */
    public final boolean keepAliveEnabled;
    /** 是否正在被拖拽 */
    public final boolean isDragging;
    /** 是否正在被缩放 */
    public final boolean isResizing;

    /**
     * 全参数构造函数。
     */
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

    /**
     * 更新位置并返回新状态。
     *
     * @param xPx 新的 X 坐标
     * @param yPx 新的 Y 坐标
     * @return 新的状态对象
     */
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

    /**
     * 更新尺寸并返回新状态。
     *
     * @param widthPx 新的宽度
     * @param heightPx 新的高度
     * @return 新的状态对象
     */
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

    /**
     * 更新可见性并返回新状态。
     *
     * @param visible 是否可见
     * @return 新的状态对象
     */
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

    /**
     * 更新关闭按钮位置并返回新状态。
     *
     * @param position 新的按钮位置
     * @return 新的状态对象
     */
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

    /**
     * 更新音效开关并返回新状态。
     *
     * @param enabled 是否启用音效
     * @return 新的状态对象
     */
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

    /**
     * 更新常驻后台开关并返回新状态。
     *
     * @param enabled 是否启用常驻后台
     * @return 新的状态对象
     */
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

    /**
     * 更新拖拽状态并返回新状态。
     *
     * @param dragging 是否正在拖拽
     * @return 新的状态对象
     */
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

    /**
     * 更新缩放状态并返回新状态。
     *
     * @param resizing 是否正在缩放
     * @return 新的状态对象
     */
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

