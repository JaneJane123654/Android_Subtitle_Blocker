package com.zimuzhedang.subtitleblocker.ui;

import android.Manifest;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.LocaleList;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.data.GithubReleaseClient;
import com.zimuzhedang.subtitleblocker.data.ReleaseInfo;
import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SharedPreferencesSettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SoundPlayer;
import com.zimuzhedang.subtitleblocker.data.ToneSoundPlayer;
import com.zimuzhedang.subtitleblocker.data.VersionNameComparator;
import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;
import com.zimuzhedang.subtitleblocker.domain.OneShotEffect;
import com.zimuzhedang.subtitleblocker.domain.OverlayManager;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.domain.Settings;
import com.zimuzhedang.subtitleblocker.infra.Logger;
import com.zimuzhedang.subtitleblocker.platform.DefaultKeepAliveController;
import com.zimuzhedang.subtitleblocker.platform.KeepAliveController;
import com.zimuzhedang.subtitleblocker.platform.OverlayRuntime;
import com.zimuzhedang.subtitleblocker.platform.PermissionNavigator;
import com.zimuzhedang.subtitleblocker.platform.SystemPermissionNavigator;
import com.zimuzhedang.subtitleblocker.vm.OverlayViewModel;

/**
 * 应用主界面。
 * 负责展示设置项、控制悬浮窗的开启与关闭、处理权限申请以及配置的导入导出。
 *
 * @author Trae
 * @since 2026-01-30
 */
public final class MainActivity extends AppCompatActivity {
    /** 通知权限请求码 */
    private static final int REQUEST_POST_NOTIFICATIONS = 1001;
    private static final int MIN_MINIMIZE_DOT_SIZE_DP = 10;
    private static final int MAX_MINIMIZE_DOT_SIZE_DP = 200;
    private static final int UPDATE_CONNECT_TIMEOUT_MS = 10000;
    private static final int UPDATE_READ_TIMEOUT_MS = 30000;
    private static final String UPDATE_APK_DIR = "updates";
    private static final String UPDATE_APK_FILE_NAME = "subtitle-blocker-latest.apk";

    private OverlayViewModel viewModel;
    /** 权限导航器 */
    private PermissionNavigator permissionNavigator;
    /** 常驻后台控制器 */
    private KeepAliveController keepAliveController;
    /** 音效播放器 */
    private SoundPlayer soundPlayer;
    /** 配置仓库 */
    private SettingsRepository settingsRepository;
    private final GithubReleaseClient releaseClient = new GithubReleaseClient();
    private final ExecutorService updateExecutor = Executors.newSingleThreadExecutor();
    private volatile boolean checkingUpdate;
    /** 当前悬浮窗状态缓存 */
    private OverlayState currentState;

    private MaterialButton btnEnable;
    private MaterialButton btnDisable;
    private MaterialButton btnOpenPermission;
    private MaterialButton btnCheckUpdate;
    private MaterialButton btnExportConfig;
    private MaterialButton btnImportConfig;
    private MaterialButton btnUsage;
    private RadioGroup rgClosePosition;
    private RadioButton rbLeftTop;
    private RadioButton rbRightTop;
    private RadioGroup rgLanguage;
    private RadioButton rbLangSystem;
    private RadioButton rbLangZh;
    private RadioButton rbLangEn;
    private RadioButton rbLangFr;
    private RadioButton rbLangEs;
    private RadioButton rbLangRu;
    private RadioButton rbLangAr;
    private SwitchMaterial switchSound;
    private SwitchMaterial switchKeepAlive;
    private SwitchMaterial switchTransparencyToggle;
    private SwitchMaterial switchTransparencyAutoRestore;
    private SwitchMaterial switchMinimizeDotRotate;
    private EditText editTransparencySeconds;
    private SeekBar seekMinimizeDotSize;
    private TextView textMinimizeDotSizeValue;
    private boolean updatingTransparencySeconds;
    private boolean updatingLanguage;
    private Settings.AppLanguage currentAppLanguage;

    @Override
    protected void attachBaseContext(Context newBase) {
        SettingsRepository repository = new SharedPreferencesSettingsRepository(newBase);
        Settings settings = repository.loadSettings();
        super.attachBaseContext(applyLanguage(newBase, settings.appLanguage));
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        settingsRepository = new SharedPreferencesSettingsRepository(this);
        viewModel = OverlayManager.getInstance().getViewModel(this);
        permissionNavigator = new SystemPermissionNavigator(this);
        keepAliveController = new DefaultKeepAliveController(this);
        soundPlayer = new ToneSoundPlayer();

        bindViews();
        bindViewModel();
        Settings settings = settingsRepository.loadSettings();
        currentAppLanguage = settings.appLanguage;
        setupSettingsUi(settings);
        if (savedInstanceState == null) {
            checkForUpdate(false);
        }
    }

    /**
     * 绑定视图组件并设置监听器。
     */
    private void bindViews() {
        btnEnable = findViewById(R.id.btnEnable);
        btnDisable = findViewById(R.id.btnDisable);
        btnOpenPermission = findViewById(R.id.btnOpenPermission);
        btnCheckUpdate = findViewById(R.id.btnCheckUpdate);
        btnExportConfig = findViewById(R.id.btnExportConfig);
        btnImportConfig = findViewById(R.id.btnImportConfig);
        btnUsage = findViewById(R.id.btnUsage);
        rgClosePosition = findViewById(R.id.rgClosePosition);
        rbLeftTop = findViewById(R.id.rbLeftTop);
        rbRightTop = findViewById(R.id.rbRightTop);
        rgLanguage = findViewById(R.id.rgLanguage);
        rbLangSystem = findViewById(R.id.rbLangSystem);
        rbLangZh = findViewById(R.id.rbLangZh);
        rbLangEn = findViewById(R.id.rbLangEn);
        rbLangFr = findViewById(R.id.rbLangFr);
        rbLangEs = findViewById(R.id.rbLangEs);
        rbLangRu = findViewById(R.id.rbLangRu);
        rbLangAr = findViewById(R.id.rbLangAr);
        switchSound = findViewById(R.id.switchSound);
        switchKeepAlive = findViewById(R.id.switchKeepAlive);
        switchTransparencyToggle = findViewById(R.id.switchTransparencyToggle);
        switchTransparencyAutoRestore = findViewById(R.id.switchTransparencyAutoRestore);
        switchMinimizeDotRotate = findViewById(R.id.switchMinimizeDotRotate);
        editTransparencySeconds = findViewById(R.id.editTransparencySeconds);
        seekMinimizeDotSize = findViewById(R.id.seekMinimizeDotSize);
        textMinimizeDotSizeValue = findViewById(R.id.textMinimizeDotSizeValue);

        btnEnable.setOnClickListener(v -> viewModel.onRequestShow(permissionNavigator.canDrawOverlays()));
        btnDisable.setOnClickListener(v -> viewModel.onRequestHide());
        btnOpenPermission.setOnClickListener(v -> permissionNavigator.openOverlayPermissionSettings(this));
        btnCheckUpdate.setOnClickListener(v -> checkForUpdate(true));
        btnExportConfig.setOnClickListener(v -> exportConfig());
        btnImportConfig.setOnClickListener(v -> importConfig());
        btnUsage.setOnClickListener(v -> startActivity(new android.content.Intent(this, UsageActivity.class)));
        updateCheckButtonState();

        rgClosePosition.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.rbLeftTop) {
                viewModel.onCloseButtonPositionChanged(CloseButtonPosition.LEFT_TOP);
            } else if (checkedId == R.id.rbRightTop) {
                viewModel.onCloseButtonPositionChanged(CloseButtonPosition.RIGHT_TOP);
            }
        });

        rgLanguage.setOnCheckedChangeListener((group, checkedId) -> {
            if (updatingLanguage) {
                return;
            }
            Settings.AppLanguage language = resolveLanguageById(checkedId);
            Settings settings = settingsRepository.loadSettings().withAppLanguage(language);
            settingsRepository.saveSettings(settings);
            applyLanguageChange(language);
        });

        switchSound.setOnCheckedChangeListener((buttonView, isChecked) -> viewModel.onSoundEnabledChanged(isChecked));
        switchKeepAlive.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked && !hasPostNotificationsPermission()) {
                requestPostNotificationsPermission();
                switchKeepAlive.setChecked(false);
                return;
            }
            viewModel.onKeepAliveChanged(isChecked);
        });
        switchTransparencyToggle.setOnCheckedChangeListener((buttonView, isChecked) -> {
            viewModel.onTransparencyToggleEnabledChanged(isChecked);
            if (!isChecked) {
                switchTransparencyAutoRestore.setChecked(false);
            }
            updateTransparencySettingsUi();
        });
        switchTransparencyAutoRestore.setOnCheckedChangeListener((buttonView, isChecked) -> {
            viewModel.onTransparencyAutoRestoreEnabledChanged(isChecked);
            updateTransparencySettingsUi();
        });
        switchMinimizeDotRotate.setOnCheckedChangeListener((buttonView, isChecked) ->
                viewModel.onMinimizeDotRotateEnabledChanged(isChecked)
        );
        editTransparencySeconds.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}

            @Override
            public void afterTextChanged(Editable s) {
                if (updatingTransparencySeconds) {
                    return;
                }
                int seconds = parseAutoRestoreSeconds(s.toString());
                viewModel.onTransparencyAutoRestoreSecondsChanged(seconds);
            }
        });
        seekMinimizeDotSize.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                int sizeDp = progressToMinimizeDotSize(progress);
                updateMinimizeDotSizeLabel(sizeDp);
                if (fromUser) {
                    viewModel.onMinimizeDotSizeChanged(sizeDp);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });
    }

    /**
     * 绑定 ViewModel 数据流。
     */
    private void bindViewModel() {
        viewModel.getOverlayState().observe(this, this::renderOverlay);
        viewModel.getEffect().observe(this, effect -> {
            if (effect == null) {
                return;
            }
            // MainActivity 只处理 NAVIGATE_TO_PERMISSION 和 PLAY_SOUND
            // REQUEST_HIDE_AFTER_FADE 由 OverlayRuntime 处理，不在这里消费
            if (effect.type == OneShotEffect.Type.NAVIGATE_TO_PERMISSION) {
                if (effect.consume()) {
                    Toast.makeText(this, R.string.action_open_permission, Toast.LENGTH_SHORT).show();
                    permissionNavigator.openOverlayPermissionSettings(this);
                    viewModel.clearEffect();
                }
            } else if (effect.type == OneShotEffect.Type.PLAY_SOUND) {
                if (effect.consume()) {
                    soundPlayer.playClick();
                    viewModel.clearEffect();
                }
            }
            // 注意：不处理 REQUEST_HIDE_AFTER_FADE，让 OverlayRuntime 处理
        });
    }

    /**
     * 根据状态渲染悬浮窗。
     *
     * @param state 悬浮窗状态
     */
    private void renderOverlay(OverlayState state) {
        if (state == null) {
            return;
        }
        currentState = state;
        soundPlayer.setEnabled(state.soundEnabled);
        if (state.visible) {
            OverlayRuntime.getInstance().start(this);
            if (state.keepAliveEnabled) {
                keepAliveController.start();
            } else {
                keepAliveController.stop();
            }
        } else {
            keepAliveController.stop();
            OverlayRuntime.getInstance().stop();
        }
    }

    /**
     * 初始化设置界面的 UI 状态。
     *
     * @param settings 持久化配置
     */
    private void setupSettingsUi(Settings settings) {
        if (settings.closeButtonPosition == CloseButtonPosition.LEFT_TOP) {
            rbLeftTop.setChecked(true);
        } else {
            rbRightTop.setChecked(true);
        }
        updatingLanguage = true;
        switch (settings.appLanguage) {
            case ZH:
                rbLangZh.setChecked(true);
                break;
            case EN:
                rbLangEn.setChecked(true);
                break;
            case FR:
                rbLangFr.setChecked(true);
                break;
            case ES:
                rbLangEs.setChecked(true);
                break;
            case RU:
                rbLangRu.setChecked(true);
                break;
            case AR:
                rbLangAr.setChecked(true);
                break;
            case SYSTEM:
            default:
                rbLangSystem.setChecked(true);
                break;
        }
        updatingLanguage = false;
        switchSound.setChecked(settings.soundEnabled);
        switchKeepAlive.setChecked(settings.keepAliveEnabled);
        switchTransparencyToggle.setChecked(settings.transparencyToggleEnabled);
        switchTransparencyAutoRestore.setChecked(settings.transparencyAutoRestoreEnabled);
        updatingTransparencySeconds = true;
        editTransparencySeconds.setText(String.valueOf(settings.transparencyAutoRestoreSeconds));
        editTransparencySeconds.setSelection(editTransparencySeconds.getText().length());
        updatingTransparencySeconds = false;

        int dotSizeDp = clampMinimizeDotSize(settings.minimizeDotSize);
        seekMinimizeDotSize.setMax(MAX_MINIMIZE_DOT_SIZE_DP - MIN_MINIMIZE_DOT_SIZE_DP);
        seekMinimizeDotSize.setProgress(minimizeDotSizeToProgress(dotSizeDp));
        updateMinimizeDotSizeLabel(dotSizeDp);
        switchMinimizeDotRotate.setChecked(settings.minimizeDotRotateEnabled);

        updateTransparencySettingsUi();
    }

    @Override
    protected void onResume() {
        super.onResume();
        Settings latest = settingsRepository.loadSettings();
        switchMinimizeDotRotate.setChecked(latest.minimizeDotRotateEnabled);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        updateExecutor.shutdownNow();
    }

    private void checkForUpdate(boolean manual) {
        if (checkingUpdate) {
            if (manual) {
                Toast.makeText(this, R.string.toast_update_checking, Toast.LENGTH_SHORT).show();
            }
            return;
        }
        checkingUpdate = true;
        updateCheckButtonState();
        if (manual) {
            Toast.makeText(this, R.string.toast_update_checking, Toast.LENGTH_SHORT).show();
        }
        updateExecutor.execute(() -> {
            try {
                ReleaseInfo releaseInfo = releaseClient.fetchLatestRelease();
                runOnUiThread(() -> handleLatestRelease(releaseInfo, manual));
            } catch (Exception e) {
                Logger.e("check update failed", e);
                runOnUiThread(() -> {
                    if (manual) {
                        Toast.makeText(this, R.string.toast_update_check_failed, Toast.LENGTH_SHORT).show();
                    }
                });
            } finally {
                runOnUiThread(() -> {
                    checkingUpdate = false;
                    updateCheckButtonState();
                });
            }
        });
    }

    private void handleLatestRelease(ReleaseInfo releaseInfo, boolean manual) {
        String currentVersionName = getCurrentVersionName();
        String currentNormalizedVersion = VersionNameComparator.normalize(currentVersionName);
        if (!VersionNameComparator.isNewer(releaseInfo.normalizedVersion, currentNormalizedVersion)) {
            if (manual) {
                Toast.makeText(this, R.string.toast_already_latest, Toast.LENGTH_SHORT).show();
            }
            return;
        }

        String ignoredVersion = settingsRepository.loadIgnoredUpdateVersion();
        if (ignoredVersion != null && VersionNameComparator.compare(releaseInfo.normalizedVersion, ignoredVersion) <= 0) {
            if (manual) {
                Toast.makeText(this, R.string.toast_update_ignored_until_newer, Toast.LENGTH_SHORT).show();
            }
            return;
        }
        showUpdateDialog(releaseInfo, currentNormalizedVersion);
    }

    private void showUpdateDialog(ReleaseInfo releaseInfo, String currentNormalizedVersion) {
        String latestDisplay = displayVersion(releaseInfo);
        String message = getString(
                R.string.update_dialog_message,
                currentNormalizedVersion,
                latestDisplay
        );
        new AlertDialog.Builder(this)
                .setTitle(R.string.update_dialog_title)
                .setMessage(message)
                .setPositiveButton(R.string.action_update_now, (dialog, which) -> {
                    settingsRepository.saveIgnoredUpdateVersion(null);
                    startDownloadAndInstall(releaseInfo);
                })
                .setNegativeButton(R.string.action_remind_next_version, (dialog, which) -> {
                    settingsRepository.saveIgnoredUpdateVersion(releaseInfo.normalizedVersion);
                    Toast.makeText(this, R.string.toast_update_ignore_set, Toast.LENGTH_SHORT).show();
                })
                .setNeutralButton(R.string.action_cancel, null)
                .show();
    }

    private void startDownloadAndInstall(ReleaseInfo releaseInfo) {
        if (releaseInfo.apkDownloadUrl == null || releaseInfo.apkDownloadUrl.trim().isEmpty()) {
            Toast.makeText(this, R.string.toast_update_download_unavailable, Toast.LENGTH_SHORT).show();
            openReleasePage(releaseInfo.releasePageUrl);
            return;
        }
        Toast.makeText(this, R.string.toast_update_downloading, Toast.LENGTH_SHORT).show();
        updateExecutor.execute(() -> {
            try {
                File apkFile = downloadLatestApk(releaseInfo.apkDownloadUrl);
                runOnUiThread(() -> installDownloadedApk(apkFile));
            } catch (Exception e) {
                Logger.e("download latest apk failed", e);
                runOnUiThread(() -> {
                    Toast.makeText(this, R.string.toast_update_download_failed, Toast.LENGTH_SHORT).show();
                    openReleasePage(releaseInfo.releasePageUrl);
                });
            }
        });
    }

    private File downloadLatestApk(String apkUrl) throws Exception {
        File baseDir = getExternalFilesDir(null);
        if (baseDir == null) {
            baseDir = getFilesDir();
        }
        File updateDir = new File(baseDir, UPDATE_APK_DIR);
        if (!updateDir.exists() && !updateDir.mkdirs()) {
            throw new IllegalStateException("create update dir failed");
        }

        File target = new File(updateDir, UPDATE_APK_FILE_NAME);
        HttpURLConnection connection = null;
        InputStream inputStream = null;
        FileOutputStream outputStream = null;
        try {
            connection = (HttpURLConnection) new URL(apkUrl).openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(UPDATE_CONNECT_TIMEOUT_MS);
            connection.setReadTimeout(UPDATE_READ_TIMEOUT_MS);
            connection.setRequestProperty("User-Agent", "subtitle-blocker-android");

            int responseCode = connection.getResponseCode();
            if (responseCode < 200 || responseCode >= 300) {
                throw new IllegalStateException("download http code=" + responseCode);
            }

            inputStream = connection.getInputStream();
            outputStream = new FileOutputStream(target, false);
            byte[] buffer = new byte[8192];
            int len;
            while ((len = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, len);
            }
            outputStream.flush();
            return target;
        } finally {
            if (inputStream != null) {
                inputStream.close();
            }
            if (outputStream != null) {
                outputStream.close();
            }
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    private void installDownloadedApk(File apkFile) {
        if (!apkFile.exists()) {
            Toast.makeText(this, R.string.toast_update_download_failed, Toast.LENGTH_SHORT).show();
            return;
        }
        Uri apkUri = FileProvider.getUriForFile(
                this,
                getPackageName() + ".fileprovider",
                apkFile
        );
        Intent installIntent = new Intent(Intent.ACTION_VIEW);
        installIntent.setDataAndType(apkUri, "application/vnd.android.package-archive");
        installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        try {
            startActivity(installIntent);
            Toast.makeText(this, R.string.toast_update_install_start, Toast.LENGTH_SHORT).show();
        } catch (ActivityNotFoundException e) {
            Logger.e("no installer activity found", e);
            Toast.makeText(this, R.string.toast_update_install_failed, Toast.LENGTH_SHORT).show();
        }
    }

    private void openReleasePage(@Nullable String releasePageUrl) {
        if (releasePageUrl == null || releasePageUrl.trim().isEmpty()) {
            return;
        }
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(releasePageUrl));
        try {
            startActivity(browserIntent);
        } catch (ActivityNotFoundException e) {
            Logger.e("open release page failed", e);
        }
    }

    private String displayVersion(ReleaseInfo releaseInfo) {
        if (releaseInfo.tagName != null && !releaseInfo.tagName.trim().isEmpty()) {
            return releaseInfo.tagName;
        }
        return releaseInfo.normalizedVersion;
    }

    private String getCurrentVersionName() {
        try {
            PackageInfo info = getPackageManager().getPackageInfo(getPackageName(), 0);
            if (info.versionName == null || info.versionName.trim().isEmpty()) {
                return "0";
            }
            return info.versionName;
        } catch (Exception e) {
            Logger.e("read current version failed", e);
            return "0";
        }
    }

    private void updateCheckButtonState() {
        if (btnCheckUpdate == null) {
            return;
        }
        btnCheckUpdate.setEnabled(!checkingUpdate);
        btnCheckUpdate.setText(checkingUpdate ? R.string.action_checking_update : R.string.action_check_update);
    }

    /**
     * 导出当前配置到剪贴板（JSON 格式）。
     */
    private void exportConfig() {
        try {
            Settings settings = settingsRepository.loadSettings();
            OverlayState state = currentState != null ? currentState : settingsRepository.loadLastOverlayState();
            if (state == null) {
                Toast.makeText(this, R.string.toast_import_failed, Toast.LENGTH_SHORT).show();
                return;
            }
            JSONObject json = new JSONObject();
            json.put("widthPx", state.widthPx);
            json.put("heightPx", state.heightPx);
            json.put("xPx", state.xPx);
            json.put("yPx", state.yPx);
            json.put("closeButtonPosition", settings.closeButtonPosition.name());
            json.put("soundEnabled", settings.soundEnabled);
            json.put("keepAliveEnabled", settings.keepAliveEnabled);
            json.put("appLanguage", settings.appLanguage.value);
            json.put("transparencyToggleEnabled", settings.transparencyToggleEnabled);
            json.put("transparencyAutoRestoreEnabled", settings.transparencyAutoRestoreEnabled);
            json.put("transparencyAutoRestoreSeconds", settings.transparencyAutoRestoreSeconds);
            json.put("minimizeDotSize", settings.minimizeDotSize);
            json.put("minimizeDotRotateEnabled", settings.minimizeDotRotateEnabled);
            ClipboardManager clipboard = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
            clipboard.setPrimaryClip(ClipData.newPlainText("overlay_config", json.toString()));
            Toast.makeText(this, R.string.toast_exported, Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            Toast.makeText(this, R.string.toast_import_failed, Toast.LENGTH_SHORT).show();
        }
    }

    /**
     * 从剪贴板导入 JSON 配置。
     */
    private void importConfig() {
        ClipboardManager clipboard = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
        if (clipboard == null || !clipboard.hasPrimaryClip()) {
            Toast.makeText(this, R.string.toast_import_failed, Toast.LENGTH_SHORT).show();
            return;
        }
        try {
            ClipData clipData = clipboard.getPrimaryClip();
            if (clipData == null || clipData.getItemCount() == 0) {
                Toast.makeText(this, R.string.toast_import_failed, Toast.LENGTH_SHORT).show();
                return;
            }
            String text = String.valueOf(clipData.getItemAt(0).coerceToText(this));
            JSONObject json = new JSONObject(text);
            int width = json.getInt("widthPx");
            int height = json.getInt("heightPx");
            int x = json.getInt("xPx");
            int y = json.getInt("yPx");
            CloseButtonPosition position = CloseButtonPosition.valueOf(json.getString("closeButtonPosition"));
            boolean soundEnabled = json.getBoolean("soundEnabled");
            boolean keepAliveEnabled = json.getBoolean("keepAliveEnabled");
            Settings.AppLanguage appLanguage = Settings.AppLanguage.fromValue(json.optString("appLanguage"));
            boolean transparencyToggleEnabled = json.optBoolean("transparencyToggleEnabled", true);
            boolean transparencyAutoRestoreEnabled = json.optBoolean("transparencyAutoRestoreEnabled", false);
            int transparencyAutoRestoreSeconds = json.optInt("transparencyAutoRestoreSeconds", 5);
            Settings settings = new Settings(
                    position,
                    soundEnabled,
                    keepAliveEnabled,
                    appLanguage,
                    transparencyToggleEnabled,
                    transparencyAutoRestoreEnabled,
                    transparencyAutoRestoreSeconds,
                    json.optInt("minimizeDotSize", 40),
                    json.optBoolean("minimizeDotRotateEnabled", false),
                    settingsRepository.loadIgnoredUpdateVersion()
            );
            OverlayState state = new OverlayState(
                    width,
                    height,
                    x,
                    y,
                    currentState != null && currentState.visible,
                    position,
                    soundEnabled,
                    keepAliveEnabled,
                    transparencyToggleEnabled,
                    false,
                    false,
                    false,
                    false
            );
            viewModel.applyImportedState(state, settings);
            setupSettingsUi(settings);
            applyLanguageChange(settings.appLanguage);
            Toast.makeText(this, R.string.toast_import_success, Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            Toast.makeText(this, R.string.toast_import_failed, Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_POST_NOTIFICATIONS) {
            boolean granted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
            switchKeepAlive.setChecked(granted);
            viewModel.onKeepAliveChanged(granted);
        }
    }

    /**
     * 检查是否已授予发送通知权限（Android 13+）。
     *
     * @return true 表示已授权或版本低于 Android 13
     */
    private boolean hasPostNotificationsPermission() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) {
            return true;
        }
        return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED;
    }

    /**
     * 请求发送通知权限（Android 13+）。
     */
    private void requestPostNotificationsPermission() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) {
            return;
        }
        ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.POST_NOTIFICATIONS}, REQUEST_POST_NOTIFICATIONS);
    }

    private void updateTransparencySettingsUi() {
        boolean toggleEnabled = switchTransparencyToggle.isChecked();
        boolean autoRestoreEnabled = switchTransparencyAutoRestore.isChecked();
        switchTransparencyAutoRestore.setEnabled(toggleEnabled);
        editTransparencySeconds.setEnabled(toggleEnabled && autoRestoreEnabled);
    }

    private int parseAutoRestoreSeconds(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return 5;
        }
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException e) {
            return 5;
        }
    }

    private int clampMinimizeDotSize(int sizeDp) {
        return Math.max(MIN_MINIMIZE_DOT_SIZE_DP, Math.min(MAX_MINIMIZE_DOT_SIZE_DP, sizeDp));
    }

    private int progressToMinimizeDotSize(int progress) {
        int range = MAX_MINIMIZE_DOT_SIZE_DP - MIN_MINIMIZE_DOT_SIZE_DP;
        int safeProgress = Math.max(0, Math.min(range, progress));
        return MIN_MINIMIZE_DOT_SIZE_DP + safeProgress;
    }

    private int minimizeDotSizeToProgress(int sizeDp) {
        return clampMinimizeDotSize(sizeDp) - MIN_MINIMIZE_DOT_SIZE_DP;
    }

    private void updateMinimizeDotSizeLabel(int sizeDp) {
        textMinimizeDotSizeValue.setText(getString(R.string.format_minimize_dot_size_dp, sizeDp));
    }

    private Settings.AppLanguage resolveLanguageById(int checkedId) {
        if (checkedId == R.id.rbLangZh) {
            return Settings.AppLanguage.ZH;
        }
        if (checkedId == R.id.rbLangEn) {
            return Settings.AppLanguage.EN;
        }
        if (checkedId == R.id.rbLangFr) {
            return Settings.AppLanguage.FR;
        }
        if (checkedId == R.id.rbLangEs) {
            return Settings.AppLanguage.ES;
        }
        if (checkedId == R.id.rbLangRu) {
            return Settings.AppLanguage.RU;
        }
        if (checkedId == R.id.rbLangAr) {
            return Settings.AppLanguage.AR;
        }
        return Settings.AppLanguage.SYSTEM;
    }

    private void applyLanguageChange(Settings.AppLanguage language) {
        if (language == currentAppLanguage) {
            return;
        }
        currentAppLanguage = language;
        recreate();
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
