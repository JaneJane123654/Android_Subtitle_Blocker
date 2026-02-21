package com.zimuzhedang.subtitleblocker.domain;

/**
 * 一次性副作用模型类。
 * 用于从 ViewModel 向 View 层发送瞬间发生的事件（如播放声音、导航等）。
 * 每个副作用只能被消费一次，防止 LiveData 重复推送导致的重复执行。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OneShotEffect {
    /** 副作用类型枚举 */
    public enum Type {
        /** 播放点击提示音 */
        PLAY_SOUND,
        /** 在淡出动画后请求隐藏悬浮窗 */
        REQUEST_HIDE_AFTER_FADE,
        /** 跳转到系统悬浮窗权限设置页 */
        NAVIGATE_TO_PERMISSION,
        REQUEST_RESTORE_AFTER_DELAY,
        CANCEL_RESTORE_DELAY
    }

    /** 当前副作用类型 */
    public final Type type;
    public final long delayMs;
    
    /** 标记该副作用是否已被消费 */
    private boolean consumed = false;

    /**
     * 构造函数。
     *
     * @param type 副作用类型
     */
    public OneShotEffect(Type type) {
        this.type = type;
        this.delayMs = 0L;
    }

    public OneShotEffect(Type type, long delayMs) {
        this.type = type;
        this.delayMs = delayMs;
    }
    
    /**
     * 尝试消费该副作用。
     * 每个副作用只能被消费一次，后续调用将返回 false。
     *
     * @return true 表示成功消费，false 表示已经被消费过
     */
    public synchronized boolean consume() {
        if (consumed) {
            return false;
        }
        consumed = true;
        return true;
    }
    
    /**
     * 检查该副作用是否已被消费。
     *
     * @return true 表示已消费，false 表示未消费
     */
    public boolean isConsumed() {
        return consumed;
    }
}
