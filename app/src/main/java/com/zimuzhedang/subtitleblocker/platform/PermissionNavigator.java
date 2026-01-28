package com.zimuzhedang.subtitleblocker.platform;

import android.app.Activity;

public interface PermissionNavigator {
    boolean canDrawOverlays();

    void openOverlayPermissionSettings(Activity activity);
}

