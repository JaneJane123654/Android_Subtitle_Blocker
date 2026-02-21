package com.zimuzhedang.subtitleblocker.vm;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.domain.AnimType;
import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;
import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;
import com.zimuzhedang.subtitleblocker.domain.OneShotEffect;
import com.zimuzhedang.subtitleblocker.domain.OverlayConstraints;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.domain.ScreenBounds;
import com.zimuzhedang.subtitleblocker.domain.Settings;
import com.zimuzhedang.subtitleblocker.platform.ScreenInfoProvider;

/**
 * 悬浮窗视图模型，负责处理悬浮窗的业务逻辑和状态管理。
 * 处理用户的拖拽、缩放、点击等交互，并根据约束条件更新悬浮窗状态。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayViewModel extends ViewModel {
    /** 移动动画时长 (毫秒) */
    private static final long MOVE_ANIM_MS = 150L;
    /** 缩放动画时长 (毫秒) */
    private static final long RESIZE_ANIM_MS = 200L;
    /** 淡入淡出动画时长 (毫秒) */
    private static final long FADE_ANIM_MS = 300L;
    private static final int MIN_AUTO_RESTORE_SECONDS = 1;
    private static final int MAX_AUTO_RESTORE_SECONDS = 60;

    private final SettingsRepository settingsRepository;
    private final ScreenInfoProvider screenInfoProvider;
    /** 悬浮窗当前状态的 LiveData */
    private final MutableLiveData<OverlayState> overlayState = new MutableLiveData<>();
    /** 动画规格的 LiveData */
    private final MutableLiveData<AnimationSpec> animationSpec = new MutableLiveData<>();
    /** 一次性副作用的 LiveData (如播放声音、跳转权限页) */
    private final MutableLiveData<OneShotEffect> effect = new MutableLiveData<>();

    /**
     * 构造函数。
     *
     * @param settingsRepository 设置仓库，用于持久化和加载配置
     * @param screenInfoProvider 屏幕信息提供者，用于获取屏幕尺寸和密度
     */
    public OverlayViewModel(SettingsRepository settingsRepository, ScreenInfoProvider screenInfoProvider) {
        this.settingsRepository = settingsRepository;
        this.screenInfoProvider = screenInfoProvider;
        Settings settings = settingsRepository.loadSettings();
        overlayState.setValue(buildDefaultState(settings));
    }

    /** @return 悬浮窗状态的只读 LiveData */
    public LiveData<OverlayState> getOverlayState() {
        return overlayState;
    }

    /** @return 动画规格的只读 LiveData */
    public LiveData<AnimationSpec> getAnimationSpec() {
        return animationSpec;
    }

    /** @return 副作用的只读 LiveData */
    public LiveData<OneShotEffect> getEffect() {
        return effect;
    }

    /** 清除当前的副作用。 */
    public void clearEffect() {
        effect.setValue(null);
    }

    /**
     * 请求显示悬浮窗。
     *
     * @param hasPermission 是否已获得悬浮窗权限
     */
    public void onRequestShow(boolean hasPermission) {
        if (!hasPermission) {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.NAVIGATE_TO_PERMISSION));
            return;
        }
        Settings settings = settingsRepository.loadSettings();
        OverlayState lastState = settingsRepository.loadLastOverlayState();
        OverlayState base = lastState != null ? lastState : buildDefaultState(settings);
        OverlayState updated = base
                .withCloseButtonPosition(settings.closeButtonPosition)
                .withSoundEnabled(settings.soundEnabled)
                .withKeepAliveEnabled(settings.keepAliveEnabled)
                .withTransparencyToggleEnabled(settings.transparencyToggleEnabled)
                .withTransparentMode(false)
                .withVisibility(true);
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        updated = OverlayConstraints.clampPosition(updated, bounds);
        overlayState.setValue(updated);
        animationSpec.setValue(null);
        effect.setValue(null);
    }

    /** 请求隐藏悬浮窗。 */
    public void onRequestHide() {
        OverlayState current = requireState();
        if (current.soundEnabled) {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.PLAY_SOUND));
        }
        overlayState.setValue(current.withVisibility(true));
        animationSpec.setValue(new AnimationSpec(FADE_ANIM_MS, AnimType.FADE));
        effect.setValue(new OneShotEffect(OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE));
    }

    /** 当悬浮窗完全隐藏后的回调。 */
    public void onOverlayHidden() {
        OverlayState current = requireState();
        overlayState.setValue(current.withVisibility(false));
    }

    /** 点击关闭按钮时的处理。 */
    public void onCloseClick() {
        OverlayState current = requireState();
        if (current.soundEnabled) {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.PLAY_SOUND));
        }
        overlayState.setValue(current.withVisibility(true));
        animationSpec.setValue(new AnimationSpec(FADE_ANIM_MS, AnimType.FADE));
        effect.setValue(new OneShotEffect(OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE));
    }

    /** 开始拖拽时的处理。 */
    public void onDragStart() {
        OverlayState current = requireState();
        overlayState.setValue(current.withDragging(true));
        animationSpec.setValue(null);
    }

    /**
     * 拖拽过程中的处理。
     *
     * @param dxPx X轴偏移量 (像素)
     * @param dyPx Y轴偏移量 (像素)
     */
    public void onDragMove(int dxPx, int dyPx) {
        OverlayState current = requireState();
        OverlayState moved = current.withPosition(current.xPx + dxPx, current.yPx + dyPx);
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        OverlayState clamped = OverlayConstraints.clampPosition(moved, bounds).withDragging(true);
        overlayState.setValue(clamped);
        animationSpec.setValue(null);
    }

    /** 拖拽结束时的处理，会进行边缘吸附。 */
    public void onDragEnd() {
        OverlayState current = requireState().withDragging(false);
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        int threshold = screenInfoProvider.dpToPx(15);
        OverlayState snapped = OverlayConstraints.snapToEdgeIfNeeded(current, bounds, threshold);
        snapped = OverlayConstraints.clampPosition(snapped, bounds);
        overlayState.setValue(snapped);
        settingsRepository.saveLastOverlayState(snapped);
        animationSpec.setValue(new AnimationSpec(MOVE_ANIM_MS, AnimType.MOVE));
    }

    /** 开始缩放时的处理。 */
    public void onResizeStart() {
        OverlayState current = requireState();
        overlayState.setValue(current.withResizing(true));
        animationSpec.setValue(null);
    }

    /**
     * 缩放过程中的处理。
     *
     * @param dwPx 宽度增量 (像素)
     * @param dhPx 高度增量 (像素)
     */
    public void onResizeMove(int dwPx, int dhPx) {
        OverlayState current = requireState();
        OverlayState resized = current.withSize(current.widthPx + dwPx, current.heightPx + dhPx);
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        int minWidth = screenInfoProvider.dpToPx(100);
        int minHeight = screenInfoProvider.dpToPx(40);
        resized = OverlayConstraints.clampSize(resized, bounds, minWidth, minHeight);
        resized = OverlayConstraints.clampPosition(resized, bounds).withResizing(true);
        overlayState.setValue(resized);
        animationSpec.setValue(null);
    }

    /** 缩放结束时的处理。 */
    public void onResizeEnd() {
        OverlayState current = requireState().withResizing(false);
        overlayState.setValue(current);
        settingsRepository.saveLastOverlayState(current);
        animationSpec.setValue(new AnimationSpec(RESIZE_ANIM_MS, AnimType.RESIZE));
    }

    /** 屏幕边界改变时的处理 (如旋转屏幕)。 */
    public void onBoundsChanged() {
        OverlayState current = requireState();
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        int minWidth = screenInfoProvider.dpToPx(100);
        int minHeight = screenInfoProvider.dpToPx(40);
        OverlayState clamped = OverlayConstraints.clampSize(current, bounds, minWidth, minHeight);
        clamped = OverlayConstraints.clampPosition(clamped, bounds);
        overlayState.setValue(clamped);
        animationSpec.setValue(new AnimationSpec(MOVE_ANIM_MS, AnimType.MOVE));
    }

    /**
     * 关闭按钮位置改变。
     *
     * @param position 新的位置
     */
    public void onCloseButtonPositionChanged(CloseButtonPosition position) {
        Settings settings = settingsRepository.loadSettings().withCloseButtonPosition(position);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        overlayState.setValue(current.withCloseButtonPosition(position));
    }

    /**
     * 提示音开关改变。
     *
     * @param enabled 是否启用
     */
    public void onSoundEnabledChanged(boolean enabled) {
        Settings settings = settingsRepository.loadSettings().withSoundEnabled(enabled);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        overlayState.setValue(current.withSoundEnabled(enabled));
    }

    /**
     * 常驻通知开关改变。
     *
     * @param enabled 是否启用
     */
    public void onKeepAliveChanged(boolean enabled) {
        Settings settings = settingsRepository.loadSettings().withKeepAliveEnabled(enabled);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        overlayState.setValue(current.withKeepAliveEnabled(enabled));
    }

    public void onTransparencyToggleEnabledChanged(boolean enabled) {
        Settings settings = settingsRepository.loadSettings().withTransparencyToggleEnabled(enabled);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        OverlayState updated = current.withTransparencyToggleEnabled(enabled);
        if (!enabled && current.transparentMode) {
            updated = updated.withTransparentMode(false);
            effect.setValue(new OneShotEffect(OneShotEffect.Type.CANCEL_RESTORE_DELAY));
        }
        overlayState.setValue(updated);
    }

    public void onTransparencyAutoRestoreEnabledChanged(boolean enabled) {
        Settings settings = settingsRepository.loadSettings().withTransparencyAutoRestoreEnabled(enabled);
        settingsRepository.saveSettings(settings);
        if (!enabled) {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.CANCEL_RESTORE_DELAY));
        }
    }

    public void onTransparencyAutoRestoreSecondsChanged(int seconds) {
        int normalized = normalizeSeconds(seconds);
        Settings settings = settingsRepository.loadSettings().withTransparencyAutoRestoreSeconds(normalized);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        if (current.transparentMode && settings.transparencyAutoRestoreEnabled) {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.REQUEST_RESTORE_AFTER_DELAY, normalized * 1000L));
        }
    }

    public void onTransparencyToggleRequested() {
        OverlayState current = requireState();
        Settings settings = settingsRepository.loadSettings();
        if (!settings.transparencyToggleEnabled) {
            return;
        }
        boolean nextTransparent = !current.transparentMode;
        overlayState.setValue(current.withTransparentMode(nextTransparent));
        if (nextTransparent) {
            if (settings.transparencyAutoRestoreEnabled) {
                int seconds = normalizeSeconds(settings.transparencyAutoRestoreSeconds);
                effect.setValue(new OneShotEffect(OneShotEffect.Type.REQUEST_RESTORE_AFTER_DELAY, seconds * 1000L));
            }
        } else {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.CANCEL_RESTORE_DELAY));
        }
    }

    public void onTransparencyAutoRestoreTimeout() {
        OverlayState current = requireState();
        if (!current.transparentMode) {
            return;
        }
        overlayState.setValue(current.withTransparentMode(false));
    }

    /**
     * 应用导入的状态。
     *
     * @param importedState 导入的悬浮窗状态
     * @param settings 导入的配置
     */
    public void applyImportedState(OverlayState importedState, Settings settings) {
        settingsRepository.saveSettings(settings);
        settingsRepository.saveLastOverlayState(importedState);
        OverlayState current = requireState();
        OverlayState updated = new OverlayState(
                importedState.widthPx,
                importedState.heightPx,
                importedState.xPx,
                importedState.yPx,
                current.visible,
                settings.closeButtonPosition,
                settings.soundEnabled,
                settings.keepAliveEnabled,
                settings.transparencyToggleEnabled,
                false,
                current.isDragging,
                current.isResizing
        );
        overlayState.setValue(updated);
    }

    private OverlayState requireState() {
        OverlayState current = overlayState.getValue();
        if (current == null) {
            Settings settings = settingsRepository.loadSettings();
            current = buildDefaultState(settings);
            overlayState.setValue(current);
        }
        return current;
    }

    private OverlayState buildDefaultState(Settings settings) {
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        int width = screenInfoProvider.dpToPx(220);
        int height = screenInfoProvider.dpToPx(80);
        int x = Math.max(bounds.safeInsets.left, (bounds.widthPx - width) / 2);
        int y = Math.max(bounds.safeInsets.top, (int) (bounds.heightPx * 0.65f));
        return new OverlayState(
                width,
                height,
                x,
                y,
                false,
                settings.closeButtonPosition,
                settings.soundEnabled,
                settings.keepAliveEnabled,
                settings.transparencyToggleEnabled,
                false,
                false,
                false
        );
    }

    private int normalizeSeconds(int seconds) {
        if (seconds < MIN_AUTO_RESTORE_SECONDS) {
            return MIN_AUTO_RESTORE_SECONDS;
        }
        if (seconds > MAX_AUTO_RESTORE_SECONDS) {
            return MAX_AUTO_RESTORE_SECONDS;
        }
        return seconds;
    }
}
