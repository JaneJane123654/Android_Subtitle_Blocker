package com.zimuzhedang.subtitleblocker.domain;

import android.content.Context;
import com.zimuzhedang.subtitleblocker.data.SharedPreferencesSettingsRepository;
import com.zimuzhedang.subtitleblocker.platform.DefaultScreenInfoProvider;
import com.zimuzhedang.subtitleblocker.vm.OverlayViewModel;

/**
 * 悬浮窗管理器，负责管理 {@link OverlayViewModel} 的生命周期。
 * 采用单例模式，确保整个应用中只有一个 ViewModel 实例。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayManager {
    private static OverlayManager instance;
    private OverlayViewModel viewModel;

    private OverlayManager() {}

    /**
     * 获取 OverlayManager 的单例实例。
     *
     * @return OverlayManager 实例
     */
    public static synchronized OverlayManager getInstance() {
        if (instance == null) {
            instance = new OverlayManager();
        }
        return instance;
    }

    /**
     * 获取或创建 {@link OverlayViewModel} 实例。
     *
     * @param context Android 上下文，用于初始化 Repository 和 Provider
     * @return OverlayViewModel 实例
     */
    public synchronized OverlayViewModel getViewModel(Context context) {
        if (viewModel == null) {
            viewModel = new OverlayViewModel(
                new SharedPreferencesSettingsRepository(context.getApplicationContext()),
                new DefaultScreenInfoProvider(context.getApplicationContext())
            );
        }
        return viewModel;
    }
}
