# Tune

[中文](README.md) · [English](README_en.md)

Tune 是一款紧凑的本地与在线音乐播放器，使用 Flutter 开发。界面由左侧导航（发现 / 音乐库 / 喜欢 / 音源 / 设置）、右侧内容区和底部播放条组成；播放队列是底栏或正在播放页打开的非模态侧栏，不占用导航位；它只遮住内容区，底栏和侧栏仍可用。

## 功能

- 本地音乐目录扫描、搜索与持久化
- 在线音源：Openverse、Jamendo、Internet Archive、ccMixter、iTunes 试听、播客 RSS、Audius、Wikimedia Commons、网络电台，以及自建 NeteaseCloudMusicApi、Navidrome/Subsonic 与 Jellyfin
- 自己添加音源：挑一个类型（直链音频、播放列表、JSON 接口、GraphQL 接口……），填上它的参数就是一个新实例；同一类型可以加好几个
- 播放队列增删、拖拽重排、点播与清空
- 播放/暂停、上一首/下一首、进度拖拽、音量与循环模式
- 按来源筛选音乐库，远程歌曲显示来源与封面
- 曲目行用图标标识格式、音质、码率等，悬停看说明，点开看完整曲目信息与文件路径
- 喜欢：曲目行、播放队列、在线搜索结果、正在播放页与底栏的播放卡片都有红心，标过的曲子收在「喜欢」页里
- 发现：从音乐库和喜欢里挑今日混音、歌手与流派分段；只在本机计算，不请求音源接口；可选开启本地播放记录改善推荐；可按歌手显式在线找更多；单曲与歌手都能少推荐，可撤销；已经在队列里的曲目会降权；健康度低的音源在推荐里也会降权
- 浅色 / 深色 / 系统主题，扫描目录与音源配置持久化
- 界面语言：简体中文、繁體中文、中文（通用）、English；切换语言后音源名、日期与数字格式一起跟随
- 900×600 默认窗口，最小 760×520
- Linux 桌面集成：系统托盘常驻（关窗口后继续播放）、MPRIS 系统媒体控制（键盘媒体键、`playerctl`）、可设为音频文件的默认程序

## 技术栈

- Flutter + Riverpod + go_router
- just_audio；Linux 使用 just_audio_media_kit + 系统 libmpv
- Dio、shared_preferences、file_picker
- flutter_localizations / gen-l10n

## 项目结构

```text
lib/
├── app/                  # 应用入口、路由、主题、壳层
├── features/             # player / library / queue / settings / sources / desktop
├── data/services/        # 音频、扫描、音源适配器、持久化、MPRIS、托盘
├── domain/models/        # Song、音源配置与扫描结果
├── shared/               # 通用 UI 与工具
└── l10n/                 # 国际化资源
```

音源模型与扩展方式见 [需求/音源设计.md](需求/音源设计.md)。

## 运行

```bash
flutter pub get
flutter run -d linux
```

## 构建

Linux 是当前验收平台：

```bash
flutter build linux --debug
```

其它平台保留工程入口，要在对应系统上构建：

| 平台 | 命令 | 前置条件 |
| --- | --- | --- |
| Linux | `flutter build linux --release` | 系统装有 libmpv（`libmpv2`） |
| Windows | `flutter build windows --release` | Visual Studio 的 C++ 桌面工作负载 |
| macOS | `flutter build macos --release` | Xcode 命令行工具 |
| Android | `flutter build apk --release` | 可选 `android/key.properties`，见下 |
| Web | `flutter build web --release` | — |

Android 的 release 签名从 `android/key.properties` 读取 `storeFile`、`storePassword`、`keyAlias`、`keyPassword`。没有该文件时回落到 debug 签名，产物只能本机试装，不能发布。

## 桌面图标

- 原图是 `branding/app_icon.png`；改完原图后跑 `dart run flutter_launcher_icons` 重新生成各平台图标。原图不进包，`assets/` 里只放运行时要用的素材。
- Linux 的主题图标另有一条规则：图形缩到画布的 13/16 留出透明边，跟别的应用一样大。改完原图再跑 `dart run tool/generate_linux_icons.dart`。
- Linux 的 dock 与任务栏图标来自桌面项，程序自身也带一份窗口图标。
- 桌面项要装进本机的 XDG 目录，dock 才会显示 Tune 的图标（每次换机器装一次）：

```bash
flutter build linux --debug
./linux/install-desktop-entry.sh
```

## 已知限制

- 当前主要验收平台为 Linux 桌面端。
- 远程播放依赖网络；桌面端边播边缓存，播放不等待下载，Web 端只能流式播放。
- Web 端没有本地音乐目录，也没有托盘、MPRIS 与默认播放器设置；音乐库索引存在浏览器里，刷新后还在。
- 浏览器不允许脚本自定义 `User-Agent` 与 `Referer`，Web 端也带不了请求头；需要请求头的音源（Jellyfin、ccMixter）在 Web 端可能无法播放。
- 浏览器的同源策略会拦掉没有返回 CORS 头的接口（Wikimedia、ccMixter 等），这些音源在 Web 端扫描失败；能否播完取决于对方接口是否放行浏览器。
- Windows 使用 just_audio_windows 播放，不支持自定义请求头；需要请求头的音源（Jellyfin、ccMixter）可能无法播放，且没有托盘与 MPRIS 媒体控制。
- macOS 没有托盘与 MPRIS 媒体控制；沙盒只放行 `~/Music` 和用户亲手选过的目录，重开应用后若目录访问被拒，需要重新选择一次。
- Android / iOS 的本地扫描需要运行时存储权限，当前没有实现申请流程，移动端本地库可能为空；在线音源不受影响。
- 远程播放地址可能过期；网易云、Subsonic、播客订阅与 Jellyfin 支持单曲刷新，其余音源需重新扫描。
- 网络电台是直播流，不缓存、不显示进度条。
- 旧版移动端通知、歌词、均衡器、播放历史与账户功能已移出主链路。
- 不支持任意脚本插件：曾支持的 MusicFree JS 插件能力已下线，自定义音源只接受声明式参数。

## 许可证

Tune 的源代码采用 [MIT License](LICENSE)。内置字体采用 SIL OFL-1.1；Dart/Flutter
依赖的许可证随安装包的 `NOTICES` 分发；Linux 播放依赖系统的 libmpv（Ubuntu 打包为
GPL-3+，不随 Tune 分发）。完整的第三方声明见
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
