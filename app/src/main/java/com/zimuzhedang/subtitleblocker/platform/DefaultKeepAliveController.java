package com.zimuzhedang.subtitleblocker.platform;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.content.ContextCompat;

import com.zimuzhedang.subtitleblocker.infra.Logger;

public final class DefaultKeepAliveController implements KeepAliveController {
    private final Context context;

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

    private boolean canStartForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                    == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }
}
