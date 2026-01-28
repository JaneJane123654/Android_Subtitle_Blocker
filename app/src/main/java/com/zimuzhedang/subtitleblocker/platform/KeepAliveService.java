package com.zimuzhedang.subtitleblocker.platform;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.infra.Logger;
import com.zimuzhedang.subtitleblocker.ui.MainActivity;

public final class KeepAliveService extends Service {
    private static final String CHANNEL_ID = "subtitle_blocker_keep_alive";

    @Override
    public void onCreate() {
        super.onCreate();
        try {
            NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager != null) {
                NotificationChannel channel = new NotificationChannel(CHANNEL_ID, getString(R.string.app_name), NotificationManager.IMPORTANCE_LOW);
                manager.createNotificationChannel(channel);
            }
            Notification notification = buildNotification();
            startForeground(1, notification);
        } catch (Exception e) {
            Logger.e("keep alive startForeground failed", e);
            stopSelf();
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        stopForeground(true);
        super.onDestroy();
    }

    private Notification buildNotification() {
        Intent intent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ? PendingIntent.FLAG_IMMUTABLE : 0
        );
        Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? new Notification.Builder(this, CHANNEL_ID)
                : new Notification.Builder(this);
        builder.setContentTitle(getString(R.string.notification_keep_alive_title))
                .setContentText(getString(R.string.notification_keep_alive_text))
                .setSmallIcon(android.R.drawable.ic_menu_info_details)
                .setContentIntent(pendingIntent);
        return builder.build();
    }
}
