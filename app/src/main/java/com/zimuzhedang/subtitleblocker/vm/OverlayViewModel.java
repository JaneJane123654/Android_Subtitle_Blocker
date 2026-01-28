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

public final class OverlayViewModel extends ViewModel {
    private static final long MOVE_ANIM_MS = 150L;
    private static final long RESIZE_ANIM_MS = 200L;
    private static final long FADE_ANIM_MS = 300L;

    private final SettingsRepository settingsRepository;
    private final ScreenInfoProvider screenInfoProvider;
    private final MutableLiveData<OverlayState> overlayState = new MutableLiveData<>();
    private final MutableLiveData<AnimationSpec> animationSpec = new MutableLiveData<>();
    private final MutableLiveData<OneShotEffect> effect = new MutableLiveData<>();

    public OverlayViewModel(SettingsRepository settingsRepository, ScreenInfoProvider screenInfoProvider) {
        this.settingsRepository = settingsRepository;
        this.screenInfoProvider = screenInfoProvider;
        Settings settings = settingsRepository.loadSettings();
        overlayState.setValue(buildDefaultState(settings));
    }

    public LiveData<OverlayState> getOverlayState() {
        return overlayState;
    }

    public LiveData<AnimationSpec> getAnimationSpec() {
        return animationSpec;
    }

    public LiveData<OneShotEffect> getEffect() {
        return effect;
    }

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
                .withVisibility(true);
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        updated = OverlayConstraints.clampPosition(updated, bounds);
        overlayState.setValue(updated);
        animationSpec.setValue(null);
    }

    public void onRequestHide() {
        OverlayState current = requireState();
        if (current.soundEnabled) {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.PLAY_SOUND));
        }
        overlayState.setValue(current.withVisibility(true));
        animationSpec.setValue(new AnimationSpec(FADE_ANIM_MS, AnimType.FADE));
        effect.setValue(new OneShotEffect(OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE));
    }

    public void onOverlayHidden() {
        OverlayState current = requireState();
        overlayState.setValue(current.withVisibility(false));
    }

    public void onCloseClick() {
        OverlayState current = requireState();
        if (current.soundEnabled) {
            effect.setValue(new OneShotEffect(OneShotEffect.Type.PLAY_SOUND));
        }
        overlayState.setValue(current.withVisibility(true));
        animationSpec.setValue(new AnimationSpec(FADE_ANIM_MS, AnimType.FADE));
        effect.setValue(new OneShotEffect(OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE));
    }

    public void onDragStart() {
        OverlayState current = requireState();
        overlayState.setValue(current.withDragging(true));
        animationSpec.setValue(null);
    }

    public void onDragMove(int dxPx, int dyPx) {
        OverlayState current = requireState();
        OverlayState moved = current.withPosition(current.xPx + dxPx, current.yPx + dyPx);
        ScreenBounds bounds = screenInfoProvider.getCurrentBounds();
        OverlayState clamped = OverlayConstraints.clampPosition(moved, bounds).withDragging(true);
        overlayState.setValue(clamped);
        animationSpec.setValue(null);
    }

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

    public void onResizeStart() {
        OverlayState current = requireState();
        overlayState.setValue(current.withResizing(true));
        animationSpec.setValue(null);
    }

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

    public void onResizeEnd() {
        OverlayState current = requireState().withResizing(false);
        overlayState.setValue(current);
        settingsRepository.saveLastOverlayState(current);
        animationSpec.setValue(new AnimationSpec(RESIZE_ANIM_MS, AnimType.RESIZE));
    }

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

    public void onCloseButtonPositionChanged(CloseButtonPosition position) {
        Settings settings = settingsRepository.loadSettings().withCloseButtonPosition(position);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        overlayState.setValue(current.withCloseButtonPosition(position));
    }

    public void onSoundEnabledChanged(boolean enabled) {
        Settings settings = settingsRepository.loadSettings().withSoundEnabled(enabled);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        overlayState.setValue(current.withSoundEnabled(enabled));
    }

    public void onKeepAliveChanged(boolean enabled) {
        Settings settings = settingsRepository.loadSettings().withKeepAliveEnabled(enabled);
        settingsRepository.saveSettings(settings);
        OverlayState current = requireState();
        overlayState.setValue(current.withKeepAliveEnabled(enabled));
    }

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
                false,
                false
        );
    }
}
