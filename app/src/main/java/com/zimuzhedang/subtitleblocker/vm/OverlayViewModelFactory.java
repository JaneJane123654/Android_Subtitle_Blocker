package com.zimuzhedang.subtitleblocker.vm;

import androidx.annotation.NonNull;
import androidx.lifecycle.ViewModel;
import androidx.lifecycle.ViewModelProvider;

import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.platform.ScreenInfoProvider;

public final class OverlayViewModelFactory implements ViewModelProvider.Factory {
    private final SettingsRepository settingsRepository;
    private final ScreenInfoProvider screenInfoProvider;

    public OverlayViewModelFactory(SettingsRepository settingsRepository, ScreenInfoProvider screenInfoProvider) {
        this.settingsRepository = settingsRepository;
        this.screenInfoProvider = screenInfoProvider;
    }

    @NonNull
    @Override
    public <T extends ViewModel> T create(@NonNull Class<T> modelClass) {
        if (modelClass.isAssignableFrom(OverlayViewModel.class)) {
            return (T) new OverlayViewModel(settingsRepository, screenInfoProvider);
        }
        throw new IllegalArgumentException("Unknown ViewModel class");
    }
}

