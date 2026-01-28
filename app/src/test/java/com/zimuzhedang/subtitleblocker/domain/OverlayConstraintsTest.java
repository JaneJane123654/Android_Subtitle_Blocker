package com.zimuzhedang.subtitleblocker.domain;

import androidx.core.graphics.Insets;

import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.is;

public final class OverlayConstraintsTest {
    @Test
    public void clampPosition_respectsInsets() {
        ScreenBounds bounds = new ScreenBounds(1000, 2000, Insets.of(10, 20, 30, 40));
        OverlayState state = new OverlayState(
                200,
                200,
                -100,
                10,
                true,
                CloseButtonPosition.RIGHT_TOP,
                false,
                false,
                false,
                false
        );
        OverlayState clamped = OverlayConstraints.clampPosition(state, bounds);
        assertThat(clamped.xPx, is(10));
        assertThat(clamped.yPx, is(20));
    }

    @Test
    public void clampSize_respectsMinMax() {
        ScreenBounds bounds = new ScreenBounds(1000, 2000, Insets.of(0, 0, 0, 0));
        OverlayState state = new OverlayState(
                10,
                10,
                0,
                0,
                true,
                CloseButtonPosition.RIGHT_TOP,
                false,
                false,
                false,
                false
        );
        OverlayState clamped = OverlayConstraints.clampSize(state, bounds, 100, 40);
        assertThat(clamped.widthPx, is(100));
        assertThat(clamped.heightPx, is(40));
    }

    @Test
    public void snapToEdge_prefersNearest() {
        ScreenBounds bounds = new ScreenBounds(1000, 2000, Insets.of(0, 0, 0, 0));
        OverlayState state = new OverlayState(
                200,
                200,
                5,
                0,
                true,
                CloseButtonPosition.RIGHT_TOP,
                false,
                false,
                false,
                false
        );
        OverlayState snapped = OverlayConstraints.snapToEdgeIfNeeded(state, bounds, 15);
        assertThat(snapped.xPx, is(0));
    }
}

