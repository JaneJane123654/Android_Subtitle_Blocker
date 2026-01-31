package com.zimuzhedang.subtitleblocker.infra;

import android.util.Log;

/**
 * 统一日志工具类。
 * 封装了系统 {@link Log}，统一管理应用日志输出。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class Logger {
    /** 日志标签 */
    private static final String TAG = "SubtitleBlocker";

    private Logger() {
    }

    /**
     * 输出普通信息日志。
     *
     * @param message 日志内容
     */
    public static void i(String message) {
        Log.i(TAG, message);
    }

    /**
     * 输出警告信息日志。
     *
     * @param message 日志内容
     */
    public static void w(String message) {
        Log.w(TAG, message);
    }

    /**
     * 输出错误信息日志。
     *
     * @param message 错误描述
     * @param t 异常对象
     */
    public static void e(String message, Throwable t) {
        Log.e(TAG, message, t);
    }
}

