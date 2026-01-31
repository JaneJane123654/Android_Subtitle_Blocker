package com.zimuzhedang.subtitleblocker.platform;

import android.app.Activity;

/**
 * 权限导航器接口。
 * 负责检查悬浮窗权限以及引导用户跳转到系统权限设置页面。
 *
 * @author Trae
 * @since 2026-01-30
 */
public interface PermissionNavigator {
    /**
     * 检查当前是否已授予悬浮窗权限。
     *
     * @return true 表示已授权，false 表示未授权
     */
    boolean canDrawOverlays();

    /**
     * 打开系统悬浮窗权限设置页面。
     *
     * @param activity 用于启动 Intent 的 Activity 实例
     */
    void openOverlayPermissionSettings(Activity activity);
}

