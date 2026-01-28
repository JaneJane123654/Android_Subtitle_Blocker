package com.zimuzhedang.subtitleblocker.platform;

import android.content.Context;
import android.graphics.Point;
import android.os.Build;
import android.view.WindowInsets;
import android.view.WindowManager;

import androidx.core.graphics.Insets;

import com.zimuzhedang.subtitleblocker.domain.ScreenBounds;

public final class DefaultScreenInfoProvider implements ScreenInfoProvider {
    private final Context context;
    private final WindowManager windowManager;

    public DefaultScreenInfoProvider(Context context) {
        this.context = context.getApplicationContext();
        this.windowManager = (WindowManager) this.context.getSystemService(Context.WINDOW_SERVICE);
    }

    @Override
    public ScreenBounds getCurrentBounds() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            android.view.WindowMetrics metrics = windowManager.getCurrentWindowMetrics();
            android.graphics.Rect bounds = metrics.getBounds();
            WindowInsets insets = metrics.getWindowInsets();
            android.graphics.Insets systemInsets = insets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
            Insets safeInsets = Insets.of(systemInsets.left, systemInsets.top, systemInsets.right, systemInsets.bottom);
            return new ScreenBounds(bounds.width(), bounds.height(), safeInsets);
        }
        Point size = new Point();
        windowManager.getDefaultDisplay().getSize(size);
        Insets safeInsets = Insets.of(0, 0, 0, 0);
        return new ScreenBounds(size.x, size.y, safeInsets);
    }

    @Override
    public int dpToPx(float dp) {
        return Math.round(dp * context.getResources().getDisplayMetrics().density);
    }
}
