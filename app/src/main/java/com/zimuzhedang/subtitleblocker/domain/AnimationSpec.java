package com.zimuzhedang.subtitleblocker.domain;

/**
 * 动画规格配置类。
 * 定义了动画的时长和类型。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class AnimationSpec {
    /** 动画时长 (毫秒) */
    public final long durationMs;
    /** 动画类型 */
    public final AnimType type;

    /**
     * 构造函数。
     *
     * @param durationMs 动画时长
     * @param type 动画类型
     */
    public AnimationSpec(long durationMs, AnimType type) {
        this.durationMs = durationMs;
        this.type = type;
    }
}

