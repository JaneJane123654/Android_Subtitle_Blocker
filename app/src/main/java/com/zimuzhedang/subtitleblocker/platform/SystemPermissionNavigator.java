package com.zimuzhedang.subtitleblocker.platform;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

public final class SystemPermissionNavigator implements PermissionNavigator {
    private final Context context;

    public SystemPermissionNavigator(Context context) {
        this.context = context.getApplicationContext();
    }

    @Override
    public boolean canDrawOverlays() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true;
        }
        return Settings.canDrawOverlays(context);
    }

    @Override
    public void openOverlayPermissionSettings(Activity activity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return;
        }
        Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + activity.getPackageName()));
        activity.startActivity(intent);
    }
}
