# 字幕遮挡器应用项目说明

本项目为字幕遮挡器应用的完整实现方案，包含编码指导和相关文档。

## 项目结构
- `app/`：主应用模块，包含源码、资源和构建配置。
- `build.gradle`、`settings.gradle`：项目级构建配置文件。
- `gradle/`：Gradle相关配置。
- `实现文档.md`、`项目描述文件.md` 等：项目设计与实现相关文档。

## 构建与运行
1. 安装 Android Studio 或配置好 Android 开发环境。
2. 使用 `./gradlew assembleRelease` 命令编译生成 Release APK。
3. APK 文件生成于 `app/build/outputs/apk/release/` 目录。

## 主要功能
- 遮挡视频字幕，提升观影体验。
- 支持多种遮挡样式和自定义设置。

## 联系与反馈
如有问题或建议，请在项目主页提交 issue。
