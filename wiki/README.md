# Tune Code Wiki

> 状态：索引 · 适用版本 1.33.0 · 最后核对 2026-11-15
>
> 本 wiki 是代码的结构化导览：帮读者快速定位「什么住在哪、谁拥有什么」。
> 规则与设计决策的权威来源是根目录 `AGENTS.md` 与 `docs/`；本 wiki 只做地图，不复制规则原文。
> 想知道某份设计文档该不该读、算不算规范，看 [`docs/README.md`](../docs/README.md)（文档索引与状态约定）。

## 项目概述

**Tune** 是一款紧凑的本地与在线音乐播放器，当前版本 `1.35.4+64`（`Pocket`，2026-11-16）。

- **技术栈**：Flutter 3 / Dart 3.8+ · Riverpod 2（StateNotifier/AsyncNotifier）· go_router · just_audio（Linux / Windows 都走 just_audio_media_kit + media_kit_libs_* + 系统 libmpv）· dio · SQLite（sqlite3 + sqlite3_flutter_libs）· gen-l10n；另有 audio_service、permission_handler、sherpa_onnx（Android 后台播放 / 运行时权限 / 本地 ASR）
- **壳层形态**：左侧导航（发现 / 音乐库 / 喜欢 / 音源 / 设置）+ 右侧内容区 + 底部播放条；播放队列是从底栏或正在播放页打开的**非模态侧栏**，不注册路由
- **主验收平台**：Linux 桌面；Windows / Android / iOS 保留工程入口；macOS 与 Web 已移除
- **窗口**：首帧 900×600（GTK runner），运行时首次启动默认 1120×760，最小 760×520；紧凑布局按 900×600 设计验收
- **界面语言**：简体中文、繁體中文、中文（通用）、English

## Wiki 索引

| 文档 | 内容 |
| --- | --- |
| [architecture.md](architecture.md) | 整体架构：分层、依赖方向、状态归属、持久化地图 |
| [modules.md](modules.md) | 主要模块职责：13 个 feature + 全局服务层 + shared/core |
| [key-classes.md](key-classes.md) | 关键类与函数说明：controller、service、domain 模型 |
| [dependencies.md](dependencies.md) | 依赖关系：第三方依赖清单与内部依赖方向 |
| [getting-started.md](getting-started.md) | 运行方式：环境、启动、构建、测试门禁、打包发布 |

## 一分钟速查

### 跑起来

```bash
flutter pub get
flutter run -d linux
```

### 提交前门禁

```bash
./tool/check.sh --l10n   # gen-l10n 一致性 + analyze + 确定性用例（CI 同一脚本，另加 --tools --docs）
```

等价分步：`flutter analyze`（必须 No issues found）、`flutter test`（全绿）、改过 ARB 再
`flutter gen-l10n` 并提交产物。

> 注意：工程路径含中文时，`flutter analyze` 需要一处 Flutter SDK 补丁，见
> [getting-started.md](getting-started.md) 的「SDK 补丁」一节。

### 入口调用链

```text
lib/main.dart                        # bootstrap：错误捕获、ProviderScope、单实例占位
  └─ TuneApp（lib/app/app.dart）      # appInitializationProvider → AppInitializer
       └─ MaterialApp.router          # CompactTheme + locale + HintLayer
            └─ CompactShell           # AppSidebar + 页面区 + PlayerDock + QueuePanel
```

启动初始化顺序（`AppInitializer.initialize`）：偏好存储 → 数据库 → 喜欢 → 播放记录 →
播放会话 → 音频播放器 → 扫描器 → 桌面集成 → 发现页信号观察。

## 源码布局

```text
lib/
├── main.dart                 # 只做 bootstrap
├── app/                      # MaterialApp.router、路由、主题、启动初始化
│   ├── router/app_router.dart
│   └── theme/                # CompactTheme + CompactTokens + 字阶
├── config/                   # AppInitializer、版本号
├── core/                     # l10n 桥接、常量、扩展、窗口服务
├── data/services/            # 全局服务：播放、扫描、音源适配器、持久化、桌面集成
│   ├── music_sources/        # 30 个音源适配器（30 个注册类型）+ 注册表
│   ├── smart_lyrics/         # 智能歌词引擎（whisper / sherpa / OpenAI 兼容）
│   ├── database/             # AppDatabase（SQLite 表定义与读写）
│   ├── mpris/ tray/ desktop/ # 桌面集成接口（无平台依赖）
│   └── impl/                 # 上述接口的 IO 实现
├── domain/models/            # 全局实体：Song、MusicSourceConfig 等
├── features/<f>/             # 按业务能力分包（见 modules.md）
│   ├── domain/               # 不可变状态与业务规则（不依赖 Flutter）
│   ├── application/          # controller / provider：状态的唯一所有者
│   ├── data/                 # 该 feature 私有的持久化
│   └── presentation/         # widget / page：只读 provider
├── providers/                # 跨层共享的 provider（封面缓存、持久化）
├── shared/ui/                # 跨 feature 复用 widget（不含业务状态）
├── l10n/                     # ARB 源文件 + gen-l10n 产物
└── utils/                    # logger、文件名清洗、稳定 key
```

## 核心设计决策（一句话版）

1. **单一事实来源**：每份状态只有一个 controller 持有，队列就是 `PlaybackState` 的一部分，没有第二个队列容器。
2. **依赖方向单向**：`presentation → application → domain`，`data/` 与 `domain/` 不反向依赖 `features/`。
3. **service 不认识 Riverpod**：`data/services` 只编排 I/O，状态全在 controller。
4. **快慢值分订阅**：播放位置（高频）由画它的那一小块自己订阅，队列/模式/音量（低频）走切片 provider，避免整页重建。
5. **库不入内存**：`LibraryState.songs` 始终是 SQLite 读出的一个窗口（1000 行），淘汰也在数据库内完成。
6. **音源 = 类型 + 实例**：类型是适配器代码，实例是读者的一条配置；UI 不按 id 硬编码。

详细论证见 `AGENTS.md` §1 与 `docs/architecture.md`。

## 参与贡献与治理

代码之外的协作入口都在仓库根，规则只有一份，别在 wiki 里抄第二遍：

| 要做的事 | 读哪份 |
| --- | --- |
| 开发环境、分支模型、门禁、提 PR | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| 谁负责、怎么决策、怎么发布 | [GOVERNANCE.md](../GOVERNANCE.md) |
| 报安全漏洞（请走私密渠道） | [SECURITY.md](../SECURITY.md) |
| 提问、求助、提需求 | [SUPPORT.md](../SUPPORT.md) |
| 参与前必须遵守的行为准则 | [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) |
| 用不了、要排障（现象 → 原因 → 怎么确认 → 怎么处理） | [docs/troubleshooting.md](../docs/troubleshooting.md) |

自动化接触面在 `.github/`：`workflows/ci.yml` 跑 `./tool/check.sh --l10n --tools --docs`；issue 表单是
`ISSUE_TEMPLATE/bug_report.yml` 与 `feature_request.yml`；PR 模板在 `PULL_REQUEST_TEMPLATE.md`；
`dependabot.yml` 每周一并一次依赖更新。提交信息格式 `type(scope): 中文说明`，一次提交只做一件事。
