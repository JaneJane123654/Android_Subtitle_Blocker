package com.zimuzhedang.subtitleblocker.ui;

import android.Manifest;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Toast;
import org.json.JSONObject;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.ViewModelProvider;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SharedPreferencesSettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SoundPlayer;
import com.zimuzhedang.subtitleblocker.data.ToneSoundPlayer;
import com.zimuzhedang.subtitleblocker.domain.CloseButtonPosition;
import com.zimuzhedang.subtitleblocker.domain.OneShotEffect;
import com.zimuzhedang.subtitleblocker.domain.OverlayState;
import com.zimuzhedang.subtitleblocker.domain.Settings;
import com.zimuzhedang.subtitleblocker.platform.DefaultKeepAliveController;
import com.zimuzhedang.subtitleblocker.platform.DefaultScreenInfoProvider;
import com.zimuzhedang.subtitleblocker.platform.FloatWindowController;
import com.zimuzhedang.subtitleblocker.platform.KeepAliveController;
import com.zimuzhedang.subtitleblocker.platform.PermissionNavigator;
import com.zimuzhedang.subtitleblocker.platform.SystemPermissionNavigator;
import com.zimuzhedang.subtitleblocker.platform.WindowManagerFloatWindowController;
import com.zimuzhedang.subtitleblocker.vm.OverlayViewModel;
import com.zimuzhedang.subtitleblocker.vm.OverlayViewModelFactory;

public final class MainActivity extends AppCompatActivity {
    private static final int REQUEST_POST_NOTIFICATIONS = 1001;

    private OverlayViewModel viewModel;
    private OverlayViewBinder viewBinder;
    private OverlayWindowView overlayView;
    private FloatWindowController windowController;
    private PermissionNavigator permissionNavigator;
    private KeepAliveController keepAliveController;
    private SoundPlayer soundPlayer;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private com.zimuzhedang.subtitleblocker.domain.AnimationSpec pendingAnim;
    private SettingsRepository settingsRepository;
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
        DefaultScreenInfoProvider screenInfoProvider = new DefaultScreenInfoProvider(this);
        viewModel = new ViewModelProvider(this, new OverlayViewModelFactory(settingsRepository, screenInfoProvider))
                .get(OverlayViewModel.class);
        permissionNavigator = new SystemPermissionNavigator(this);
        keepAliveController = new DefaultKeepAliveController(this);
        soundPlayer = new ToneSoundPlayer();
        overlayView = new OverlayWindowView(this);
        windowController = new WindowManagerFloatWindowController(this);
        viewBinder = new OverlayViewBinder(windowController, overlayView);

        bindViews();
        bindOverlayEvents();
        bindViewModel();
        setupSettingsUi(settingsRepository.loadSettings());
    }

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

    private void bindOverlayEvents() {
        overlayView.setListener(new OverlayWindowView.Listener() {
            @Override
            public void onClose() {
                viewModel.onCloseClick();
            }

            @Override
            public void onDragStart() {
                viewModel.onDragStart();
            }

            @Override
            public void onDragMove(int dxPx, int dyPx) {
                viewModel.onDragMove(dxPx, dyPx);
            }

            @Override
            public void onDragEnd() {
                viewModel.onDragEnd();
            }

            @Override
            public void onResizeStart() {
                viewModel.onResizeStart();
            }

            @Override
            public void onResizeMove(int dwPx, int dhPx) {
                viewModel.onResizeMove(dwPx, dhPx);
            }

            @Override
            public void onResizeEnd() {
                viewModel.onResizeEnd();
            }
        });
    }

    private void bindViewModel() {
        viewModel.getOverlayState().observe(this, this::renderOverlay);
        viewModel.getAnimationSpec().observe(this, spec -> pendingAnim = spec);
        viewModel.getEffect().observe(this, effect -> {
            if (effect == null) {
                return;
            }
            if (effect.type == OneShotEffect.Type.NAVIGATE_TO_PERMISSION) {
                Toast.makeText(this, R.string.action_open_permission, Toast.LENGTH_SHORT).show();
                permissionNavigator.openOverlayPermissionSettings(this);
            } else if (effect.type == OneShotEffect.Type.PLAY_SOUND) {
                soundPlayer.playClick();
            } else if (effect.type == OneShotEffect.Type.REQUEST_HIDE_AFTER_FADE) {
                handler.postDelayed(() -> {
                    windowController.hide();
                    viewModel.onOverlayHidden();
                    keepAliveController.stop();
                }, 320L);
            }
        });
    }

    private void renderOverlay(OverlayState state) {
        if (state == null) {
            return;
        }
        currentState = state;
        soundPlayer.setEnabled(state.soundEnabled);
        viewBinder.bind(state, pendingAnim);
        pendingAnim = null;
        if (state.visible && state.keepAliveEnabled) {
            keepAliveController.start();
        } else if (!state.visible) {
            keepAliveController.stop();
        }
    }

    private void setupSettingsUi(Settings settings) {
        if (settings.closeButtonPosition == CloseButtonPosition.LEFT_TOP) {
            rbLeftTop.setChecked(true);
        } else {
            rbRightTop.setChecked(true);
        }
        switchSound.setChecked(settings.soundEnabled);
        switchKeepAlive.setChecked(settings.keepAliveEnabled);
    }

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

    private boolean hasPostNotificationsPermission() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) {
            return true;
        }
        return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPostNotificationsPermission() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) {
            return;
        }
        ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.POST_NOTIFICATIONS}, REQUEST_POST_NOTIFICATIONS);
    }
}
