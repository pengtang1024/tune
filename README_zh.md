# Tune - 你的私人旋律收纳箱

Tune 是一款音乐播放器应用，旨在为你提供简洁直观的界面来管理和播放本地音乐库。

## 功能特点

- **本地音乐库管理**: 轻松整理本地音乐文件
- **自定义播放列表**: 按风格、心情或场景创建播放列表
- **流畅播放体验**: 享受高品质音频播放
- **音效调节**: 通过可自定义的声音设置微调音频
- **极简界面**: 专注于音乐体验的简洁设计

## 安装步骤

1. 确保你的机器上已安装 Flutter
2. 克隆此代码仓库
3. 运行 `flutter pub get` 安装依赖
4. 连接设备或启动模拟器
5. 运行 `flutter run` 启动应用程序

## 支持平台

- Android
- iOS
- Linux
- macOS
- Windows
- Web

## 项目描述

Tune：让每一段旋律都找到归属 在喧嚣的日常里，总有一些旋律会悄悄住进心里 —— 可能是清晨唤醒你的轻快节奏，是深夜陪伴你的温柔民谣，或是旅途中偶然邂逅的惊喜单曲。 

Tune 不止是一款音乐播放器，更是你私人的「旋律收纳箱」。在这里，你可以轻松整理本地音乐库，按风格、心情或场景自定义歌单，让每首歌都在最合适的位置等你；流畅的播放体验搭配细腻的音效调节，让耳机里的每一个音符都清晰饱满，仿佛置身现场；简约而不简单的界面设计，藏着对音乐的纯粹热爱，没有多余干扰，只有你与音乐的独处时光。

无论是珍藏多年的经典老歌，还是刚发现的小众佳作，Tune 都能帮你妥帖安放，让每一次点开都成为一场美好的听觉重逢。

用 Tune，让音乐回归本真，让每段时光都有旋律相伴。

## 技术架构

本项目采用 Clean Architecture + BLoC 模式的分层架构，确保跨平台一致性和可维护性。

### 架构分层

1. **表现层 (Presentation Layer)**
   - 页面 (Pages)
   - 组件 (Components)
   - BLoC 状态管理
   - 路由管理

2. **领域层 (Domain Layer)**
   - 实体 (Entities)
   - 用例 (Use Cases)
   - 仓库接口 (Repository Interfaces)

3. **数据层 (Data Layer)**
   - 仓库实现 (Repository Implementations)
   - 数据源接口 (Data Source Interfaces)
   - 本地数据源 (Local Data Sources)
   - 远程数据源 (Remote Data Sources)

4. **核心层 (Core Layer)**
   - 服务 (Services)
   - 工具类 (Utils)
   - 常量 (Constants)
   - 全局状态 (Global State)

### 核心模块

- **音频播放核心模块**: 使用 just_audio 实现播放、暂停、切换、进度控制等功能
- **音乐库模块**: 通过自定义实现获取本地音乐，支持在线流媒体资源
- **播放列表模块**: 使用 Hive 或 SQLite 存储播放列表
- **用户模块**: 支持第三方登录，用 shared_preferences 存储用户会话
- **UI/UX 模块**: 响应式设计，支持自定义主题和暗色模式

## 📦 主要技术栈

- 状态管理: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- 路由管理: [auto_route](https://pub.dev/packages/auto_route)
- 音频播放: [just_audio](https://pub.dev/packages/just_audio)
- 本地音乐获取: 自定义实现
- 权限管理: [permission_handler](https://pub.dev/packages/permission_handler)
- 依赖注入: [get_it](https://pub.dev/packages/get_it)
- 国际化: [flutter_localizations](https://pub.dev/packages/flutter_localizations)

## 跨平台适配

- **移动端**: 遵循平台设计规范，支持后台播放、锁屏控制和通知栏播放器控件
- **桌面端**: 设计窗口化布局，集成系统托盘，支持快捷键和多窗口
- **Web 端**: 实现响应式网页设计，处理浏览器音频限制，支持 PWA

## 目录结构

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

## 常用命令

### 国际化

手动生成本地化文件:
```
flutter gen-l10n
```

### 图标

使用 flutter_launcher_icons 自动生成图标:
```
flutter pub run flutter_launcher_icons:main
```

### 代码生成

运行 build_runner 进行代码生成:
```
flutter pub run build_runner build --delete-conflicting-outputs
```

### 测试

运行所有测试:
```
flutter test
```

运行带覆盖率的测试:
```
flutter test --coverage
```

## 测试策略

- 单元测试: 测试用例和仓库逻辑
- 集成测试: 测试数据源和网络请求
- 小部件测试: 测试UI组件
- 端到端测试: 测试用户流程

## 扩展性考虑

- 采用插件化架构
- 支持 API 版本控制
- 提供可配置主题
- 实现模块化测试确保稳定性