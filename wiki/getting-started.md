# 运行方式

## 环境要求

- Flutter 3（Dart SDK ^3.8.1）
- Linux 桌面是当前唯一主验收平台；Windows / Android / iOS 保留工程入口；macOS 与 Web 已移除
- Linux 播放依赖系统 libmpv（Debian/Ubuntu 包名 `libmpv2`）

## 运行

```bash
flutter pub get
flutter run -d linux
```

## 提交前门禁

```bash
flutter analyze   # 必须 No issues found
flutter test      # 全绿
flutter gen-l10n  # 改过 ARB 文案才需要，产物入库
```

只写测试不算验证：`analyze` 干净 + `test` 全绿 + 亲手跑过界面，三者都要有。

### SDK 补丁（中文路径必需）

工程路径含中文时，Flutter 3.47.x 的 `flutter analyze` 会因 LSP 报文 `Content-Length`
写成字符数（而非 UTF-8 字节数）而炸。这是 SDK 自己的 bug，本地已改：

```bash
# ${FLUTTER_ROOT}/packages/flutter_tools/lib/src/dart/analysis.dart 的 _writeMessage：
# ${message.length}  →  ${utf8.encode(message).length}
rm -f /opt/flutter/bin/cache/flutter_tools.stamp
flutter --version   # 让工具重建快照
```

`flutter upgrade` 会冲掉补丁；临时兜底是 `dart analyze`（不走 LSP，结果一样）。

## 构建

| 平台 | 命令 | 前置条件 |
| --- | --- | --- |
| Linux | `flutter build linux --release` | 系统装有 libmpv（`libmpv2`） |
| Windows | `flutter build windows --release` | Visual Studio 的 C++ 桌面工作负载 |
| Android | `flutter build apk --release` | 可选 `android/key.properties`（没有则回落 debug 签名，不能发布） |

## 打包与自动更新

```bash
flutter build linux --release
./tool/package_linux.sh    # 产物：dist/tune-linux-x64-<version>.tar.gz
```

- 设置页「关于 → 检查更新」：桌面端从 GitHub release 读最新版本，下载对应平台归档换掉运行中的 bundle，重启生效。
- 1.5.0 之前的版本没有更新入口，用 `./tool/upgrade_local.sh` 升级一次。
- 发布步骤详见 `docs/updates.md`。

## 桌面图标

```bash
dart run flutter_launcher_icons        # 改完 branding/app_icon.png 后重生成各平台图标
dart run tool/generate_linux_icons.dart  # Linux 主题图标（图形缩到画布 13/16）
flutter build linux --debug && ./linux/install-desktop-entry.sh  # 装 XDG 桌面项（每台机器一次）
```

## 测试布局

`test/` 镜像 `lib/` 结构：

| 目录 | 放什么 |
| --- | --- |
| `test/app/` | controller、界面、设置测试；替身（`fake_*.dart`）也放这里 |
| `test/core/` | l10n、文本方向等核心工具 |
| `test/domain/` | 领域模型 |
| `test/services/` | 服务与适配器，含跨服务集成用例 |
| `tool/perf/` | 性能基准（库滚动、推荐、重建） |

替身约定：`FakeAudioPlayerService`、`FakeSongDownloadService`、`FakeStreamUrlResolver`、`FakePersistenceService`；controller 替身继承原类覆盖 `build()`。

语言守卫测试（改文案必读 `docs/i18n.md`）：`localization_test.dart`（扫源码查硬编码）、`localization_render_test.dart`（真渲染每页抓硬编码与超长标签）、`localization_numbers_test.dart`（数字分组）。

## 已知限制（摘自 README）

- 远程播放依赖网络；桌面端边播边缓存，播放不等待下载。
- Windows 用 just_audio_windows，不支持自定义请求头；Jellyfin、ccMixter 可能无法播放；无托盘与 MPRIS。
- Android / iOS 本地扫描需运行时存储权限，申请流程未实现，移动端本地库可能为空。
- 远程播放地址可能过期；网易云、Subsonic、播客、Jellyfin 支持单曲刷新，其余音源需重扫。
- 网络电台是直播流：不缓存、不显示进度条。
- 不支持任意脚本插件：自定义音源只接受声明式参数。

## 深入阅读

| 主题 | 权威文档 |
| --- | --- |
| 改动优先级与红线 | `AGENTS.md` §1 |
| 目录分层、扩展路径 | `docs/architecture.md` |
| 推荐 / 发现页 | `docs/recommendation.md` |
| 智能歌词票池共识 | `docs/smart-lyrics.md` |
| 队列模型 | `需求/队列模型方案.md` |
| 启动恢复播放 | `docs/playback-session.md` |
| 桌面集成协议 | `需求/桌面集成方案.md` |
| 文案与语言 | `docs/i18n.md`、`需求/多语言设计.md` |
| 性能预算 | `docs/performance.md` |
| 发布 | `docs/updates.md` |
