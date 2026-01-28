package com.zimuzhedang.subtitleblocker.infra;

import android.util.Log;

public final class Logger {
    private static final String TAG = "SubtitleBlocker";

    private Logger() {
    }

    public static void i(String message) {
        Log.i(TAG, message);
    }

    public static void w(String message) {
        Log.w(TAG, message);
    }

    public static void e(String message, Throwable t) {
        Log.e(TAG, message, t);
    }
}

