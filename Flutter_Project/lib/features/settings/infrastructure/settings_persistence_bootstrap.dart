import 'package:hive_flutter/hive_flutter.dart';

import 'hive_settings_data_source.dart';
import 'hive_settings_repository.dart';
import 'settings_storage_schema.dart';

final class SettingsPersistenceBootstrap {
  const SettingsPersistenceBootstrap._();

  static Future<HiveSettingsRepository> openDefaultRepository() async {
    await Hive.initFlutter();
    final dataSource = await HiveSettingsDataSource.open(
      boxName: SettingsStorageSchema.boxName,
    );
    return HiveSettingsRepository(dataSource);
  }
}
