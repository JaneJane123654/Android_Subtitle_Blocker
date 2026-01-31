package com.zimuzhedang.subtitleblocker.platform;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.content.ContextCompat;

import com.zimuzhedang.subtitleblocker.infra.Logger;

/**
 * 常驻后台服务控制器的默认实现。
 * 通过 {@link KeepAliveService} 实现前台服务管理。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class DefaultKeepAliveController implements KeepAliveController {
    private final Context context;

    /**
     * 构造函数。
     *
     * @param context 上下文
     */
    public DefaultKeepAliveController(Context context) {
        this.context = context.getApplicationContext();
    }

    @Override
    public void start() {
        if (!canStartForegroundService()) {
            Logger.w("keep alive start blocked by notification permission");
            return;
        }
        Intent intent = new Intent(context, KeepAliveService.class);
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent);
            } else {
                context.startService(intent);
            }
        } catch (Exception e) {
            Logger.e("keep alive start failed", e);
        }
    }

    @Override
    public void stop() {
        Intent intent = new Intent(context, KeepAliveService.class);
        try {
            context.stopService(intent);
        } catch (Exception e) {
            Logger.e("keep alive stop failed", e);
        }
    }

    /**
     * 检查是否可以启动前台服务。
     * Android 13+ 需要通知权限才能显示前台服务通知。
     *
     * @return true 表示有权限或系统版本较低，false 表示缺失权限
     */
    private boolean canStartForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                    == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }
}
