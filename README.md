# Tune - 现代化音乐播放器

Tune 是一款现代化的跨平台音乐播放器应用，使用 Flutter 框架开发，支持 Windows、Android 和 iOS 平台。

## 功能特性

- 🎵 本地音乐播放
- 📊 智能音乐库管理
- 🎨 个性化主题定制
- ⚡ 高性能音频解码
- 📱 跨平台支持
- 🔒 安全数据存储

## 技术栈

- **框架**: Flutter
- **状态管理**: Riverpod
- **路由管理**: Go Router
- **主题管理**: FlexColorScheme
- **音频播放**: just_audio
- **本地存储**: Hive, Shared Preferences, Flutter Secure Storage
- **权限管理**: Permission Handler
- **国际化**: Flutter Intl

## 安全特性

- 使用 `flutter_secure_storage` 加密存储敏感数据
- 路径验证防止路径遍历攻击
- 输入验证和错误处理

## 性能优化

- 图片加载优化（cacheWidth/cacheHeight）
- 列表渲染优化（cacheExtent）
- 音频播放资源管理
- 内存泄漏预防

## 项目结构

```
lib/
├── core/                 # 核心功能
│   ├── extension/        # 扩展功能
│   ├── router/           # 路由管理
│   └── settings/         # 设置相关
├── data/                 # 数据层
│   ├── models/           # 数据模型
│   ├── repositories/     # 数据仓库
│   └── services/         # 数据服务
├── domain/               # 业务逻辑层
│   └── models/           # 领域模型
├── ui/                   # 表现层
│   ├── core/             # 核心UI组件
│   ├── home/             # 首页
│   ├── library/          # 音乐库
│   ├── player/           # 播放器
│   └── widgets/          # 通用组件
├── providers/            # Riverpod提供者
└── utils/                # 工具类
```

## 安装与运行

1. 克隆项目
```bash
git clone <repository-url>
cd tune
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 构建

- Windows: `flutter build windows`
- Android: `flutter build apk`
- iOS: `flutter build ios`

## 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进项目。

## 许可证

[MIT License](LICENSE)