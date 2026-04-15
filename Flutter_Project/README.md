# Flutter 重构工程骨架

这是为旧 Android 原生项目设计的全新 Flutter 重构目录。旧工程保持原样，新的跨平台方案全部在 `Flutter_Project/` 下推进。

当前环境没有安装 Flutter/Dart CLI，所以这里先落地了：

- 面向 AI 实施者的技术架构文档
- 面向迁移执行的无损迁移规范
- 旧原生功能清单与覆盖矩阵
- 一个最小 Flutter 入口骨架

## 文档入口

- `docs/TECH_ARCHITECTURE.md`
- `docs/AI_DEVELOPMENT_SPEC.md`
- `docs/LEGACY_FEATURE_INVENTORY.md`

## 架构结论

- 状态管理：`Riverpod`
- 网络请求：`Dio`
- 本地存储：`Hive`
- 依赖注入：`get_it + injectable`
- 路由：`go_router`
- 平台桥接：`Pigeon`

## 重要平台结论

旧 Android 应用的核心能力是“系统级悬浮遮挡层”。这个能力在 Android 上成立，但在 iOS 上无法对第三方 App 进行系统级悬浮覆盖。因此新架构采用：

- Android：保留“全局悬浮层”平台适配器
- iOS：改为“应用内遮挡层 / 预览播放器”模式
- Flutter 共享：设置、领域模型、约束逻辑、导入导出、语言、更新检查、UI 组件

## 后续实施建议

安装 Flutter SDK 后，优先按文档中的目标目录结构继续补齐 `android/`、`ios/` 壳层与依赖，再逐功能迁移，不要直接把旧 Java 代码机械翻译成 Dart。
