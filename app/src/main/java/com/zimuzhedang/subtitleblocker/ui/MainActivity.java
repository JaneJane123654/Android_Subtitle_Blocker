package com.zimuzhedang.subtitleblocker.ui;

import android.Manifest;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Toast;
import org.json.JSONObject;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SharedPreferencesSettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SoundPlayer;
import com.zimuzhedang.subtitleblocker.data.ToneSoundPlayer;
import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;
import com.zimuzhedang.subtitleblocker.domain.OneShotEffect;
import com.zimuzhedang.subtitleblocker.domain.OverlayManager;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.domain.Settings;
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

    private OverlayViewModel viewModel;
    /** 权限导航器 */
    private PermissionNavigator permissionNavigator;
    /** 常驻后台控制器 */
    private KeepAliveController keepAliveController;
    /** 音效播放器 */
    private SoundPlayer soundPlayer;
    /** 配置仓库 */
    private SettingsRepository settingsRepository;
    /** 当前悬浮窗状态缓存 */
    private OverlayState currentState;

    private MaterialButton btnEnable;
    private MaterialButton btnDisable;
    private MaterialButton btnOpenPermission;
    private MaterialButton btnExportConfig;
    private MaterialButton btnImportConfig;
    private RadioGroup rgClosePosition;
    private RadioButton rbLeftTop;
    private RadioButton rbRightTop;
    private SwitchMaterial switchSound;
    private SwitchMaterial switchKeepAlive;
    private SwitchMaterial switchTransparencyToggle;
    private SwitchMaterial switchTransparencyAutoRestore;
    private EditText editTransparencySeconds;
    private boolean updatingTransparencySeconds;

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
        setupSettingsUi(settingsRepository.loadSettings());
    }

    /**
     * 绑定视图组件并设置监听器。
     */
    private void bindViews() {
        btnEnable = findViewById(R.id.btnEnable);
        btnDisable = findViewById(R.id.btnDisable);
        btnOpenPermission = findViewById(R.id.btnOpenPermission);
        btnExportConfig = findViewById(R.id.btnExportConfig);
        btnImportConfig = findViewById(R.id.btnImportConfig);
        rgClosePosition = findViewById(R.id.rgClosePosition);
        rbLeftTop = findViewById(R.id.rbLeftTop);
        rbRightTop = findViewById(R.id.rbRightTop);
        switchSound = findViewById(R.id.switchSound);
        switchKeepAlive = findViewById(R.id.switchKeepAlive);
        switchTransparencyToggle = findViewById(R.id.switchTransparencyToggle);
        switchTransparencyAutoRestore = findViewById(R.id.switchTransparencyAutoRestore);
        editTransparencySeconds = findViewById(R.id.editTransparencySeconds);

        btnEnable.setOnClickListener(v -> viewModel.onRequestShow(permissionNavigator.canDrawOverlays()));
        btnDisable.setOnClickListener(v -> viewModel.onRequestHide());
        btnOpenPermission.setOnClickListener(v -> permissionNavigator.openOverlayPermissionSettings(this));
        btnExportConfig.setOnClickListener(v -> exportConfig());
        btnImportConfig.setOnClickListener(v -> importConfig());

        rgClosePosition.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.rbLeftTop) {
                viewModel.onCloseButtonPositionChanged(CloseButtonPosition.LEFT_TOP);
            } else if (checkedId == R.id.rbRightTop) {
                viewModel.onCloseButtonPositionChanged(CloseButtonPosition.RIGHT_TOP);
            }
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
        switchSound.setChecked(settings.soundEnabled);
        switchKeepAlive.setChecked(settings.keepAliveEnabled);
        switchTransparencyToggle.setChecked(settings.transparencyToggleEnabled);
        switchTransparencyAutoRestore.setChecked(settings.transparencyAutoRestoreEnabled);
        updatingTransparencySeconds = true;
        editTransparencySeconds.setText(String.valueOf(settings.transparencyAutoRestoreSeconds));
        editTransparencySeconds.setSelection(editTransparencySeconds.getText().length());
        updatingTransparencySeconds = false;
        updateTransparencySettingsUi();
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
            json.put("transparencyToggleEnabled", settings.transparencyToggleEnabled);
            json.put("transparencyAutoRestoreEnabled", settings.transparencyAutoRestoreEnabled);
            json.put("transparencyAutoRestoreSeconds", settings.transparencyAutoRestoreSeconds);
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
            boolean transparencyToggleEnabled = json.optBoolean("transparencyToggleEnabled", false);
            boolean transparencyAutoRestoreEnabled = json.optBoolean("transparencyAutoRestoreEnabled", false);
            int transparencyAutoRestoreSeconds = json.optInt("transparencyAutoRestoreSeconds", 5);
            Settings settings = new Settings(
                    position,
                    soundEnabled,
                    keepAliveEnabled,
                    transparencyToggleEnabled,
                    transparencyAutoRestoreEnabled,
                    transparencyAutoRestoreSeconds
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
                    false
            );
            viewModel.applyImportedState(state, settings);
            setupSettingsUi(settings);
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
}
