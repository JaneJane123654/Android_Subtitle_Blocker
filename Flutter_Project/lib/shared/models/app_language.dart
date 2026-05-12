enum AppLanguage {
  system('SYSTEM', ''),
  zh('ZH', 'zh'),
  en('EN', 'en'),
  fr('FR', 'fr'),
  es('ES', 'es'),
  ru('RU', 'ru'),
  ar('AR', 'ar');

  const AppLanguage(this.value, this.languageTag);

  final String value;
  final String languageTag;

  static AppLanguage fromValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return AppLanguage.system;
    }
    for (final language in AppLanguage.values) {
      if (language.value.toLowerCase() == raw.toLowerCase()) {
        return language;
      }
    }
    return AppLanguage.system;
  }
}
