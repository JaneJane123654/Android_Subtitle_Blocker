package com.zimuzhedang.subtitleblocker.vm;

import androidx.annotation.NonNull;
import androidx.lifecycle.ViewModel;
import androidx.lifecycle.ViewModelProvider;

import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.platform.ScreenInfoProvider;

/**
 * {@link OverlayViewModel} 的工厂类。
 * 负责注入依赖项（如 Repository 和 Provider）并实例化 ViewModel。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayViewModelFactory implements ViewModelProvider.Factory {
    private final SettingsRepository settingsRepository;
    private final ScreenInfoProvider screenInfoProvider;

    /**
     * 构造函数。
     *
     * @param settingsRepository 配置仓库
     * @param screenInfoProvider 屏幕信息提供者
     */
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

