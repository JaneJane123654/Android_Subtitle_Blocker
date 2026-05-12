import 'package:subtitle_blocker_flutter_refactor/features/settings/domain/settings_domain.dart';
import 'package:subtitle_blocker_flutter_refactor/shared/models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('Settings', () {
    test('defaultValue mirrors the legacy Java defaultValue constructor', () {
      final settings = Settings.defaultValue();

      expect(settings.closeButtonPosition, CloseButtonPosition.rightTop);
      expect(settings.soundEnabled, isFalse);
      expect(settings.keepAliveEnabled, isFalse);
      expect(settings.appLanguage, AppLanguage.system);
      expect(settings.transparencyToggleEnabled, isTrue);
      expect(settings.transparencyAutoRestoreEnabled, isFalse);
      expect(settings.transparencyAutoRestoreSeconds, 5);
      expect(settings.minimizeDotSize, 40);
      expect(settings.minimizeDotRotateEnabled, isFalse);
      expect(settings.ignoredUpdateVersion, isNull);
    });

    test('with methods update one field and preserve the remaining fields', () {
      final settings = Settings.defaultValue()
          .withCloseButtonPosition(CloseButtonPosition.leftTop)
          .withSoundEnabled(true)
          .withKeepAliveEnabled(true)
          .withAppLanguage(AppLanguage.fr)
          .withTransparencyToggleEnabled(false)
          .withTransparencyAutoRestoreEnabled(true)
          .withTransparencyAutoRestoreSeconds(12)
          .withMinimizeDotSize(72)
          .withMinimizeDotRotateEnabled(true)
          .withIgnoredUpdateVersion('v2.0.0');

      expect(settings.closeButtonPosition, CloseButtonPosition.leftTop);
      expect(settings.soundEnabled, isTrue);
      expect(settings.keepAliveEnabled, isTrue);
      expect(settings.appLanguage, AppLanguage.fr);
      expect(settings.transparencyToggleEnabled, isFalse);
      expect(settings.transparencyAutoRestoreEnabled, isTrue);
      expect(settings.transparencyAutoRestoreSeconds, 12);
      expect(settings.minimizeDotSize, 72);
      expect(settings.minimizeDotRotateEnabled, isTrue);
      expect(settings.ignoredUpdateVersion, 'v2.0.0');
    });

    test(
      'ignored version copy can preserve, set, and clear nullable value',
      () {
        final withVersion = Settings.defaultValue().copyWith(
          ignoredUpdateVersion: 'v1.2.3',
        );

        expect(withVersion.copyWith().ignoredUpdateVersion, 'v1.2.3');
        expect(
          withVersion.withIgnoredUpdateVersion(null).ignoredUpdateVersion,
          isNull,
        );
      },
    );
  });

  group('AppLanguage', () {
    test(
      'fromValue preserves Java null, empty, invalid, and case branches',
      () {
        expect(AppLanguage.fromValue(null), AppLanguage.system);
        expect(AppLanguage.fromValue(''), AppLanguage.system);
        expect(AppLanguage.fromValue('missing'), AppLanguage.system);
        expect(AppLanguage.fromValue('zh'), AppLanguage.zh);
        expect(AppLanguage.fromValue('EN'), AppLanguage.en);
        expect(AppLanguage.fromValue('fr'), AppLanguage.fr);
        expect(AppLanguage.fromValue('es'), AppLanguage.es);
        expect(AppLanguage.fromValue('ru'), AppLanguage.ru);
        expect(AppLanguage.fromValue('ar'), AppLanguage.ar);
      },
    );

    test('language tags mirror the legacy enum table', () {
      expect(AppLanguage.system.languageTag, '');
      expect(AppLanguage.zh.languageTag, 'zh');
      expect(AppLanguage.en.languageTag, 'en');
      expect(AppLanguage.fr.languageTag, 'fr');
      expect(AppLanguage.es.languageTag, 'es');
      expect(AppLanguage.ru.languageTag, 'ru');
      expect(AppLanguage.ar.languageTag, 'ar');
    });
  });
}
