package com.zimuzhedang.subtitleblocker.data;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

import androidx.annotation.Nullable;

/**
 * GitHub Release 查询客户端。
 */
public final class GithubReleaseClient {
    private static final String API_URL = "https://api.github.com/repos/JaneJane123654/zimuzhedang/releases/latest";
    private static final int CONNECT_TIMEOUT_MS = 10000;
    private static final int READ_TIMEOUT_MS = 15000;

    public ReleaseInfo fetchLatestRelease() throws IOException, JSONException {
        HttpURLConnection connection = null;
        InputStream stream = null;
        try {
            connection = (HttpURLConnection) new URL(API_URL).openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(CONNECT_TIMEOUT_MS);
            connection.setReadTimeout(READ_TIMEOUT_MS);
            connection.setRequestProperty("Accept", "application/vnd.github+json");
            connection.setRequestProperty("X-GitHub-Api-Version", "2022-11-28");
            connection.setRequestProperty("User-Agent", "subtitle-blocker-android");

            int code = connection.getResponseCode();
            if (code < 200 || code >= 300) {
                throw new IOException("GitHub API http code=" + code);
            }

            stream = connection.getInputStream();
            String body = readAll(stream);
            JSONObject root = new JSONObject(body);
            String tagName = root.optString("tag_name", "0");
            String normalized = VersionNameComparator.normalize(tagName);
            String htmlUrl = root.optString("html_url", null);
            String apkUrl = findApkDownloadUrl(root.optJSONArray("assets"));
            return new ReleaseInfo(tagName, normalized, apkUrl, htmlUrl);
        } finally {
            if (stream != null) {
                stream.close();
            }
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    @Nullable
    private static String findApkDownloadUrl(@Nullable JSONArray assets) {
        if (assets == null) {
            return null;
        }
        for (int i = 0; i < assets.length(); i++) {
            JSONObject item = assets.optJSONObject(i);
            if (item == null) {
                continue;
            }
            String name = item.optString("name", "");
            if (!name.toLowerCase().endsWith(".apk")) {
                continue;
            }
            String url = item.optString("browser_download_url", "");
            if (!url.isEmpty()) {
                return url;
            }
        }
        return null;
    }

    private static String readAll(InputStream inputStream) throws IOException {
        StringBuilder builder = new StringBuilder();
        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
        char[] buffer = new char[2048];
        int count;
        while ((count = reader.read(buffer)) != -1) {
            builder.append(buffer, 0, count);
        }
        return builder.toString();
    }
}
