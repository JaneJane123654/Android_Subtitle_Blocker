# AI 开发规范与无损迁移协议

## 1. 非协商规则

- 不得修改旧 `app/` 原生项目中的任何业务代码。
- 每迁移一个功能，必须先在 `LEGACY_FEATURE_INVENTORY.md` 中找到对应条目。
- AI 不得把 View 层和业务层混写。
- AI 不得省略旧代码中的 `null` 判断、默认值、异常降级、权限失败分支。
- 遇到 iOS 无法实现的 Android 独占能力时，必须显式声明“平台降级策略”。

## 2. 翻译协议

## 2.1 Activity / Fragment -> Flutter 页面结构

规则：

- 一个原生 `Activity` 默认对应一个 Flutter route page。
- 一个原生 `Fragment` 默认对应一个页面片段组件、标签页、对话框或子导航分支，不强制一比一路由化。
- 一个原生页面中的多个 `Card` 区块，在 Flutter 中优先拆成独立 section widget。

本项目映射：

- `MainActivity` -> `SettingsHomePage`
- `UsageActivity` -> `UsageGuidePage`
- 无 `Fragment` -> 无需模拟 Fragment 容器
- `OverlayWindowView` -> `OverlayCanvas` 共享组件

## 2.2 ViewModel -> Riverpod 状态类

规则：

- 原生 `ViewModel` 中的“持久状态”转成 `State`。
- 原生 `LiveData<OneShotEffect>` 转成“状态中的 command 字段”或独立 command stream，由 `ref.listen` 消费。
- 原生 `Repository` 注入改为 `Notifier` 依赖注入，不允许在 controller 内手写单例。

本项目映射建议：

- `OverlayViewModel` -> `OverlaySessionController extends Notifier<OverlaySessionState>`
- `SettingsRepository` -> `SettingsRepository` Dart 接口
- `OverlayManager` 单例 -> Riverpod provider scope，不再保留手写 singleton

## 2.3 XML Layout -> Flutter 声明式 UI

规则：

- 迁移的是“结构语义、交互语义、视觉层次”，不是 View 树逐节点抄写。
- 使用 `Stack`、`Positioned`、`GestureDetector` 重建悬浮层交互。
- 使用表单组件和设计 token 重建设置页，不要继续维护“XML id 驱动”的心智模型。

## 2.4 原生 Runtime / Service -> 平台适配器

规则：

- 任何依赖系统窗口、前台服务、安装 APK、系统权限设置页的能力都必须下沉到平台 adapter。
- Flutter 共享层只调用抽象接口，例如 `OverlayHostPort`、`PermissionPort`、`UpdateInstallPort`。
- 平台通道必须用 `Pigeon` 生成，禁止手写弱类型 method name 字符串。

## 3. 无损迁移协议

AI 在读取任意旧 Java/Kotlin/XML 文件时，必须执行以下流程。

### Step 1. 建立源码索引

每个原生文件都要归类到以下类型之一：

- Screen
- Widget/View
- ViewModel/Controller
- Domain Model
- Repository/DataSource
- Platform Adapter
- Test
- Manifest/Permission
- Strings/Layout Resource

### Step 2. 抽取行为合同

对每个方法都至少提取下面九项：

- 触发条件
- 输入参数
- 依赖的持久化数据
- 读取的运行时状态
- 输出状态变更
- 副作用
- `null` 处理
- 异常处理
- 定时器/动画/延时

没有形成行为合同的代码，不允许直接迁移。

### Step 3. 生成迁移任务单

每个 feature 必须拆成以下子任务：

- 共享领域模型
- 共享 controller
- Flutter 页面/组件
- 本地存储
- 网络/远程数据
- 平台适配器
- 单元测试
- Widget/集成测试

### Step 4. 测试先行对齐

迁移顺序必须是：

1. 先写或补齐 Dart 领域测试
2. 再写 controller 测试
3. 再写页面和平台桥接实现

### Step 5. 分支覆盖核对

AI 必须枚举所有 `if/else`、`try/catch`、空值分支，直到 feature matrix 中所有分支都被打勾。

### Step 6. 评审门禁

每个功能合并前必须满足：

- inventory 条目标记为 `migrated`
- 已知平台差异已记录
- 边界常量已写入测试
- `null` 与异常 fallback 已在代码中可见

## 4. 旧项目中必须保留的业务常量与边界

| 规则 | 旧行为 |
| --- | --- |
| 默认遮挡层尺寸 | `220dp x 80dp` |
| 默认遮挡层最小尺寸 | `100dp x 40dp` |
| 默认位置 | `x = 居中`, `y = max(safeTop, screenHeight * 0.65)` |
| 缩放上限 | 屏幕宽高的 `80%` |
| 吸边阈值 | `15dp` |
| 移动动画时长 | `150ms` |
| 缩放动画时长 | `200ms` |
| 淡出动画时长 | `300ms` |
| 淡出后真正隐藏延迟 | `320ms` |
| 自动恢复透明时间范围 | `1..60 秒` |
| 自动恢复秒数输入为空或非法 | 回退到 `5 秒` |
| 最小化光点尺寸范围 | `10..200dp` |
| 最小化光点默认尺寸 | `40dp` |
| 默认关闭按钮位置 | `RIGHT_TOP` |
| 默认语言 | `SYSTEM` |
| 默认声音开关 | `false` |
| 默认保活开关 | `false` |
| 默认透明切换开关 | `true` |
| 默认自动恢复开关 | `false` |
| 默认忽略版本 | `null` |

这些值必须被提升为 Dart 常量并写入单元测试，不能埋在 UI 控件里。

## 5. 旧项目中必须保留的分支行为

### 5.1 显示遮挡层

- 没有悬浮窗权限时，不显示遮挡层，而是发出“跳转权限设置”的命令。
- 有权限时，优先恢复上一次保存的遮挡层位置和尺寸。
- 恢复时要把透明状态重置为 `false`。

### 5.2 隐藏遮挡层

- `onRequestHide()` 和 `onCloseClick()` 都不是立即隐藏。
- 先发出淡出动画。
- 动画结束后再真正隐藏。
- 如果声音开启，隐藏前还要发出播放提示音命令。

### 5.3 透明模式

- 透明切换总开关关闭时，点击遮挡层不得切换透明。
- 如果在透明状态下关闭透明总开关，必须立即恢复非透明，并取消自动恢复定时器。
- 如果透明自动恢复开启，切换到透明后必须启动延时恢复命令。
- 从透明切回非透明时，必须取消延时恢复命令。

### 5.4 保活开关

- Android 13+ 没有通知权限时，勾选保活不能直接成功。
- 必须先请求通知权限。
- 权限未授予时，保活开关回到关闭状态。

### 5.5 导入导出

- 导出时优先用当前运行状态；没有当前状态时回退到上次保存状态。
- 两者都拿不到时，必须明确失败，不能导出半残 JSON。
- 导入 JSON 失败时必须完整失败，不能部分吞掉异常后写入脏数据。
- 导入后透明状态强制为 `false`。
- 导入后 `visible` 继承当前运行可见性，而不是导入值。

### 5.6 更新检查

- 自动检查与手动检查的用户提示不一样。
- 当前版本已经最新时，只有手动检查才提示“已是最新版本”。
- 被忽略的版本号必须参与比较，只有发现更高版本时才重新提醒。
- Android 下载 APK 失败时，回退为打开 release 页面。

## 6. 空值与异常处理强制规范

所有外部边界必须显式处理 `null`、空字符串、异常：

- 剪贴板读取
- 本地存储读取
- JSON 解析
- 版本号读取
- 网络请求
- 文件目录创建
- 平台安装器启动
- 浏览器跳转
- 权限申请结果

实现规则：

- 外部调用统一返回 `Result<T>` 或 `Either<AppFailure, T>`。
- UI 层不直接 `try/catch Exception`。
- controller 只能消费领域失败对象，不直接拼平台异常文案。
- 所有默认值都写成常量，不允许魔法数字散落。

## 7. 测试规范

### 7.1 必须有的单元测试

- `OverlayConstraints` 等价测试
- `VersionNameComparator` 等价测试
- `Settings` 默认值测试
- 透明自动恢复范围与非法输入测试
- 最小化光点尺寸 clamp 测试

### 7.2 必须有的 controller 测试

- 显示/隐藏遮挡层状态流
- 权限不足时的命令流
- 透明切换与自动恢复命令
- 导入配置后的状态合成规则
- 忽略版本比较逻辑

### 7.3 必须有的 widget / integration 测试

- 设置首页交互
- 遮挡层拖拽、缩放、吸边
- Android 悬浮窗 adapter contract test
- iOS 应用内遮挡模式交互

## 8. AI 实施模板

每迁移一个功能，提交说明必须包含以下结构：

```text
Feature:
Source Files:
Behavior Contract:
Null / Exception Cases:
Platform Differences:
Tests Added:
Open Risks:
```

## 9. Definition of Done

一个功能只有在同时满足以下条件时才算迁移完成：

- 旧代码功能已在 inventory 中找到对应项
- 行为合同已抽取
- 共享状态和平台差异已拆开
- `null` 和异常分支全部实现
- 单元测试和 controller 测试通过
- Android / iOS 差异已文档化
- 没有未解释的“功能缩减”
