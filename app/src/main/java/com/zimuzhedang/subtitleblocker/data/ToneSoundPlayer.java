package com.zimuzhedang.subtitleblocker.data;

import android.media.ToneGenerator;
import android.media.AudioManager;

/**
 * 基于 {@link ToneGenerator} 的音效播放器实现。
 * 使用系统内置音频合成器播放简单的提示音。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class ToneSoundPlayer implements SoundPlayer {
    private final ToneGenerator toneGenerator;
    private boolean enabled;

    /**
     * 默认构造函数。
     * 初始化系统 ToneGenerator 实例。
     */
    public ToneSoundPlayer() {
        this.toneGenerator = new ToneGenerator(AudioManager.STREAM_MUSIC, 60);
        this.enabled = false;
    }

    @Override
    public void playClick() {
        if (!enabled) {
            return;
        }
        toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP, 120);
    }

    @Override
    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }
}

