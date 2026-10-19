# Tune

[中文](README.md) · [English](README_en.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Русский](README_ru.md)

Tune 是一款紧凑的本地与在线音乐播放器，使用 Flutter 开发。界面采用双栏布局：左侧常驻播放器，右侧在音乐库、播放队列和设置之间切换。

## 功能

- 本地音乐目录扫描、搜索与持久化
- 在线音源：Openverse、Jamendo、Internet Archive、ccMixter、iTunes 试听、播客 RSS、自建 NeteaseCloudMusicApi 与自建 Navidrome/Subsonic
- 播放队列增删、拖拽重排、点播与清空
- 播放/暂停、上一首/下一首、进度拖拽、音量与循环模式
- 按来源筛选音乐库，远程歌曲显示来源与封面
- 浅色 / 深色 / 系统主题，扫描目录与音源配置持久化
- 900×600 默认窗口，最小 760×520

## 技术栈

- Flutter + Riverpod + go_router
- just_audio；Linux 使用 just_audio_media_kit + 系统 libmpv
- Dio、shared_preferences、file_picker
- flutter_localizations / gen-l10n

## 项目结构

```text
lib/
├── app/                  # 应用入口、路由、主题、壳层
├── features/             # player / library / queue / settings / sources
├── data/services/        # 音频、扫描、音源适配器、持久化
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

## 已知限制

- 当前主要验收平台为 Linux 桌面端。
- 远程播放依赖网络，暂未提供下载/离线缓存。
- 远程播放地址可能过期，需要重新扫描对应音源刷新。
- 旧版移动端通知、歌词、均衡器、播放历史与账户功能已移出主链路。

## 许可证

[MIT License](LICENSE)
