import 'package:hive/hive.dart';

import 'settings_storage_schema.dart';

final class HiveStorageSnapshot {
  const HiveStorageSnapshot({
    required this.settingsJson,
    required this.overlaySnapshotJson,
  });

  final String? settingsJson;
  final String? overlaySnapshotJson;
}

final class HiveSettingsDataSource {
  const HiveSettingsDataSource(this._box);

  final Box<String> _box;

  static Future<HiveSettingsDataSource> open({
    String boxName = SettingsStorageSchema.boxName,
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return HiveSettingsDataSource(box);
  }

  String? readSettingsJson() {
    return _box.get(SettingsStorageSchema.settingsKey);
  }

  Future<void> writeSettingsJson(String value) {
    return _box.put(SettingsStorageSchema.settingsKey, value);
  }

  String? readOverlaySnapshotJson() {
    return _box.get(SettingsStorageSchema.overlaySnapshotKey);
  }

  Future<void> writeOverlaySnapshotJson(String value) {
    return _box.put(SettingsStorageSchema.overlaySnapshotKey, value);
  }

  HiveStorageSnapshot captureSnapshot() {
    return HiveStorageSnapshot(
      settingsJson: readSettingsJson(),
      overlaySnapshotJson: readOverlaySnapshotJson(),
    );
  }

  Future<void> restoreSnapshot(HiveStorageSnapshot snapshot) async {
    if (snapshot.settingsJson == null) {
      await _box.delete(SettingsStorageSchema.settingsKey);
    } else {
      await writeSettingsJson(snapshot.settingsJson!);
    }
    if (snapshot.overlaySnapshotJson == null) {
      await _box.delete(SettingsStorageSchema.overlaySnapshotKey);
    } else {
      await writeOverlaySnapshotJson(snapshot.overlaySnapshotJson!);
    }
  }
}
