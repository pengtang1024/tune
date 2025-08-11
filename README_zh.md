# Tune - 跨平台音乐播放器

<p align="center">
  <img src="app.png" width="200" alt="Tune Logo" />
</p>

<p align="center">
  让每一段旋律都找到归属
</p>

<p align="center">
  <a href="README.md">中文</a> •
  <a href="README_en.md">English</a> •
  <a href="README_ja.md">日本語</a> •
  <a href="README_ko.md">한국어</a> •
  <a href="README_ru.md">Русский</a>
</p>

## 🎵 关于 Tune

在喧嚣的日常里，总有一些旋律会悄悄住进心里 —— 可能是清晨唤醒你的轻快节奏，是深夜陪伴你的温柔民谣，或是旅途中偶然邂逅的惊喜单曲。

Tune 不止是一款音乐播放器，更是你私人的「旋律收纳箱」。在这里，你可以轻松整理本地音乐库，按风格、心情或场景自定义歌单，让每首歌都在最合适的位置等你；流畅的播放体验搭配细腻的音效调节，让耳机里的每一个音符都清晰饱满，仿佛置身现场；简约而不简单的界面设计，藏着对音乐的纯粹热爱，没有多余干扰，只有你与音乐的独处时光。

无论是珍藏多年的经典老歌，还是刚发现的小众佳作，Tune 都能帮你妥帖安放，让每一次点开都成为一场美好的听觉重逢。

用 Tune，让音乐回归本真，让每段时光都有旋律相伴。

## 🌟 特性

- 🎧 **高质量音频播放** - 支持 MP3、FLAC、WAV 等多种音频格式
- 📚 **本地音乐管理** - 自动扫描并整理本地音乐库，支持元数据解析
- 🎨 **多主题支持** - 8种精美主题（潮流轻电、极简灰调、自然森系、赛博霓虹、暖调治愈等），支持深色/浅色模式自动切换
- 🌍 **多语言支持** - 支持中文、英文、日文、韩文、俄文
- 📱 **跨平台兼容** - Android、iOS、Windows、macOS、Linux、Web 全平台支持
- ⚡ **流畅体验** - 后台播放、通知栏控制、快速搜索
- 🎛️ **个性化设置** - 字体、主题、语言等丰富自定义选项
- 🎯 **智能推荐** - 基于播放历史的个性化音乐推荐
- 📥 **离线缓存** - 支持在线音乐缓存，随时随地享受音乐
- 📋 **播放列表** - 支持创建和管理自定义播放列表
- 🔄 **多种播放模式** - 列表循环、单曲循环、随机播放
- ⏩ **播放控制** - 支持播放进度拖拽、音量调节、播放速度调节(0.5x-2.0x)
- 🎵 **歌词同步** - 支持LRC格式歌词实时同步显示
- 🔍 **智能搜索** - 支持按歌曲名、艺术家、专辑搜索

## 🎨 主题预览

Tune 提供了多种精美主题供您选择：

1. **时尚电子 (Trendy Electro)** - 紫色调现代电子风格
2. **极简灰调 (Minimal Gray)** - 简洁的灰色调设计
3. **自然森系 (Nature Forest)** - 清新的绿色自然风格
4. **赛博霓虹 (Cyber Neon)** - 未来感的霓虹色彩
5. **温暖治愈 (Warm Healing)** - 温馨的橙色治愈系
6. **暖橙渐变 (Warm Orange Gradient)** - 渐变橙色温暖风格
7. **单色主题 (Monochrome)** - 统一色彩的极简设计
8. **鲜艳红调 (Vibrant Red)** - 热情洋溢的红色主题

所有主题均遵循"浅色通透、深色细腻"的设计理念，采用低饱和度色彩搭配，营造高级感。

## 🛠 技术架构

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

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.8.1 或更高版本
- Dart SDK 3.8.1 或更高版本
- 支持的 IDE (Android Studio / VS Code)

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 开发模式运行
flutter run

# 构建特定平台
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
flutter build windows  # Windows
flutter build macos    # macOS
flutter build linux    # Linux
```

## 🔧 主要依赖

- **音频播放**: [just_audio](https://pub.dev/packages/just_audio)
- **状态管理**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **路由管理**: [auto_route](https://pub.dev/packages/auto_route)
- **本地存储**: [hive](https://pub.dev/packages/hive), [shared_preferences](https://pub.dev/packages/shared_preferences)
- **网络请求**: [dio](https://pub.dev/packages/dio)
- **依赖注入**: [get_it](https://pub.dev/packages/get_it)
- **国际化**: [flutter_localizations](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)

## 📱 平台支持

| 平台     | 状态     | 备注 |
|----------|----------|------|
| Android  | ✅ 支持   | API 21+ |
| iOS      | ✅ 支持   | iOS 11+ |
| Windows  | ✅ 支持   | Windows 10+ |
| macOS    | ✅ 支持   | macOS 10.15+ |
| Linux    | ✅ 支持   | Ubuntu 20.04+ |
| Web      | ✅ 支持   | 现代浏览器 |

## 🤝 贡献

欢迎任何形式的贡献！如果您想为 Tune 做出贡献，请遵循以下步骤：

1. Fork 本仓库
2. 创建您的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- 感谢所有为开源社区做出贡献的开发者
- 感谢 Flutter 团队提供的优秀框架
- 感谢 JetBrains 提供的开发工具支持

---

<p align="center">
  用 Tune，让音乐回归本真，让每段时光都有旋律相伴。
</p>