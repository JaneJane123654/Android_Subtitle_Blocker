package com.zimuzhedang.subtitleblocker.data;

/**
 * 音效播放器接口。
 * 用于播放应用内的交互提示音。
 *
 * @author Trae
 * @since 2026-01-30
 */
public interface SoundPlayer {
    /** 播放点击提示音 */
    void playClick();

    /**
     * 设置播放器是否启用。
     *
     * @param enabled true 表示启用，false 表示静音
     */
    void setEnabled(boolean enabled);
}

