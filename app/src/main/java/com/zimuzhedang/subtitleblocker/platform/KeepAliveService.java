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

/**
 * 常驻后台服务。
 * 通过启动前台服务（Foreground Service）并显示通知，降低应用被系统杀死的概率。
 * 该服务还负责在后台模式下启动和停止 {@link OverlayRuntime}。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class KeepAliveService extends Service {
    /** 通知渠道 ID */
    private static final String CHANNEL_ID = "subtitle_blocker_keep_alive";

    @Override
    public void onCreate() {
        super.onCreate();
        setupForeground();
        // 注意：不传入 stopCallback，避免隐藏遮罩时服务自杀导致应用退出
        // 服务的停止应该由 MainActivity 通过 keepAliveController.stop() 控制
        OverlayRuntime.getInstance().start(this);
    }

    /**
     * 配置前台服务。
     * 创建通知渠道（Android 8.0+）并启动前台通知。
     */
    private void setupForeground() {
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
        OverlayRuntime.getInstance().stop();
        stopForeground(true);
        super.onDestroy();
    }

    /**
     * 构建前台服务显示的通知。
     *
     * @return 配置好的通知对象
     */
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
