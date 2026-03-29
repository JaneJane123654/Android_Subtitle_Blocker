package com.zimuzhedang.subtitleblocker.data;

import androidx.annotation.Nullable;

/**
 * GitHub Release 信息。
 */
public final class ReleaseInfo {
    public final String tagName;
    public final String normalizedVersion;
    @Nullable
    public final String apkDownloadUrl;
    @Nullable
    public final String releasePageUrl;

    public ReleaseInfo(
            String tagName,
            String normalizedVersion,
            @Nullable String apkDownloadUrl,
            @Nullable String releasePageUrl
    ) {
        this.tagName = tagName;
        this.normalizedVersion = normalizedVersion;
        this.apkDownloadUrl = apkDownloadUrl;
        this.releasePageUrl = releasePageUrl;
    }
}
