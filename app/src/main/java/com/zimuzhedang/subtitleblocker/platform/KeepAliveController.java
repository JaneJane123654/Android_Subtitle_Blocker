package com.zimuzhedang.subtitleblocker.platform;

/**
 * 常驻后台服务控制器接口。
 * 用于启动或停止前台服务，以保持应用在后台运行。
 *
 * @author Trae
 * @since 2026-01-30
 */
public interface KeepAliveController {
    /** 启动常驻后台服务 */
    void start();

    /** 停止常驻后台服务 */
    void stop();
}

