# Tune

[中文](README.md) · [English](README_en.md)

Tune 是一款紧凑的本地与在线音乐播放器，使用 Flutter 开发。界面采用双栏布局：左侧常驻播放器，右侧在音乐库、播放队列和设置之间切换。

## 功能

- 本地音乐目录扫描、搜索与持久化
- 在线音源：Openverse、Jamendo、Internet Archive、ccMixter、iTunes 试听、播客 RSS、Audius、Wikimedia Commons、网络电台，以及自建 NeteaseCloudMusicApi、Navidrome/Subsonic 与 Jellyfin
- 自己添加音源：挑一个类型（直链音频、播放列表、JSON 接口、GraphQL 接口……），填上它的参数就是一个新实例；同一类型可以加好几个
- 播放队列增删、拖拽重排、点播与清空
- 播放/暂停、上一首/下一首、进度拖拽、音量与循环模式
- 按来源筛选音乐库，远程歌曲显示来源与封面
- 曲目行用图标标识格式、音质、码率等，悬停看说明，点开看完整曲目信息与文件路径
- 喜欢：曲目行、播放队列与正在播放页都有红心，标过的曲子收在「喜欢」页里
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

```bash
flutter build linux --debug
```

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
- 远程播放地址可能过期；网易云、Subsonic、播客订阅与 Jellyfin 支持单曲刷新，其余音源需重新扫描。
- 网络电台是直播流，不缓存、不显示进度条。
- 旧版移动端通知、歌词、均衡器、播放历史与账户功能已移出主链路。
- 不支持任意脚本插件：曾支持的 MusicFree JS 插件能力已下线，自定义音源只接受声明式参数。

## 许可证

[MIT License](LICENSE)
