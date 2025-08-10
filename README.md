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

🎵 **音乐播放模块** - 集成 just_audio 实现高质量音频播放，支持多种音频格式（MP3、FLAC、WAV等），提供播放控制（播放/暂停/停止/上一首/下一首）、音量控制、播放进度控制等功能

📋 **音乐库模块** - 通过自定义实现获取本地音乐，支持在线流媒体资源

🔊 **流畅的播放体验** - 享受高保真的音频播放质量

🎚️ **音效调节** - 精细调节音频参数，自定义声音设置

🎨 **主题系统** - 支持多种预设主题（Trendy Electro、Minimal Gray、Nature Forest、Cyber Neon、Warm Healing），可跟随系统主题或手动切换

🌍 **多语言支持** - 支持中英文切换，可扩展更多语言

📱 **响应式设计** - 适配不同屏幕尺寸，支持移动端和桌面端

⏯️ **后台播放** - 支持后台播放音乐，提供通知栏控制

## 🏗️ 技术架构

本项目采用 Clean Architecture + BLoC 模式的分层架构，确保跨平台一致性和可维护性。

### 架构分层

```
lib/
├── config/                 # 配置文件
│   └── theme/              # 主题配置
├── core/                   # 核心层
│   ├── di/                 # 依赖注入
│   ├── routes/             # 路由管理
│   ├── services/           # 核心服务
│   └── utils/              # 工具类
├── data/                   # 数据层
│   ├── datasources/        # 数据源
│   ├── models/             # 数据模型
│   └── repositories/       # 仓库实现
├── domain/                 # 领域层
│   ├── entities/           # 实体
│   ├── repositories/       # 仓库接口
│   └── usecases/           # 用例
└── presentation/           # 表现层
    ├── bloc/               # 状态管理
    ├── pages/              # 页面
    ├── widgets/            # 通用组件
    └── components/         # 业务组件
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

## 📈 扩展性考虑

- 采用插件化架构
- 支持 API 版本控制
- 提供可配置主题
- 实现模块化测试确保稳定性

## 📄 许可证

本项目采用 MIT 许可证 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。