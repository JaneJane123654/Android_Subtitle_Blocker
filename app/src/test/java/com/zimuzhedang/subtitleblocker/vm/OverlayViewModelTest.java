package com.zimuzhedang.subtitleblocker.vm;

import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.domain.AnimType;
import com.zimuzhedang.subtitleblocker.domain.AnimationSpec;
import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;
import com.zimuzhedang.subtitleblocker.domain.OneShotEffect;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.domain.ScreenBounds;
import com.zimuzhedang.subtitleblocker.domain.Settings;
import com.zimuzhedang.subtitleblocker.platform.ScreenInfoProvider;

import androidx.arch.core.executor.testing.InstantTaskExecutorRule;
import androidx.core.graphics.Insets;

import org.junit.Assert;
import org.junit.Rule;
import org.junit.Test;

public final class OverlayViewModelTest {
    @Rule
    public final InstantTaskExecutorRule instantTaskExecutorRule = new InstantTaskExecutorRule();

    private static final class FakeSettingsRepository implements SettingsRepository {
        private Settings settings = new Settings(CloseButtonPosition.RIGHT_TOP, true, true, false, false, 5);
        private OverlayState lastState;
        @Override
        public Settings loadSettings() {
            return settings;
        }
        @Override
        public void saveSettings(Settings settings) {
            this.settings = settings;
        }
        @Override
        public OverlayState loadLastOverlayState() {
            return lastState;
        }
        @Override
        public void saveLastOverlayState(OverlayState state) {
            lastState = state;
        }
    }

    private static final class FakeScreenInfoProvider implements ScreenInfoProvider {
        private final ScreenBounds bounds = new ScreenBounds(1080, 1920, Insets.of(0, 24, 0, 0));
        @Override
        public ScreenBounds getCurrentBounds() {
            return bounds;
        }
        @Override
        public int dpToPx(float dp) {
            return Math.round(dp * 3);
        }
    }

    @Test
    public void show_keepsVisible_untilExplicitHide() {
        FakeSettingsRepository repo = new FakeSettingsRepository();
        FakeScreenInfoProvider screen = new FakeScreenInfoProvider();
        OverlayViewModel vm = new OverlayViewModel(repo, screen);
        vm.onRequestShow(true);
        OverlayState s1 = vm.getOverlayState().getValue();
        Assert.assertNotNull(s1);
        Assert.assertTrue(s1.visible);
        OverlayState s2 = vm.getOverlayState().getValue();
        Assert.assertTrue(s2.visible);
    }

    @Test
    public void show_keepsVisible_after30Seconds() throws InterruptedException {
        FakeSettingsRepository repo = new FakeSettingsRepository();
        FakeScreenInfoProvider screen = new FakeScreenInfoProvider();
        OverlayViewModel vm = new OverlayViewModel(repo, screen);
        vm.onRequestShow(true);
        Thread.sleep(31000);
        OverlayState state = vm.getOverlayState().getValue();
        Assert.assertNotNull(state);
        Assert.assertTrue(state.visible);
    }

    @Test
    public void close_triggersFadeAndHideEffect() {
        FakeSettingsRepository repo = new FakeSettingsRepository();
        FakeScreenInfoProvider screen = new FakeScreenInfoProvider();
        OverlayViewModel vm = new OverlayViewModel(repo, screen);
        vm.onRequestShow(true);
        vm.onCloseClick();
        AnimationSpec anim = vm.getAnimationSpec().getValue();
        OneShotEffect eff = vm.getEffect().getValue();
        Assert.assertNotNull(anim);
        Assert.assertEquals(AnimType.FADE, anim.type);
        Assert.assertNotNull(eff);
        Assert.assertEquals(OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE, eff.type);
    }

    @Test
    public void hide_triggersFadeAndHideEffect() {
        FakeSettingsRepository repo = new FakeSettingsRepository();
        FakeScreenInfoProvider screen = new FakeScreenInfoProvider();
        OverlayViewModel vm = new OverlayViewModel(repo, screen);
        vm.onRequestShow(true);
        vm.onRequestHide();
        AnimationSpec anim = vm.getAnimationSpec().getValue();
        OneShotEffect eff = vm.getEffect().getValue();
        Assert.assertNotNull(anim);
        Assert.assertEquals(AnimType.FADE, anim.type);
        Assert.assertNotNull(eff);
        Assert.assertEquals(OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE, eff.type);
    }

    @Test
    public void show_doesNotTriggerAutoHideEffect() {
        FakeSettingsRepository repo = new FakeSettingsRepository();
        FakeScreenInfoProvider screen = new FakeScreenInfoProvider();
        OverlayViewModel vm = new OverlayViewModel(repo, screen);
        vm.onRequestShow(true);
        OneShotEffect eff = vm.getEffect().getValue();
        Assert.assertTrue(eff == null || eff.type != OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE);
    }
}
