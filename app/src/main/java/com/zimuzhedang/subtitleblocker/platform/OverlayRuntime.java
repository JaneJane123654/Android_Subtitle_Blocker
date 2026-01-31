package com.zimuzhedang.subtitleblocker.platform;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.lifecycle.Observer;

import com.zimuzhedang.subtitleblocker.data.SoundPlayer;
import com.zimuzhedang.subtitleblocker.data.ToneSoundPlayer;
import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;
import com.zimuzhedang.subtitleblocker.domain.OneShotEffect;
import com.zimuzhedang.subtitleblocker.domain.OverlayManager;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.ui.OverlayViewBinder;
import com.zimuzhedang.subtitleblocker.ui.OverlayWindowView;
import com.zimuzhedang.subtitleblocker.vm.OverlayViewModel;

/**
 * 悬浮窗运行时环境，负责连接 ViewModel 和具体的 Android 平台实现。
 * 处理视图绑定、动画执行、声音播放以及悬浮窗的生命周期管理。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class OverlayRuntime {
    private static OverlayRuntime instance;

    private OverlayViewModel viewModel;
    private OverlayWindowView overlayView;
    private FloatWindowController windowController;
    private OverlayViewBinder viewBinder;
    private SoundPlayer soundPlayer;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private AnimationSpec pendingAnim;
    private boolean started;
    private Runnable stopCallback;
    /** 用于精确取消隐藏任务的 Runnable 引用 */
    private Runnable hideRunnable;

    private final Observer<OverlayState> stateObserver = this::renderOverlay;
    private final Observer<AnimationSpec> animObserver = spec -> pendingAnim = spec;
    private final Observer<OneShotEffect> effectObserver = this::handleEffect;

    private OverlayRuntime() {}

    /**
     * 获取 OverlayRuntime 的单例实例。
     *
     * @return OverlayRuntime 实例
     */
    public static synchronized OverlayRuntime getInstance() {
        if (instance == null) {
            instance = new OverlayRuntime();
        }
        return instance;
    }

    /**
     * 启动悬浮窗运行时。
     *
     * @param context Android 上下文
     */
    public synchronized void start(Context context) {
        start(context, null);
    }

    /**
     * 启动悬浮窗运行时。
     *
     * @param context Android 上下文
     * @param stopCallback 当悬浮窗停止显示时的回调
     */
    public synchronized void start(Context context, Runnable stopCallback) {
        if (started) {
            if (stopCallback != null) {
                this.stopCallback = stopCallback;
            }
            return;
        }
        // 取消可能残留的隐藏任务，防止之前的延迟任务影响新的显示
        cancelPendingHide();
        viewModel = OverlayManager.getInstance().getViewModel(context.getApplicationContext());
        windowController = new WindowManagerFloatWindowController(context.getApplicationContext());
        overlayView = new OverlayWindowView(context.getApplicationContext());
        viewBinder = new OverlayViewBinder(windowController, overlayView);
        soundPlayer = new ToneSoundPlayer();

        overlayView.setListener(new OverlayWindowView.Listener() {
            @Override
            public void onClose() {
                viewModel.onCloseClick();
            }

            @Override
            public void onDragStart() {
                viewModel.onDragStart();
            }

            @Override
            public void onDragMove(int dxPx, int dyPx) {
                viewModel.onDragMove(dxPx, dyPx);
            }

            @Override
            public void onDragEnd() {
                viewModel.onDragEnd();
            }

            @Override
            public void onResizeStart() {
                viewModel.onResizeStart();
            }

            @Override
            public void onResizeMove(int dwPx, int dhPx) {
                viewModel.onResizeMove(dwPx, dhPx);
            }

            @Override
            public void onResizeEnd() {
                viewModel.onResizeEnd();
            }
        });

        viewModel.getOverlayState().observeForever(stateObserver);
        viewModel.getAnimationSpec().observeForever(animObserver);
        viewModel.getEffect().observeForever(effectObserver);
        this.stopCallback = stopCallback;
        started = true;
    }

    /**
     * 停止悬浮窗运行时，移除所有观察者并隐藏视图。
     */
    public synchronized void stop() {
        if (!started) {
            return;
        }
        // 取消所有待执行的 Handler 任务，防止已注册的隐藏任务在 stop 后仍然执行
        cancelPendingHide();
        if (viewModel != null) {
            viewModel.getOverlayState().removeObserver(stateObserver);
            viewModel.getAnimationSpec().removeObserver(animObserver);
            viewModel.getEffect().removeObserver(effectObserver);
        }
        if (windowController != null) {
            windowController.hide();
        }
        stopCallback = null;
        started = false;
    }

    /**
     * 取消待执行的隐藏任务。
     */
    private void cancelPendingHide() {
        if (hideRunnable != null) {
            handler.removeCallbacks(hideRunnable);
            hideRunnable = null;
        }
        // 额外清除所有可能残留的回调
        handler.removeCallbacksAndMessages(null);
    }

    /**
     * 渲染悬浮窗状态。
     *
     * @param state 悬浮窗状态
     */
    private void renderOverlay(OverlayState state) {
        if (state == null) {
            return;
        }
        soundPlayer.setEnabled(state.soundEnabled);
        viewBinder.bind(state, pendingAnim);
        pendingAnim = null;
    }

    /**
     * 处理一次性副作用。
     *
     * @param effect 副作用类型
     */
    private void handleEffect(OneShotEffect effect) {
        if (effect == null) {
            return;
        }
        // 使用 consume() 确保每个副作用只被处理一次
        if (!effect.consume()) {
            return;
        }
        if (effect.type == OneShotEffect.Type.PLAY_SOUND) {
            soundPlayer.playClick();
        } else if (effect.type == OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE) {
            // 先取消之前可能存在的隐藏任务，避免重复执行
            cancelPendingHide();
            hideRunnable = () -> {
                if (!started) {
                    // 如果已经停止，不执行隐藏操作
                    return;
                }
                windowController.hide();
                viewModel.onOverlayHidden();
                hideRunnable = null;
                if (stopCallback != null) {
                    stopCallback.run();
                }
            };
            handler.postDelayed(hideRunnable, 320L);
        }
        viewModel.clearEffect();
    }
}
