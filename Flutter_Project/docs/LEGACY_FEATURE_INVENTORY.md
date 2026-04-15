# 旧 Android 功能清单与 Flutter 目标映射

这份清单是迁移验收基线。AI 在迁移任何功能前，必须先确认这里是否已有条目；没有条目就先补条目，再写代码。

| 功能 | 旧源码入口 | 关键边界 | Flutter 目标模块 | 平台策略 |
| --- | --- | --- | --- | --- |
| 设置首页 | `ui/MainActivity.java`, `res/layout/activity_main.xml` | 单页内包含设置、权限、更新、导入导出、使用说明入口 | `features/settings` | 共享 |
| 使用说明页 | `ui/UsageActivity.java`, `res/layout/activity_usage.xml` | 跟随应用语言切换 | `features/usage` | 共享 |
| 遮挡层共享状态 | `vm/OverlayViewModel.java`, `domain/OverlayState.java` | 显示、隐藏、拖拽、缩放、透明、最小化 | `features/overlay/application` + `domain` | 共享 |
| 遮挡层视图与手势 | `ui/OverlayWindowView.java`, `res/layout/view_overlay_window.xml` | 点击切透明、点击恢复、拖拽、双轴/单轴缩放、最小化光点 | `features/overlay/presentation` | 共享 UI，宿主不同 |
| 遮挡层约束规则 | `domain/OverlayConstraints.java`, `domain/ScreenBounds.java` | 安全区约束、最小尺寸、80% 上限、15dp 吸边 | `features/overlay/domain` | 共享 |
| Android 悬浮窗运行时 | `platform/OverlayRuntime.java`, `ui/OverlayViewBinder.java`, `platform/WindowManagerFloatWindowController.java` | 真正显示/隐藏系统悬浮层、处理延时隐藏与恢复 | `core/platform/android` | Android 独有 |
| 悬浮窗权限导航 | `platform/PermissionNavigator.java`, `platform/SystemPermissionNavigator.java` | 权限不足时跳系统设置页 | `core/platform/android` | Android 独有 |
| 前台保活 | `platform/KeepAliveController.java`, `platform/KeepAliveService.java` | Android 13+ 通知权限前置 | `core/platform/android` | Android 独有 |
| 设置持久化 | `data/SettingsRepository.java`, `data/SharedPreferencesSettingsRepository.java`, `domain/Settings.java` | 默认值、上次布局状态、忽略版本号 | `features/settings/infrastructure` | 共享，存储改 Hive |
| 版本检查 | `data/GithubReleaseClient.java`, `data/ReleaseInfo.java` | GitHub latest release，APK 资源链接探测 | `features/updates/infrastructure` | 共享网络层 |
| 版本号比较 | `data/VersionNameComparator.java` | 去前缀、去 qualifier、非数字回退 0 | `features/updates/domain` | 共享 |
| Android 安装更新 | `ui/MainActivity.java` 中下载/安装逻辑 | 下载失败回退到 release 页面，安装器不存在要失败提示 | `core/platform/android` | Android 独有 |
| 配置导出 | `ui/MainActivity.java#exportConfig` | JSON 字段必须完整，当前态优先 | `features/config_transfer` | 共享 |
| 配置导入 | `ui/MainActivity.java#importConfig` | JSON 非法完整失败，透明状态重置，保留当前可见性 | `features/config_transfer` | 共享 |
| 多语言 | `res/values*/strings.xml`, `Settings.AppLanguage` | SYSTEM/ZH/EN/FR/ES/RU/AR | `features/settings` + `app/i18n` | 共享 |
| 声音提示 | `data/SoundPlayer.java`, `data/ToneSoundPlayer.java` | 只在开启声音时触发 | `core/platform` | 共享抽象，平台实现 |
| 单元测试基线 | `OverlayViewModelTest.java`, `OverlayConstraintsTest.java`, `VersionNameComparatorTest.java` | 这些不是可选项，必须在 Dart 侧重建 | `test/` | 共享 |

## 迁移优先级

### P0

- `OverlayState`
- `Settings`
- `OverlayConstraints`
- `VersionNameComparator`

### P1

- 设置页
- 使用说明页
- 导入导出
- 多语言

### P2

- Flutter 预览遮挡层
- iOS 应用内遮挡模式

### P3

- Android 全局悬浮层 adapter
- Android 保活
- Android APK 更新安装

## 已确认的旧项目关键默认值

- 关闭按钮默认位置：`RIGHT_TOP`
- 声音默认：`false`
- 保活默认：`false`
- 透明切换默认：`true`
- 自动恢复默认：`false`
- 自动恢复秒数默认：`5`
- 最小化光点默认尺寸：`40dp`
- 最小化旋转默认：`false`

## 已确认的旧项目关键测试来源

- `app/src/test/java/com/zimuzhedang/subtitleblocker/vm/OverlayViewModelTest.java`
- `app/src/test/java/com/zimuzhedang/subtitleblocker/domain/OverlayConstraintsTest.java`
- `app/src/test/java/com/zimuzhedang/subtitleblocker/data/VersionNameComparatorTest.java`

这些测试文件要作为 Flutter 迁移期的第一批重建对象，而不是等 UI 完成后再补。
