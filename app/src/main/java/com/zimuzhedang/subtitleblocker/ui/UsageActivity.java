package com.zimuzhedang.subtitleblocker.ui;

import android.content.Context;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;
import android.os.LocaleList;
import java.util.Locale;

import androidx.appcompat.app.AppCompatActivity;

import com.zimuzhedang.subtitleblocker.R;
import com.zimuzhedang.subtitleblocker.data.SettingsRepository;
import com.zimuzhedang.subtitleblocker.data.SharedPreferencesSettingsRepository;
import com.zimuzhedang.subtitleblocker.domain.Settings;

public final class UsageActivity extends AppCompatActivity {
    @Override
    protected void attachBaseContext(Context newBase) {
        SettingsRepository repository = new SharedPreferencesSettingsRepository(newBase);
        Settings settings = repository.loadSettings();
        super.attachBaseContext(applyLanguage(newBase, settings.appLanguage));
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_usage);
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
