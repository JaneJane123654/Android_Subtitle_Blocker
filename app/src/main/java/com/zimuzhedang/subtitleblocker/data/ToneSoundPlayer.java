package com.zimuzhedang.subtitleblocker.data;

import android.media.ToneGenerator;
import android.media.AudioManager;

public final class ToneSoundPlayer implements SoundPlayer {
    private final ToneGenerator toneGenerator;
    private boolean enabled;

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

