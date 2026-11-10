# 依赖关系

## 内部依赖方向

```text
presentation → application → domain
       └────────→ data/services → domain/models
```

- `domain/`、`data/`、`core/` 不 import `features/`、`app/`、`shared/ui/`。
- `features/x/presentation` 不 import `features/y/presentation`（唯一历史例外：`library_pane.dart` → `online_search_sheet.dart`，待消除）。
- `features/x/application` 可以 import 别的 feature 的 `application` / `domain`。
- service 不依赖 Riverpod；widget 不直接持有 service，只通过 provider。

## 主要调用链

```text
LibraryPane ─watch→ LibraryController ─→ SqliteLibraryStorage ─→ AppDatabase (songs)
     │                  └─autoScan→ CrossPlatformMusicScanner
LibraryPane ─tap→ ListPlayback ─→ PlaybackController ─→ AudioPlayerService (just_audio)
                                       ├─→ AudioSourceResolver ─→ SongDownloadService
                                       ├─→ TrackPrefetcher
                                       └─→ PlaybackSessionRecorder ─→ PlaybackSessionStore (queue 表)
NowPlayingPage ─→ LyricsController ─→ LibraryPaths（.lrc / .manual.lrc / .smart.lrc）
DiscoveryPane ─→ DiscoveryController ─→ RecommendationEngine（纯 domain 计算）
                 └─ DiscoveryFeedbackStore / ListeningSignalStore
SourcesPane ─→ MusicSourcesController ─→ MusicSourceService（type→adapter 注册表）
Desktop：PlaybackController ─→ DesktopIntegrationController ─→ MPRIS / Tray（D-Bus 会话总线）
```

## 第三方运行时依赖

| 依赖 | 版本 | 用途 |
| --- | --- | --- |
| `flutter_riverpod` / `riverpod` | ^2.6.1 | 状态管理 |
| `go_router` | ^16.1.0 | 路由；ShellRoute + CustomTransitionPage |
| `just_audio` | ^0.10.4 | 音频播放抽象 |
| `just_audio_media_kit` + `media_kit_libs_linux` | ^2.1.0 / ^1.2.1 | Linux 播放后端（系统 libmpv） |
| `just_audio_windows` | ^0.2.2 | Windows 播放后端 |
| `audio_session` | ^0.2.3 | 音频会话 |
| `dbus` | ^0.7.15 | MPRIS、托盘、单实例（file_picker 牵制 0.7 线） |
| `window_manager` | ^0.5.0 | 桌面窗口管理 |
| `sqlite3` + `sqlite3_flutter_libs` | ^3.8.0 / ^0.6.0 | 音乐库索引、队列、喜欢、智能歌词账本 |
| `shared_preferences` | ^2.5.3 | 仅旧数据迁移 |
| `dio` | ^5.4.0 | 网络请求（音源、下载、封面、更新） |
| `xml` | ^6.6.1 | 播客 RSS 解析 |
| `crypto` | ^3.0.7 | Subsonic token 签名 |
| `charset` | ^2.0.1 | 读取其它编码的歌词文件 |
| `audio_metadata_reader` | ^1.4.2（vendor 覆盖） | 本地音频元数据；上游 `Buffer.read` 无界分配，补丁见 `vendor/audio_metadata_reader/VENDORED.md` |
| `path` / `path_provider` | ^1.9.0 / ^2.1.3 | 路径处理与平台目录 |
| `file_picker` | ^10.3.1 | 文件选择 |
| `flutter_localizations` + `intl` | sdk / ^0.20.2 | 本地化（gen-l10n，产物入库） |
| `logger` | ^2.6.1 | 日志（`Log` 封装为 debug/info/error 三级） |
| `cupertino_icons` | ^1.0.8 | 图标 |

## 开发依赖

| 依赖 | 用途 |
| --- | --- |
| `flutter_test` | 测试（test/ 镜像 lib 结构） |
| `flutter_lints` | ^6.0.0 lint 规则集 |
| `flutter_launcher_icons` | 各平台图标生成（原图 `branding/app_icon.png`） |
| `image` | `tool/generate_linux_icons.dart` 生成 Linux 主题图标 |

## dependency_overrides

`audio_metadata_reader` 指向 `vendor/audio_metadata_reader`：修复损坏标签可声明 GB 级帧导致的无界分配。

## 内置资源

- 字体（OFL-1.1）：Fraunces、Instrument Sans、Noto Sans SC、Noto Serif SC、JetBrains Mono
- `assets/icons/`、`LICENSE`、`THIRD_PARTY_NOTICES.md` 与字体 OFL 文本随包分发
- Linux 播放依赖系统 `libmpv2`（GPL-3+，不随 Tune 分发）
