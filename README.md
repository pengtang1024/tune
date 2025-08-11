# Tune - 音乐播放器 🎵

<p align="center">
  <img src="assets/icons/app_icon.png" alt="Tune Logo" width="120" />
</p>

<p align="center">
  <a href="README_zh.md">中文</a> |
  <a href="README_en.md">English</a> |
  <a href="README_ja.md">日本語</a> |
  <a href="README_ko.md">한국어</a> |
  <a href="README_ru.md">Русский</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/平台-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-blue" alt="支持的平台" />
  <img src="https://img.shields.io/badge/Flutter-%5E3.0-green" alt="Flutter 版本" />
  <img src="https://img.shields.io/badge/许可证-MIT-blue.svg" alt="许可证" />
</p>

Tune 是一款专注于提供简洁直观界面的跨平台音乐播放器应用，旨在帮助用户管理和播放本地音乐库。

在喧嚣的日常里，总有一些旋律会悄悄住进心里 —— 可能是清晨唤醒你的轻快节奏，是深夜陪伴你的温柔民谣，或是旅途中偶然邂逅的惊喜单曲。

Tune 不止是一款音乐播放器，更是你私人的「旋律收纳箱」。在这里，你可以轻松整理本地音乐库，按风格、心情或场景自定义歌单，让每首歌都在最合适的位置等你；流畅的播放体验搭配细腻的音效调节，让耳机里的每一个音符都清晰饱满，仿佛置身现场；简约而不简单的界面设计，藏着对音乐的纯粹热爱，没有多余干扰，只有你与音乐的独处时光。

无论是珍藏多年的经典老歌，还是刚发现的小众佳作，Tune 都能帮你妥帖安放，让每一次点开都成为一场美好的听觉重逢。

用 Tune，让音乐回归本真，让每段时光都有旋律相伴。

## 🎵 功能特性

 🎧 **高质量音频播放** - 支持 MP3、FLAC、WAV、AAC 等多种音频格式，提供流畅的播放体验

📚 **本地音乐管理** - 自动扫描并整理本地音乐库，支持元数据解析和封面提取

🎶 **播放控制** - 完整的播放控制功能（播放/暂停/停止/上一首/下一首），支持播放进度拖拽、音量调节、播放速度调节(0.5x-2.0x)

📋 **播放列表** - 支持创建和管理自定义播放列表，支持列表循环、单曲循环、随机播放等多种播放模式

🎵 **歌词同步** - 支持LRC格式歌词实时同步显示，提供沉浸式歌词体验

🔍 **智能搜索** - 支持按歌曲名、艺术家、专辑、流派等元数据快速搜索

🎨 **多主题支持** - 8种精美主题（潮流轻电、极简灰调、自然森系、赛博霓虹、暖调治愈等），支持深色/浅色模式自动切换，可自定义主题颜色

🌍 **多语言支持** - 支持中文、英文、日文、韩文、俄文等多种语言，界面语言可自动适配系统设置

📱 **响应式设计** - 适配不同屏幕尺寸，支持移动端和桌面端，提供最佳观看体验

⏯️ **后台播放** - 支持后台播放音乐，提供通知栏控制和锁屏控制

🎧 **音效调节** - 提供均衡器调节功能，支持音效增强、低音增强等音效设置

💾 **离线缓存** - 支持在线音乐缓存，随时随地享受音乐

🎯 **智能推荐** - 基于播放历史的个性化音乐推荐，发现更多好音乐

⚙️ **个性化设置** - 提供丰富的个性化设置选项，包括字体、主题、播放设置等

## 🏗️ 技术架构

本项目采用 Clean Architecture + BLoC 模式的分层架构，确保跨平台一致性和可维护性。

### 技术架构

Tune 采用 Clean Architecture + BLoC 模式构建，确保代码的可维护性和可扩展性：

```
lib/
├── app/                    # 应用核心配置
│   ├── router/             # 路由管理
│   └── theme/              # 主题系统
├── core/                   # 核心层
│   ├── bloc/               # 全局状态管理
│   ├── config/             # 应用配置
│   ├── error/              # 错误处理
│   ├── network/            # 网络相关
│   ├── services/           # 核心服务
│   ├── storage/            # 数据存储
│   ├── utils/              # 工具类
│   └── widgets/            # 核心组件
├── features/               # 功能模块
│   ├── audio/              # 音频播放功能
│   ├── home/               # 首页模块
│   ├── library/            # 音乐库模块
│   ├── player/             # 播放器模块
│   ├── profile/            # 个人资料模块
│   ├── search/             # 搜索模块
│   └── settings/           # 设置模块
├── l10n/                   # 国际化资源
└── di/                     # 依赖注入
```

### 核心模块

- **音频播放核心模块** - 使用 just_audio 实现播放、暂停、切换、进度控制等功能
- **音乐库模块** - 通过自定义实现获取本地音乐，支持在线流媒体资源
- **播放列表模块** - 使用 Hive 或 SQLite 存储播放列表
- **用户模块** - 支持第三方登录，用 shared_preferences 存储用户会话
- **UI/UX 模块** - 响应式设计，支持自定义主题和暗色模式

## 📦 主要技术栈

- **状态管理**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **路由管理**: [auto_route](https://pub.dev/packages/auto_route)
- **音频播放**: [just_audio](https://pub.dev/packages/just_audio)
- **本地音乐获取**: 自定义实现
- **权限管理**: [permission_handler](https://pub.dev/packages/permission_handler)
- **依赖注入**: [get_it](https://pub.dev/packages/get_it)
- **国际化**: [flutter_localizations](https://pub.dev/packages/flutter_localizations)

## 🚀 快速开始

1. 克隆项目:
   ```bash
   git clone <repository-url>
   ```

2. 安装依赖:
   ```bash
   flutter pub get
   ```

3. 运行应用:
   ```bash
   flutter run
   ```

## 🎯 跨平台适配

- **移动端**: 遵循平台设计规范，支持后台播放、锁屏控制和通知栏播放器控件
- **桌面端**: 设计窗口化布局，集成系统托盘，支持快捷键和多窗口
- **Web 端**: 实现响应式网页设计，处理浏览器音频限制，支持 PWA

## 🛠️ 常用命令

### 国际化

手动生成本地化文件:
```bash
flutter gen-l10n
```

### 图标

使用 flutter_launcher_icons 自动生成图标:
```bash
flutter pub run flutter_launcher_icons:main
```

### 代码生成

运行 build_runner 进行代码生成:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 测试

运行所有测试:
```bash
flutter test
```

运行带覆盖率的测试:
```bash
flutter test --coverage
```

## 🧪 测试策略

- **单元测试**: 测试用例和仓库逻辑
- **集成测试**: 测试数据源和网络请求
- **小部件测试**: 测试UI组件
- **端到端测试**: 测试用户流程

## 📱 平台支持

| 平台     | 状态     | 备注 |
|----------|----------|------|
| Android  | ✅ 支持   | API 21+ |
| iOS      | ✅ 支持   | iOS 11+ |
| Windows  | ✅ 支持   | Windows 10+ |
| macOS    | ✅ 支持   | macOS 10.15+ |
| Linux    | ✅ 支持   | Ubuntu 20.04+ |
| Web      | ✅ 支持   | 现代浏览器
## 📱 平台支持

| 平台     | 状态     | 备注 |
|----------|----------|------|
| Android  | ✅ 支持   | API 21+ |
| iOS      | ✅ 支持   | iOS 11+ |
| Windows  | ✅ 支持   | Windows 10+ |
| macOS    | ✅ 支持   | macOS 10.15+ |
| Linux    | ✅ 支持   | Ubuntu 20.04+ |
| Web      | ✅ 支持   | 现代浏览器

## 📄 许可证

本项目采用 MIT 许可证 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
