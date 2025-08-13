**添加规则文件可帮助模型精准理解你的编码偏好，如框架、代码风格等**
**规则文件只对当前工程生效，单文件限制10000字符。如果无需将该文件提交到远程 Git 仓库，请将其添加到 .gitignore**
1.导入必须使用绝对路径,避免使用相对路径
2.注释：
    必须使用中文注释
    注释必须在代码之前
3.尽量使用Bloc模式编写代码
4.框架：Clean Architecture架构
lib/
├── app/                          # 应用入口与全局配置
│   ├── app.dart                  # 根Widget（根据平台选择Material/Cupertino）
│   ├── app_initializer.dart      # 应用初始化（DI、日志、崩溃监控）
│   ├── router/
│   │   ├── app_router.dart       # 路由表（auto_route生成）
│   │   ├── route_guards.dart     # 路由守卫（登录校验、平台权限校验）
│   │   └── router_observer.dart  # 路由监听（统计页面跳转）
│   └── theme/
│       ├── app_theme.dart        # 主题入口（根据平台切换主题）
│       ├── material_theme.dart   # Material Design主题（移动/桌面）
│       ├── cupertino_theme.dart  # Cupertino主题（iOS优先）
│       └── web_theme.dart        # Web端专属样式（如滚动条、字体缩放）
│
├── core/                         # 全平台通用核心（无平台依赖）
│   ├── config/
│   │   ├── env/
│   │   │   ├── env.dart          # 环境抽象类（API地址、超时等）
│   │   │   ├── dev_env.dart      # 开发环境
│   │   │   └── prod_env.dart     # 生产环境
│   │   ├── app_constants.dart    # 全局常量（版本号、存储键前缀）
│   │   └── platform_constants.dart # 平台相关常量（如桌面端窗口大小）
│   ├── error/
│   │   ├── exceptions/
│   │   │   ├── app_exception.dart # 基础异常类
│   │   │   ├── network_exception.dart # 网络异常
│   │   │   └── platform_exception.dart # 平台适配异常
│   │   ├── error_handler.dart    # 全局错误处理（统一弹窗、日志）
│   │   └── error_widgets/
│   │       ├── network_error_widget.dart # 网络错误页
│   │       └── platform_unsupported_widget.dart # 平台不支持页
│   ├── network/
│   │   ├── client/
│   │   │   ├── api_client.dart   # API客户端抽象接口
│   │   │   └── dio_client.dart   # Dio实现（全平台共用，配置差异化）
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart # 认证拦截器
│   │   │   └── log_interceptor.dart  # 日志拦截器（Web端屏蔽敏感信息）
│   │   └── network_info.dart     # 网络状态检测（抽象接口）
│   ├── storage/
│   │   ├── storage.dart          # 存储抽象接口（get/set/delete）
│   │   └── secure_storage.dart   # 安全存储抽象接口（加密数据）
│   ├── utils/
│   │   ├── date_utils.dart       # 日期工具（纯Dart，全平台复用）
│   │   ├── string_utils.dart     # 字符串工具
│   │   └── validation_utils.dart # 表单校验工具
│   └── widgets/
│       ├── common/
│       │   ├── loading_indicator.dart # 加载指示器（全平台统一样式）
│       │   └── error_retry_button.dart # 错误重试按钮
│       └── layout/
│           ├── adaptive_container.dart # 自适应容器（根据平台调整内边距）
│           └── responsive_layout.dart # 响应式布局（适配不同屏幕尺寸）
│
├── domain/                       # 领域层（纯Dart，全平台100%复用）
│   ├── entities/
│   │   ├── song.dart             # 歌曲实体（id、名称、歌手、时长等）
│   │   ├── playlist.dart         # 歌单实体
│   │   └── user.dart             # 用户实体
│   ├── repositories/
│   │   ├── music_repository.dart # 音乐仓库接口（定义获取歌曲、歌单的契约）
│   │   └── user_repository.dart  # 用户仓库接口
│   └── usecases/
│       ├── music/
│       │   ├── get_song_usecase.dart # 获取单首歌曲用例
│       │   └── get_playlist_usecase.dart # 获取歌单用例
│       └── user/
│           └── login_usecase.dart # 登录用例
│
├── data/                         # 数据层（实现领域接口，处理数据）
│   ├── repositories/
│   │   ├── music_repository_impl.dart # 音乐仓库实现
│   │   └── user_repository_impl.dart  # 用户仓库实现
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── music_remote_datasource.dart # 音乐远程数据源（API调用）
│   │   │   └── user_remote_datasource.dart  # 用户远程数据源
│   │   └── local/
│   │       ├── music_local_datasource.dart # 音乐本地数据源（缓存歌曲）
│   │       └── user_local_datasource.dart  # 用户本地数据源（缓存登录信息）
│   ├── models/                   # DTO模型（与API/DB字段对应）
│   │   ├── song_dto.dart         # 歌曲DTO
│   │   └── user_dto.dart         # 用户DTO
│   └── mappers/                  # DTO ↔ 实体转换
│       ├── song_mapper.dart      # 歌曲映射
│       └── user_mapper.dart      # 用户映射
│
├── presentation/                 # 表现层（UI与状态，复用为主）
│   ├── blocs/
│   │   ├── music/
│   │   │   ├── song_bloc.dart    # 歌曲状态管理
│   │   │   ├── song_state.dart   # 歌曲状态
│   │   │   └── song_event.dart   # 歌曲事件
│   │   └── player/
│   │       ├── player_cubit.dart # 播放器Cubit（播放/暂停/切歌）
│   │       └── player_state.dart # 播放器状态
│   ├── pages/
│   │   ├── home/
│   │   │   ├── home_page.dart    # 首页（全平台复用）
│   │   │   └── home_page_desktop.dart # 桌面端首页（仅布局差异）
│   │   ├── player/
│   │   │   └── music_player_page.dart # 音乐播放页
│   │   └── login/
│   │       └── login_page.dart   # 登录页
│   └── widgets/
│       ├── music/
│       │   ├── song_card.dart    # 歌曲卡片（全平台复用）
│       │   └── playlist_grid.dart # 歌单网格
│       └── player/
│           ├── player_controls.dart # 播放控制组件
│           └── progress_bar.dart # 进度条组件
│
├── platform/                     # 平台适配层（隔离差异）
│   ├── services/
│   │   ├── network/
│   │   │   ├── network_info_mobile.dart # 移动端网络检测（Connectivity_plus）
│   │   │   ├── network_info_web.dart    # Web端网络检测（Navigator.connection）
│   │   │   └── network_info_desktop.dart # 桌面端网络检测
│   │   ├── storage/
│   │   │   ├── local_storage_mobile.dart # 移动端存储（Hive）
│   │   │   ├── local_storage_web.dart    # Web端存储（localStorage）
│   │   │   └── local_storage_desktop.dart # 桌面端存储（SQLite）
│   │   ├── media/
│   │   │   ├── audio_player_mobile.dart # 移动端音频播放（just_audio）
│   │   │   ├── audio_player_web.dart    # Web端音频播放（audio_web）
│   │   │   └── audio_player_desktop.dart # 桌面端音频播放（dart_vlc）
│   │   └── permissions/
│   │       ├── permission_service_mobile.dart # 移动端权限（permission_handler）
│   │       └── permission_service_desktop.dart # 桌面端权限（直接返回允许）
│   ├── widgets/
│   │   ├── navigation/
│   │   │   ├── mobile_bottom_nav.dart   # 移动端底部导航
│   │   │   ├── desktop_side_nav.dart    # 桌面端侧边导航
│   │   │   └── web_top_nav.dart         # Web端顶部导航
│   │   └── controls/
│   │       ├── desktop_volume_slider.dart # 桌面端音量滑块（带快捷键）
│   │       └── mobile_volume_button.dart # 移动端音量按钮（双击放大）
│   └── channel/
│       ├── mobile_channel.dart    # 移动端MethodChannel（调用原生API）
│       └── web_channel.dart       # Web端JS交互（js_interop）
│
├── features/                     # 业务模块（按功能拆分）
│   ├── music_library/            # 音乐库模块（示例）
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   └── social_share/             # 社交分享模块（示例）
│       ├── presentation/
│       ├── domain/
│       └── data/
│
└── di/                           # 依赖注入
├── injector.dart             # 注入器入口（初始化所有模块）
├── core_module.dart          # 核心服务注册（无平台依赖）
├── data_module.dart          # 数据层服务注册
└── platform_module.dart      # 平台服务注册（根据运行时平台动态选择）
5.本地化支持中英日韩俄
6.使用flutter analyze查看缺失key,在app_en添加缺失的key,并且根据完善好的en生成其他语言的arb,然后执行i10n-gen
