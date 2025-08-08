# Tune - 音乐播放器

Tune 是一款专注于提供简洁直观界面的跨平台音乐播放器应用，旨在帮助用户管理和播放本地音乐库。

## 功能特性

- 本地音乐库管理
- 自定义播放列表（按风格、心情或场景）
- 流畅的音频播放体验
- 音效调节（Equalizer）
- 极简界面设计
- 支持多平台（Android、iOS、Windows、macOS、Linux 和 Web）

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
- **音乐库模块**: 通过 on_audio_query 获取本地音乐，支持在线流媒体资源
- **播放列表模块**: 使用 Hive 或 SQLite 存储播放列表
- **用户模块**: 支持第三方登录，用 shared_preferences 存储用户会话
- **UI/UX 模块**: 响应式设计，支持自定义主题和暗色模式

## 技术栈

- 音频播放: [just_audio](https://pub.dev/packages/just_audio)
- 状态管理: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- 本地存储: [hive](https://pub.dev/packages/hive) + [shared_preferences](https://pub.dev/packages/shared_preferences)
- 网络请求: [dio](https://pub.dev/packages/dio)
- 路由管理: [auto_route](https://pub.dev/packages/auto_route)
- 本地音乐获取: [on_audio_query](https://pub.dev/packages/on_audio_query)
- 权限管理: [permission_handler](https://pub.dev/packages/permission_handler)
- 后台任务: [workmanager](https://pub.dev/packages/workmanager) (Android) + [background_fetch](https://pub.dev/packages/background_fetch) (iOS)
- UI 组件: [flutter_screenutil](https://pub.dev/packages/flutter_screenutil)

## 跨平台适配

- **移动端**: 遵循平台设计规范，支持后台播放、锁屏控制和通知栏播放器控件
- **桌面端**: 设计窗口化布局，集成系统托盘，支持快捷键和多窗口
- **Web 端**: 实现响应式网页设计，处理浏览器音频限制，支持 PWA

## 快速开始

1. 克隆项目:
   ```
   git clone <repository-url>
   ```

2. 安装依赖:
   ```
   flutter pub get
   ```

3. 运行应用:
   ```
   flutter run
   ```

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