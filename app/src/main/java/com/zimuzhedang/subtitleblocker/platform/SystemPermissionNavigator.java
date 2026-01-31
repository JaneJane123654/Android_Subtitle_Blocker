package com.zimuzhedang.subtitleblocker.platform;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

/**
 * 系统权限导航器的具体实现。
 * 使用 Android 系统 API 进行权限检查和跳转。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class SystemPermissionNavigator implements PermissionNavigator {
    private final Context context;

    /**
     * 构造函数。
     *
     * @param context 上下文
     */
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
