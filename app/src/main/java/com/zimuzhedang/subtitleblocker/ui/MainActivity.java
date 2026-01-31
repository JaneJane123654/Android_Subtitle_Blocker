package com.zimuzhedang.subtitleblocker.ui;

import android.Manifest;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.pm.PackageManager;
import android.os.Bundle;
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
            // 使用 consume() 确保每个副作用只被处理一次
            if (!effect.consume()) {
                return;
            }
            if (effect.type == OneShotEffect.Type.NAVIGATE_TO_PERMISSION) {
                Toast.makeText(this, R.string.action_open_permission, Toast.LENGTH_SHORT).show();
                permissionNavigator.openOverlayPermissionSettings(this);
            } else if (effect.type == OneShotEffect.Type.PLAY_SOUND) {
                soundPlayer.playClick();
            }
            viewModel.clearEffect();
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
            Settings settings = new Settings(position, soundEnabled, keepAliveEnabled);
            OverlayState state = new OverlayState(
                    width,
                    height,
                    x,
                    y,
                    currentState != null && currentState.visible,
                    position,
                    soundEnabled,
                    keepAliveEnabled,
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
}
