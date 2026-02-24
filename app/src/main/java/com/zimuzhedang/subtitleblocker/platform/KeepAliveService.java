package com.zimuzhedang.subtitleblocker.platform;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Build;
import android.os.IBinder;
import android.os.LocaleList;
import java.util.Locale;

import androidx.annotation.Nullable;

import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SharedPreferencesSettingsRepository;
import com.zimuzhedang.subtitleblocker.domain.Settings;
import com.zimuzhedang.subtitleblocker.infra.Logger;
import com.zimuzhedang.subtitleblocker.ui.MainActivity;

/**
 * 常驻后台服务。
 * 通过启动前台服务（Foreground Service）并显示通知，降低应用被系统杀死的概率。
 * 注意：该服务只负责保持应用存活，不管理悬浮窗的生命周期。
 * 悬浮窗的显示/隐藏完全由 MainActivity 和 OverlayRuntime 管理。
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
        // 注意：KeepAliveService 只负责保持前台服务，不管理 OverlayRuntime
        // OverlayRuntime 的生命周期完全由 MainActivity 管理
    }

    /**
     * 配置前台服务。
     * 创建通知渠道（Android 8.0+）并启动前台通知。
     */
    private void setupForeground() {
        try {
            Context localizedContext = getLocalizedContext();
            NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager != null) {
                NotificationChannel channel = new NotificationChannel(CHANNEL_ID, localizedContext.getString(R.string.app_name), NotificationManager.IMPORTANCE_LOW);
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
        // 注意：不调用 OverlayRuntime.stop()
        // OverlayRuntime 的生命周期由 MainActivity 管理，服务停止不影响悬浮窗
        stopForeground(true);
        super.onDestroy();
    }

    /**
     * 构建前台服务显示的通知。
     *
     * @return 配置好的通知对象
     */
    private Notification buildNotification() {
        Context localizedContext = getLocalizedContext();
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
        builder.setContentTitle(localizedContext.getString(R.string.notification_keep_alive_title))
                .setContentText(localizedContext.getString(R.string.notification_keep_alive_text))
                .setSmallIcon(android.R.drawable.ic_menu_info_details)
                .setContentIntent(pendingIntent);
        return builder.build();
    }

    private Context getLocalizedContext() {
        SettingsRepository repository = new SharedPreferencesSettingsRepository(this);
        Settings settings = repository.loadSettings();
        return applyLanguage(this, settings.appLanguage);
    }

    private static Context applyLanguage(Context context, Settings.AppLanguage language) {
        if (language == Settings.AppLanguage.SYSTEM) {
            return context;
        }
        Locale locale = Locale.forLanguageTag(language.languageTag);
        Configuration config = new Configuration(context.getResources().getConfiguration());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            config.setLocales(new LocaleList(locale));
        } else {
            config.locale = locale;
        }
        return context.createConfigurationContext(config);
    }
}
